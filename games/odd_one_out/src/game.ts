// Pure game rules: puzzles, difficulty, scoring. No DOM, so it is unit-tested.

export type Tier = 'EASY' | 'MEDIUM' | 'HARD' | 'INSANE';

// Each pair stays distinct in any monospace font; look-alikes that collapse in
// some fonts (O/0, I/l/1) are left out on purpose.
const PAIRS: Record<Tier, [string, string][]> = {
  EASY: [['?', '2'], ['X', 'O'], ['#', '@'], ['+', '%'], ['A', 'V'], ['H', 'T'], ['$', '&'], ['*', '='], ['L', '7']],
  MEDIUM: [['B', '8'], ['S', '5'], ['Z', '2'], ['G', '6'], ['M', 'N'], ['K', 'X'], ['E', 'F'], ['C', 'G'], ['U', 'V']],
  HARD: [['O', 'Q'], ['P', 'R'], ['b', 'd'], ['p', 'q'], ['6', '9'], ['V', 'Y'], ['n', 'h'], ['u', 'v'], ['m', 'n'], ['E', 'F']],
  INSANE: [['o', 'ö'], ['u', 'ü'], ['a', 'ä'], ['e', 'é'], ['c', 'ç'], ['n', 'ñ'], ['O', 'Q'], ['P', 'R'], ['i', 'j']],
};

export const START_TIME = 30;
export const CORRECT_BONUS = 2;
export const WRONG_PENALTY = 3;
export const BASE_POINTS = 100;
export const MAX_MULT = 5;

export function tierFor(level: number): Tier {
  if (level <= 5) return 'EASY';
  if (level <= 10) return 'MEDIUM';
  if (level <= 20) return 'HARD';
  return 'INSANE';
}

/** Grid side grows by one every 2 levels: 6×6 at level 1, 15×15 at 20, capped at 20×20. */
export const gridSize = (level: number) => Math.min(20, 6 + Math.floor((level - 1) / 2));

/** Combo multiplier: +1× every 3 straight hits, capped at 5×. */
export const multiplier = (streak: number) => Math.min(MAX_MULT, 1 + Math.floor(streak / 3));

export interface Puzzle {
  rows: number;
  cols: number;
  base: string;
  odd: string;
  oddIndex: number;
  tier: Tier;
}

export type Rng = () => number;

export function mulberry32(seed: number): Rng {
  let a = seed >>> 0;
  return () => {
    a = (a + 0x6d2b79f5) >>> 0;
    let t = a;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

export function hashString(s: string): number {
  let h = 2166136261;
  for (let i = 0; i < s.length; i++) h = Math.imul(h ^ s.charCodeAt(i), 16777619);
  return h >>> 0;
}

/** Today's date in the player's timezone, e.g. "2026-10-30" — the daily seed. */
export function todayKey(d = new Date()): string {
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
}

/**
 * One round. `maxCols`/`maxRows` are how many cells fit on screen at a usable
 * touch size; the tier's square grid shrinks to that, extra rows make up cells.
 */
export function makePuzzle(level: number, rng: Rng, maxCols = 99, maxRows = 99): Puzzle {
  const tier = tierFor(level);
  const n = gridSize(level);
  const cols = Math.max(4, Math.min(n, maxCols));
  const rows = Math.max(4, Math.min(Math.ceil((n * n) / cols), maxRows));
  const pairs = PAIRS[tier];
  const [a, b] = pairs[Math.floor(rng() * pairs.length)];
  const flip = rng() < 0.5;
  return {
    rows,
    cols,
    base: flip ? b : a,
    odd: flip ? a : b,
    oddIndex: Math.floor(rng() * rows * cols),
    tier,
  };
}

export interface Rank {
  title: string;
  min: number;
}

const RANKS: Rank[] = [
  { title: 'LEGEND', min: 6000 },
  { title: 'EAGLE EYE', min: 3500 },
  { title: 'SHARPSHOOTER', min: 2000 },
  { title: 'SPOTTER', min: 1000 },
  { title: 'ROOKIE', min: 0 },
];

export const rankFor = (score: number) => RANKS.find((r) => score >= r.min)!;
