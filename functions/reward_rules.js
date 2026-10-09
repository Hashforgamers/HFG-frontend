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

module.exports = {
  STREAK_REWARDS,
  claimStreak,
  streakStatus,
  istWeekKey,
  previousDayKey,
};
