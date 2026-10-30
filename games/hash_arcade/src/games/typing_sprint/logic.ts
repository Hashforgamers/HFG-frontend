import { pick, type Rng } from '../../engine/rng';
import { COMMON_WORDS } from '../_shared/dictionary';

/** Short words early, longer later. */
export const nextWord = (typed: number, rng: Rng) =>
  pick(rng, COMMON_WORDS.filter((w) => w.length >= 3 + Math.min(3, Math.floor(typed / 6)) && w.length <= 4 + Math.min(3, Math.floor(typed / 4))));

/** Standard words-per-minute: 5 characters = one word. */
export const wpm = (chars: number, ms: number) => (ms > 0 ? Math.round(chars / 5 / (ms / 60000)) : 0);
