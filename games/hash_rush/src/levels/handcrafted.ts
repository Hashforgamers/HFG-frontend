import type { LevelConfig } from './LevelConfig';
import { add, difficulty, div, gatePair, mul, sub, wave } from './LevelGenerator';

/**
 * Levels 1-5: one per world, each introducing a few mechanics.
 *  1 Neon Highway    gates, grunts, barrels            - Iron Titan
 *  2 Desert Ruins    brutes, moving gate, bridge, crusher - Inferno Guardian
 *  3 Frozen Fortress lasers, falling platform, turrets, first bad gate (−10) - Void Commander
 *  4 Cyber City      moving walls, blades, giants, x5   - Iron Titan II
 *  5 Volcanic Core   everything, x10                    - Inferno Guardian II
 */
const base = (n: number, parTime: number) => {
  const d = difficulty(n);
  return { id: n, enemyHpScale: d.enemyHpScale, enemyDmgScale: d.enemyDmgScale, parTime, reward: { credits: d.credits }, seed: 1000 + n };
};

export const HANDCRAFTED: readonly LevelConfig[] = [
  {
    ...base(1, 75),
    name: 'First Contact', world: 'neon', length: 132,
    gates: [
      ...gatePair(16, add(10), add(5)),
      ...gatePair(36, add(5), mul(2)),
      ...gatePair(72, mul(3), mul(2)),
    ],
    waves: [wave(52, 'grunt', 10), wave(88, 'grunt', 18), wave(93, 'brute', 2)],
    obstacles: [{ kind: 'barrel', z: 87, x: 0 }],
    boss: { kind: 'titan', hp: 4600, tier: 1 },
  },
  {
    ...base(2, 90),
    name: 'Buried Legion', world: 'desert', length: 156,
    gates: [
      ...gatePair(16, add(25), add(10)),
      { z: 40, x: 0, width: 3.8, op: mul(2), moveAmp: 2.6, moveSpeed: 0.9 },
      ...gatePair(88, add(10), mul(3)),
      ...gatePair(114, mul(2), add(25)),
    ],
    waves: [wave(54, 'grunt', 14), wave(58, 'brute', 3), wave(100, 'grunt', 22), wave(105, 'brute', 5)],
    obstacles: [
      { kind: 'bridge', z0: 66, z1: 76, x0: -1, x1: 4.6 },
      { kind: 'crusher', z: 82, x: -2.4, width: 4.4, depth: 3, period: 3.2 },
      { kind: 'barrel', z: 103, x: -2 },
    ],
    boss: { kind: 'inferno', hp: 5400, tier: 1 },
  },
  {
    ...base(3, 95),
    name: 'Cold Front', world: 'frozen', length: 164,
    gates: [
      ...gatePair(16, add(25), mul(2)),
      ...gatePair(46, mul(3), add(10)),
      { z: 96, x: 0, width: 3.8, op: mul(3), moveAmp: 2.8, moveSpeed: 1.1 },
      ...gatePair(122, sub(10), mul(2)),
    ],
    waves: [
      wave(60, 'grunt', 18), wave(63, 'turret', 1, 3.6),
      wave(108, 'grunt', 24), wave(112, 'brute', 6), wave(110, 'turret', 1, -3.6),
    ],
    obstacles: [
      { kind: 'laser', z: 32, x0: -5, x1: 0.4, period: 3.4 },
      { kind: 'fallingPlatform', z0: 72, z1: 80, x0: 0.4, x1: 5 },
      { kind: 'laser', z: 88, x0: -0.4, x1: 5, period: 3.2, phase: 1.5 },
    ],
    boss: { kind: 'void', hp: 6000, tier: 1 },
  },
  {
    ...base(4, 100),
    name: 'Overclocked', world: 'cyber', length: 176,
    gates: [
      ...gatePair(16, mul(2), add(25)),
      ...gatePair(50, add(10), mul(5)),
      ...gatePair(100, div(2), mul(3)),
      { z: 132, x: 0, width: 3.6, op: mul(3), moveAmp: 3, moveSpeed: 1.2 },
    ],
    waves: [
      wave(64, 'grunt', 26), wave(69, 'brute', 5),
      wave(114, 'grunt', 30), wave(119, 'brute', 6), wave(124, 'giant', 1),
    ],
    obstacles: [
      { kind: 'movingWall', z: 34, width: 3.0, amp: 3.2, speed: 1.0 },
      { kind: 'blade', z: 82, x: -2.3, radius: 2.1, speed: 2.4 },
      { kind: 'blade', z: 90, x: 2.3, radius: 2.1, speed: -2.4 },
      { kind: 'barrel', z: 117, x: 1.5 },
    ],
    boss: { kind: 'titan', hp: 5000, tier: 1.5 },
  },
  {
    ...base(5, 110),
    name: 'Meltdown', world: 'volcanic', length: 190,
    gates: [
      ...gatePair(16, add(25), mul(2)),
      { z: 44, x: 0, width: 3.4, op: mul(10), moveAmp: 3.2, moveSpeed: 1.3 },
      ...gatePair(98, mul(3), add(25)),
      ...gatePair(146, mul(3), sub(25)),
    ],
    waves: [
      wave(58, 'grunt', 30), wave(63, 'brute', 6), wave(61, 'turret', 1, -3.6),
      wave(112, 'grunt', 30), wave(117, 'brute', 6), wave(122, 'giant', 1),
      wave(114, 'turret', 1, 3.6),
    ],
    obstacles: [
      { kind: 'crusher', z: 30, x: 2.4, width: 4.4, depth: 3, period: 3 },
      { kind: 'bridge', z0: 72, z1: 82, x0: -4.6, x1: 1 },
      { kind: 'laser', z: 90, x0: -5, x1: 0.4, period: 3 },
      { kind: 'barrel', z: 115, x: -1 },
      { kind: 'barrel', z: 118, x: 2 },
      { kind: 'fallingPlatform', z0: 130, z1: 138, x0: -5, x1: -0.4 },
      { kind: 'movingWall', z: 156, width: 3.2, amp: 3.2, speed: 1.2 },
    ],
    boss: { kind: 'inferno', hp: 6000, tier: 1.5 },
  },
];
