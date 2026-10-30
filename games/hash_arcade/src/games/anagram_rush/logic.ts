import { pick, shuffle, type Rng } from '../../engine/rng';
import { COMMON_WORDS, VALID_WORDS } from '../_shared/dictionary';
import { spellable } from '../_shared/words.helpers';

export interface Rack {
  letters: string[];
  /** Every dictionary word of 3+ letters the rack can spell. */
  answers: string[];
}

/** A 6–7 letter base word guarantees plenty of answers. */
export function makeRack(rng: Rng): Rack {
  for (;;) {
    const base = pick(rng, COMMON_WORDS.filter((w) => w.length >= 6));
    const answers = [...VALID_WORDS].filter((w) => w.length >= 3 && spellable(w, base));
    if (answers.length >= 12) return { letters: shuffle(rng, [...base]), answers };
  }
}

/** Longer words are worth far more. */
export const wordPoints = (w: string) => [0, 0, 0, 30, 60, 120, 220, 350][Math.min(7, w.length)];
