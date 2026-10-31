import { int, pick, shuffle, type Rng } from '../../engine/rng';

export interface Target {
  nums: number[];
  target: number;
}

/**
 * Countdown rules: whole positive numbers at every step. The target is built
 * by combining some of the numbers, so it can always be reached.
 */
export function makeTarget(level: number, rng: Rng): Target {
  const count = level <= 3 ? 4 : level <= 7 ? 5 : 6;
  const bigs = Math.min(2, Math.floor(level / 3));
  const [lo, hi] = level <= 3 ? [10, 60] : level <= 7 ? [50, 300] : [100, 999];
  for (;;) {
    const nums = [
      ...Array.from({ length: bigs }, () => pick(rng, [25, 50, 75, 100])),
      ...Array.from({ length: count - bigs }, () => int(rng, 1, 10)),
    ];
    let pool = shuffle(rng, nums);
    let acc = pool[0];
    pool = pool.slice(1);
    for (const v of pool.slice(0, int(rng, 1, pool.length))) {
      const choices = [acc + v, acc * v, acc > v ? acc - v : -1, acc % v === 0 ? acc / v : -1].filter((x) => x > 0);
      acc = pick(rng, choices);
    }
    if (acc >= lo && acc <= hi && !nums.includes(acc)) return { nums: shuffle(rng, nums), target: acc };
  }
}

/** Step allowed under the rules: positive whole results only. */
export function combine(a: number, op: '+' | '−' | '×' | '÷', b: number): number | null {
  if (op === '+') return a + b;
  if (op === '×') return a * b;
  if (op === '−') return a > b ? a - b : null;
  return b !== 0 && a % b === 0 ? a / b : null;
}
