import { pick, shuffle, type Rng } from '../../engine/rng';

export interface Flow {
  n: number;
  /** Each pair's two endpoint cells. */
  ends: [number, number][];
  /** A known non-crossing route per pair, proving it's solvable. */
  routes: number[][];
}

export const sizeFor = (level: number) => (level <= 2 ? 5 : level <= 6 ? 6 : 7);
export const pairsFor = (level: number) => Math.min(7, 3 + Math.floor(level / 2));

const adj = (i: number, n: number) =>
  [i - n, i + n, i % n ? i - 1 : -1, (i + 1) % n ? i + 1 : -1].filter((j) => j >= 0 && j < n * n);
export const adjacent = (a: number, b: number, n: number) => adj(a, n).includes(b);

/** Routes are random self-avoiding walks on free cells, at least 3 long. */
export function makeFlow(level: number, rng: Rng): Flow {
  const n = sizeFor(level);
  const want = pairsFor(level);
  for (;;) {
    const used = new Set<number>();
    const routes: number[][] = [];
    for (let attempt = 0; attempt < 200 && routes.length < want; attempt++) {
      const free = [...Array(n * n).keys()].filter((i) => !used.has(i));
      if (!free.length) break;
      const route = [pick(rng, free)];
      const len = 3 + Math.floor(rng() * n);
      while (route.length < len) {
        const opts = shuffle(rng, adj(route[route.length - 1], n)).filter((j) => !used.has(j) && !route.includes(j));
        if (!opts.length) break;
        route.push(opts[0]);
      }
      if (route.length >= 3) {
        route.forEach((c) => used.add(c));
        routes.push(route);
      }
    }
    if (routes.length === want) return { n, routes, ends: routes.map((r) => [r[0], r[r.length - 1]]) };
  }
}

/** Valid when every pair's path joins its two ends through adjacent cells and no cell is shared. */
export function solvedFlow(f: Flow, paths: number[][]): boolean {
  const seen = new Set<number>();
  return f.ends.every(([a, b], k) => {
    const p = paths[k] ?? [];
    if (p.length < 2) return false;
    const ok = ((p[0] === a && p[p.length - 1] === b) || (p[0] === b && p[p.length - 1] === a)) &&
      p.every((c, i) => i === 0 || adjacent(p[i - 1], c, f.n));
    const clash = p.some((c) => seen.has(c));
    p.forEach((c) => seen.add(c));
    return ok && !clash;
  });
}
