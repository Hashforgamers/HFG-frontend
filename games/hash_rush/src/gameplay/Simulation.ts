import { Rng } from '../core/Rng';
import type { LevelConfig } from '../levels/LevelConfig';
import { BossState, BossSystem } from './BossSystem';
import { Cannon } from './Cannon';
import { resolveCombat } from './CombatSystem';
import { CrowdSystem, type Lane } from './CrowdSystem';
import { EnemySystem } from './EnemySystem';
import { GateSystem } from './GateSystem';
import { ObstacleSystem } from './ObstacleSystem';
import { ProjectileSystem } from './ProjectileSystem';
import { SpatialGrid } from './SpatialGrid';
import type { PlayerStats } from './Upgrades';
import { BOSS_STANDOFF, FX, FxQueue, LEASH, MAX_AGENTS, SIM_DT, UNIT_CAP } from './constants';

export interface SimInput {
  /** Where the player wants the cannon, metres across the track. */
  aimX: number;
  /** True on the tick the Overdrive button is pressed. */
  ability: boolean;
}

export type SimStatus = 'playing' | 'won' | 'lost';
export const MAX_LEVEL_SCORE = 20000;

export interface RunSummary {
  levelId: number;
  status: SimStatus;
  score: number;
  time: number;
  enemiesKilled: number;
  unitsLost: number;
  peakArmy: number;
  armyLeft: number;
  gateActivations: number;
  cannonHp: number;
  stars: number;
}

export interface SimOptions {
  maxAgents?: number;
  unitCap?: number;
  /** Endless mode: cannon health carried over from the previous stage. */
  startHp?: number;
  /** Endless mode: survivors carried over, on top of the Starting Army upgrade. */
  extraArmy?: number;
}

/**
 * The whole game, with no rendering, audio or DOM in it. Fixed 60 Hz steps
 * and a seeded RNG make a run deterministic for a given input stream, which
 * is what lets the tests and the balance report play levels headlessly.
 */
export class Simulation {
  readonly fx = new FxQueue();
  readonly cannon: Cannon;
  readonly crowd: CrowdSystem;
  readonly enemies: EnemySystem;
  readonly gates: GateSystem;
  readonly obstacles: ObstacleSystem;
  readonly pods = new ProjectileSystem();
  readonly boss: BossSystem;
  readonly grid: SpatialGrid;
  status: SimStatus = 'playing';
  time = 0;
  peakArmy = 0;
  /** Cannon's stop line in front of the boss. */
  readonly stopZ: number;
  /** Bridges + gate funnels, for the army's formation. */
  private readonly lanes: Lane[];

  constructor(readonly level: LevelConfig, readonly stats: PlayerStats, opts: SimOptions = {}) {
    const rng = new Rng(level.seed);
    this.cannon = new Cannon(stats);
    this.crowd = new CrowdSystem(rng, opts.maxAgents ?? MAX_AGENTS);
    this.crowd.unitHp = stats.unitHealth;
    this.crowd.unitCap = opts.unitCap ?? UNIT_CAP;
    this.enemies = new EnemySystem(rng, level.enemyHpScale, level.enemyDmgScale);
    this.enemies.setWaves(level.waves);
    this.gates = new GateSystem(level.gates);
    this.obstacles = new ObstacleSystem(level.obstacles, 90 * level.enemyHpScale);
    this.boss = new BossSystem(level.boss, level.length, rng);
    this.grid = new SpatialGrid(this.enemies);
    this.stopZ = level.length - BOSS_STANDOFF;
    this.lanes = [...this.obstacles.lanes, ...this.gates.lanes];
    // the starting army stands in front of the cannon
    if (opts.startHp !== undefined) this.cannon.hp = Math.max(1, Math.min(this.cannon.maxHp, opts.startHp));
    const startArmy = stats.startArmy + Math.max(0, Math.floor(opts.extraArmy ?? 0));
    for (let k = 0; k < startArmy; k++) this.crowd.add(((k % 9) - 4) * 0.7, 2.5 + Math.floor(k / 9) * 0.7, 1, 1);
  }

  /** Progress along the track, 0..1 (1 = at the boss). */
  get progress(): number {
    return Math.min(1, this.cannon.z / this.stopZ);
  }

  step(input: SimInput, dt = SIM_DT): void {
    if (this.status !== 'playing') return;
    const { cannon, crowd, enemies, boss, fx } = this;
    this.time += dt;

    const pods = cannon.update(dt, input.aimX, input.ability, this.stopZ, enemies.blockerZ, fx);
    for (let p = 0; p < pods; p++) this.pods.fire(cannon.x, cannon.z + 1.8);

    const zMin = cannon.z - 6;
    const zMax = cannon.z + LEASH + 40;
    const frontLimit = boss.z - boss.stats.radius - 0.5;
    this.grid.build(zMin, zMax);
    this.pods.update(dt, this.stats.podDamage, frontLimit, crowd, enemies, this.grid, this.gates, this.obstacles, boss, fx);
    enemies.update(dt, cannon.x, cannon.z, crowd, this.obstacles.lanes, fx);
    resolveCombat(dt, this.stats.unitDamage, crowd, enemies, this.grid, boss, fx);
    crowd.update(dt, cannon.x, cannon.z, frontLimit, this.lanes);
    this.gates.update(dt, crowd, fx, zMin, zMax);
    this.obstacles.update(dt, crowd, enemies, fx, zMin, zMax);
    const wasAlive = boss.state !== BossState.Dying && boss.state !== BossState.Dead;
    boss.update(dt, cannon.x, cannon.z, crowd, enemies, fx);
    cannon.takeDamage(enemies.cannonDamage + boss.cannonDamage, fx);

    if (crowd.count > this.peakArmy) this.peakArmy = crowd.count;
    if (wasAlive && boss.state === BossState.Dying) {
      enemies.killAll(fx);
      crowd.cheer();
    }
    if (boss.state === BossState.Dead) {
      this.status = 'won';
      fx.push(FX.Victory, cannon.x, cannon.z);
    } else if (cannon.hp <= 0 && boss.state !== BossState.Dying) {
      this.status = 'lost';
      fx.push(FX.Explosion, cannon.x, cannon.z, 4);
    }
  }

  /** Continues used in this run. */
  continues = 0;

  /**
   * Continue after a defeat: the cannon comes back at 60 % health with a short
   * shield, and a shockwave clears every enemy close to it. Progress, army and
   * score are kept. Returns false if the run was not lost.
   */
  revive(): boolean {
    if (this.status !== 'lost') return false;
    const { cannon, enemies, fx } = this;
    this.status = 'playing';
    this.continues++;
    cannon.hp = cannon.maxHp * 0.6;
    cannon.shield = 3;
    cannon.hurt = 0;
    for (let i = 0; i < enemies.cap; i++) {
      if (enemies.isAlive(i) && enemies.z[i]! - cannon.z < 16) enemies.hit(i, Infinity, fx);
    }
    for (const tg of this.boss.telegraphs) tg.live = false;
    fx.push(FX.Explosion, cannon.x, cannon.z, 8);
    fx.push(FX.Ability, cannon.x, cannon.z);
    return true;
  }

  score(): number {
    let s = this.enemies.score + this.gates.activations * 5;
    if (this.status === 'won') {
      s += 1000 + 250 * this.level.boss.tier;
      s += Math.min(1500, this.crowd.count * 2);
      s += Math.round((this.cannon.hp / this.cannon.maxHp) * 500);
      s += Math.round(Math.max(0, this.level.parTime - this.time) * 10);
    }
    return Math.max(0, Math.min(MAX_LEVEL_SCORE, Math.round(s)));
  }

  summary(): RunSummary {
    const hp = this.cannon.hp / this.cannon.maxHp;
    return {
      levelId: this.level.id,
      status: this.status,
      score: this.score(),
      time: this.time,
      enemiesKilled: this.enemies.killed,
      unitsLost: this.crowd.lost,
      peakArmy: this.peakArmy,
      armyLeft: this.crowd.count,
      gateActivations: this.gates.activations,
      cannonHp: this.cannon.hp,
      stars: this.status !== 'won' ? 0 : hp >= 0.75 ? 3 : hp >= 0.4 ? 2 : 1,
    };
  }
}
