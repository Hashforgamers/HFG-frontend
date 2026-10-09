"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const {
  DEFAULT_POLICY, istDayKey, skipReason, clampInt,
} = require("./push_policy");

const now = Date.UTC(2026, 9, 9, 12, 0, 0); // 17:30 IST
const min = 60 * 1000;

test("IST day rolls over at 18:30 UTC", () => {
  assert.equal(istDayKey(Date.UTC(2026, 9, 9, 18, 29)), "20261009");
  assert.equal(istDayKey(Date.UTC(2026, 9, 9, 18, 30)), "20261010");
});

test("skips users online now or seen within 2h", () => {
  const base = {sentToday: 0, nowMs: now, policy: DEFAULT_POLICY};
  assert.equal(skipReason({...base, isOnline: true}), "recently_active");
  assert.equal(
      skipReason({...base, lastSeenMs: now - 119 * min}), "recently_active");
  assert.equal(skipReason({...base, lastSeenMs: now - 121 * min}), null);
  assert.equal(skipReason({...base}), null);
});

test("a stale is_online flag does not block pushes", () => {
  assert.equal(skipReason({isOnline: true, lastSeenMs: now - 10 * 60 * min,
    sentToday: 0, nowMs: now, policy: DEFAULT_POLICY}), null);
});

test("caps at N per day", () => {
  const base = {nowMs: now, lastSeenMs: now - 5 * 60 * min,
    policy: DEFAULT_POLICY};
  assert.equal(skipReason({...base, sentToday: 2}), null);
  assert.equal(skipReason({...base, sentToday: 3}), "daily_cap");
});

test("clampInt falls back on junk and clamps range", () => {
  assert.equal(clampInt("abc", 3, 1, 20), 3);
  assert.equal(clampInt(0, 3, 1, 20), 3);
  assert.equal(clampInt(99, 3, 1, 20), 20);
  assert.equal(clampInt(5, 3, 1, 20), 5);
});
