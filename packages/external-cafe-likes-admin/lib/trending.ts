import { FieldValue, Timestamp } from "firebase-admin/firestore";
import { writeTrendCopy } from "@/lib/ai";
import { getAdminDb } from "@/lib/firebase-admin";
import { createCampaign } from "@/lib/push";
import {
  bookingsToday,
  isQuietHourIst,
  istDay,
  rankCafeTrends,
  TREND_RULES,
  type CafeTrend,
  type FunnelEvent,
} from "@/lib/trend-math";

const STATE = () => getAdminDb().collection("push_automation").doc("trending");
const DAY = 24 * 60 * 60 * 1000;

export type TrendingState = {
  enabled: boolean;
  lastRunAt: string | null;
  lastOutcome: string;
  lastSentDay: string;
  lastCampaignId: string;
};

export type RunResult =
  | { outcome: "sent"; campaignId: string; trend: CafeTrend; title: string; body: string }
  | { outcome: "preview"; trend: CafeTrend; title: string; body: string; copySource: "ai" | "template" }
  | { outcome: "skipped"; reason: string; candidates?: CafeTrend[] };

export async function getTrendingState(): Promise<TrendingState> {
  const d = (await STATE().get()).data() ?? {};
  return {
    enabled: d.enabled === true,
    lastRunAt: d.last_run_at instanceof Timestamp ? d.last_run_at.toDate().toISOString() : null,
    lastOutcome: d.last_outcome ?? "",
    lastSentDay: d.last_sent_day ?? "",
    lastCampaignId: d.last_campaign_id ?? "",
  };
}

export async function setTrendingEnabled(enabled: boolean, by: string) {
  await STATE().set({ enabled, updated_by: by, updated_at: FieldValue.serverTimestamp() }, { merge: true });
}

/**
 * Finds today's most trending cafe and broadcasts it to all users.
 * `preview` runs the same detection and copy but never sends or claims the day.
 */
export async function runTrending({ preview = false } = {}): Promise<RunResult> {
  const now = Date.now();
  const day = istDay(now);
  const state = (await STATE().get()).data() ?? {};

  if (!preview) {
    // Cheap checks first, so a paused or already-done day costs one read.
    const early =
      state.enabled !== true ? "Autopilot is off." :
      isQuietHourIst(now) ? "Quiet hours (22:00-09:00 IST)." :
      state.last_sent_day === day ? "Already sent today's trending push." :
      null;
    if (early) return record({ outcome: "skipped", reason: early });
  }

  const recent: Record<string, number> = state.recent_cafes ?? {};
  const skip = new Set(Object.keys(recent).filter((id) => now - recent[id] < TREND_RULES.repeatDays * DAY));
  const events = await loadEvents(now);
  const trends = rankCafeTrends(events, now, skip);
  if (trends.length === 0) {
    return preview
      ? { outcome: "skipped", reason: "No cafe is trending right now." }
      : record({ outcome: "skipped", reason: "No cafe is trending right now." });
  }

  const trend = trends[0];
  const facts = { cafeName: trend.cafeName, viewersToday: trend.viewersToday, bookingsToday: bookingsToday(events, now) };
  let copySource: "ai" | "template" = "ai";
  let copy: { title: string; body: string };
  try {
    copy = await writeTrendCopy(facts);
    if (copy.title.length > 65 || copy.body.length > 240) throw new Error("AI copy too long");
  } catch {
    copySource = "template";
    copy = {
      title: `${trend.cafeName} is trending 🔥`,
      body: `${trend.viewersToday} players checked it out today. Grab a slot before it fills up.`,
    };
  }
  if (preview) return { outcome: "preview", trend, ...copy, copySource };

  // Claim the day before sending so overlapping cron calls can't both send.
  const claimed = await getAdminDb().runTransaction(async (tx) => {
    const fresh = (await tx.get(STATE())).data() ?? {};
    if (fresh.enabled !== true || fresh.last_sent_day === day) return false;
    tx.set(STATE(), { last_sent_day: day }, { merge: true });
    return true;
  });
  if (!claimed) return record({ outcome: "skipped", reason: "Another run already sent today's push." });

  try {
    const sent = await createCampaign(
      {
        name: `Auto · Trending · ${trend.cafeName}`,
        title: copy.title,
        body: copy.body,
        channel: "offer_channel",
        audience: { kind: "all" },
      },
      "autopilot:trending",
    );
    await STATE().set(
      { last_campaign_id: sent.id, recent_cafes: { ...pruned(recent, now), [trend.cafeId]: now } },
      { merge: true },
    );
    return record({ outcome: "sent", campaignId: sent.id, trend, ...copy });
  } catch (error) {
    // Free the day again so the next run can retry.
    await STATE().set({ last_sent_day: "" }, { merge: true });
    throw error;
  }
}

// shortcut: reads every funnel event from the last 7 days (one query on
// occurredAtMs, no composite index). Fine at one run a day; add an
// eventType+occurredAtMs index and filter on cafe_viewed if volume grows.
async function loadEvents(now: number): Promise<FunnelEvent[]> {
  const snap = await getAdminDb()
    .collection("notification_funnel_events")
    .where("occurredAtMs", ">=", now - 7 * DAY)
    .select("eventType", "firebaseUid", "occurredAtMs", "payload.cafe_id", "payload.cafe_name")
    .get();
  return snap.docs.map((doc) => {
    const d = doc.data();
    return {
      eventType: String(d.eventType ?? ""),
      firebaseUid: String(d.firebaseUid ?? ""),
      occurredAtMs: Number(d.occurredAtMs ?? 0),
      cafeId: d.payload?.cafe_id ? String(d.payload.cafe_id) : undefined,
      cafeName: d.payload?.cafe_name ? String(d.payload.cafe_name) : undefined,
    };
  });
}

function pruned(recent: Record<string, number>, now: number) {
  return Object.fromEntries(Object.entries(recent).filter(([, ms]) => now - ms < TREND_RULES.repeatDays * DAY));
}

async function record(result: RunResult): Promise<RunResult> {
  const text =
    result.outcome === "sent" ? `Sent "${result.title}" (${result.trend.cafeName})` :
    result.outcome === "skipped" ? `Skipped: ${result.reason}` : "";
  await STATE().set({ last_run_at: FieldValue.serverTimestamp(), last_outcome: text }, { merge: true });
  return result;
}
