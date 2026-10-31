import { COMMON_WORDS, VALID_WORDS } from './dictionary';

export const isWord = (w: string) => VALID_WORDS.has(w.toLowerCase());
export const commonOfLength = (n: number) => COMMON_WORDS.filter((w) => w.length === n);

/** Letter multiset check: can `word` be spelled from `letters`? */
export function spellable(word: string, letters: string): boolean {
  const pool: Record<string, number> = {};
  for (const l of letters) pool[l] = (pool[l] ?? 0) + 1;
  for (const l of word) {
    if (!pool[l]) return false;
    pool[l]--;
  }
  return true;
}
