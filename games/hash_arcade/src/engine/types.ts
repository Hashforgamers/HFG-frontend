import type { ComponentType } from 'react';
import type { Rng } from './rng';

export type Mode = 'solo' | 'daily';

export type Category = 'observation' | 'math' | 'memory' | 'reflex' | 'logic' | 'words';

/** What a running game can do. The shell owns the clock, score, combo and lives. */
export interface GameCtx {
  rng: Rng;
  mode: Mode;
  /** Correct move: adds `points` (× combo if the game uses combos) and optional seconds. Returns points given. */
  hit(points?: number, seconds?: number): number;
  /** Wrong move: breaks the combo, takes seconds and/or a life. */
  miss(opts?: { seconds?: number; life?: boolean }): void;
  /** End the run now (games without a clock end themselves). */
  finish(): void;
  /** Resolves after `ms` of unpaused play. Never resolves once the run is over. */
  sleep(ms: number): Promise<void>;
  /** Unpaused play time in ms. */
  now(): number;
  /** Called every animation frame while playing; returns an unsubscribe. */
  onFrame(cb: (playMs: number) => void): () => void;
  /** Game-specific number shown on the results card, e.g. average reaction ms. */
  stat(label: string, value: string | number): void;
}

export interface GameProps {
  ctx: GameCtx;
}

export interface GameDef {
  id: string;
  name: string;
  category: Category;
  blurb: string;
  howTo: string[];
  /** Big character on the thumbnail. */
  glyph: string;
  /** Thumbnail accent colour. */
  accent: string;
  /** Run length in seconds; omit for games that end on lives or rounds. */
  duration?: number;
  lives?: number;
  combo?: boolean;
  /** A strong score. Normalises this game's scores to 0–1000 for XP and the arcade leaderboard. */
  par: number;
  /** Missing until the game is built; the home screen shows it as coming soon. */
  load?: () => Promise<{ default: ComponentType<GameProps> }>;
}
