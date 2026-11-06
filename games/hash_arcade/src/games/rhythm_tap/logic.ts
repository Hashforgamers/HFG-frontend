import type { Rng } from '../../engine/rng';

export const LEAD_MS = 1600; // how long a note is visible before its beat
export const PERFECT_MS = 60;
export const GOOD_MS = 140;

export type Judgement = 'perfect' | 'good' | 'miss';
export const judge = (deltaMs: number): Judgement =>
  Math.abs(deltaMs) <= PERFECT_MS ? 'perfect' : Math.abs(deltaMs) <= GOOD_MS ? 'good' : 'miss';

export interface Chart {
  bpm: number;
  notes: number[]; // ms from song start
  lengthMs: number;
}

/**
 * 32 beats. Early bars are on the beat; later ones add eighth notes and rests.
 * Notes are never closer than an eighth so each has its own tap.
 */
export function makeChart(rng: Rng, bpm = 100): Chart {
  const beat = 60000 / bpm;
  const notes: number[] = [];
  for (let b = 0; b < 32; b++) {
    const bar = Math.floor(b / 4);
    if (bar > 1 && rng() < 0.15) continue; // rest
    notes.push(Math.round(LEAD_MS + 800 + b * beat));
    if (bar > 2 && rng() < 0.3) notes.push(Math.round(LEAD_MS + 800 + (b + 0.5) * beat));
  }
  return { bpm, notes, lengthMs: LEAD_MS + 800 + 32 * beat + 800 };
}
