import { shuffle, type Rng } from '../../engine/rng';
import { GLYPHS } from '../_shared/glyphs';

export const layoutFor = (level: number) => (level <= 1 ? { cols: 3, rows: 4 } : level <= 3 ? { cols: 4, rows: 4 } : { cols: 4, rows: 5 });

/** Glyph index per card; every glyph appears exactly twice. */
export function makeDeck(level: number, rng: Rng): number[] {
  const { cols, rows } = layoutFor(level);
  const pairs = shuffle(rng, [...GLYPHS.keys()]).slice(0, (cols * rows) / 2);
  return shuffle(rng, [...pairs, ...pairs]);
}
