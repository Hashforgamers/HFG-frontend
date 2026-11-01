// Self-check: node --experimental-strip-types lib/trend-math.check.ts
import assert from "node:assert/strict";
import { bookingsToday, isQuietHourIst, istDay, rankCafeTrends, type FunnelEvent } from "./trend-math.ts";

const DAY = 24 * 60 * 60 * 1000;
const now = Date.UTC(2026, 10, 2, 12, 0); // 17:30 IST
const view = (cafeId: string, uid: string, daysAgo: number): FunnelEvent => ({
  eventType: "cafe_viewed",
  firebaseUid: uid,
  occurredAtMs: now - daysAgo * DAY - 60_000,
  cafeId,
  cafeName: `Cafe ${cafeId}`,
});

// A: 6 viewers today, ~1/day before -> trending.
// B: 6 viewers today but 6/day every day -> steady, not trending.
// C: one user refreshing 20 times today -> 1 viewer, not trending.
const events: FunnelEvent[] = [
  ...["u1", "u2", "u3", "u4", "u5", "u6"].map((u) => view("A", u, 0)),
  ...[1, 2, 3, 4, 5, 6].map((d) => view("A", "old", d)),
  ...[0, 1, 2, 3, 4, 5, 6].flatMap((d) => ["v1", "v2", "v3", "v4", "v5", "v6"].map((u) => view("B", u, d))),
  ...Array.from({ length: 20 }, () => view("C", "spammer", 0)),
  { eventType: "booking_confirmed", firebaseUid: "u1", occurredAtMs: now - 3_600_000 },
  { eventType: "booking_confirmed", firebaseUid: "u2", occurredAtMs: now - 2 * DAY },
];

const trends = rankCafeTrends(events, now);
assert.deepEqual(trends.map((t) => t.cafeId), ["A"]);
assert.equal(trends[0].viewersToday, 6);
assert.equal(trends[0].dailyAverage, 1);
assert.equal(trends[0].lift, 6);

// Recently promoted cafes are skipped.
assert.deepEqual(rankCafeTrends(events, now, new Set(["A"])), []);
// Events older than 7 days or in the future are ignored.
assert.deepEqual(rankCafeTrends([view("A", "x", 8), { ...view("A", "y", 0), occurredAtMs: now + DAY }], now), []);

assert.equal(bookingsToday(events, now), 1);
assert.equal(istDay(Date.UTC(2026, 10, 1, 18, 29)), "2026-11-01");
assert.equal(istDay(Date.UTC(2026, 10, 1, 18, 30)), "2026-11-02");
assert.equal(isQuietHourIst(Date.UTC(2026, 10, 2, 16, 29)), false); // 21:59 IST
assert.equal(isQuietHourIst(Date.UTC(2026, 10, 2, 16, 30)), true); // 22:00 IST
assert.equal(isQuietHourIst(Date.UTC(2026, 10, 2, 3, 30)), false); // 09:00 IST

console.log("trend-math ok");
