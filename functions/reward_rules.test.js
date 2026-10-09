"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const {claimStreak, streakStatus, istWeekKey, STREAK_REWARDS} =
  require("./reward_rules");
const {istDayKey} = require("./push_policy");

const DAY = 24 * 60 * 60 * 1000;
const t0 = Date.UTC(2026, 9, 9, 6, 0); // Fri 9 Oct 2026, 11:30 IST

test("first claim is day 1", () => {
  const r = claimStreak({}, t0);
  assert.deepEqual(r, {alreadyClaimed: false, streak: 1, amount: 5,
    day: "20261009"});
});

test("consecutive days escalate to day 7", () => {
  let state = {};
  const amounts = [];
  for (let i = 0; i < 7; i++) {
    const r = claimStreak(state, t0 + i * DAY);
    amounts.push(r.amount);
    state = {lastClaimDay: r.day, streak: r.streak};
  }
  assert.deepEqual(amounts, [...STREAK_REWARDS]);
  // Day 8 starts a new week at day 1.
  assert.equal(claimStreak(state, t0 + 7 * DAY).streak, 1);
});

test("second claim the same day is refused", () => {
  const r = claimStreak({lastClaimDay: "20261009", streak: 3}, t0);
  assert.equal(r.alreadyClaimed, true);
  assert.equal(r.amount, 0);
});

test("missing a day resets to day 1", () => {
  const r = claimStreak({lastClaimDay: istDayKey(t0 - 2 * DAY), streak: 4},
      t0);
  assert.equal(r.streak, 1);
});

test("status shows the next reward without claiming", () => {
  assert.deepEqual(
      streakStatus({lastClaimDay: istDayKey(t0 - DAY), streak: 2}, t0),
      {claimedToday: false, streak: 2, nextAmount: 15});
  assert.equal(streakStatus({}, t0).nextAmount, 5);
  assert.equal(
      streakStatus({lastClaimDay: "20261009", streak: 2}, t0).claimedToday,
      true);
});

test("after day 7, tomorrow shows day 1's reward", () => {
  assert.equal(
      streakStatus({lastClaimDay: "20261009", streak: 7}, t0).nextAmount, 5);
});

test("IST week starts Monday", () => {
  assert.equal(istWeekKey(t0), "20261005");
  // Sunday 11 Oct 23:59 IST is still that week; Monday 00:00 IST is next.
  assert.equal(istWeekKey(Date.UTC(2026, 9, 11, 18, 29)), "20261005");
  assert.equal(istWeekKey(Date.UTC(2026, 9, 11, 18, 30)), "20261012");
});

const {DEFAULT_MISSIONS, applyEvent, missionsView, sanitizeMissions} =
  require("./reward_rules");

test("ludo wins count toward the win mission, losses don't", () => {
  let c = applyEvent(DEFAULT_MISSIONS, {}, {game: "ludo", won: false});
  assert.equal(c.win_ludo_2 || 0, 0);
  c = applyEvent(DEFAULT_MISSIONS, c, {game: "ludo", won: true});
  c = applyEvent(DEFAULT_MISSIONS, c, {game: "ludo", won: true});
  c = applyEvent(DEFAULT_MISSIONS, c, {game: "ludo", won: true});
  assert.equal(c.win_ludo_2, 2); // capped at target
});

test("arcade plays: specific game and the any-game mission", () => {
  let c = applyEvent(DEFAULT_MISSIONS, {}, {game: "super_over", won: false});
  assert.equal(c.play_super_over_1, 1);
  assert.equal(c.play_arcade_3, 1);
  c = applyEvent(DEFAULT_MISSIONS, c, {game: "pac_man", won: false});
  assert.equal(c.play_super_over_1, 1);
  assert.equal(c.play_arcade_3, 2);
});

test("view reports progress and claimed flags", () => {
  const v = missionsView(DEFAULT_MISSIONS,
      {counts: {win_ludo_2: 1}, claimed: {play_super_over_1: true}});
  assert.equal(v[0].progress, 1);
  assert.equal(v[1].claimed, true);
});

test("bad config falls back to defaults", () => {
  assert.equal(sanitizeMissions(null).length, 3);
  assert.equal(sanitizeMissions([{id: 1}]).length, 3);
  const one = sanitizeMissions([{id: "x", title: "X", event: "play",
    game: "wordly", target: 2, reward: 5}]);
  assert.deepEqual(one.map((m) => m.id), ["x"]);
});

const {matchEndReward, placement, invitePair} = require("./reward_rules");

test("match-end reward by placement", () => {
  assert.equal(matchEndReward(1), 15);
  assert.equal(matchEndReward(2), 8);
  assert.equal(matchEndReward(4), 5);
  assert.equal(matchEndReward(9), 5);
});

test("placement: winners order, else last", () => {
  assert.equal(placement("blue", ["green", "blue"], 4), 2);
  assert.equal(placement("red", ["green"], 2), 2);
  assert.equal(placement("red", ["green", "blue", "yellow"], 4), 4);
});

test("invite pair only for a friend's first friends-room match", () => {
  const base = {quick: false, hostUid: "h", uid: "f", completedBefore: 0};
  assert.deepEqual(invitePair(base), {inviter: "h", invitee: "f"});
  assert.equal(invitePair({...base, quick: true}), null);
  assert.equal(invitePair({...base, uid: "h"}), null);
  assert.equal(invitePair({...base, completedBefore: 1}), null);
});
