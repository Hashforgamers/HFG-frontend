import { sample, shuffle, type Rng } from '../../engine/rng';
import { WORDS } from '../_shared/words';

export interface WordRound {
  study: string[];
  /** Half studied, half new, shuffled. */
  test: { word: string; seen: boolean }[];
}

export const studyCount = (level: number) => Math.min(12, 3 + level);
export const studyMs = (count: number) => 1500 + count * 650;

export function makeWordRound(level: number, rng: Rng): WordRound {
  const k = studyCount(level);
  const picks = sample(rng, WORDS.length, k * 2).map((i) => WORDS[i]);
  const study = picks.slice(0, k);
  const test = shuffle(rng, [...study.map((word) => ({ word, seen: true })), ...picks.slice(k).map((word) => ({ word, seen: false }))]);
  return { study, test };
}
