import { int, pick, type Rng } from '../../engine/rng';
import { OPS, eq, evaluate, isInt, q, type Op } from '../_shared/fraction';

export interface Blanks {
  nums: number[];
  target: number;
}

export const blanksFor = (level: number) => (level <= 3 ? 1 : level <= 8 ? 2 : 3);

/** Retries until the hidden ops give a whole, non-negative answer (× and ÷ bind first). */
export function makeBlanks(level: number, rng: Rng): Blanks {
  const k = blanksFor(level);
  for (;;) {
    const nums = Array.from({ length: k + 1 }, () => int(rng, 1, level < 6 ? 9 : 12));
    const ops = Array.from({ length: k }, () => pick(rng, level < 2 ? (['+', '−'] as Op[]) : OPS));
    const r = evaluate(nums, ops);
    if (r && isInt(r) && r.n >= 0) return { nums, target: r.n };
  }
}

/** Any operators that make the equation true count. */
export const checkBlanks = (b: Blanks, ops: Op[]) => {
  const r = evaluate(b.nums, ops);
  return r != null && eq(r, q(b.target));
};
