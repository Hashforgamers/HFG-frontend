import { pick, shuffle, type Rng } from '../../engine/rng';

export const PEOPLE = ['Aarav', 'Diya', 'Kabir', 'Meera'];
export const GAMES = ['Chess', 'Valorant', 'FIFA', 'Ludo'];
export const SNACKS = ['Samosa', 'Pizza', 'Momos', 'Vada pav'];

/** assignment[p] = index of that person's game / snack */
export interface Solution {
  game: number[];
  snack: number[];
}
export type Clue =
  | { kind: 'has'; person: number; what: 'game' | 'snack'; item: number; yes: boolean }
  | { kind: 'link'; game: number; snack: number; yes: boolean };

export const sizeFor = (level: number) => (level <= 3 ? 3 : 4);

function perms(n: number): number[][] {
  if (n === 1) return [[0]];
  return perms(n - 1).flatMap((p) => Array.from({ length: n }, (_, i) => [...p.slice(0, i), n - 1, ...p.slice(i)]));
}

export const holds = (c: Clue, s: Solution): boolean =>
  c.kind === 'has'
    ? (c.what === 'game' ? s.game[c.person] : s.snack[c.person]) === c.item === c.yes
    : s.snack[s.game.indexOf(c.game)] === c.snack === c.yes;

export function solutions(n: number, clues: Clue[]): Solution[] {
  const ps = perms(n);
  const out: Solution[] = [];
  for (const game of ps) for (const snack of ps) if (clues.every((c) => holds(c, { game, snack }))) out.push({ game, snack });
  return out;
}

function randomClue(n: number, s: Solution, rng: Rng): Clue {
  const yes = rng() < 0.45;
  if (rng() < 0.6) {
    const person = Math.floor(rng() * n);
    const what = rng() < 0.5 ? 'game' : 'snack';
    const truth = what === 'game' ? s.game[person] : s.snack[person];
    const item = yes ? truth : pick(rng, [...Array(n).keys()].filter((i) => i !== truth));
    return { kind: 'has', person, what, item, yes };
  }
  const game = Math.floor(rng() * n);
  const truth = s.snack[s.game.indexOf(game)];
  return { kind: 'link', game, snack: yes ? truth : pick(rng, [...Array(n).keys()].filter((i) => i !== truth)), yes };
}

export interface LogicPuzzle {
  n: number;
  solution: Solution;
  clues: Clue[];
}

/** Adds true clues until exactly one assignment fits, then drops any clue that isn't needed. */
export function makeLogic(level: number, rng: Rng): LogicPuzzle {
  const n = sizeFor(level);
  const solution = { game: shuffle(rng, [...Array(n).keys()]), snack: shuffle(rng, [...Array(n).keys()]) };
  let clues: Clue[] = [];
  while (solutions(n, clues).length > 1) clues.push(randomClue(n, solution, rng));
  for (const c of [...clues]) {
    const without = clues.filter((x) => x !== c);
    if (solutions(n, without).length === 1) clues = without;
  }
  return { n, solution, clues: shuffle(rng, clues) };
}

export function clueText(c: Clue): string {
  if (c.kind === 'has') {
    const thing = c.what === 'game' ? `plays ${GAMES[c.item]}` : `eats ${SNACKS[c.item]}`;
    return `${PEOPLE[c.person]} ${c.yes ? '' : "doesn't "}${c.yes ? thing : thing.replace('plays', 'play').replace('eats', 'eat')}`;
  }
  return `The ${GAMES[c.game]} player ${c.yes ? 'eats' : "doesn't eat"} ${SNACKS[c.snack]}`;
}
