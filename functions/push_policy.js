"use strict";

/**
 * Push frequency policy: pure helpers (unit-tested in push_policy.test.js)
 * plus a cached loader for the server-side Remote Config values.
 */

const DEFAULT_POLICY = Object.freeze({
  maxPerUserPerDay: 3,
  skipActiveMinutes: 120,
  socialProofMinMinutes: 360,
});

const IST_OFFSET_MS = 330 * 60 * 1000;

/** Calendar day in India (the app's market), e.g. "20261009". */
function istDayKey(nowMs) {
  const d = new Date(nowMs + IST_OFFSET_MS);
  const mm = String(d.getUTCMonth() + 1).padStart(2, "0");
  const dd = String(d.getUTCDate()).padStart(2, "0");
  return `${d.getUTCFullYear()}${mm}${dd}`;
}

/**
 * True when the user was in the app within the window. last_seen_at is kept
 * fresh by the app's presence heartbeat; is_online alone can be stale after
 * a killed app, so it only counts when there is no timestamp.
 */
function isRecentlyActive({isOnline, lastSeenMs, nowMs, skipActiveMinutes}) {
  if (!lastSeenMs) return isOnline === true;
  return nowMs - lastSeenMs < skipActiveMinutes * 60 * 1000;
}

/**
 * Why an engagement push to this user should be skipped, or null to send.
 * @return {null|"recently_active"|"daily_cap"}
 */
function skipReason({isOnline, lastSeenMs, sentToday, nowMs, policy}) {
  if (isRecentlyActive({
    isOnline,
    lastSeenMs,
    nowMs,
    skipActiveMinutes: policy.skipActiveMinutes,
  })) {
    return "recently_active";
  }
  if (sentToday >= policy.maxPerUserPerDay) return "daily_cap";
  return null;
}

function clampInt(value, fallback, min, max) {
  const n = Number(value);
  if (!Number.isFinite(n) || n <= 0) return fallback;
  return Math.min(max, Math.max(min, Math.round(n)));
}

let cached = null;
let cachedAtMs = 0;
const CACHE_MS = 5 * 60 * 1000;

/**
 * Reads push_max_per_user_per_day, push_skip_active_minutes and
 * push_social_proof_min_minutes from server-side Remote Config, falling back
 * to DEFAULT_POLICY if the template is missing or unreachable.
 */
async function loadPolicy(admin, logger) {
  const now = Date.now();
  if (cached && now - cachedAtMs < CACHE_MS) return cached;
  let policy = {...DEFAULT_POLICY};
  try {
    const template = await admin.remoteConfig().getServerTemplate({
      defaultConfig: {
        push_max_per_user_per_day: DEFAULT_POLICY.maxPerUserPerDay,
        push_skip_active_minutes: DEFAULT_POLICY.skipActiveMinutes,
        push_social_proof_min_minutes: DEFAULT_POLICY.socialProofMinMinutes,
      },
    });
    const config = template.evaluate();
    policy = {
      maxPerUserPerDay: clampInt(
          config.getNumber("push_max_per_user_per_day"),
          DEFAULT_POLICY.maxPerUserPerDay, 1, 20),
      skipActiveMinutes: clampInt(
          config.getNumber("push_skip_active_minutes"),
          DEFAULT_POLICY.skipActiveMinutes, 0, 24 * 60),
      socialProofMinMinutes: clampInt(
          config.getNumber("push_social_proof_min_minutes"),
          DEFAULT_POLICY.socialProofMinMinutes, 0, 7 * 24 * 60),
    };
  } catch (error) {
    if (logger) {
      logger.warn("Push policy: Remote Config unavailable, using defaults", {
        error: error instanceof Error ? error.message : String(error),
      });
    }
  }
  cached = policy;
  cachedAtMs = now;
  return policy;
}

module.exports = {
  DEFAULT_POLICY,
  istDayKey,
  isRecentlyActive,
  skipReason,
  clampInt,
  loadPolicy,
};
