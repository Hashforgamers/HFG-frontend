import { sample, shuffle, type Rng } from '../../engine/rng';
import { GLYPHS } from '../_shared/glyphs';

export interface Placement {
  size: number;
  /** cell index → glyph */
  items: { cell: number; glyph: string }[];
  /** order the player is asked for them */
  order: number[];
}

export const sizeFor = (level: number) => (level <= 4 ? 4 : 5);
export const countFor = (level: number) => Math.min(8, 2 + Math.floor(level / 2));

export function makePlacement(level: number, rng: Rng): Placement {
  const size = sizeFor(level);
  const count = countFor(level);
  const cells = sample(rng, size * size, count);
  const glyphs = sample(rng, GLYPHS.length, count).map((i) => GLYPHS[i]);
  return { size, items: cells.map((cell, i) => ({ cell, glyph: glyphs[i] })), order: shuffle(rng, [...Array(count).keys()]) };
}

export const showMs = (count: number) => 1400 + count * 450;
