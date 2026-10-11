import type { LevelConfig } from './LevelConfig';
import { generateLevel } from './LevelGenerator';

/** Endless mode opens once this campaign level has been cleared. */
export const ENDLESS_UNLOCK_LEVEL = 5;
/** Survivors that follow the cannon into the next stage, at most. */
export const ENDLESS_MAX_CARRY = 120;
/** Cannon repair between stages. */
export const ENDLESS_HEAL = 25;
/** Ceiling on the endless score that counts towards the career score. */
export const ENDLESS_SCORE_CAP = 200000;

/**
 * Stage `k` (1-based) of an endless run: a generated level, two campaign
 * levels harder each time, so the worlds, bosses and traps keep rotating.
 * The run ends when the cannon is destroyed.
 */
export function endlessStage(stage: number): LevelConfig {
  const k = Math.max(1, Math.floor(stage));
  const level = generateLevel(4 + k * 2);
  return { ...level, name: `Stage ${k}`, reward: { credits: 30 + 10 * k } };
}

export interface EndlessBest {
  score: number;
  stage: number;
}
