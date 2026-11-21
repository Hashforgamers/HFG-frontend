import { int, pick, shuffle, type Rng } from '../../engine/rng';
import { COMMON_WORDS } from '../_shared/dictionary';

export const DIRS = [[0, 1], [1, 0], [1, 1], [-1, 1], [0, -1], [-1, 0], [-1, -1], [1, -1]] as const;

export interface Search {
  n: number;
  grid: string[];
  words: string[];
  /** cell indices of each word, start to end */
  places: number[][];
}

export const sizeFor = (level: number) => (level <= 2 ? 7 : level <= 5 ? 8 : 9);
export const countFor = (level: number) => Math.min(8, 4 + Math.floor(level / 2));
/** Forward directions first; reversed and diagonal words appear later. */
export const dirsFor = (level: number) => DIRS.slice(0, level <= 2 ? 2 : level <= 4 ? 3 : level <= 6 ? 4 : 8);

export function makeSearch(level: number, rng: Rng): Search {
  const n = sizeFor(level);
  for (;;) {
    const grid = Array<string>(n * n).fill('');
    const words: string[] = [];
    const places: number[][] = [];
    const pool = shuffle(rng, COMMON_WORDS.filter((w) => w.length >= 3 && w.length <= n - 1));
    for (const w of pool) {
      if (words.length === countFor(level)) break;
      if (words.some((x) => x.includes(w) || w.includes(x))) continue; // no word hiding inside another
      for (let tries = 0; tries < 40; tries++) {
        const [dr, dc] = pick(rng, dirsFor(level));
        const r0 = int(rng, 0, n - 1), c0 = int(rng, 0, n - 1);
        const cells = [...w].map((_, k) => [r0 + dr * k, c0 + dc * k]);
        if (cells.some(([r, c]) => r < 0 || c < 0 || r >= n || c >= n)) continue;
        if (cells.some(([r, c], k) => grid[r * n + c] && grid[r * n + c] !== w[k])) continue;
        cells.forEach(([r, c], k) => (grid[r * n + c] = w[k]));
        words.push(w);
        places.push(cells.map(([r, c]) => r * n + c));
        break;
      }
    }
    if (words.length < countFor(level)) continue;
    const letters = 'eeeeaaaiioonnrrsstlcdmuhgpbfkwy';
    for (let i = 0; i < grid.length; i++) if (!grid[i]) grid[i] = pick(rng, [...letters]);
    return { n, grid, words, places };
  }
}

/** Cells on the straight line from a to b (row, column or diagonal), else null. */
export function lineBetween(a: number, b: number, n: number): number[] | null {
  const ar = Math.floor(a / n), ac = a % n, br = Math.floor(b / n), bc = b % n;
  const dr = Math.sign(br - ar), dc = Math.sign(bc - ac);
  const len = Math.max(Math.abs(br - ar), Math.abs(bc - ac));
  if (!(ar === br || ac === bc || Math.abs(br - ar) === Math.abs(bc - ac))) return null;
  return Array.from({ length: len + 1 }, (_, k) => (ar + dr * k) * n + ac + dc * k);
}

/** Which listed word a selected line spells, forwards or backwards. */
export function wordAt(s: Search, cells: number[]): number {
  const text = cells.map((i) => s.grid[i]).join('');
  return s.words.findIndex((w, k) => {
    const p = s.places[k];
    return (w === text || [...w].reverse().join('') === text) && (p.join() === cells.join() || [...p].reverse().join() === cells.join());
  });
}
