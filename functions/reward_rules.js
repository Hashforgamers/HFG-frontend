"use strict";

/**
 * Pure reward rules (no Firebase), unit-tested in reward_rules.test.js.
 * Days and weeks are on the Indian calendar (IST).
 */

const {istDayKey} = require("./push_policy");

const DAY_MS = 24 * 60 * 60 * 1000;
const IST_OFFSET_MS = 330 * 60 * 1000;

/** Hash coins for streak days 1..7; day 7+ keeps paying the last value. */
const STREAK_REWARDS = Object.freeze([5, 10, 15, 20, 25, 30, 50]);

function previousDayKey(nowMs) {
  return istDayKey(nowMs - DAY_MS);
}

/**
 * Claiming today's streak reward.
 * @param {{lastClaimDay?: string, streak?: number}} state
 * @return {{alreadyClaimed: boolean, streak: number, amount: number,
 *   day: string}}
 */
function claimStreak(state, nowMs) {
  const today = istDayKey(nowMs);
  const last = state.lastClaimDay || "";
  const current = Number(state.streak) || 0;
  if (last === today) {
    return {alreadyClaimed: true, streak: current, amount: 0, day: today};
  }
  // Missing a day resets to day 1; a full week cycles back to day 1 too.
  const continues = last === previousDayKey(nowMs) && current < 7;
  const streak = continues ? current + 1 : 1;
  return {
    alreadyClaimed: false,
    streak,
    amount: STREAK_REWARDS[streak - 1],
    day: today,
  };
}

/** What the streak UI should show without claiming. */
function streakStatus(state, nowMs) {
  const today = istDayKey(nowMs);
  const last = state.lastClaimDay || "";
  const current = Number(state.streak) || 0;
  if (last === today) {
    const tomorrow = current < 7 ? current + 1 : 1;
    return {claimedToday: true, streak: current,
      nextAmount: STREAK_REWARDS[tomorrow - 1]};
  }
  const alive = last === previousDayKey(nowMs) && current < 7;
  const next = alive ? current + 1 : 1;
  return {claimedToday: false, streak: alive ? current : 0,
    nextAmount: STREAK_REWARDS[next - 1]};
}

/** Monday-based week key in IST, e.g. "2026-W41" style "20261005". */
function istWeekKey(nowMs) {
  const d = new Date(nowMs + IST_OFFSET_MS);
  const dow = (d.getUTCDay() + 6) % 7; // Monday = 0
  const monday = Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate()) -
      dow * DAY_MS;
  return istDayKey(monday - IST_OFFSET_MS);
}

/**
 * Default daily missions; overridden by Firestore config/daily_missions
 * ({missions: [...]}) when present. event "play" counts any finished game
 * of `game` ("*" = any arcade game), "win" only wins.
 */
const DEFAULT_MISSIONS = Object.freeze([
  {id: "win_ludo_2", title: "Win 2 Ludo matches", event: "win",
    game: "ludo", target: 2, reward: 20},
  {id: "play_super_over_1", title: "Play 1 Super Over", event: "play",
    game: "super_over", target: 1, reward: 10},
  {id: "play_arcade_3", title: "Play 3 games", event: "play",
    game: "*", target: 3, reward: 15},
]);

/** Keeps only well-formed missions from config. */
function sanitizeMissions(raw) {
  if (!Array.isArray(raw)) return [...DEFAULT_MISSIONS];
  const ok = raw.filter((m) => m && typeof m.id === "string" &&
      (m.event === "play" || m.event === "win") &&
      typeof m.game === "string" &&
      Number(m.target) > 0 && Number(m.reward) > 0)
      .map((m) => ({id: m.id, title: String(m.title || m.id),
        event: m.event, game: m.game,
        target: Math.round(Number(m.target)),
        reward: Math.round(Number(m.reward))}));
  return ok.length ? ok : [...DEFAULT_MISSIONS];
}

/** @param {{game: string, won: boolean}} ev */
function matchesMission(m, ev) {
  if (m.event === "win" && !ev.won) return false;
  return m.game === "*" || m.game === ev.game;
}

/** New counts after one finished game; never above a mission's target. */
function applyEvent(missions, counts, ev) {
  const next = {...(counts || {})};
  for (const m of missions) {
    if (!matchesMission(m, ev)) continue;
    next[m.id] = Math.min(m.target, (Number(next[m.id]) || 0) + 1);
  }
  return next;
}

function missionsView(missions, progress) {
  const counts = (progress && progress.counts) || {};
  const claimed = (progress && progress.claimed) || {};
  return missions.map((m) => ({
    ...m,
    progress: Math.min(m.target, Number(counts[m.id]) || 0),
    claimed: claimed[m.id] === true,
  }));
}

module.exports = {
  DEFAULT_MISSIONS,
  sanitizeMissions,
  matchesMission,
  applyEvent,
  missionsView,
  STREAK_REWARDS,
  claimStreak,
  streakStatus,
  istWeekKey,
  previousDayKey,
};
