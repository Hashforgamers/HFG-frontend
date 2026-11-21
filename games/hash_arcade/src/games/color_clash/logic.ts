import { pick, shuffle, type Rng } from '../../engine/rng';

export const COLORS = [
  { name: 'RED', hex: '#ff3b5c' },
  { name: 'GREEN', hex: '#39ff88' },
  { name: 'BLUE', hex: '#2ec5ff' },
  { name: 'YELLOW', hex: '#ffd23f' },
  { name: 'PURPLE', hex: '#b26bff' },
  { name: 'ORANGE', hex: '#ff8a2a' },
] as const;

export type ColorName = (typeof COLORS)[number]['name'];
export const hexOf = (name: ColorName) => COLORS.find((c) => c.name === name)!.hex;

export interface ClashRound {
  word: ColorName;
  ink: ColorName;
  options: ColorName[];
}

/** Early rounds are sometimes congruent; from level 4 the word never matches its ink. */
export function makeRound(level: number, rng: Rng): ClashRound {
  const names = COLORS.map((c) => c.name);
  const count = level < 6 ? 3 : level < 14 ? 4 : 6;
  const word = pick(rng, names);
  const congruent = level < 4 && rng() < 0.3;
  const ink = congruent ? word : pick(rng, names.filter((n) => n !== word));
  // the word's own colour is always a choice: that's the trap
  const rest = shuffle(rng, names.filter((n) => n !== ink && n !== word));
  const options = shuffle(rng, [...new Set([ink, word])].concat(rest).slice(0, count));
  return { word, ink, options };
}
