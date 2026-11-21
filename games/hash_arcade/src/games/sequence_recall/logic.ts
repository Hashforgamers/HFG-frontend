import { shuffle, sample, type Rng } from '../../engine/rng';
import { GLYPHS } from '../_shared/glyphs';

export interface Recall {
  /** The six symbols on the answer pad this round. */
  pad: string[];
  sequence: string[];
}

/** Repeats allowed but never twice in a row, so each flash is visibly a new step. */
export function makeRecall(length: number, rng: Rng): Recall {
  const pad = sample(rng, GLYPHS.length, 6).map((i) => GLYPHS[i]);
  const sequence: string[] = [];
  while (sequence.length < length) {
    const s = pad[Math.floor(rng() * pad.length)];
    if (s !== sequence[sequence.length - 1]) sequence.push(s);
  }
  return { pad: shuffle(rng, pad), sequence };
}
