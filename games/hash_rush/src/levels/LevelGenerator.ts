import { Rng } from '../core/Rng';
import type { BossKind, EnemyKind, GateDef, GateOp, LevelConfig, ObstacleDef, WaveDef } from './LevelConfig';
import { WORLD_NAMES, WORLD_ORDER } from './LevelConfig';
import { BOSS_CONTACT_CAP } from '../gameplay/CombatSystem';
import { CANNON_SPEED, MAX_AGENTS, UNIT_CAP } from '../gameplay/constants';

/** Share of the expected army's strength a wave is built to absorb. */
const WAVE_PRESSURE = 0.15;
/** Seconds of uninterrupted melee the boss is built to withstand. */
const BOSS_SECONDS = 11;

export const LEVEL_COUNT = 30;
const BOSSES: readonly BossKind[] = ['titan', 'inferno', 'void'];

export const add = (value: number): GateOp => ({ kind: 'add', value });
export const mul = (value: number): GateOp => ({ kind: 'mul', value });
export const sub = (value: number): GateOp => ({ kind: 'sub', value });
export const div = (value: number): GateOp => ({ kind: 'div', value });

/** Two gates side by side: the basic "pick one" choice. */
export function gatePair(z: number, left: GateOp, right: GateOp): GateDef[] {
  return [
    { z, x: -2.5, width: 4.4, op: left },
    { z, x: 2.5, width: 4.4, op: right },
  ];
}

export function wave(z: number, kind: EnemyKind, count: number, x = 0): WaveDef {
  // grunts come in swarms: many weak bodies read better than a few tough ones
  return { z, x, kind, count: kind === 'grunt' ? Math.round(count * 1.5) : count };
}

/**
 * Balancing knobs for a level number (1-based). Difficulty comes mostly from
 * what the level *asks* of the player (worse gate offers, more traps, mixed
 * enemy types); these scales only keep enemies relevant as upgrades grow.
 */
export function difficulty(n: number) {
  const tier = Math.floor((n - 1) / 5);
  return {
    tier,
    enemyHpScale: 1 + 0.12 * (n - 1),
    enemyDmgScale: 1 + 0.05 * (n - 1),
    bossTier: 1 + tier * 0.5,
    credits: 80 + 20 * n,
  };
}

/** Procedural level for n >= 6, built from the same pieces as the handcrafted ones. */
export function generateLevel(n: number): LevelConfig {
  const d = difficulty(n);
  const rng = new Rng(7919 * n + 13);
  const world = WORLD_ORDER[(n - 1) % WORLD_ORDER.length]!;
  const length = 170 + d.tier * 12 + rng.int(0, 20);
  const gates: GateDef[] = [];
  const waves: WaveDef[] = [];
  const obstacles: ObstacleDef[] = [];

  // `army` tracks the force a player who takes the better gates should have at
  // this point of the track. Waves and the boss are sized from it, so a level
  // is hard because of what it asks, not because of a number picked blind.
  let army = 4;
  const fireRate = 2.4 + 0.12 * d.tier;
  const march = (metres: number) => {
    army = Math.min(UNIT_CAP, army + (fireRate * metres) / CANNON_SPEED);
  };
  const gain = (op: GateOp, efficiency: number) => {
    army = Math.min(UNIT_CAP, op.kind === 'add' ? army + op.value : army * (1 + (op.value - 1) * efficiency));
  };

  const smallAdds = [add(5), add(10), add(25)];
  const mults = d.tier >= 2 ? [mul(2), mul(3), mul(5)] : [mul(2), mul(3)];
  const gateRow = (z: number, index: number) => {
    // multipliers only every other row, so armies grow in steps rather than exploding
    const multRow = index % 2 === 1;
    let good: GateOp = multRow ? rng.pick(mults) : add(25);
    let weak: GateOp = multRow && rng.next() < 0.45 ? mul(2) : rng.pick([add(5), add(10)]);
    // from level 6 on, the wrong side of a row is sometimes an outright trap
    if (n >= 6 && index > 0 && rng.next() < 0.3 + d.tier * 0.06) weak = rng.next() < 0.5 ? div(2) : sub(rng.pick([10, 25]));
    if (multRow && index > 1 && rng.next() < 0.1 + d.tier * 0.02) good = mul(10);
    const flip = rng.next() < 0.5;
    if (rng.next() < 0.2 + d.tier * 0.08) {
      // one moving gate instead of a static pair: harder to line up
      gates.push({ z, x: 0, width: 3.6, op: good, moveAmp: 2.8, moveSpeed: 0.9 + d.tier * 0.15 });
      gain(good, 0.55);
    } else {
      gates.push(...gatePair(z, flip ? good : weak, flip ? weak : good));
      gain(good, 0.8);
    }
  };
  // the ×100 jackpot: narrow, fast, late — worth chasing but easy to miss
  const jackpotAt = n >= 20 ? 1 : -1;

  const trapKinds = ['barrel', 'crusher', 'laser', 'movingWall', 'blade', 'bridge', 'fallingPlatform'] as const;
  const unlocked = Math.min(trapKinds.length, 2 + d.tier + (n % 5));
  const trap = (z: number) => {
    const kind = trapKinds[rng.int(0, unlocked - 1)]!;
    const side = rng.next() < 0.5 ? -1 : 1;
    if (kind !== 'barrel') army *= 0.8;
    switch (kind) {
      case 'barrel': obstacles.push({ kind, z: z + 6, x: side * rng.range(0.5, 3) }); break;
      case 'crusher': obstacles.push({ kind, z, x: side * 2.4, width: 4.4, depth: 3, period: 3.2 - d.tier * 0.15, phase: rng.range(0, 3) }); break;
      case 'laser': obstacles.push({ kind, z, x0: side < 0 ? -5 : -0.5, x1: side < 0 ? 0.5 : 5, period: 3.4 - d.tier * 0.15, phase: rng.range(0, 3) }); break;
      case 'movingWall': obstacles.push({ kind, z, width: 3.4, amp: 3.2, speed: 0.9 + d.tier * 0.12, phase: rng.range(0, 6) }); break;
      case 'blade': obstacles.push({ kind, z, x: side * 2.3, radius: 2.1, speed: 2.2 + d.tier * 0.25 }); break;
      case 'bridge': obstacles.push({ kind, z0: z, z1: z + 9, x0: side < 0 ? -4.6 : -0.6, x1: side < 0 ? 0.6 : 4.6 }); break;
      case 'fallingPlatform': obstacles.push({ kind, z0: z, z1: z + 7, x0: side < 0 ? -5 : 0.4, x1: side < 0 ? -0.4 : 5 }); break;
    }
  };

  let z = 16;
  let row = 0;
  march(z);
  while (z < length - 62) {
    const start = z;
    if (row === jackpotAt) {
      gates.push({ z, x: 0, width: 2.6, op: mul(100), moveAmp: 3.6, moveSpeed: 1.7 });
      gain(mul(100), 0.35);
    } else {
      gateRow(z, row);
    }
    z += rng.range(13, 16);
    if (row > 0 || d.tier > 0) {
      trap(z);
      z += 13;
    }
    march(z - start);
    // the wave is a fixed share of what the army can chew through
    const pressure = WAVE_PRESSURE + 0.01 * Math.min(n, 20);
    const budget = (army * pressure) / d.enemyHpScale;
    let grunts = Math.round(budget * 0.55);
    let brutes = row >= 1 ? Math.round((budget * 0.3) / 4) : 0;
    let giants = row >= 2 && army > 200 ? Math.min(3, Math.round((budget * 0.15) / 28)) : 0;
    grunts = Math.max(6, Math.min(70, grunts));
    brutes = Math.min(16, brutes);
    waves.push(wave(z, 'grunt', grunts));
    if (brutes > 0) waves.push(wave(z + 6, 'brute', brutes));
    if (giants > 0) waves.push(wave(z + 10, 'giant', giants, rng.range(-2, 2)));
    if (rng.next() < 0.3 + d.tier * 0.06) waves.push(wave(z + 3, 'turret', 1, rng.next() < 0.5 ? -3.6 : 3.6));
    army *= 0.75;
    const end = z + rng.range(18, 22);
    march(end - z);
    z = end;
    row++;
  }
  gates.push(...gatePair(length - 42, mul(2), rng.pick(smallAdds)));
  march(length - 42 - z);
  gain(mul(2), 0.8);
  // at most BOSS_CONTACT_CAP agents hit the boss at once; past the agent budget each agent stands for several units
  const contactDps = BOSS_CONTACT_CAP * 10 * (1 + 0.03 * n) * Math.max(1, army / MAX_AGENTS);
  const bossHp = Math.round((contactDps * (BOSS_SECONDS + d.tier)) / 100) * 100;

  return {
    id: n,
    name: `${WORLD_NAMES[world]} ${['II', 'III', 'IV', 'V', 'VI'][d.tier - 1] ?? ''}`.trim(),
    world,
    length,
    gates,
    waves,
    obstacles,
    boss: { kind: BOSSES[(n - 1) % BOSSES.length]!, hp: bossHp, tier: d.bossTier },
    enemyHpScale: d.enemyHpScale,
    enemyDmgScale: d.enemyDmgScale,
    parTime: Math.round(length / 3.4 + 45),
    reward: { credits: d.credits },
    seed: 1000 + n,
  };
}
