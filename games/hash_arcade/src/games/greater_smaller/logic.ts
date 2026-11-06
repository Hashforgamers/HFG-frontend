import { int, type Rng } from '../../engine/rng';

export interface Side {
  label: string;
  value: number;
}
export interface Pair {
  left: Side;
  right: Side;
  ask: 'greater' | 'smaller';
}

function side(level: number, rng: Rng): Side {
  if (level <= 5) {
    const v = int(rng, 1, 99);
    return { label: String(v), value: v };
  }
  if (level <= 12) {
    const v = int(rng, 1, 999) / 100;
    return { label: String(v), value: v };
  }
  if (rng() < 0.5) {
    const d = int(rng, 2, 12), n = int(rng, 1, d - 1);
    return { label: `${n}/${d}`, value: n / d };
  }
  const a = int(rng, 2, 9), b = int(rng, 2, 9);
  return { label: `${a}×${b}`, value: a * b };
}

/** Never a tie. From level 13 the two sides are the same kind (two fractions or two products). */
export function makePair(level: number, rng: Rng): Pair {
  for (;;) {
    const left = side(level, rng);
    let right = side(level, rng);
    if (level > 12) {
      const want = left.label.includes('/');
      while (right.label.includes('/') !== want) right = side(level, rng);
    }
    if (Math.abs(left.value - right.value) < 1e-9) continue;
    return { left, right, ask: level >= 5 && rng() < 0.5 ? 'smaller' : 'greater' };
  }
}

export const correctSide = (p: Pair): 'left' | 'right' =>
  (p.left.value > p.right.value) === (p.ask === 'greater') ? 'left' : 'right';
