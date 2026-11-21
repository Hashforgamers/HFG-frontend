import { sample, type Rng } from '../../engine/rng';

/** Flip cell i and its orthogonal neighbours on an n×n board. */
export function press(grid: boolean[], i: number, n: number): boolean[] {
  const g = [...grid];
  const r = Math.floor(i / n), c = i % n;
  for (const [dr, dc] of [[0, 0], [1, 0], [-1, 0], [0, 1], [0, -1]]) {
    const rr = r + dr, cc = c + dc;
    if (rr >= 0 && rr < n && cc >= 0 && cc < n) g[rr * n + cc] = !g[rr * n + cc];
  }
  return g;
}

export const solved = (grid: boolean[]) => grid.every((on) => !on);

export const sizeFor = (level: number) => (level <= 2 ? 3 : level <= 5 ? 4 : 5);

export interface Board {
  n: number;
  grid: boolean[];
  /** The presses that made it; pressing them again solves it, so every board is solvable. */
  presses: number[];
}

export function scramble(level: number, rng: Rng): Board {
  const n = sizeFor(level);
  const k = Math.min(Math.floor((n * n) / 2), 2 + level);
  for (;;) {
    const presses = sample(rng, n * n, k);
    const grid = presses.reduce((g, i) => press(g, i, n), Array<boolean>(n * n).fill(false));
    // on 4×4 and 5×5 some press sets cancel out; never hand over a solved board
    if (!solved(grid)) return { n, grid, presses };
  }
}

export const solvePoints = (k: number, moves: number) => 100 + 20 * Math.max(0, 2 * k - moves);
