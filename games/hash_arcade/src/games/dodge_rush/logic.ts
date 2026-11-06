import { sample, type Rng } from '../../engine/rng';

export const lanesFor = (level: number) => (level < 15 ? 3 : 4);
/** Falling speed in field-heights per second. */
export const speedFor = (level: number) => Math.min(1.4, 0.45 + level * 0.025);
export const gapFor = (level: number) => Math.max(0.32, 0.62 - level * 0.01);

/** Blocked lanes in one row: always at least one free lane. */
export function makeRow(lanes: number, level: number, rng: Rng): number[] {
  const blocked = Math.min(lanes - 1, 1 + Math.floor(rng() * (level < 8 ? 1 : 2)));
  return sample(rng, lanes, blocked);
}

/** Player sits at y 0.85–0.95; a row is 0.08 tall. */
export const hitsPlayer = (rowY: number, lanesBlocked: number[], lane: number) =>
  lanesBlocked.includes(lane) && rowY + 0.08 > 0.85 && rowY < 0.95;
