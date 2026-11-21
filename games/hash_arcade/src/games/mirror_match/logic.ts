import { shuffle, type Rng } from '../../engine/rng';

export type Pic = boolean[]; // n×n

export const flipH = (p: Pic, n: number): Pic => p.map((_, i) => p[Math.floor(i / n) * n + (n - 1 - (i % n))]);
export const rot90 = (p: Pic, n: number): Pic => p.map((_, i) => p[(n - 1 - (i % n)) * n + Math.floor(i / n)]);
const keyOf = (p: Pic) => p.map(Number).join('');

/** All 8 rotations/reflections differ, so exactly one option is the mirror. */
export function asymmetric(p: Pic, n: number): boolean {
  const seen = new Set<string>();
  let r = p;
  for (let k = 0; k < 4; k++) {
    seen.add(keyOf(r));
    seen.add(keyOf(flipH(r, n)));
    r = rot90(r, n);
  }
  return seen.size === 8;
}

export const sizeFor = (level: number) => (level <= 3 ? 3 : level <= 8 ? 4 : 5);

export interface MirrorRound {
  n: number;
  pic: Pic;
  options: Pic[];
  answer: number;
}

/** Options: the mirror image plus the original turned 0°, 90° and 270° (none of which is a mirror). */
export function makeMirror(level: number, rng: Rng): MirrorRound {
  const n = sizeFor(level);
  let pic: Pic;
  do pic = Array.from({ length: n * n }, () => rng() < 0.45);
  while (!asymmetric(pic, n) || pic.filter(Boolean).length < n);
  const mirror = flipH(pic, n);
  const r1 = rot90(pic, n);
  const options = shuffle(rng, [mirror, pic, r1, rot90(rot90(r1, n), n)]);
  return { n, pic, options, answer: options.indexOf(mirror) };
}
