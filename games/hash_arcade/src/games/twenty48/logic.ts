import type { Rng } from '../../engine/rng';

export type Dir = 'left' | 'right' | 'up' | 'down';
export const N = 4;

/** Slide one row left: merge equal pairs once, return the new row and points (sum of merges). */
export function slideRow(row: number[]): { row: number[]; points: number } {
  const tiles = row.filter(Boolean);
  const out: number[] = [];
  let points = 0;
  for (let i = 0; i < tiles.length; i++) {
    if (tiles[i] === tiles[i + 1]) {
      out.push(tiles[i] * 2);
      points += tiles[i] * 2;
      i++;
    } else out.push(tiles[i]);
  }
  while (out.length < N) out.push(0);
  return { row: out, points };
}

const idx = (dir: Dir, line: number, k: number) => {
  switch (dir) {
    case 'left': return line * N + k;
    case 'right': return line * N + (N - 1 - k);
    case 'up': return k * N + line;
    case 'down': return (N - 1 - k) * N + line;
  }
};

export function move(board: number[], dir: Dir): { board: number[]; points: number; moved: boolean } {
  const next = [...board];
  let points = 0;
  for (let line = 0; line < N; line++) {
    const r = slideRow(Array.from({ length: N }, (_, k) => board[idx(dir, line, k)]));
    points += r.points;
    r.row.forEach((v, k) => (next[idx(dir, line, k)] = v));
  }
  return { board: next, points, moved: next.some((v, i) => v !== board[i]) };
}

/** A 2 (90%) or 4 in a random empty cell. */
export function addTile(board: number[], rng: Rng): number[] {
  const empty = board.map((v, i) => (v ? -1 : i)).filter((i) => i >= 0);
  if (!empty.length) return board;
  const next = [...board];
  next[empty[Math.floor(rng() * empty.length)]] = rng() < 0.9 ? 2 : 4;
  return next;
}

export const canMove = (board: number[]) => (['left', 'right', 'up', 'down'] as Dir[]).some((d) => move(board, d).moved);
export const newBoard = (rng: Rng) => addTile(addTile(Array(N * N).fill(0), rng), rng);
