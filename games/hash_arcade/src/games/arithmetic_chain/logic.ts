import { int, type Rng } from '../../engine/rng';

export interface Chain {
  start: number;
  steps: string[];
  answer: number;
}

export const stepsFor = (level: number) => Math.min(9, 3 + Math.floor(level / 2));
export const stepMs = (level: number) => Math.max(650, 1500 - level * 60);

/** Each step keeps the running total a whole number from 0 to 300. */
export function makeChain(level: number, rng: Rng): Chain {
  const start = int(rng, 2, 20);
  let t = start;
  const steps: string[] = [];
  for (let i = 0; i < stepsFor(level); i++) {
    const r = rng();
    const divs = [2, 3, 4, 5].filter((d) => t % d === 0 && t > 0);
    if (level > 4 && r < 0.2 && t <= 40) {
      const v = int(rng, 2, 4);
      t *= v;
      steps.push(`× ${v}`);
    } else if (level > 6 && r < 0.35 && divs.length) {
      const v = divs[int(rng, 0, divs.length - 1)];
      t /= v;
      steps.push(`÷ ${v}`);
    } else if (r < 0.65 && t > 3) {
      const v = int(rng, 1, Math.min(20, t));
      t -= v;
      steps.push(`− ${v}`);
    } else {
      const v = int(rng, 1, 20);
      t += v;
      steps.push(`+ ${v}`);
    }
    if (t > 300) {
      steps.pop();
      t = steps.reduce((acc, s) => runStep(acc, s), start);
    }
  }
  return { start, steps, answer: t };
}

export function runStep(t: number, s: string): number {
  const v = Number(s.slice(2));
  switch (s[0]) {
    case '+': return t + v;
    case '−': return t - v;
    case '×': return t * v;
    default: return t / v;
  }
}
