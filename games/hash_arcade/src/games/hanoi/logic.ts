export const disksFor = (level: number) => Math.min(7, 2 + level);
export const optimal = (n: number) => 2 ** n - 1;

export type Pegs = number[][]; // bottom → top, bigger number = bigger disk

export const start = (n: number): Pegs => [Array.from({ length: n }, (_, i) => n - i), [], []];

export function canMove(p: Pegs, from: number, to: number): boolean {
  const disk = p[from][p[from].length - 1];
  const top = p[to][p[to].length - 1];
  return disk != null && from !== to && (top == null || top > disk);
}

export function moveDisk(p: Pegs, from: number, to: number): Pegs {
  if (!canMove(p, from, to)) return p;
  const next = p.map((s) => [...s]);
  next[to].push(next[from].pop()!);
  return next;
}

export const done = (p: Pegs, n: number) => p[2].length === n;
/** Full points at the minimum moves, less for every extra one. */
export const solvePoints = (n: number, moves: number) => Math.max(50, 100 * n - (moves - optimal(n)) * 10);
