// Exact rational arithmetic, so 8 ÷ 3 stays 8/3 instead of 2.6666….
export interface Q {
  n: number;
  d: number;
}

const gcd = (a: number, b: number): number => (b === 0 ? Math.abs(a) : gcd(b, a % b));

export function q(n: number, d = 1): Q {
  if (d === 0) throw new Error('division by zero');
  const g = gcd(n, d) || 1;
  const s = d < 0 ? -1 : 1;
  return { n: (s * n) / g, d: (s * d) / g };
}

export type Op = '+' | '−' | '×' | '÷';
export const OPS: Op[] = ['+', '−', '×', '÷'];

/** null for division by zero. */
export function apply(a: Q, op: Op, b: Q): Q | null {
  switch (op) {
    case '+': return q(a.n * b.d + b.n * a.d, a.d * b.d);
    case '−': return q(a.n * b.d - b.n * a.d, a.d * b.d);
    case '×': return q(a.n * b.n, a.d * b.d);
    case '÷': return b.n === 0 ? null : q(a.n * b.d, a.d * b.n);
  }
}

export const eq = (a: Q, b: Q) => a.n === b.n && a.d === b.d;
export const isInt = (a: Q) => a.d === 1;
export const show = (a: Q) => (a.d === 1 ? String(a.n) : `${a.n}/${a.d}`);

/** Standard precedence: × and ÷ first, then + and −, left to right. */
export function evaluate(nums: number[], ops: Op[]): Q | null {
  const terms: Q[] = [q(nums[0])];
  const addOps: Op[] = [];
  for (let i = 0; i < ops.length; i++) {
    const next = q(nums[i + 1]);
    if (ops[i] === '×' || ops[i] === '÷') {
      const r = apply(terms[terms.length - 1], ops[i], next);
      if (!r) return null;
      terms[terms.length - 1] = r;
    } else {
      addOps.push(ops[i]);
      terms.push(next);
    }
  }
  return addOps.reduce<Q>((acc, op, i) => apply(acc, op, terms[i + 1])!, terms[0]);
}
