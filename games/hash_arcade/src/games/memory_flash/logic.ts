import { sample, type Rng } from '../../engine/rng';

export interface Flash {
  size: number;
  cells: number[];
}

export const sizeFor = (level: number) => Math.min(6, 3 + Math.floor((level - 1) / 3));
export const countFor = (level: number) => Math.min(sizeFor(level) ** 2 - 2, 3 + Math.floor((level - 1) / 2));

export function makeFlash(level: number, rng: Rng): Flash {
  const size = sizeFor(level);
  return { size, cells: sample(rng, size * size, countFor(level)) };
}

/** How long the pattern stays lit: more cells, a little longer. */
export const showMs = (count: number) => 700 + count * 110;
