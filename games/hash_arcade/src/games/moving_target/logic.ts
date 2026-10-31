import type { Rng } from '../../engine/rng';

export interface Mover {
  id: number;
  x: number;
  y: number;
  vx: number;
  vy: number;
}

export const RADIUS = 0.07;
export const countFor = (level: number) => Math.min(4, 1 + Math.floor(level / 5));
export const speedFor = (level: number) => Math.min(0.9, 0.25 + level * 0.03);

let next = 0;
export function mover(level: number, rng: Rng): Mover {
  const a = rng() * Math.PI * 2;
  const s = speedFor(level);
  return { id: next++, x: 0.2 + rng() * 0.6, y: 0.2 + rng() * 0.6, vx: Math.cos(a) * s, vy: Math.sin(a) * s };
}

/** Advance `dt` seconds, bouncing off the field's walls. */
export function step(m: Mover, dt: number): Mover {
  let { x, y, vx, vy } = m;
  x += vx * dt;
  y += vy * dt;
  if (x < RADIUS) [x, vx] = [RADIUS, Math.abs(vx)];
  if (x > 1 - RADIUS) [x, vx] = [1 - RADIUS, -Math.abs(vx)];
  if (y < RADIUS) [y, vy] = [RADIUS, Math.abs(vy)];
  if (y > 1 - RADIUS) [y, vy] = [1 - RADIUS, -Math.abs(vy)];
  return { ...m, x, y, vx, vy };
}
