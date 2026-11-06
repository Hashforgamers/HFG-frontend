import type { Rng } from '../../engine/rng';

export const sizeFor = (level: number) => (level <= 2 ? 3 : 4);

export const solvedBoard = (n: number) => [...Array.from({ length: n * n - 1 }, (_, i) => i + 1), 0];
export const isSolved = (b: number[]) => b.every((v, i) => v === (i === b.length - 1 ? 0 : i + 1));

export function slidable(b: number[], n: number, i: number): boolean {
  const z = b.indexOf(0);
  return (Math.abs(z - i) === 1 && Math.floor(z / n) === Math.floor(i / n)) || Math.abs(z - i) === n;
}

export function slide(b: number[], n: number, i: number): number[] {
  if (!slidable(b, n, i)) return b;
  const next = [...b];
  const z = b.indexOf(0);
  [next[z], next[i]] = [next[i], next[z]];
  return next;
}

/** Shuffle by random legal moves from the solved board, so it's always solvable. */
export function shuffled(level: number, rng: Rng): number[] {
  const n = sizeFor(level);
  let b = solvedBoard(n);
  let prev = -1;
  for (let k = 0; k < 40 + level * 25 || isSolved(b); k++) {
    const options = b.map((_, i) => i).filter((i) => slidable(b, n, i) && i !== prev);
    const pickI = options[Math.floor(rng() * options.length)];
    prev = b.indexOf(0);
    b = slide(b, n, pickI);
  }
  return b;
}
