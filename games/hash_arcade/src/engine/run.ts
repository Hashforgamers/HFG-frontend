import { create } from 'zustand';
import { multiplier, type Rng } from './rng';
import { haptic } from './host';
import { sfx } from './sfx';
import type { GameCtx, GameDef, Mode } from './types';

export type Status = 'countdown' | 'playing' | 'paused' | 'over';

export interface SessionState {
  status: Status;
  score: number;
  combo: number;
  maxCombo: number;
  hits: number;
  misses: number;
  lives: number | null;
  stats: Record<string, string | number>;
  /** Bumped on every hit/miss so the HUD can animate. */
  lastGain: { id: number; points: number } | null;
  lastMiss: number;
}

const fresh = (def: GameDef): SessionState => ({
  status: 'countdown',
  score: 0,
  combo: 0,
  maxCombo: 0,
  hits: 0,
  misses: 0,
  lives: def.lives ?? null,
  stats: {},
  lastGain: null,
  lastMiss: 0,
});

/** The run on screen, so the app's back button can pause it (see main.tsx). */
export const activeRun: { current: Run | null } = { current: null };

/** The one live run. Only one game plays at a time, so a single store is enough. */
export const useSession = create<SessionState>(() => ({ ...fresh({} as GameDef), status: 'over' }));

export interface Run {
  ctx: GameCtx;
  /** Seconds left, Infinity for untimed games. */
  timeLeft(): number;
  /** Ends the 3-2-1 countdown; nothing moves before this. */
  begin(): void;
  pause(): void;
  resume(): void;
  dispose(): void;
}

/**
 * One rAF loop drives everything: the countdown, ctx.sleep timers and game
 * frame callbacks. Paused or backgrounded time never counts.
 */
export function createRun(def: GameDef, mode: Mode, rng: Rng, onOver: () => void): Run {
  const set = useSession.setState;
  const get = useSession.getState;
  set(fresh(def), true);

  let playMs = 0;
  let bonus = 0;
  let ended = false;
  let last = performance.now();
  const sleeps: { at: number; resolve: () => void }[] = [];
  const frames = new Set<(t: number) => void>();

  const timeLeft = () => (def.duration == null ? Infinity : def.duration + bonus - playMs / 1000);

  const end = () => {
    if (ended) return;
    ended = true;
    sleeps.length = 0;
    set({ status: 'over' });
    sfx.over();
    haptic('heavy');
    onOver();
  };

  let raf = 0;
  const loop = (now: number) => {
    raf = requestAnimationFrame(loop);
    const dt = Math.min(now - last, 100); // clamp: a hidden tab must not eat the clock
    last = now;
    if (ended || get().status !== 'playing') return;
    playMs += dt;
    for (let i = sleeps.length - 1; i >= 0; i--) {
      if (sleeps[i].at <= playMs) sleeps.splice(i, 1)[0].resolve();
    }
    frames.forEach((f) => f(playMs));
    if (timeLeft() <= 0) end();
  };
  raf = requestAnimationFrame(loop);

  const ctx: GameCtx = {
    rng,
    mode,
    hit(points = 100, seconds = 0) {
      if (ended) return 0;
      const s = get();
      const combo = s.combo + 1;
      const mult = def.combo ? multiplier(combo) : 1;
      const gained = Math.round(points * mult);
      bonus += seconds;
      set({
        score: s.score + gained,
        combo,
        maxCombo: Math.max(s.maxCombo, combo),
        hits: s.hits + 1,
        lastGain: { id: s.hits + 1, points: gained },
      });
      sfx.correct(mult);
      haptic('light');
      return gained;
    },
    miss({ seconds = 0, life = false } = {}) {
      if (ended) return;
      const s = get();
      bonus -= seconds;
      const lives = life && s.lives != null ? s.lives - 1 : s.lives;
      set({ combo: 0, misses: s.misses + 1, lives, lastMiss: s.lastMiss + 1 });
      sfx.wrong();
      haptic('heavy');
      if (lives === 0) end();
    },
    finish: end,
    sleep: (ms) =>
      new Promise<void>((resolve) => {
        if (!ended) sleeps.push({ at: playMs + ms, resolve });
      }),
    now: () => playMs,
    onFrame(cb) {
      frames.add(cb);
      return () => frames.delete(cb);
    },
    stat(label, value) {
      set((s) => ({ stats: { ...s.stats, [label]: value } }));
    },
  };

  const run: Run = {
    ctx,
    timeLeft,
    begin: () => {
      if (get().status !== 'countdown') return;
      last = performance.now();
      set({ status: 'playing' });
    },
    pause: () => get().status === 'playing' && set({ status: 'paused' }),
    resume: () => {
      if (get().status !== 'paused') return;
      last = performance.now();
      set({ status: 'playing' });
    },
    dispose: () => {
      cancelAnimationFrame(raf);
      ended = true;
      sleeps.length = 0;
      frames.clear();
      if (activeRun.current === run) activeRun.current = null;
    },
  };
  activeRun.current = run;
  return run;
}
