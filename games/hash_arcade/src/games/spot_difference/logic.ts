import { int, pick, sample, type Rng } from '../../engine/rng';
import { PALETTE, SHAPES, type Shape } from '../_shared/shapes';

export type Item = { shape: Shape; color: string } | null;
export interface Scene {
  cols: number;
  rows: number;
  left: Item[];
  right: Item[];
  diffs: number[];
}

export const layoutFor = (level: number) => (level <= 2 ? { cols: 4, rows: 4 } : level <= 5 ? { cols: 5, rows: 5 } : { cols: 6, rows: 6 });
export const diffsFor = (level: number) => Math.min(6, 3 + Math.floor(level / 3));

const randomItem = (rng: Rng): Item => ({ shape: pick(rng, SHAPES), color: pick(rng, PALETTE) });
export const sameItem = (a: Item, b: Item) => (a == null || b == null ? a === b : a.shape === b.shape && a.color === b.color);

/** Every change is visible: a new colour, a new shape, or an item removed or added. */
export function makeScene(level: number, rng: Rng): Scene {
  const { cols, rows } = layoutFor(level);
  const left: Item[] = Array.from({ length: cols * rows }, () => (rng() < 0.15 ? null : randomItem(rng)));
  const right = [...left];
  const diffs = sample(rng, cols * rows, diffsFor(level));
  for (const i of diffs) {
    const a = left[i];
    const kind = a == null ? 3 : int(rng, 0, 2);
    let b: Item;
    do {
      if (kind === 0) b = { shape: a!.shape, color: pick(rng, PALETTE) };
      else if (kind === 1) b = { shape: pick(rng, SHAPES), color: a!.color };
      else if (kind === 2) b = null;
      else b = randomItem(rng);
    } while (sameItem(a, b));
    right[i] = b;
  }
  return { cols, rows, left, right, diffs };
}
