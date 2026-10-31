"use strict";

/**
 * HashWallet rewards. The server decides who earns what and records it in
 * reward_ledger/{referenceId} as "issued"; the app then credits it through the
 * existing hash-coins endpoint with that same reference_id and calls
 * markRewardPaid. Clients can never write reward_* collections (see
 * firestore.rules notes in the sprint summary).
 */

const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");
const {
  claimStreak, streakStatus, sanitizeMissions, applyEvent, missionsView,
  matchEndReward, placement, invitePair, INVITE_REWARD,
} = require("./reward_rules");
const {istDayKey} = require("./push_policy");

const db = admin.firestore();
const LEDGER = "reward_ledger";
const STATE = "reward_state";
const PROGRESS = "mission_progress";

let missionsCache = null;
let missionsCachedAt = 0;

/** Today's missions from config/daily_missions, cached for 5 minutes. */
async function loadMissions() {
  if (missionsCache && Date.now() - missionsCachedAt < 5 * 60 * 1000) {
    return missionsCache;
  }
  let raw = null;
  try {
    raw = ((await db.collection("config").doc("daily_missions").get())
        .data() || {}).missions;
  } catch (_) {
    // Fall back to defaults.
  }
  missionsCache = sanitizeMissions(raw);
  missionsCachedAt = Date.now();
  return missionsCache;
}

function progressRef(uid, day) {
  return db.collection(PROGRESS).doc(`${uid}_${day}`);
}

/**
 * Counts one finished game toward today's missions. [eventId] dedupes the
 * same game being reported twice; [fromClient] is counted for monitoring.
 * @return {Promise<string[]>} ids of missions completed by this event.
 */
async function recordGameEvent(uid, ev, {eventId, fromClient}) {
  const missions = await loadMissions();
  const day = istDayKey(Date.now());
  const ref = progressRef(uid, day);
  return db.runTransaction(async (tx) => {
    const p = (await tx.get(ref)).data() || {};
    const seen = Array.isArray(p.seen) ? p.seen : [];
    if (eventId && seen.includes(eventId)) return [];
    const reports = Number(p.client_reports) || 0;
    const before = p.counts || {};
    const counts = applyEvent(missions, before, ev);
    const completed = missions
        .filter((m) => (before[m.id] || 0) < m.target &&
          counts[m.id] >= m.target)
        .map((m) => m.id);
    tx.set(ref, {
      uid,
      day,
      counts,
      seen: eventId ? [...seen, eventId].slice(-60) : seen,
      client_reports: reports + (fromClient ? 1 : 0),
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    }, {merge: true});
    return completed;
  });
}

async function missionsFor(uid) {
  const missions = await loadMissions();
  const p = (await progressRef(uid, istDayKey(Date.now())).get()).data();
  return missionsView(missions, p || {});
}

function requireUid(context) {
  const uid = context.auth && context.auth.uid;
  if (!uid) {
    throw new functions.https.HttpsError("unauthenticated", "Sign in first.");
  }
  return uid;
}

/** Ledger entry as the app sees it. */
function entryView(id, data) {
  return {
    reference_id: id,
    amount: data.amount,
    source: data.source,
    title: data.title || "",
    status: data.status,
  };
}

/**
 * Issues a reward inside a transaction. The reference id is deterministic, so
 * issuing the same reward twice is a no-op.
 * @return {Promise<boolean>} true if newly issued.
 */
async function issueInTx(tx, {referenceId, uid, amount, source, title, meta}) {
  const ref = db.collection(LEDGER).doc(referenceId);
  const snap = await tx.get(ref);
  if (snap.exists) return false;
  tx.set(ref, {
    uid,
    amount,
    source,
    title: title || "",
    meta: meta || {},
    status: "issued",
    created_at: admin.firestore.FieldValue.serverTimestamp(),
  });
  return true;
}

/**
 * Issues several rewards in one transaction. Firestore needs every read
 * before any write, so all ledger docs are read first.
 */
async function issueManyInTx(tx, entries) {
  const refs = entries.map((e) => db.collection(LEDGER).doc(e.referenceId));
  const snaps = await Promise.all(refs.map((r) => tx.get(r)));
  return () => entries.forEach((e, i) => {
    if (snaps[i].exists) return;
    tx.set(refs[i], {
      uid: e.uid,
      amount: e.amount,
      source: e.source,
      title: e.title || "",
      meta: e.meta || {},
      status: "issued",
      created_at: admin.firestore.FieldValue.serverTimestamp(),
    });
  });
}

async function issueReward(entry) {
  return db.runTransaction((tx) => issueInTx(tx, entry));
}

async function pendingFor(uid) {
  const snap = await db.collection(LEDGER)
      .where("uid", "==", uid)
      .where("status", "==", "issued")
      .limit(50)
      .get();
  return snap.docs.map((d) => entryView(d.id, d.data()));
}

const rewardsStatus = functions.https.onCall(async (_data, context) => {
  const uid = requireUid(context);
  const state = (await db.collection(STATE).doc(uid).get()).data() || {};
  return {
    streak: streakStatus(state.streak || {}, Date.now()),
    missions: await missionsFor(uid),
    pending: await pendingFor(uid),
  };
});

const claimDailyStreak = functions.https.onCall(async (_data, context) => {
  const uid = requireUid(context);
  const stateRef = db.collection(STATE).doc(uid);
  const result = await db.runTransaction(async (tx) => {
    const state = (await tx.get(stateRef)).data() || {};
    const claim = claimStreak(state.streak || {}, Date.now());
    if (claim.alreadyClaimed) return claim;
    const referenceId = `streak_${uid}_${claim.day}`;
    await issueInTx(tx, {
      referenceId,
      uid,
      amount: claim.amount,
      source: "daily_streak",
      title: `Day ${claim.streak} streak`,
      meta: {streak: claim.streak, day: claim.day},
    });
    tx.set(stateRef, {
      streak: {lastClaimDay: claim.day, streak: claim.streak},
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    }, {merge: true});
    return {...claim, referenceId};
  });
  return {...result, pending: await pendingFor(uid)};
});

const markRewardPaid = functions.https.onCall(async (data, context) => {
  const uid = requireUid(context);
  const referenceId = String((data && data.referenceId) || "");
  if (!referenceId) {
    throw new functions.https.HttpsError("invalid-argument", "referenceId");
  }
  const ref = db.collection(LEDGER).doc(referenceId);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists || snap.data().uid !== uid) {
      throw new functions.https.HttpsError("not-found", "No such reward.");
    }
    if (snap.data().status === "paid") return;
    tx.update(ref, {
      status: "paid",
      paid_at: admin.firestore.FieldValue.serverTimestamp(),
    });
  });
  return {ok: true};
});

/**
 * Offline Ludo and arcade games, reported by the app when one finishes.
 * Online Ludo is counted server-side from ludo_matches instead.
 */
const reportGamePlayed = functions.https.onCall(async (data, context) => {
  const uid = requireUid(context);
  const game = String((data && data.game) || "").slice(0, 40);
  const eventId = String((data && data.eventId) || "").slice(0, 120);
  if (!game || !eventId) {
    throw new functions.https.HttpsError("invalid-argument", "game, eventId");
  }
  const completed = await recordGameEvent(uid,
      {game, won: data.won === true},
      {eventId: `client_${eventId}`, fromClient: true});
  return {completed, missions: await missionsFor(uid)};
});

const claimMission = functions.https.onCall(async (data, context) => {
  const uid = requireUid(context);
  const missionId = String((data && data.missionId) || "");
  const missions = await loadMissions();
  const mission = missions.find((m) => m.id === missionId);
  if (!mission) {
    throw new functions.https.HttpsError("not-found", "Unknown mission.");
  }
  const day = istDayKey(Date.now());
  const ref = progressRef(uid, day);
  const issued = await db.runTransaction(async (tx) => {
    const p = (await tx.get(ref)).data() || {};
    if ((p.claimed || {})[missionId] === true) return false;
    if ((Number((p.counts || {})[missionId]) || 0) < mission.target) {
      throw new functions.https.HttpsError("failed-precondition",
          "Mission not complete yet.");
    }
    await issueInTx(tx, {
      referenceId: `mission_${uid}_${day}_${missionId}`,
      uid,
      amount: mission.reward,
      source: "daily_mission",
      title: mission.title,
      meta: {mission_id: missionId, day},
    });
    tx.set(ref, {claimed: {[missionId]: true}}, {merge: true});
    return true;
  });
  return {
    issued,
    amount: issued ? mission.reward : 0,
    missions: await missionsFor(uid),
    pending: await pendingFor(uid),
  };
});

/** Seat name -> uid for the human players of a match doc. */
function humanSeats(match) {
  const seats = match.seats || {};
  return Object.entries(seats)
      .filter(([, s]) => s && s.uid && s.bot !== true)
      .map(([seat, s]) => ({seat, uid: String(s.uid)}));
}

/**
 * Task 8 + 9: placement reward for every finished match and, on a
 * friend's first finished friends-room match, the invite reward for both.
 */
async function rewardMatchEnd({uid, matchId, position, quick, hostUid}) {
  const stateRef = db.collection(STATE).doc(uid);
  await db.runTransaction(async (tx) => {
    const state = (await tx.get(stateRef)).data() || {};
    const completedBefore = Number(state.completed_matches) || 0;

    const entries = [{
      referenceId: `ludo_end_${matchId}_${uid}`,
      uid,
      amount: matchEndReward(position),
      source: "ludo_match_end",
      title: position === 1 ? "Ludo win" : "Ludo match finished",
      meta: {match_id: matchId, position},
    }];
    const pair = invitePair({quick, hostUid, uid, completedBefore});
    if (pair) {
      entries.push({
        referenceId: `invite_${pair.invitee}`,
        uid: pair.invitee,
        amount: INVITE_REWARD,
        source: "invite_joined",
        title: "Played your first match with a friend",
        meta: {match_id: matchId, inviter: pair.inviter},
      }, {
        referenceId: `invite_by_${pair.inviter}_${pair.invitee}`,
        uid: pair.inviter,
        amount: INVITE_REWARD,
        source: "invite_reward",
        title: "Your friend finished their first match",
        meta: {match_id: matchId, invitee: pair.invitee},
      });
    }
    const write = await issueManyInTx(tx, entries);
    write();
    tx.set(stateRef, {
      completed_matches: completedBefore + 1,
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    }, {merge: true});
  });
}

/** Online Ludo: counts plays/wins when a match finishes. */
const onLudoMatchFinished = functions.firestore
    .document("ludo_matches/{matchId}")
    .onUpdate(async (change, context) => {
      const before = change.before.data() || {};
      const after = change.after.data() || {};
      if (before.status === "finished" || after.status !== "finished") {
        return null;
      }
      const matchId = context.params.matchId;
      const winners = Array.isArray(after.winners) ? after.winners : [];
      const humans = humanSeats(after);
      const seatCount = Object.keys(after.seats || {}).length;
      await Promise.all(humans.map(async ({seat, uid}) => {
        await recordGameEvent(uid, {game: "ludo", won: winners[0] === seat},
            {eventId: `ludo_${matchId}`, fromClient: false});
        await rewardMatchEnd({
          uid,
          matchId,
          position: placement(seat, winners, seatCount),
          quick: after.quick === true,
          hostUid: String(after.host_uid || ""),
        });
      }));
      return null;
    });

/** New player's first match (offline, so only ever once per account). */
const FIRST_MATCH_REWARD = 20;

const claimFirstMatchReward = functions.https.onCall(async (_data, context) => {
  const uid = requireUid(context);
  const issued = await issueReward({
    referenceId: `first_match_${uid}`,
    uid,
    amount: FIRST_MATCH_REWARD,
    source: "first_match",
    title: "First match complete",
  });
  return {issued, amount: issued ? FIRST_MATCH_REWARD : 0,
    pending: await pendingFor(uid)};
});

module.exports = {
  claimFirstMatchReward,
  reportGamePlayed,
  claimMission,
  onLudoMatchFinished,
  humanSeats,
  issueReward,
  issueInTx,
  pendingFor,
  requireUid,
  rewardsStatus,
  claimDailyStreak,
  markRewardPaid,
};
