import { int, type Rng } from '../../engine/rng';

export const PEGS = 4;
export const TRIES = 10;
export const colorsFor = (level: number) => (level <= 2 ? 5 : 6);

export const makeCode = (level: number, rng: Rng) => Array.from({ length: PEGS }, () => int(rng, 0, colorsFor(level) - 1));

/** exact: right colour, right place. near: right colour, wrong place (duplicates counted once). */
export function score(code: number[], guess: number[]): { exact: number; near: number } {
  let exact = 0;
  const left: Record<number, number> = {};
  const rest: number[] = [];
  code.forEach((c, i) => {
    if (guess[i] === c) exact++;
    else {
      left[c] = (left[c] ?? 0) + 1;
      rest.push(guess[i]);
    }
  });
  let near = 0;
  for (const g of rest) if (left[g]) {
    near++;
    left[g]--;
  }
  return { exact, near };
}
