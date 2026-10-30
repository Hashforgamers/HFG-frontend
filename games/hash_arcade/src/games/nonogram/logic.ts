import type { Rng } from '../../engine/rng';

export const sizeFor = (level: number) => (level <= 3 ? 5 : level <= 7 ? 6 : 8);

/** Run lengths of filled cells, e.g. ■■□■ → [2, 1]; an empty line → [0]. */
export function clue(line: boolean[]): number[] {
  const runs: number[] = [];
  let run = 0;
  for (const on of line) {
    if (on) run++;
    else if (run) {
      runs.push(run);
      run = 0;
    }
  }
  if (run) runs.push(run);
  return runs.length ? runs : [0];
}

export const rowsOf = (g: boolean[], n: number) => Array.from({ length: n }, (_, r) => g.slice(r * n, r * n + n));
export const colsOf = (g: boolean[], n: number) => Array.from({ length: n }, (_, c) => Array.from({ length: n }, (_, r) => g[r * n + c]));

export interface Nonogram {
  n: number;
  picture: boolean[];
  rows: number[][];
  cols: number[][];
}

/** Random picture, about 55% filled, no empty rows or columns. */
export function makeNonogram(level: number, rng: Rng): Nonogram {
  const n = sizeFor(level);
  for (;;) {
    const picture = Array.from({ length: n * n }, () => rng() < 0.55);
    const rows = rowsOf(picture, n).map(clue);
    const cols = colsOf(picture, n).map(clue);
    if ([...rows, ...cols].every((c) => c[0] !== 0)) return { n, picture, rows, cols };
  }
}

/** Any grid matching every clue counts, even if it isn't the original picture. */
export const matchesClues = (p: Nonogram, grid: boolean[]) =>
  rowsOf(grid, p.n).every((l, i) => clue(l).join() === p.rows[i].join()) &&
  colsOf(grid, p.n).every((l, i) => clue(l).join() === p.cols[i].join());
