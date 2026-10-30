import { pick, type Rng } from '../../engine/rng';
import { commonOfLength } from '../_shared/words.helpers';

export type Mark = 'hit' | 'near' | 'miss';
export const TRIES = 6;

export const makeAnswer = (rng: Rng) => pick(rng, commonOfLength(5));

/** Green for the right spot; yellow only for letters still unmatched (duplicates handled). */
export function markGuess(answer: string, guess: string): Mark[] {
  const marks: Mark[] = Array(5).fill('miss');
  const left: Record<string, number> = {};
  [...answer].forEach((c, i) => {
    if (guess[i] === c) marks[i] = 'hit';
    else left[c] = (left[c] ?? 0) + 1;
  });
  [...guess].forEach((c, i) => {
    if (marks[i] !== 'hit' && left[c]) {
      marks[i] = 'near';
      left[c]--;
    }
  });
  return marks;
}
