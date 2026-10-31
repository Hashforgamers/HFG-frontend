import { pick, type Rng } from '../../engine/rng';
import { commonOfLength, isWord } from '../_shared/words.helpers';

export const oneApart = (a: string, b: string) => a.length === b.length && [...a].filter((c, i) => c !== b[i]).length === 1;

/** Breadth-first search over common words; returns the shortest ladder or null. */
export function shortest(from: string, to: string, words: string[]): string[] | null {
  const prev = new Map<string, string | null>([[from, null]]);
  const queue = [from];
  while (queue.length) {
    const w = queue.shift()!;
    if (w === to) {
      const path = [w];
      while (prev.get(path[0])) path.unshift(prev.get(path[0])!);
      return path;
    }
    for (const x of words) if (!prev.has(x) && oneApart(w, x)) {
      prev.set(x, w);
      queue.push(x);
    }
  }
  return null;
}

export interface Ladder {
  start: string;
  end: string;
  best: string[];
}

export const stepsFor = (level: number) => Math.min(6, 2 + Math.floor(level / 2));

/** End word is exactly `steps` changes away along common words, so it can be done. */
export function makeLadder(level: number, rng: Rng): Ladder {
  const words = commonOfLength(level <= 4 ? 3 : 4);
  const steps = stepsFor(level);
  for (;;) {
    const start = pick(rng, words);
    // walk outwards breadth-first and take a word at the right distance
    const dist = new Map<string, number>([[start, 0]]);
    const queue = [start];
    while (queue.length) {
      const w = queue.shift()!;
      if (dist.get(w)! >= steps) continue;
      for (const x of words) if (!dist.has(x) && oneApart(w, x)) {
        dist.set(x, dist.get(w)! + 1);
        queue.push(x);
      }
    }
    const far = [...dist].filter(([, d]) => d === steps).map(([w]) => w);
    if (far.length) {
      const end = pick(rng, far);
      return { start, end, best: shortest(start, end, words)! };
    }
  }
}

/** A legal rung: one letter changed and a real word (any dictionary word, not just common ones). */
export const legalStep = (from: string, to: string) => oneApart(from, to) && isWord(to);
