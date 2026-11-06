import { pick, shuffle, type Rng } from '../../engine/rng';
import { PALETTE, SHAPES, type Shape } from '../_shared/shapes';

export interface Token {
  shape: Shape;
  color: string;
  rotate: number;
}
export interface Board {
  cols: number;
  tokens: Token[];
  pair: [number, number];
}

const key = (t: Token) => `${t.shape}|${t.color}|${t.rotate}`;
export const sameToken = (a: Token, b: Token) => key(a) === key(b);

// shapes whose rotation is visible (a rotated circle looks the same)
const TURNABLE: Shape[] = ['triangle', 'star', 'heart', 'cross', 'hexagon'];
const TURNS = [0, 90, 180, 270];

export const countFor = (level: number) => Math.min(20, 6 + level * 2 - (level % 2));

/**
 * Exactly one identical pair. Later levels draw from fewer shapes and colours,
 * so near-misses (same shape, other colour or turn) get common.
 */
export function makeBoard(level: number, rng: Rng): Board {
  const count = countFor(level);
  const shapes = level <= 3 ? SHAPES : TURNABLE;
  const colors = level <= 6 ? PALETTE : PALETTE.slice(0, 3);
  const seen = new Set<string>();
  const tokens: Token[] = [];
  while (tokens.length < count - 1) {
    const shape = pick(rng, shapes);
    const t = { shape, color: pick(rng, colors), rotate: TURNABLE.includes(shape) ? pick(rng, TURNS) : 0 };
    if (!seen.has(key(t))) {
      seen.add(key(t));
      tokens.push(t);
    }
  }
  const twin = pick(rng, tokens);
  const all = shuffle(rng, [...tokens, { ...twin }]);
  const pair = all.map((t, i) => (sameToken(t, twin) ? i : -1)).filter((i) => i >= 0) as [number, number];
  return { cols: count <= 9 ? 3 : 4, tokens: all, pair };
}
