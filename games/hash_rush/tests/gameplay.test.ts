import { describe, expect, it } from 'vitest';
import { Rng } from '../src/core/Rng';
import { BossState, BossSystem } from '../src/gameplay/BossSystem';
import { agentDamage, enemyDamage } from '../src/gameplay/CombatSystem';
import { AgentState, CrowdSystem, agentScale } from '../src/gameplay/CrowdSystem';
import { ADD_GATE_COOLDOWN, GateSystem, applyGate, type GateRuntime } from '../src/gameplay/GateSystem';
import { ObstacleSystem } from '../src/gameplay/ObstacleSystem';
import { EnemySystem } from '../src/gameplay/EnemySystem';
import { ProjectileSystem } from '../src/gameplay/ProjectileSystem';
import { Simulation } from '../src/gameplay/Simulation';
import { SpatialGrid } from '../src/gameplay/SpatialGrid';
import { UPGRADES, UPGRADE_IDS, computeStats, upgradeCost, zeroUpgrades } from '../src/gameplay/Upgrades';
import { FX, FxQueue, SIM_DT, SPAWN_BUDGET, UNIT_CAP } from '../src/gameplay/constants';
import type { GateOp, LevelConfig } from '../src/levels/LevelConfig';
import { add, div, mul, sub } from '../src/levels/LevelGenerator';
import { getLevel } from '../src/levels/LevelManager';
import { playLevel } from './bot';

const gate = (op: GateOp): GateRuntime => ({ def: { z: 10, x: 0, width: 4, op }, x: 0, cooldown: 0, flash: 0, produced: 0, activations: 0, lost: 0, carry: 0 });
const crowdOf = (n: number, cap = 600) => {
  const crowd = new CrowdSystem(new Rng(1), cap);
  crowd.add(0, 5, n, n);
  return crowd;
};
const firstActive = (c: CrowdSystem) => {
  for (let i = 0; i < c.cap; i++) if (c.isActive(i)) return i;
  return -1;
};
const baseStats = computeStats(zeroUpgrades());

describe('gate multiplication', () => {
  it.each([2, 3, 5, 10, 100])('×%i turns one unit into exactly that many', (k) => {
    const crowd = crowdOf(1);
    const added = applyGate(gate(mul(k)), crowd, firstActive(crowd), new FxQueue());
    expect(added).toBe(k - 1);
    expect(crowd.count).toBe(k);
  });

  it.each([1, 5, 10, 25])('+%i adds exactly that many', (n) => {
    const crowd = crowdOf(7);
    applyGate(gate(add(n)), crowd, firstActive(crowd), new FxQueue());
    expect(crowd.count).toBe(7 + n);
  });

  it('multiplies an agent that stands for many units by its full strength', () => {
    const crowd = new CrowdSystem(new Rng(1), 4);
    crowd.add(0, 5, 40, 1); // one agent, strength 40
    const g = gate(mul(3));
    applyGate(g, crowd, firstActive(crowd), new FxQueue());
    expect(crowd.count).toBe(120);
    expect(g.produced).toBe(80);
  });

  it('an additive gate pays once, then recharges', () => {
    const crowd = crowdOf(3);
    const g = gate(add(10));
    const fx = new FxQueue();
    expect(applyGate(g, crowd, 0, fx)).toBe(10);
    expect(applyGate(g, crowd, 1, fx)).toBe(0);
    expect(crowd.count).toBe(13);
    g.cooldown = 0;
    expect(applyGate(g, crowd, 1, fx)).toBe(10);
    expect(ADD_GATE_COOLDOWN).toBeGreaterThan(0);
  });

  it('every unit that crosses a ×2 gate is doubled exactly once', () => {
    const crowd = crowdOf(50, 600);
    const gates = new GateSystem([{ z: 10, x: 0, width: 10, op: mul(2) }]);
    const fx = new FxQueue();
    for (let t = 0; t < 240; t++) {
      crowd.update(SIM_DT, 0, 20, 1000, []);
      gates.update(SIM_DT, crowd, fx, 0, 100);
      fx.clear();
    }
    expect(crowd.count).toBe(100);
  });

  it('very large multipliers stop at the population cap and report what was dropped', () => {
    const crowd = crowdOf(100);
    const fx = new FxQueue();
    const g = gate(mul(100));
    for (let i = 0; i < crowd.cap; i++) if (crowd.isActive(i)) applyGate(g, crowd, i, fx);
    expect(crowd.count).toBe(UNIT_CAP);
    let capped = 0;
    for (let i = 0; i < fx.n; i++) if (fx.type[i] === FX.GateCapped) capped++;
    expect(capped).toBeGreaterThan(0);
    // nothing more can be added, by any route
    expect(crowd.add(0, 0, 50)).toBe(0);
    expect(crowd.count).toBe(UNIT_CAP);
  });
});

describe('bad gates', () => {
  it.each([2, 3, 5])('÷%i keeps exactly one unit in every k', (k) => {
    const crowd = crowdOf(60);
    const g = gate(div(k));
    const fx = new FxQueue();
    for (let i = 0; i < crowd.cap; i++) if (crowd.isActive(i)) applyGate(g, crowd, i, fx);
    expect(crowd.count).toBe(60 / k);
    expect(g.lost).toBe(60 - 60 / k);
  });

  it('÷2 halves an agent that stands for many units', () => {
    const crowd = new CrowdSystem(new Rng(1), 4);
    crowd.add(0, 5, 41, 1);
    expect(applyGate(gate(div(2)), crowd, firstActive(crowd), new FxQueue())).toBe(-21);
    expect(crowd.count).toBe(20);
  });

  it('−n removes exactly n units, once, then recharges', () => {
    const crowd = crowdOf(30);
    const g = gate(sub(10));
    const fx = new FxQueue();
    expect(applyGate(g, crowd, firstActive(crowd), fx)).toBe(-10);
    expect(crowd.count).toBe(20);
    expect(applyGate(g, crowd, firstActive(crowd), fx)).toBe(0);
    expect(crowd.count).toBe(20);
  });

  it('−n cannot take more units than exist', () => {
    const crowd = crowdOf(4);
    expect(applyGate(gate(sub(25)), crowd, firstActive(crowd), new FxQueue())).toBe(-4);
    expect(crowd.count).toBe(0);
    expect(crowd.alive).toBe(0);
  });

  it('bad gates report the loss and earn no score', () => {
    const crowd = crowdOf(20, 600);
    const gates = new GateSystem([{ z: 10, x: 0, width: 10, op: div(2) }]);
    const fx = new FxQueue();
    let reported = 0;
    for (let t = 0; t < 240; t++) {
      crowd.update(SIM_DT, 0, 20, 1000, []);
      gates.update(SIM_DT, crowd, fx, 0, 100);
      for (let i = 0; i < fx.n; i++) if (fx.type[i] === FX.GateLoss) reported += fx.a[i]!;
      fx.clear();
    }
    expect(crowd.count).toBe(10);
    expect(reported).toBe(10);
    expect(gates.activations).toBe(0);
  });
});

describe('crowd count (logical vs rendered units)', () => {
  it('count is always the sum of agent strengths', () => {
    const crowd = new CrowdSystem(new Rng(3), 50);
    const fx = new FxQueue();
    crowd.add(0, 0, 30, 30);
    crowd.add(0, 0, 500, SPAWN_BUDGET); // overflows the 50-agent budget -> strength
    crowd.damage(firstActive(crowd), 35, fx);
    crowd.kill(5, AgentState.Die, fx);
    let sum = 0;
    let agents = 0;
    for (let i = 0; i < crowd.cap; i++) if (crowd.isActive(i)) (sum += crowd.str[i]!), agents++;
    expect(crowd.count).toBe(sum);
    expect(crowd.alive).toBe(agents);
    expect(agents).toBeLessThanOrEqual(50);
    expect(crowd.count).toBeGreaterThan(400);
  });

  it('never spawns more agents than the budget, however many units exist', () => {
    const crowd = new CrowdSystem(new Rng(3), 40);
    crowd.add(0, 0, 5000, 40);
    expect(crowd.count).toBe(5000);
    expect(crowd.alive).toBe(40);
    expect(crowd.add(0, 0, 1)).toBe(0); // at cap
  });

  it('bigger agents are drawn bigger, within limits', () => {
    expect(agentScale(1)).toBe(1);
    expect(agentScale(8)).toBeGreaterThan(agentScale(2));
    expect(agentScale(100000)).toBeLessThanOrEqual(2.6);
  });

  it('dead agents free their slot for reuse', () => {
    const crowd = crowdOf(10, 10);
    const fx = new FxQueue();
    for (let i = 0; i < 10; i++) crowd.kill(i, AgentState.Die, fx);
    expect(crowd.count).toBe(0);
    for (let t = 0; t < 60; t++) crowd.update(SIM_DT, 0, 0, 100, []);
    expect(crowd.add(0, 0, 10, 10)).toBe(10);
    expect(crowd.alive).toBe(10);
  });
});

describe('damage', () => {
  it('agent damage scales with strength, unit damage and time', () => {
    expect(agentDamage(1, 10, 1)).toBe(10);
    expect(agentDamage(25, 12, 0.5)).toBe(150);
  });

  it('a mobbed enemy spreads its damage', () => {
    expect(enemyDamage(8, 1, 1)).toBe(8);
    expect(enemyDamage(8, 4, 1)).toBe(4);
    expect(enemyDamage(8, 0, 1)).toBe(8);
  });

  it('damage removes whole units from an agent as its pool drains', () => {
    const crowd = new CrowdSystem(new Rng(1), 4);
    crowd.unitHp = 10;
    crowd.add(0, 0, 5, 1);
    const fx = new FxQueue();
    expect(crowd.damage(0, 25, fx)).toBe(2); // 50 -> 25 hp: 3 units left
    expect(crowd.count).toBe(3);
    expect(crowd.damage(0, 100, fx)).toBe(3);
    expect(crowd.count).toBe(0);
    expect(crowd.lost).toBe(5);
  });

  it('a pod that hits an enemy deals cannon power and deploys nothing', () => {
    const rng = new Rng(1);
    const enemies = new EnemySystem(rng);
    const e = enemies.spawn('brute', 0, 4);
    const crowd = new CrowdSystem(rng);
    const grid = new SpatialGrid(enemies);
    const pods = new ProjectileSystem();
    const fx = new FxQueue();
    const none = { podHit: () => false };
    pods.fire(0, 1.8);
    for (let t = 0; t < 30; t++) {
      grid.build(-10, 60);
      pods.update(SIM_DT, 14, 1000, crowd, enemies, grid, new GateSystem([]), new ObstacleSystem([]), none, fx);
    }
    expect(enemies.hp[e]).toBeCloseTo(80 - 14);
    expect(crowd.count).toBe(0);
    expect(pods.hits).toBe(1);
  });

  it('a pod that hits nothing deploys exactly one unit, and lands in front of a gate', () => {
    const rng = new Rng(1);
    const enemies = new EnemySystem(rng);
    const crowd = new CrowdSystem(rng);
    const grid = new SpatialGrid(enemies);
    const pods = new ProjectileSystem();
    const gates = new GateSystem([{ z: 5, x: 0, width: 4, op: mul(2) }]);
    const fx = new FxQueue();
    pods.fire(0, 1.8);
    for (let t = 0; t < 30; t++) {
      grid.build(-10, 60);
      pods.update(SIM_DT, 14, 1000, crowd, enemies, grid, gates, new ObstacleSystem([]), { podHit: () => false }, fx);
    }
    expect(crowd.count).toBe(1);
    expect(crowd.z[firstActive(crowd)]).toBeLessThan(5);
  });

  it('the pod pool never runs dry', () => {
    const pods = new ProjectileSystem();
    for (let i = 0; i < 500; i++) pods.fire(0, 0);
    expect(pods.fired).toBe(500);
    expect(pods.live.reduce((a, b) => a + b, 0)).toBe(pods.cap);
  });

  it('barrels hurt enemies in a wide radius and units in a narrow one', () => {
    const rng = new Rng(1);
    const enemies = new EnemySystem(rng);
    const near = enemies.spawn('grunt', 2.5, 10);
    const farAway = enemies.spawn('grunt', 0, 20);
    const crowd = new CrowdSystem(rng);
    crowd.add(0.5, 10, 1, 1);
    crowd.add(3, 10, 1, 1);
    const obstacles = new ObstacleSystem([{ kind: 'barrel', z: 10, x: 0 }], 90);
    expect(obstacles.hitBarrel(0, 10, 0.7, crowd, enemies, new FxQueue())).toBe(true);
    expect(enemies.isAlive(near)).toBe(false);
    expect(enemies.isAlive(farAway)).toBe(true);
    expect(crowd.count).toBe(1);
    expect(obstacles.hitBarrel(0, 10, 0.7, crowd, enemies, new FxQueue())).toBe(false);
  });

  it('a boss shield absorbs damage before health', () => {
    const boss = new BossSystem({ kind: 'void', hp: 1000, tier: 1 }, 100, new Rng(1));
    const fx = new FxQueue();
    boss.hit(50, fx);
    expect(boss.hp).toBe(1000); // not fighting yet: untouchable
    boss.state = BossState.Fight;
    boss.shield = boss.shieldMax = 100;
    boss.hit(60, fx);
    expect(boss.hp).toBe(1000);
    boss.hit(60, fx);
    expect(boss.shield).toBe(0);
    boss.hit(400, fx);
    expect(boss.hp).toBe(600);
    boss.hit(9999, fx);
    expect(boss.state).toBe(BossState.Dying);
  });
});

describe('obstacles', () => {
  const run = (def: Parameters<typeof ObstacleSystem.prototype.update>[1] extends never ? never : LevelConfig['obstacles'][number], x: number, seconds = 4) => {
    const crowd = new CrowdSystem(new Rng(1), 10);
    crowd.add(x, 0, 1, 1);
    const enemies = new EnemySystem(new Rng(2));
    const obstacles = new ObstacleSystem([def]);
    const fx = new FxQueue();
    for (let t = 0; t < seconds * 60; t++) {
      crowd.update(SIM_DT, x, 30, 1000, []);
      obstacles.update(SIM_DT, crowd, enemies, fx, 0, 100);
    }
    return crowd.count;
  };

  it('units off a bridge fall, units on it cross', () => {
    const bridge = { kind: 'bridge', z0: 10, z1: 20, x0: -1, x1: 4 } as const;
    expect(run(bridge, 2)).toBe(1);
    expect(run(bridge, -3)).toBe(0);
  });

  it('a falling platform holds for the first units and then drops', () => {
    const def = { kind: 'fallingPlatform', z0: 5, z1: 12, x0: 0.4, x1: 5 } as const;
    expect(run(def, 2, 1.2)).toBe(1); // crosses before it gives way
    const crowd = new CrowdSystem(new Rng(1), 10);
    const obstacles = new ObstacleSystem([def]);
    const fx = new FxQueue();
    crowd.add(2, 6, 1, 1);
    for (let t = 0; t < 120; t++) obstacles.update(SIM_DT, crowd, new EnemySystem(new Rng(2)), fx, 0, 100);
    expect(obstacles.list[0]!.stage).toBe(2);
    expect(crowd.count).toBe(0);
  });

  it('a laser only kills while it is on', () => {
    const def = { kind: 'laser', z: 8, x0: -5, x1: 5, period: 4 } as const;
    expect(run(def, 0, 1.5)).toBe(1); // reaches z=8 at ~0.9 s, laser fires from 2.3 s
    expect(run({ ...def, phase: 2.6 }, 0, 1.5)).toBe(0);
  });

  it('a crusher warns before it becomes lethal', () => {
    const obstacles = new ObstacleSystem([{ kind: 'crusher', z: 10, x: 0, width: 4, depth: 3, period: 4 }]);
    const crowd = new CrowdSystem(new Rng(1), 4);
    const seen: number[] = [];
    for (let t = 0; t < 240; t++) {
      obstacles.update(SIM_DT, crowd, new EnemySystem(new Rng(2)), new FxQueue(), 0, 100);
      const d = obstacles.list[0]!.danger;
      if (seen[seen.length - 1] !== d) seen.push(d);
    }
    expect(seen.slice(0, 3)).toEqual([0, 1, 2]);
  });
});

describe('upgrades', () => {
  it('every upgrade changes the stat the simulation reads', () => {
    const base = computeStats(zeroUpgrades());
    const maxed = computeStats({ fireRate: 15, startArmy: 15, unitDamage: 15, unitHealth: 15, cannonPower: 15, abilityCooldown: 10 });
    expect(maxed.fireRate).toBeGreaterThan(base.fireRate);
    expect(maxed.startArmy).toBeGreaterThan(base.startArmy);
    expect(maxed.unitDamage).toBeGreaterThan(base.unitDamage);
    expect(maxed.unitHealth).toBeGreaterThan(base.unitHealth);
    expect(maxed.podDamage).toBeGreaterThan(base.podDamage);
    expect(maxed.abilityCooldown).toBeLessThan(base.abilityCooldown);
    expect(maxed.abilityCooldown).toBeGreaterThan(5);
  });

  it('values are monotonic and costs rise with level', () => {
    for (const id of UPGRADE_IDS) {
      const def = UPGRADES[id];
      for (let l = 1; l <= def.maxLevel; l++) {
        expect(upgradeCost(id, l)).toBeGreaterThan(upgradeCost(id, l - 1));
        expect(def.value(l)).not.toBe(def.value(l - 1));
      }
    }
  });

  it('out-of-range levels are clamped', () => {
    const wild = computeStats({ ...zeroUpgrades(), fireRate: 999, unitDamage: -5 });
    expect(wild.fireRate).toBe(UPGRADES.fireRate.value(15));
    expect(wild.unitDamage).toBe(UPGRADES.unitDamage.value(0));
  });

  it('upgrades take effect in a real run', () => {
    const level = getLevel(1);
    const fire = (fireRate: number) => {
      const sim = new Simulation(level, computeStats({ ...zeroUpgrades(), fireRate }));
      for (let i = 0; i < 300; i++) sim.step({ aimX: 4, ability: false });
      return sim.pods.fired;
    };
    expect(fire(10)).toBeGreaterThan(fire(0) * 1.8);
    const army = new Simulation(level, computeStats({ ...zeroUpgrades(), startArmy: 4 }));
    expect(army.crowd.count).toBe(12);
    const overdrive = new Simulation(level, baseStats);
    overdrive.step({ aimX: 0, ability: true });
    expect(overdrive.cannon.overdrive).toBeGreaterThan(0);
    expect(overdrive.cannon.abilityCd).toBeCloseTo(baseStats.abilityCooldown, 1);
  });
});

describe('win / loss conditions', () => {
  it('a competent player wins level 1', () => {
    const sim = playLevel(getLevel(1), baseStats, 'good');
    expect(sim.status).toBe('won');
    expect(sim.boss.state).toBe(BossState.Dead);
    const s = sim.summary();
    expect(s.stars).toBeGreaterThanOrEqual(1);
    expect(s.score).toBeGreaterThan(1000);
  });

  it('a player who never moves or fires usefully can lose', () => {
    const sim = playLevel(getLevel(5), baseStats, 'idle');
    expect(sim.status).toBe('lost');
    expect(sim.cannon.hp).toBe(0);
    expect(sim.summary().stars).toBe(0);
  });

  it('zero remaining units is not a loss by itself: the cannon keeps firing', () => {
    const sim = new Simulation(getLevel(1), baseStats);
    const fx = new FxQueue();
    for (let t = 0; t < 120; t++) sim.step({ aimX: 4.5, ability: false });
    for (let i = 0; i < sim.crowd.cap; i++) sim.crowd.kill(i, AgentState.Die, fx);
    expect(sim.crowd.count).toBe(0);
    sim.step({ aimX: 4.5, ability: false });
    expect(sim.status).toBe('playing');
    for (let t = 0; t < 120; t++) sim.step({ aimX: 4.5, ability: false });
    expect(sim.crowd.count).toBeGreaterThan(0);
  });

  it('a finished run stops changing', () => {
    const sim = playLevel(getLevel(1), baseStats, 'good');
    const score = sim.score();
    const time = sim.time;
    for (let t = 0; t < 100; t++) sim.step({ aimX: 0, ability: true });
    expect(sim.score()).toBe(score);
    expect(sim.time).toBe(time);
  });

  it('is deterministic for the same inputs', () => {
    const a = playLevel(getLevel(3), baseStats, 'good').summary();
    const b = playLevel(getLevel(3), baseStats, 'good').summary();
    expect(a).toEqual(b);
  });

  it('boss fights always end (overload timer), even with no army', () => {
    const level: LevelConfig = { ...getLevel(1), gates: [], waves: [], obstacles: [], boss: { kind: 'titan', hp: 1e9, tier: 1 } };
    const sim = playLevel(level, baseStats, 'good', 400);
    expect(sim.status).toBe('lost');
  });
});

describe('edge cases', () => {
  it('rapid input changes keep the cannon inside the track', () => {
    const sim = new Simulation(getLevel(2), baseStats);
    for (let t = 0; t < 600; t++) {
      sim.step({ aimX: t % 2 ? 1e6 : -1e6, ability: t % 3 === 0 });
      expect(Math.abs(sim.cannon.x)).toBeLessThanOrEqual(4.1001);
    }
    expect(Number.isFinite(sim.cannon.x)).toBe(true);
  });

  it('survives garbage input', () => {
    const sim = new Simulation(getLevel(1), baseStats);
    sim.step({ aimX: NaN, ability: false });
    sim.step({ aimX: Infinity, ability: false });
    for (let t = 0; t < 60; t++) sim.step({ aimX: 0, ability: false });
    expect(Number.isFinite(sim.cannon.x)).toBe(true);
  });

  it('low frame rate (big steps) does not break the run', () => {
    const sim = new Simulation(getLevel(1), baseStats);
    for (let t = 0; t < 3000 && sim.status === 'playing'; t++) sim.step({ aimX: -2.5, ability: false }, 1 / 20);
    expect(sim.status).not.toBe('playing');
    expect(sim.crowd.count).toBeGreaterThanOrEqual(0);
  });

  it('the event queue is bounded', () => {
    const fx = new FxQueue();
    for (let i = 0; i < 10000; i++) fx.push(FX.Muzzle, 0, 0);
    expect(fx.n).toBe(FxQueue.CAP);
  });
});
