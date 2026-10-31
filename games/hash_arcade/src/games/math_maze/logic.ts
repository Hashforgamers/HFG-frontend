import { int, shuffle, type Rng } from '../../engine/rng';

export interface Step {
  op: '+' | '−' | '×';
  v: number;
}
export interface Maze {
  n: number;
  start: number;
  cells: Step[];
  target: number;
  /** One route that works: cell indices from top-left to bottom-right. */
  route: number[];
}

export const sizeFor = (level: number) => (level <= 3 ? 3 : level <= 8 ? 4 : 5);
export const applyStep = (t: number, s: Step) => (s.op === '+' ? t + s.v : s.op === '−' ? t - s.v : t * s.v);

function randomStep(total: number, rng: Rng): Step {
  const r = rng();
  if (r < 0.2 && total <= 40) return { op: '×', v: int(rng, 2, 3) };
  if (r < 0.55 && total >= 2) return { op: '−', v: int(rng, 1, Math.min(9, total)) };
  return { op: '+', v: int(rng, 1, 9) };
}

/** Moves go right or down only. Totals along the planted route stay 0–999. */
export function makeMaze(level: number, rng: Rng): Maze {
  const n = sizeFor(level);
  const moves = shuffle(rng, [...Array(n - 1).fill('R'), ...Array(n - 1).fill('D')]);
  const route = [0];
  for (const m of moves) route.push(route[route.length - 1] + (m === 'R' ? 1 : n));
  const start = int(rng, 1, 10);
  const cells: Step[] = Array.from({ length: n * n }, () => randomStep(int(rng, 0, 30), rng));
  let total = start;
  for (const i of route) {
    cells[i] = randomStep(total, rng);
    total = applyStep(total, cells[i]);
  }
  return { n, start, cells, target: total, route };
}

export const canStep = (from: number, to: number, n: number) => to === from + n || (to === from + 1 && to % n !== 0);

export const walk = (m: Maze, path: number[]) => path.reduce((t, i) => applyStep(t, m.cells[i]), m.start);
