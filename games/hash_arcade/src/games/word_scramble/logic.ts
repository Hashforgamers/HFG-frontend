import { pick, shuffle, type Rng } from '../../engine/rng';
import { commonOfLength, isWord, spellable } from '../_shared/words.helpers';

export const lengthFor = (level: number) => Math.min(7, 4 + Math.floor((level - 1) / 3));

/** A shuffle that isn't already the word itself. */
export function makeScramble(level: number, rng: Rng): { word: string; letters: string[] } {
  const word = pick(rng, commonOfLength(lengthFor(level)));
  let letters = shuffle(rng, [...word]);
  while (letters.join('') === word && new Set(word).size > 1) letters = shuffle(rng, [...word]);
  return { word, letters };
}

/** The intended word or any other real word using all the same letters. */
export const acceptScramble = (word: string, guess: string) =>
  guess.length === word.length && spellable(guess, word) && (guess === word || isWord(guess));
