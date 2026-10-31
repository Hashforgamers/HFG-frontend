import type { Rng } from '../../engine/rng';

/** How long a target lives before it escapes; shrinks with every hit. */
export const lifetimeMs = (level: number) => Math.max(480, 1500 - level * 35);
/** Target diameter as a share of the field's shorter side. */
export const sizeFor = (level: number) => Math.max(0.12, 0.22 - level * 0.004);

/** Centre kept a radius away from the edges so the whole target is on screen. */
export function spawn(level: number, rng: Rng) {
  const r = sizeFor(level) / 2;
  return { x: r + rng() * (1 - 2 * r), y: r + rng() * (1 - 2 * r) };
}

export const within = (px: number, py: number, t: { x: number; y: number }, r: number) => Math.hypot(px - t.x, py - t.y) <= r;
