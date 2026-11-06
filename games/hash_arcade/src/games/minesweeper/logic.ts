import { sample, type Rng } from '../../engine/rng';

export const layoutFor = (level: number) =>
  level <= 2 ? { cols: 7, rows: 7, mines: 7 } : level <= 5 ? { cols: 8, rows: 9, mines: 11 } : { cols: 9, rows: 11, mines: 17 };

export function neighbours(i: number, cols: number, rows: number): number[] {
  const r = Math.floor(i / cols), c = i % cols;
  const out: number[] = [];
  for (let dr = -1; dr <= 1; dr++)
    for (let dc = -1; dc <= 1; dc++) {
      const rr = r + dr, cc = c + dc;
      if ((dr || dc) && rr >= 0 && rr < rows && cc >= 0 && cc < cols) out.push(rr * cols + cc);
    }
  return out;
}

/** Mines are laid after the first tap, never on it or next to it, so the opening is always safe. */
export function layMines(level: number, first: number, rng: Rng): boolean[] {
  const { cols, rows, mines } = layoutFor(level);
  const safe = new Set([first, ...neighbours(first, cols, rows)]);
  const spots = [...Array(cols * rows).keys()].filter((i) => !safe.has(i));
  const mine = Array<boolean>(cols * rows).fill(false);
  for (const k of sample(rng, spots.length, mines)) mine[spots[k]] = true;
  return mine;
}

export const countAround = (mine: boolean[], i: number, cols: number, rows: number) =>
  neighbours(i, cols, rows).filter((j) => mine[j]).length;

/** Opens a cell; zero cells flood outwards like the classic game. */
export function reveal(mine: boolean[], open: boolean[], i: number, cols: number, rows: number): boolean[] {
  const next = [...open];
  const stack = [i];
  while (stack.length) {
    const k = stack.pop()!;
    if (next[k]) continue;
    next[k] = true;
    if (!mine[k] && countAround(mine, k, cols, rows) === 0) stack.push(...neighbours(k, cols, rows).filter((j) => !next[j]));
  }
  return next;
}

export const cleared = (mine: boolean[], open: boolean[]) => mine.every((m, i) => m || open[i]);
