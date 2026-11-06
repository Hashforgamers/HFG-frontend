import { int, type Rng } from '../../engine/rng';

export interface Anzan {
  numbers: number[];
  ms: number;
}

/** More numbers, more digits and faster flashes as levels climb. */
export function makeAnzan(level: number, rng: Rng): Anzan {
  const count = Math.min(12, 3 + Math.floor(level / 2));
  const digits = level <= 4 ? 1 : level <= 10 ? 2 : 3;
  const lo = digits === 1 ? 1 : 10 ** (digits - 1);
  const numbers: number[] = [];
  while (numbers.length < count) {
    const v = int(rng, lo, 10 ** digits - 1);
    if (v !== numbers[numbers.length - 1]) numbers.push(v); // a repeat would look like one long flash
  }
  return { numbers, ms: Math.max(380, 1100 - level * 45) };
}
