import { int, pick, sample, type Rng } from '../../engine/rng';

export type XOp = '+' | '−' | '×';

/** a b / c d grid: rows a·b and c·d, columns a·c and b·d. */
export const LINES: [number, number][] = [[0, 1], [2, 3], [0, 2], [1, 3]];

export interface Cross {
  vals: number[];
  ops: XOp[];
  results: number[];
  blanks: number[];
}

export const applyX = (a: number, op: XOp, b: number) => (op === '+' ? a + b : op === '−' ? a - b : a * b);

export function makeCross(level: number, rng: Rng): Cross {
  const max = level < 6 ? 9 : 12;
  const vals = Array.from({ length: 4 }, () => int(rng, 1, max));
  const opsFor: XOp[] = level < 3 ? ['+'] : level < 6 ? ['+', '−'] : ['+', '−', '×'];
  const ops = LINES.map(([a, b]) => {
    const op = pick(rng, opsFor);
    return op === '−' && vals[a] < vals[b] ? '+' : op; // results never negative
  });
  const results = LINES.map(([a, b], i) => applyX(vals[a], ops[i], vals[b]));
  return { vals, ops, results, blanks: sample(rng, 4, Math.min(4, 1 + Math.floor(level / 3))) };
}

/** Any values that satisfy all four equations count, not just the generated ones. */
export const checkCross = (c: Cross, vals: number[]) =>
  LINES.every(([a, b], i) => applyX(vals[a], c.ops[i], vals[b]) === c.results[i]);
