import { int, pick, type Rng } from '../../engine/rng';
import { GLYPHS, GLYPH_COLORS } from '../_shared/glyphs';

export interface Thing {
  x: number;
  y: number;
  glyph: string;
  color: string;
  size: number;
  rotate: number;
}
export interface Scene {
  target: Thing;
  clutter: Thing[];
}

export const clutterFor = (level: number) => Math.min(110, 25 + level * 8);

const thing = (rng: Rng, glyph: string): Thing => ({
  x: 0.06 + rng() * 0.88,
  y: 0.06 + rng() * 0.88,
  glyph,
  color: pick(rng, GLYPH_COLORS),
  size: 0.055 + rng() * 0.05,
  rotate: int(rng, -40, 40),
});

/** The target appears once; nothing is drawn right on top of it. */
export function makeScene(level: number, rng: Rng): Scene {
  const target = thing(rng, pick(rng, GLYPHS));
  const others = GLYPHS.filter((g) => g !== target.glyph);
  const clutter: Thing[] = [];
  while (clutter.length < clutterFor(level)) {
    const t = thing(rng, pick(rng, others));
    if (Math.hypot(t.x - target.x, t.y - target.y) > target.size * 0.9) clutter.push(t);
  }
  return { target, clutter };
}

/** Tap tolerance: within the target's own size (in field units). */
export const isOnTarget = (s: Scene, x: number, y: number) => Math.hypot(x - s.target.x, y - s.target.y) <= Math.max(0.06, s.target.size);
