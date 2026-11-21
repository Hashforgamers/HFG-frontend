import { int, pick, type Rng } from '../../engine/rng';

export interface Problem {
  text: string;
  answer: number;
}

/** Answers are always whole and non-negative, so the keypad needs no minus key. */
export function makeProblem(level: number, rng: Rng): Problem {
  if (level <= 4) {
    const a = int(rng, 1, 12), b = int(rng, 1, 9);
    return { text: `${a} + ${b}`, answer: a + b };
  }
  if (level <= 9) {
    const a = int(rng, 10, 50), b = int(rng, 2, 30);
    return rng() < 0.5 ? { text: `${a} + ${b}`, answer: a + b } : { text: `${Math.max(a, b)} − ${Math.min(a, b)}`, answer: Math.abs(a - b) };
  }
  if (level <= 15) {
    const kind = pick(rng, ['×', '+', '−'] as const);
    if (kind === '×') {
      const a = int(rng, 3, 12), b = int(rng, 3, 12);
      return { text: `${a} × ${b}`, answer: a * b };
    }
    const a = int(rng, 30, 99), b = int(rng, 11, 60);
    return kind === '+' ? { text: `${a} + ${b}`, answer: a + b } : { text: `${Math.max(a, b)} − ${Math.min(a, b)}`, answer: Math.abs(a - b) };
  }
  const kind = pick(rng, ['÷', '×+', '×−'] as const);
  const a = int(rng, 3, 12), b = int(rng, 3, 15);
  if (kind === '÷') return { text: `${a * b} ÷ ${a}`, answer: b };
  const c = int(rng, 2, Math.min(40, a * b));
  return kind === '×+' ? { text: `${a} × ${b} + ${c}`, answer: a * b + c } : { text: `${a} × ${b} − ${c}`, answer: a * b - c };
}
