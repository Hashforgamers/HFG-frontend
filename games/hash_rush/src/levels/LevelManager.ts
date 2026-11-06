import type { LevelConfig } from './LevelConfig';
import { LEVEL_COUNT, generateLevel } from './LevelGenerator';
import { HANDCRAFTED } from './handcrafted';

export { LEVEL_COUNT };

const cache = new Map<number, LevelConfig>();

/** Level `n` (1-based). 1-5 are handcrafted, the rest generated from a fixed seed. */
export function getLevel(n: number): LevelConfig {
  const id = Math.min(LEVEL_COUNT, Math.max(1, Math.floor(n)));
  let level = cache.get(id);
  if (!level) {
    level = HANDCRAFTED[id - 1] ?? generateLevel(id);
    cache.set(id, level);
  }
  return level;
}

/** Problems that would make a level unfair or unplayable; empty = valid. */
export function validateLevel(level: LevelConfig): string[] {
  const issues: string[] = [];
  if (level.length < 80) issues.push('track too short');
  if (level.gates.length === 0) issues.push('no gates');
  for (const g of level.gates) {
    if (g.z < 8 || g.z > level.length - 30) issues.push(`gate at z=${g.z} outside the playable stretch`);
    if (g.op.value <= 0 || ((g.op.kind === 'mul' || g.op.kind === 'div') && g.op.value < 2)) issues.push(`gate at z=${g.z} has a bad value`);
  }
  for (const w of level.waves) {
    if (w.z < 25 || w.z > level.length - 22) issues.push(`wave at z=${w.z} outside the playable stretch`);
    if (w.count <= 0) issues.push(`empty wave at z=${w.z}`);
  }
  for (const o of level.obstacles) {
    const z = 'z' in o ? o.z : o.z1;
    if (z > level.length - 28) issues.push(`${o.kind} too close to the boss arena`);
    if ((o.kind === 'bridge' || o.kind === 'fallingPlatform') && o.x1 - o.x0 < 3.5) issues.push(`${o.kind} too narrow`);
    if (o.kind === 'fallingPlatform' && o.x0 <= -4.9 && o.x1 >= 4.9) issues.push('falling platform spans the whole track');
  }
  if (level.boss.hp <= 0) issues.push('boss has no health');
  return issues;
}
