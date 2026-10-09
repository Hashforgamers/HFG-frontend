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
const {claimStreak, streakStatus} = require("./reward_rules");

const db = admin.firestore();
const LEDGER = "reward_ledger";
const STATE = "reward_state";

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

module.exports = {
  issueReward,
  issueInTx,
  pendingFor,
  requireUid,
  rewardsStatus,
  claimDailyStreak,
  markRewardPaid,
};
