import { pick, type Rng } from '../../engine/rng';
import { COMMON_WORDS } from '../_shared/dictionary';
import { isWord } from '../_shared/words.helpers';

// letters almost no word ends on keep the chain playable
export const startWord = (rng: Rng) => pick(rng, COMMON_WORDS.filter((w) => w.length >= 4 && !/[xqzjv]$/.test(w)));

export type Verdict = 'ok' | 'wrong-start' | 'not-a-word' | 'used' | 'too-short';

export function judgeLink(prev: string, word: string, used: Set<string>): Verdict {
  if (word.length < 3) return 'too-short';
  if (word[0] !== prev[prev.length - 1]) return 'wrong-start';
  if (used.has(word)) return 'used';
  return isWord(word) ? 'ok' : 'not-a-word';
}

/** Longer links are worth more. */
export const linkPoints = (w: string) => 20 * w.length;
