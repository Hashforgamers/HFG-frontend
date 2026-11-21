import { pick, sample, type Rng } from '../../engine/rng';
import { COMMON_WORDS } from '../_shared/dictionary';
import { isWord } from '../_shared/words.helpers';

export interface Gap {
  word: string;
  holes: number[];
}

export const holesFor = (level: number) => (level <= 4 ? 1 : level <= 9 ? 2 : 3);

export function makeGap(level: number, rng: Rng): Gap {
  const holes = holesFor(level);
  const word = pick(rng, COMMON_WORDS.filter((w) => w.length >= 4 + holes && w.length <= 7));
  return { word, holes: sample(rng, word.length, holes).sort((a, b) => a - b) };
}

/** Any real word that fits the visible letters counts. */
export function acceptGap(g: Gap, fills: string[]): boolean {
  const w = [...g.word];
  g.holes.forEach((h, k) => (w[h] = fills[k]));
  const guess = w.join('');
  return guess === g.word || isWord(guess);
}
