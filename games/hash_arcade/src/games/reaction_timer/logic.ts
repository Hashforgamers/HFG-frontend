export const TRIES = 5;

/** Faster than any human can react to a cue: a guess, so it counts as a false start. */
export const ANTICIPATION_MS = 100;

/** 150ms → 900, 250ms → 700, 400ms → 400, 600ms+ → 0. */
export const trialPoints = (ms: number) => (ms < ANTICIPATION_MS ? 0 : Math.max(0, Math.round((600 - ms) * 2)));

export const average = (ms: number[]) => (ms.length ? Math.round(ms.reduce((a, b) => a + b, 0) / ms.length) : 0);

/** Random wait before the cue, so it can't be anticipated. */
export const waitMs = (r: number) => 1200 + Math.round(r * 2600);
