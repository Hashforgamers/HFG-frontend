import { int, pick, sample, type Rng } from '../../engine/rng';

// Families of similar symbols: the target hides among its relatives.
const FAMILIES = [
  ['◐', '◑', '◒', '◓'],
  ['▲', '▼', '◀', '▶'],
  ['☆', '★', '✩', '✪'],
  ['↖', '↗', '↘', '↙'],
  ['⊕', '⊗', '⊖', '⊘'],
  ['♤', '♠', '♧', '♣'],
] as const;

export interface SymbolHunt {
  size: number;
  target: string;
  cells: string[];
  targets: number[];
}

export const sizeFor = (level: number) => Math.min(7, 4 + Math.floor((level - 1) / 3));

export function makeSymbolHunt(level: number, rng: Rng): SymbolHunt {
  const size = sizeFor(level);
  const family = pick(rng, FAMILIES);
  const target = pick(rng, family);
  const others = family.filter((s) => s !== target);
  const count = Math.min(6, 2 + Math.floor(level / 3));
  const targets = sample(rng, size * size, count);
  const cells = Array.from({ length: size * size }, (_, i) => (targets.includes(i) ? target : others[int(rng, 0, others.length - 1)]));
  return { size, target, cells, targets };
}
