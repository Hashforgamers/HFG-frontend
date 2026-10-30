import { pick, shuffle, type Rng } from '../../engine/rng';

export type CageOp = '+' | '−' | '×' | '÷' | '';
export interface Cage {
  cells: number[];
  op: CageOp;
  target: number;
}
export interface KenKen {
  n: number;
  solution: number[];
  cages: Cage[];
}

export const sizeFor = (level: number) => (level <= 3 ? 3 : level <= 8 ? 4 : 5);

/** Shuffled cyclic Latin square: every row and column holds 1..n once. */
export function latin(n: number, rng: Rng): number[] {
  const rows = shuffle(rng, [...Array(n).keys()]);
  const cols = shuffle(rng, [...Array(n).keys()]);
  const syms = shuffle(rng, [...Array(n).keys()].map((i) => i + 1));
  return Array.from({ length: n * n }, (_, i) => syms[(rows[Math.floor(i / n)] + cols[i % n]) % n]);
}

const neighbours = (i: number, n: number) =>
  [i - n, i + n, i % n ? i - 1 : -1, (i + 1) % n ? i + 1 : -1].filter((j) => j >= 0 && j < n * n);

export function cageValue(op: CageOp, v: number[]): number | null {
  switch (op) {
    case '': return v[0];
    case '+': return v.reduce((a, b) => a + b, 0);
    case '×': return v.reduce((a, b) => a * b, 1);
    case '−': return Math.abs(v[0] - v[1]);
    case '÷': return Math.max(...v) % Math.min(...v) === 0 ? Math.max(...v) / Math.min(...v) : null;
  }
}

export function makeKenKen(level: number, rng: Rng): KenKen {
  const n = sizeFor(level);
  const solution = latin(n, rng);
  const owner = Array<number>(n * n).fill(-1);
  const cages: Cage[] = [];
  for (const start of shuffle(rng, [...Array(n * n).keys()])) {
    if (owner[start] >= 0) continue;
    const want = rng() < 0.15 ? 1 : rng() < 0.6 ? 2 : 3;
    const cells = [start];
    owner[start] = cages.length;
    while (cells.length < want) {
      const free = cells.flatMap((c) => neighbours(c, n)).filter((j) => owner[j] < 0);
      if (!free.length) break;
      const j = pick(rng, free);
      owner[j] = cages.length;
      cells.push(j);
    }
    const v = cells.map((c) => solution[c]);
    let op: CageOp = '';
    if (cells.length === 2) {
      const ok: CageOp[] = ['+', '−', '×', ...(cageValue('÷', v) != null ? (['÷'] as CageOp[]) : [])];
      op = pick(rng, ok);
    } else if (cells.length === 3) op = pick(rng, ['+', '×'] as CageOp[]);
    cages.push({ cells, op, target: cageValue(op, v)! });
  }
  return { n, solution, cages };
}

/** Any Latin square that satisfies every cage is a valid answer. */
export function checkKenKen(k: KenKen, grid: number[]): boolean {
  const { n } = k;
  const ok = (line: number[]) => new Set(line).size === n && line.every((v) => v >= 1 && v <= n);
  for (let r = 0; r < n; r++) {
    if (!ok(grid.slice(r * n, r * n + n))) return false;
    if (!ok(Array.from({ length: n }, (_, i) => grid[i * n + r]))) return false;
  }
  return k.cages.every((c) => cageValue(c.op, c.cells.map((i) => grid[i])) === c.target);
}
