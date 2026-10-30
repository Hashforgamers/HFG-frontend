import { int, pick, type Rng } from '../../engine/rng';

export const ROUNDS = 8;
const DECOYS = ['DRAW?', 'DRAMA', 'DREW!', 'DRAWN', 'DROP!', 'WAIT', 'DOOR!', 'DRUM!'];

/** Decoy words before the real "DRAW!": none at first, up to four later. */
export function makeSignals(round: number, rng: Rng): string[] {
  const decoys = Math.min(4, Math.floor(round / 2) + (rng() < 0.5 ? 0 : 1));
  return [...Array.from({ length: decoys }, () => pick(rng, DECOYS)), 'DRAW!'];
}

export const signalGap = (rng: Rng) => int(rng, 700, 1600);
export const drawPoints = (ms: number) => (ms < 100 ? 0 : Math.max(0, Math.round((650 - ms) * 2)));
