import { int, pick, type Rng } from '../../engine/rng';

export type Rule = 'step' | 'down' | 'double' | 'squares' | 'fibonacci' | 'interleave' | 'growing';

export interface Sequence {
  rule: Rule;
  full: number[];
  missing: number;
}

const LEN = 6;

export function build(rule: Rule, rng: Rng): number[] {
  switch (rule) {
    case 'step': {
      const a = int(rng, 1, 20), d = int(rng, 2, 9);
      return Array.from({ length: LEN }, (_, i) => a + d * i);
    }
    case 'down': {
      const d = int(rng, 2, 9), a = d * LEN + int(rng, 1, 30);
      return Array.from({ length: LEN }, (_, i) => a - d * i);
    }
    case 'double': {
      const a = int(rng, 1, 5), r = int(rng, 2, 3);
      return Array.from({ length: LEN }, (_, i) => a * r ** i);
    }
    case 'squares': {
      const s = int(rng, 1, 5), c = int(rng, 0, 5);
      return Array.from({ length: LEN }, (_, i) => (s + i) ** 2 + c);
    }
    case 'fibonacci': {
      const out = [int(rng, 1, 5), int(rng, 1, 8)];
      while (out.length < LEN) out.push(out[out.length - 1] + out[out.length - 2]);
      return out;
    }
    case 'interleave': {
      const a = int(rng, 1, 10), d = int(rng, 2, 6), b = int(rng, 20, 40), e = int(rng, 2, 5);
      return Array.from({ length: LEN }, (_, i) => (i % 2 === 0 ? a + d * (i / 2) : b - e * ((i - 1) / 2)));
    }
    case 'growing': {
      // differences grow by one: 3, 4, 6, 9, 13, 18
      const out = [int(rng, 1, 10)];
      let d = int(rng, 1, 4);
      while (out.length < LEN) out.push(out[out.length - 1] + d++);
      return out;
    }
  }
}

export function rulesFor(level: number): Rule[] {
  if (level <= 3) return ['step'];
  if (level <= 7) return ['step', 'down', 'double'];
  if (level <= 12) return ['step', 'down', 'double', 'squares', 'growing'];
  return ['double', 'squares', 'fibonacci', 'interleave', 'growing'];
}

/** Early on the gap is the last term; later it can be anywhere but the first two (which define the rule). */
export function makeSequence(level: number, rng: Rng): Sequence {
  const rule = pick(rng, rulesFor(level));
  const full = build(rule, rng);
  const missing = level <= 4 ? LEN - 1 : int(rng, 2, LEN - 1);
  return { rule, full, missing };
}
