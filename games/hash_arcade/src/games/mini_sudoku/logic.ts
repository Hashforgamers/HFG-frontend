import { shuffle, type Rng } from '../../engine/rng';

export interface Sudoku {
  n: number;
  boxW: number;
  boxH: number;
  solution: number[];
  givens: number[]; // 0 = blank
}

export const shapeFor = (level: number) => (level <= 3 ? { n: 4, boxW: 2, boxH: 2 } : { n: 6, boxW: 3, boxH: 2 });

export function valid(grid: number[], n: number, boxW: number, boxH: number, i: number, v: number): boolean {
  const r = Math.floor(i / n), c = i % n;
  for (let k = 0; k < n; k++) if (grid[r * n + k] === v || grid[k * n + c] === v) return false;
  const br = r - (r % boxH), bc = c - (c % boxW);
  for (let y = 0; y < boxH; y++) for (let x = 0; x < boxW; x++) if (grid[(br + y) * n + bc + x] === v) return false;
  return true;
}

/** Number of solutions, stopping at `limit`. */
export function countSolutions(grid: number[], n: number, boxW: number, boxH: number, limit = 2): number {
  const i = grid.indexOf(0);
  if (i < 0) return 1;
  let count = 0;
  for (let v = 1; v <= n && count < limit; v++) {
    if (!valid(grid, n, boxW, boxH, i, v)) continue;
    grid[i] = v;
    count += countSolutions(grid, n, boxW, boxH, limit - count);
    grid[i] = 0;
  }
  return count;
}

function fill(grid: number[], n: number, boxW: number, boxH: number, rng: Rng): boolean {
  const i = grid.indexOf(0);
  if (i < 0) return true;
  for (const v of shuffle(rng, Array.from({ length: n }, (_, k) => k + 1))) {
    if (!valid(grid, n, boxW, boxH, i, v)) continue;
    grid[i] = v;
    if (fill(grid, n, boxW, boxH, rng)) return true;
  }
  grid[i] = 0;
  return false;
}

/** A random full grid, then clues removed one by one while the answer stays unique. */
export function makeSudoku(level: number, rng: Rng): Sudoku {
  const { n, boxW, boxH } = shapeFor(level);
  const solution = Array<number>(n * n).fill(0);
  fill(solution, n, boxW, boxH, rng);
  const givens = [...solution];
  const target = Math.round(n * n * (n === 4 ? Math.min(0.62, 0.4 + level * 0.07) : Math.min(0.6, 0.38 + (level - 3) * 0.03)));
  let removed = 0;
  for (const i of shuffle(rng, [...Array(n * n).keys()])) {
    if (removed >= target) break;
    const keep = givens[i];
    givens[i] = 0;
    if (countSolutions([...givens], n, boxW, boxH) === 1) removed++;
    else givens[i] = keep;
  }
  return { n, boxW, boxH, solution, givens };
}

export const solvedSudoku = (s: Sudoku, grid: number[]) => grid.every((v, i) => v === s.solution[i]);
