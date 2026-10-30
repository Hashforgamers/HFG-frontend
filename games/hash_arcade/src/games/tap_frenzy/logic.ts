import type { Rng } from '../../engine/rng';

export interface Bubble {
  id: number;
  x: number;
  y: number;
  gold: boolean;
}

export const ON_SCREEN = 5;
export const SIZE = 0.16;

let next = 0;
/** Never overlapping another bubble; one in eight is gold and worth triple. */
export function bubble(rng: Rng, others: Bubble[]): Bubble {
  const r = SIZE / 2;
  for (let tries = 0; ; tries++) {
    const b = { id: next++, x: r + rng() * (1 - 2 * r), y: r + rng() * (1 - 2 * r), gold: rng() < 0.125 };
    if (tries > 50 || others.every((o) => Math.hypot(o.x - b.x, o.y - b.y) > SIZE * 1.05)) return b;
  }
}
