import { int, shuffle, type Rng } from '../../engine/rng';

export interface Hunt {
  size: number;
  target: number;
  cells: number[];
}

export const sizeFor = (level: number) => Math.min(7, 4 + Math.floor((level - 1) / 3));

/** Look-alikes of the target: swapped digits, ±1, ±10. */
export function lookAlikes(t: number): number[] {
  const s = String(t);
  const out = new Set<number>([t + 1, t - 1, t + 10, t - 10, Number([...s].reverse().join(''))]);
  if (s.length === 3) out.add(Number(s[0] + s[2] + s[1]));
  return [...out].filter((v) => v !== t && v > 0 && String(v).length === s.length);
}

/** Exactly one cell holds the target. Later levels pack in more look-alikes. */
export function makeHunt(level: number, rng: Rng): Hunt {
  const size = sizeFor(level);
  const digits = level <= 6 ? 2 : 3;
  const target = int(rng, 10 ** (digits - 1) + 1, 10 ** digits - 2);
  const alikes = lookAlikes(target);
  const share = Math.min(0.7, 0.2 + level * 0.04);
  const cells: number[] = [target];
  while (cells.length < size * size) {
    const v = rng() < share && alikes.length ? alikes[int(rng, 0, alikes.length - 1)] : int(rng, 10 ** (digits - 1), 10 ** digits - 1);
    if (v !== target) cells.push(v);
  }
  return { size, target, cells: shuffle(rng, cells) };
}
