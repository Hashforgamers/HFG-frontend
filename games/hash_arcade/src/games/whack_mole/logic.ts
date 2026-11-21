import { int, type Rng } from '../../engine/rng';

export const HOLES = 9;
export const upMs = (level: number) => Math.max(520, 1200 - level * 22);
export const gapMs = (level: number) => Math.max(120, 450 - level * 10);
/** Decoys appear from level 4 and become more common. */
export const decoyChance = (level: number) => (level < 4 ? 0 : Math.min(0.35, 0.1 + level * 0.01));

export interface Pop {
  hole: number;
  decoy: boolean;
}

export function nextPop(level: number, rng: Rng, last: number): Pop {
  let hole = int(rng, 0, HOLES - 1);
  if (hole === last) hole = (hole + 1 + int(rng, 0, HOLES - 2)) % HOLES; // never the same hole twice
  return { hole, decoy: rng() < decoyChance(level) };
}
