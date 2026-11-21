import { pick, type Rng } from '../../engine/rng';
import { CATEGORIES } from '../_shared/categories';

export interface Prompt {
  category: string;
  word: string;
  belongs: boolean;
}

const NAMES = Object.keys(CATEGORIES);

/** A new category every 6 words; about half the words belong. */
export function makePrompt(rng: Rng, category: string): Prompt {
  const belongs = rng() < 0.5;
  const from = belongs ? category : pick(rng, NAMES.filter((c) => c !== category));
  return { category, word: pick(rng, CATEGORIES[from]), belongs };
}

export const categoryFor = (n: number, rng: Rng, current?: string) =>
  n % 6 === 0 || !current ? pick(rng, NAMES.filter((c) => c !== current)) : current;
