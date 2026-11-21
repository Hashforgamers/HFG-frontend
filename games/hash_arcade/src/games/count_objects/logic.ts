import { int, pick, sample, shuffle, type Rng } from '../../engine/rng';
import { PALETTE, SHAPES, type Shape } from '../_shared/shapes';

export interface Field {
  items: { x: number; y: number; shape: Shape; color: string; rotate: number }[];
  ask: Shape;
  answer: number;
}

const SLOTS = 7; // field is a 7×7 lattice with jitter, so shapes never overlap

export const flashMs = (level: number) => Math.max(700, 1700 - level * 70);

export function makeField(level: number, rng: Rng): Field {
  const kinds = Math.min(4, 2 + Math.floor(level / 4));
  const shapes = shuffle(rng, [...SHAPES]).slice(0, kinds);
  const total = Math.min(24, 5 + level * 2);
  const ask = shapes[0];
  const answer = int(rng, 1, Math.max(2, Math.floor(total / kinds) + 2));
  const items = sample(rng, SLOTS * SLOTS, total).map((slot, i) => ({
    x: ((slot % SLOTS) + 0.2 + rng() * 0.6) / SLOTS,
    y: (Math.floor(slot / SLOTS) + 0.2 + rng() * 0.6) / SLOTS,
    shape: i < answer ? ask : pick(rng, shapes.slice(1)),
    color: pick(rng, PALETTE),
    rotate: int(rng, 0, 3) * 90,
  }));
  return { items, ask, answer };
}
