// Pure trend detection over app funnel events (notification_funnel_events).
// No Firebase imports, so lib/trend-math.check.ts can run it directly.

export type FunnelEvent = {
  eventType: string;
  firebaseUid: string;
  occurredAtMs: number;
  cafeId?: string;
  cafeName?: string;
};

export type CafeTrend = {
  cafeId: string;
  cafeName: string;
  /** Distinct users who opened the cafe page in the last 24h. */
  viewersToday: number;
  /** Average distinct viewers per day over the previous 6 days. */
  dailyAverage: number;
  /** viewersToday / max(dailyAverage, 1). */
  lift: number;
};

export const TREND_RULES = {
  /** A cafe needs at least this many distinct viewers today to count. */
  minViewers: 4,
  /** ...and at least this multiple of its own recent daily average. */
  minLift: 1.5,
  /** Don't promote the same cafe again within this many days. */
  repeatDays: 7,
} as const;

const DAY = 24 * 60 * 60 * 1000;

/**
 * Cafes whose distinct viewers in the last 24h beat their own previous-6-day
 * daily average, best first. Counting distinct users (and distinct user-days
 * for the baseline) stops one person refreshing a page from making a trend.
 */
export function rankCafeTrends(
  events: FunnelEvent[],
  nowMs: number,
  skipCafeIds: Set<string> = new Set(),
): CafeTrend[] {
  const today = new Map<string, Set<string>>();
  const before = new Map<string, Set<string>>();
  const names = new Map<string, string>();
  for (const e of events) {
    if (e.eventType !== "cafe_viewed" || !e.cafeId || !e.firebaseUid) continue;
    const age = nowMs - e.occurredAtMs;
    if (age < 0 || age >= 7 * DAY) continue;
    if (e.cafeName) names.set(e.cafeId, e.cafeName);
    if (age < DAY) {
      add(today, e.cafeId, e.firebaseUid);
    } else {
      add(before, e.cafeId, `${e.firebaseUid}:${Math.floor(age / DAY)}`);
    }
  }
  const trends: CafeTrend[] = [];
  for (const [cafeId, viewers] of today) {
    const name = names.get(cafeId);
    if (!name || skipCafeIds.has(cafeId)) continue;
    const dailyAverage = (before.get(cafeId)?.size ?? 0) / 6;
    const lift = viewers.size / Math.max(dailyAverage, 1);
    if (viewers.size < TREND_RULES.minViewers || lift < TREND_RULES.minLift) continue;
    trends.push({ cafeId, cafeName: name, viewersToday: viewers.size, dailyAverage, lift });
  }
  return trends.sort((a, b) => b.lift - a.lift || b.viewersToday - a.viewersToday);
}

/** Bookings confirmed in the last 24h, across all cafes. */
export function bookingsToday(events: FunnelEvent[], nowMs: number) {
  return events.filter((e) => e.eventType === "booking_confirmed" && nowMs - e.occurredAtMs < DAY).length;
}

const IST_OFFSET = 330 * 60 * 1000;

/** India calendar day, e.g. "2026-11-02". */
export function istDay(nowMs: number) {
  return new Date(nowMs + IST_OFFSET).toISOString().slice(0, 10);
}

/** Same window as functions/push_policy.js: no pushes 22:00-09:00 IST. */
export function isQuietHourIst(nowMs: number) {
  const h = new Date(nowMs + IST_OFFSET).getUTCHours();
  return h >= 22 || h < 9;
}

function add(map: Map<string, Set<string>>, key: string, value: string) {
  let set = map.get(key);
  if (!set) map.set(key, (set = new Set()));
  set.add(value);
}
