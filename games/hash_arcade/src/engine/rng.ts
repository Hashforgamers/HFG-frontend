// Seeded randomness. The core generator is shared with the standalone Odd One Out.
export { hashString, mulberry32, multiplier, todayKey, type Rng } from '../../../odd_one_out/src/game';
import type { Rng } from '../../../odd_one_out/src/game';

/** Integer in [min, max], inclusive. */
export const int = (rng: Rng, min: number, max: number) => min + Math.floor(rng() * (max - min + 1));
export const pick = <T,>(rng: Rng, items: readonly T[]): T => items[Math.floor(rng() * items.length)];
export function shuffle<T>(rng: Rng, items: readonly T[]): T[] {
  const a = [...items];
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(rng() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}
/** `count` distinct integers from [0, n). */
export const sample = (rng: Rng, n: number, count: number) =>
  shuffle(rng, Array.from({ length: n }, (_, i) => i)).slice(0, count);
