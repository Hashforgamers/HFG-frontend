import { create } from 'zustand';
import { createJSONStorage, persist } from 'zustand/middleware';
import { todayKey } from './rng';
import type { GameDef, Mode } from './types';

/** 0–1000: how good a score is for its game, so different games compare fairly. */
export const normalize = (score: number, par: number) => Math.round(Math.min(1, Math.max(0, score / par)) * 1000);

export const xpForRun = (score: number, par: number) => 10 + Math.round(normalize(score, par) / 25);
export const levelFor = (xp: number) => Math.floor(Math.sqrt(xp / 40)) + 1;
export const xpForLevel = (level: number) => 40 * (level - 1) ** 2;

/** Sum of normalised bests: the one number the app's arcade leaderboard ranks. */
export const careerScore = (normBests: Record<string, number>) =>
  Object.values(normBests).reduce((a, b) => a + b, 0);

export function nextStreak(streak: { count: number; last: string | null }, today: string) {
  if (streak.last === today) return streak;
  const y = new Date(`${today}T12:00:00`);
  y.setDate(y.getDate() - 1);
  return { count: streak.last === todayKey(y) ? streak.count + 1 : 1, last: today };
}

export interface RunRecord {
  prevBest: number;
  xpGained: number;
  levelUp: boolean;
  career: number;
}

interface Profile {
  xp: number;
  plays: number;
  bests: Record<string, number>;
  /** Normalised best per game, feeds the career score. */
  normBests: Record<string, number>;
  /** date → game → best, for the daily challenge. Pruned to the last 14 days. */
  daily: Record<string, Record<string, number>>;
  streak: { count: number; last: string | null };
  record(def: GameDef, mode: Mode, score: number): RunRecord;
}

export const useProfile = create<Profile>()(
  persist(
    (set, get) => ({
      xp: 0,
      plays: 0,
      bests: {},
      normBests: {},
      daily: {},
      streak: { count: 0, last: null },
      record(def, mode, score) {
        const s = get();
        const today = todayKey();
        const prevBest = mode === 'daily' ? (s.daily[today]?.[def.id] ?? 0) : (s.bests[def.id] ?? 0);
        const xpGained = xpForRun(score, def.par);
        const xp = s.xp + xpGained;
        // daily runs count toward the all-time best too
        const bests = { ...s.bests, [def.id]: Math.max(s.bests[def.id] ?? 0, score) };
        const normBests = { ...s.normBests, [def.id]: normalize(bests[def.id], def.par) };
        let daily = s.daily;
        let streak = s.streak;
        if (mode === 'daily') {
          const keep = Object.keys(daily).sort().slice(-13);
          daily = Object.fromEntries(keep.map((k) => [k, daily[k]]));
          daily[today] = { ...daily[today], [def.id]: Math.max(prevBest, score) };
          streak = nextStreak(streak, today);
        }
        set({ xp, plays: s.plays + 1, bests, normBests, daily, streak });
        return { prevBest, xpGained, levelUp: levelFor(xp) > levelFor(s.xp), career: careerScore(normBests) };
      },
    }),
    {
      name: 'hash-arcade-profile',
      // private mode / blocked storage: play on without saving
      storage: createJSONStorage(() => {
        try {
          localStorage.setItem('__t', '1');
          localStorage.removeItem('__t');
          return localStorage;
        } catch {
          const mem = new Map<string, string>();
          return { getItem: (k) => mem.get(k) ?? null, setItem: (k, v) => void mem.set(k, v), removeItem: (k) => void mem.delete(k) };
        }
      }),
      partialize: ({ record: _record, ...data }) => data,
    },
  ),
);
