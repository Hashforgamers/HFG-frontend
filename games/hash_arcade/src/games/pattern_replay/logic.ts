import { int, sample, type Rng } from '../../engine/rng';

export interface Pattern {
  size: number;
  colors: number;
  /** 0 = off, 1..colors = colour index */
  cells: number[];
}

export const sizeFor = (level: number) => Math.min(5, 3 + Math.floor((level - 1) / 3));
export const colorsFor = (level: number) => (level <= 3 ? 1 : level <= 7 ? 2 : 3);

export function makePattern(level: number, rng: Rng): Pattern {
  const size = sizeFor(level);
  const colors = colorsFor(level);
  const cells = Array<number>(size * size).fill(0);
  const lit = Math.max(3, Math.round(size * size * (0.3 + Math.min(level, 10) * 0.012)));
  for (const i of sample(rng, size * size, lit)) cells[i] = int(rng, 1, colors);
  return { size, colors, cells };
}

export const showMs = (p: Pattern) => 1200 + p.cells.filter(Boolean).length * 180 * p.colors;
/** Tapping a cell cycles off → colour 1 → … → off. */
export const cycle = (v: number, colors: number) => (v + 1) % (colors + 1);
export const samePattern = (a: number[], b: number[]) => a.length === b.length && a.every((v, i) => v === b[i]);
