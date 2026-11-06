import { int, pick, shuffle, type Rng } from '../../engine/rng';
import { COMMON_WORDS } from '../_shared/dictionary';
import { isWord } from '../_shared/words.helpers';

const VOWELS = 'aeiou';

/** Plausible mistakes: swapped letters, doubled or undoubled letters, wrong vowel, a dropped letter. */
export function misspell(word: string, rng: Rng): string {
  const w = [...word];
  const i = int(rng, 1, w.length - 2);
  switch (int(rng, 0, 4)) {
    case 0: [w[i], w[i + 1]] = [w[i + 1], w[i]]; break;
    case 1: w.splice(i, 0, w[i]); break;
    case 2: w.splice(i, 1); break;
    default: {
      const v = w.findIndex((c, k) => k > 0 && VOWELS.includes(c));
      if (v > 0) w[v] = pick(rng, [...VOWELS].filter((x) => x !== w[v]));
      else w.splice(i, 0, 'e');
    }
  }
  return w.join('');
}

export interface Spell {
  word: string;
  options: string[];
}

/** Two wrong spellings that aren't real words themselves, plus the right one. */
export function makeSpell(level: number, rng: Rng): Spell {
  const word = pick(rng, COMMON_WORDS.filter((w) => w.length >= (level <= 5 ? 5 : 6)));
  const wrong = new Set<string>();
  for (let t = 0; wrong.size < 2 && t < 200; t++) {
    const m = misspell(word, rng);
    if (m !== word && !isWord(m)) wrong.add(m);
  }
  if (wrong.size < 2) return makeSpell(level, rng);
  return { word, options: shuffle(rng, [word, ...wrong]) };
}
