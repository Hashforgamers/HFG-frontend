import { int, type Rng } from '../../engine/rng';
import { OPS, apply, eq, q, type Q } from '../_shared/fraction';

/** True when the numbers can be combined, each used once, to exactly `target`. */
export function solvable(nums: Q[], target: Q): boolean {
  if (nums.length === 1) return eq(nums[0], target);
  for (let i = 0; i < nums.length; i++) {
    for (let j = 0; j < nums.length; j++) {
      if (i === j) continue;
      const rest = nums.filter((_, k) => k !== i && k !== j);
      for (const op of OPS) {
        if ((op === '+' || op === '×') && j < i) continue; // commutative: try once
        const r = apply(nums[i], op, nums[j]);
        if (r && solvable([...rest, r], target)) return true;
      }
    }
  }
  return false;
}

export const TARGET = q(24);

/** Four numbers that make 24; larger numbers as levels climb. */
export function make24(level: number, rng: Rng): number[] {
  const max = level < 4 ? 9 : 13;
  for (;;) {
    const nums = Array.from({ length: 4 }, () => int(rng, 1, max));
    if (solvable(nums.map((n) => q(n)), TARGET)) return nums;
  }
}
