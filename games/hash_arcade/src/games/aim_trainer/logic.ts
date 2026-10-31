import type { Rng } from '../../engine/rng';

export const TARGETS = 25;
/** Targets get smaller as you go: 9% of the field down to 4%. */
export const sizeFor = (n: number) => Math.max(0.04, 0.09 - n * 0.002);
/** Faster hits score more: 200 at once, down to a floor of 30. */
export const hitPoints = (ms: number) => Math.max(30, Math.round(200 - ms / 6));

export function place(n: number, rng: Rng, prev?: { x: number; y: number }) {
  const r = sizeFor(n) / 2;
  for (;;) {
    const t = { x: r + rng() * (1 - 2 * r), y: r + rng() * (1 - 2 * r) };
    // never right on top of the last one, so every target needs a real aim
    if (!prev || Math.hypot(t.x - prev.x, t.y - prev.y) > 0.25) return t;
  }
}
