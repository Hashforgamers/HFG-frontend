import { pick, type Rng } from '../../engine/rng';

const LETTERS = 'BCDFGHJKLMNPRSTV'.split('');

/** Blocks of the run: 1-back, then 2-back, then 3-back. */
export const BLOCKS = [
  { n: 1, length: 12 },
  { n: 2, length: 15 },
  { n: 3, length: 18 },
];

/** About 30% of items (after the first n) repeat the one n back; the rest never do. */
export function makeStream(n: number, length: number, rng: Rng): string[] {
  const s: string[] = [];
  for (let i = 0; i < length; i++) {
    if (i >= n && rng() < 0.3) s.push(s[i - n]);
    else s.push(pick(rng, LETTERS.filter((l) => i < n || l !== s[i - n])));
  }
  return s;
}

export const isMatch = (s: string[], i: number, n: number) => i >= n && s[i] === s[i - n];
export const STIMULUS_MS = 2200;
