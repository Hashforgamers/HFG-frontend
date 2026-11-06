import { int, pick, type Rng } from '../../engine/rng';
import { makePuzzle } from '../../../../odd_one_out/src/game';
import { makeHunt } from '../find_number/logic';

export type Task =
  | { kind: 'odd-colour'; size: number; base: string; odd: string; at: number }
  | { kind: 'odd-char'; size: number; base: string; odd: string; at: number }
  | { kind: 'number'; size: number; target: number; cells: number[] };

/** A hue shift that shrinks with level: obvious early, subtle later. */
export function oddColour(level: number, rng: Rng): Task {
  const size = Math.min(7, 3 + Math.floor(level / 3));
  const h = int(rng, 0, 359);
  const delta = Math.max(6, 40 - level * 2.5) * (rng() < 0.5 ? -1 : 1);
  return { kind: 'odd-colour', size, base: `hsl(${h} 75% 58%)`, odd: `hsl(${h + delta} 75% 58%)`, at: int(rng, 0, size * size - 1) };
}

/** Tasks rotate so no two in a row are the same kind. */
export function makeTask(level: number, rng: Rng, last?: Task['kind']): Task {
  const kind = pick(rng, (['odd-colour', 'odd-char', 'number'] as const).filter((k) => k !== last));
  if (kind === 'odd-colour') return oddColour(level, rng);
  if (kind === 'odd-char') {
    const p = makePuzzle(Math.min(level, 20), rng, 6, 6);
    return { kind, size: 6, base: p.base, odd: p.odd, at: Math.floor(rng() * 36) };
  }
  const h = makeHunt(Math.min(level, 12), rng);
  return { kind, size: h.size, target: h.target, cells: h.cells };
}

export const isAnswer = (t: Task, i: number) => (t.kind === 'number' ? t.cells[i] === t.target : i === t.at);
