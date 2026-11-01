"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const {
  DEFAULT_POLICY, istDayKey, skipReason, clampInt, isQuietHour, quietEndMs,
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
  assert.equal(skipReason({...base, sentToday: 0}), null);
  assert.equal(skipReason({...base, sentToday: 1}), "daily_cap");
});

test("quiet hours are 22:00-09:00 IST", () => {
  const ist = (h, m = 0) => Date.UTC(2026, 9, 9, h, m) - 330 * min;
  assert.equal(isQuietHour(ist(21, 59), DEFAULT_POLICY), false);
  assert.equal(isQuietHour(ist(22), DEFAULT_POLICY), true);
  assert.equal(isQuietHour(ist(3), DEFAULT_POLICY), true);
  assert.equal(isQuietHour(ist(9), DEFAULT_POLICY), false);
  assert.equal(skipReason({sentToday: 0, nowMs: ist(23),
    policy: DEFAULT_POLICY}), "quiet_hours");
  // 23:00 defers to 09:00 the next day; 03:00 to 09:00 the same day.
  assert.equal(quietEndMs(ist(23), DEFAULT_POLICY), ist(9) + 24 * 60 * min);
  assert.equal(quietEndMs(ist(3), DEFAULT_POLICY), ist(9));
});

test("clampInt falls back on junk and clamps range", () => {
  assert.equal(clampInt("abc", 3, 1, 20), 3);
  assert.equal(clampInt(0, 3, 1, 20), 3);
  assert.equal(clampInt(99, 3, 1, 20), 20);
  assert.equal(clampInt(5, 3, 1, 20), 5);
});
