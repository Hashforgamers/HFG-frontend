import { int, type Rng } from '../../engine/rng';

export const makeDigits = (length: number, rng: Rng) => Array.from({ length }, () => int(rng, 0, 9)).join('');
/** Long enough to read the digits once, short enough that it's memory. */
export const showMs = (length: number) => 900 + length * 380;
export const START_LENGTH = 3;
