const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");
const {istDayKey, loadPolicy, skipReason} = require("./push_policy");

admin.initializeApp();

const db = admin.firestore();

const FUNNEL_EVENTS_COLLECTION = "notification_funnel_events";
const FUNNEL_STATE_COLLECTION = "notification_funnel_state";
const FUNNEL_JOBS_COLLECTION = "notification_funnel_jobs";

const MAX_FUNNEL_JOBS_PER_RUN = 30;
const MINI_GAMES_TOPIC = "mira_road_users";
const MINI_GAMES_DAILY_CAMPAIGNS = [
  {
    title: "Ludo table is open",
    body: "Roll the dice, climb the board, or watch the lobby heat up.",
    deepLink: "https://hashforgamers.co.in/game/ludo?utm_source=fcm&utm_medium=push&utm_campaign=daily_mini_games&utm_content=ludo",
    content: "ludo",
  },
  {
    title: "Arcade leaderboard is moving",
    body: "Jump into Ludo, Snakes & Ladders, Pac Man and more today.",
    deepLink: "https://hashforgamers.co.in/game/mini-games?utm_source=fcm&utm_medium=push&utm_campaign=daily_mini_games&utm_content=arcade",
    content: "arcade",
  },
  {
    title: "Spectator mode: game night",
    body: "Open the mini-games lounge and see who is climbing the leaderboard.",
    deepLink: "https://hashforgamers.co.in/game/mini-games?utm_source=fcm&utm_medium=push&utm_campaign=daily_mini_games&utm_content=spectator",
    content: "spectator",
  },
];

function minutes(value) {
  return value * 60 * 1000;
}

function hours(value) {
  return value * 60 * 60 * 1000;
}

const FUNNEL_CAMPAIGNS = {
  app_open_idle: {
    delayMs: minutes(12),
    cooldownMs: hours(6),
    title: "{name}, PS5 slots are filling fast near you",
    body: "Book now before it's gone",
    channelId: "system_channel",
    excludeEvents: [
      "cafe_viewed",
      "booking_summary_viewed",
      "booking_started",
      "booking_confirmed",
    ],
  },
  cafe_viewed_followup: {
    delayMs: minutes(7),
    cooldownMs: hours(8),
    title: "{name}, that gaming cafe is still available",
    body: "Check slots before others grab them",
    channelId: "system_channel",
    excludeEvents: [
      "booking_summary_viewed",
      "booking_started",
      "booking_confirmed",
    ],
  },
  booking_summary_followup: {
    delayMs: minutes(4),
    cooldownMs: hours(6),
    title: "{name}, your slot is waiting",
    body: "Complete booking in seconds",
    channelId: "system_channel",
    excludeEvents: ["booking_started", "booking_confirmed"],
  },
  booking_started_followup: {
    delayMs: minutes(2),
    cooldownMs: hours(4),
    title: "Almost done, {name}!",
    body: "Don’t lose your slot now",
    channelId: "system_channel",
    excludeEvents: ["booking_confirmed"],
  },
  booking_cancelled_followup: {
    delayMs: minutes(4),
    cooldownMs: hours(4),
    title: "{name}, your slot is still available",
    body: "Complete booking before someone else takes it",
    channelId: "system_channel",
    excludeEvents: ["booking_confirmed"],
  },
  booking_confirmed_followup: {
    delayMs: minutes(90),
    cooldownMs: hours(12),
    title: "Booking confirmed, {name}!",
    body: "Get ready to dominate",
    channelId: "system_channel",
    excludeEvents: [],
  },
  inactivity_24h: {
    delayMs: hours(24),
    cooldownMs: hours(24),
    title: "{name}, new slots are available near you",
    body: "Jump back in and play today",
    channelId: "system_channel",
    excludeEvents: ["app_open"],
  },
  inactivity_3d: {
    delayMs: hours(72),
    cooldownMs: hours(24),
    title: "{name}, you’re missing out!",
    body: "PS5 slots are getting booked fast",
    channelId: "system_channel",
    excludeEvents: ["app_open"],
  },
  wallet_viewed_followup: {
    delayMs: minutes(30),
    cooldownMs: hours(12),
    title: "{name}, your credit is waiting",
    body: "Use it before it expires",
    channelId: "system_channel",
    excludeEvents: ["booking_started", "booking_confirmed"],
  },
  reward_unlocked_followup: {
    delayMs: minutes(1),
    cooldownMs: minutes(30),
    title: "{name}, you just earned rewards!",
    body: "Use them for your next booking",
    channelId: "system_channel",
    excludeEvents: [],
  },
  multiple_cafe_views_followup: {
    delayMs: minutes(8),
    cooldownMs: hours(8),
    title: "Still deciding, {name}?",
    body: "Best slots are getting booked fast",
    channelId: "system_channel",
    excludeEvents: [
      "booking_summary_viewed",
      "booking_started",
      "booking_confirmed",
    ],
  },
  high_intent_followup: {
    delayMs: minutes(6),
    cooldownMs: hours(6),
    title: "{name}, your perfect slot is waiting",
    body: "Book now before it's gone",
    channelId: "system_channel",
    excludeEvents: ["booking_started", "booking_confirmed"],
  },
};

function asString(value) {
  return (value ?? "").toString().trim();
}

function asNumber(value) {
  const parsed = Number(value ?? 0);
  return Number.isFinite(parsed) ? parsed : 0;
}

function asStringList(value) {
  return Array.isArray(value) ? value.map((item) => item.toString()) : [];
}

function asObject(value) {
  return value && typeof value === "object" && !Array.isArray(value) ? value : {};
}

function firstName(value) {
  const cleaned = asString(value).replace(/^@+/, "");
  if (!cleaned) return "";
  return cleaned.split(/\s+/)[0].slice(0, 24);
}

function userNameFromPayload(payload) {
  return firstName(
      payload.user_name ||
      payload.username ||
      payload.display_name ||
      payload.name,
  );
}

function renderPersonalizedCopy(template, payload) {
  const name = userNameFromPayload(payload) || "player";
  return asString(template).replace(/\{name\}/g, name);
}

function userTopic(userId) {
  return `hfg_user_${userId}`;
}

function timestampToMs(value) {
  if (!value) return 0;
  if (typeof value === "number") return value;
  if (value.toMillis) return value.toMillis();
  return 0;
}

function eventTimestampField(eventType) {
  return {
    app_open: "lastAppOpenAtMs",
    cafe_viewed: "lastCafeViewedAtMs",
    booking_summary_viewed: "lastBookingSummaryViewedAtMs",
    booking_started: "lastBookingStartedAtMs",
    booking_cancelled: "lastBookingCancelledAtMs",
    booking_confirmed: "lastBookingConfirmedAtMs",
    wallet_viewed: "lastWalletViewedAtMs",
    reward_unlocked: "lastRewardUnlockedAtMs",
    coin_earned: "lastCoinEarnedAtMs",
  }[eventType] || "";
}

function latestEventAt(state, eventType) {
  const field = eventTimestampField(eventType);
  if (!field) return 0;
  return asNumber(state[field]);
}

async function sendPushToTopic(topic, {title, body, data = {}, channelId = "system_channel"}) {
  if (!topic || !title || !body) {
    functions.logger.warn("Skipping push because required fields are missing", {
      topic,
      title,
      body,
      channelId,
    });
    return null;
  }

  const payloadData = {};
  Object.entries({...data, title, body}).forEach(([key, value]) => {
    payloadData[key] = value == null ? "" : String(value);
  });

  const message = {
    topic,
    notification: {
      title,
      body,
    },
    data: payloadData,
    android: {
      priority: "high",
      notification: {
        channelId,
        sound: "default",
      },
    },
    apns: {
      payload: {
        aps: {
          sound: "default",
          badge: 1,
          contentAvailable: true,
        },
      },
    },
  };

  functions.logger.info("Sending push notification", {
    topic,
    title,
    body,
    channelId,
    data: payloadData,
  });

  const response = await admin.messaging().send(message);
  functions.logger.info("Push notification sent", {
    topic,
    response,
  });
  return response;
}

/**
 * Reserves one of today's engagement pushes for this user, or returns why
 * not: they were active within push_skip_active_minutes (presence written by
 * the app to chat_users/{uid}) or already got push_max_per_user_per_day.
 */
async function reserveEngagementPush(userId) {
  const policy = await loadPolicy(admin, functions.logger);
  const nowMs = Date.now();
  const presence = (await db.collection("chat_users").doc(userId).get())
      .data() || {};
  const day = istDayKey(nowMs);
  const capRef = db.collection("push_caps").doc(`${userId}_${day}`);
  return db.runTransaction(async (tx) => {
    const cap = (await tx.get(capRef)).data() || {};
    const sentToday = asNumber(cap.count) || 0;
    const reason = skipReason({
      isOnline: presence.is_online === true,
      lastSeenMs: timestampToMs(presence.last_seen_at),
      sentToday,
      nowMs,
      policy,
    });
    if (reason) return reason;
    tx.set(capRef, {
      user_id: userId,
      day,
      count: sentToday + 1,
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
      // Enable a Firestore TTL policy on push_caps.expire_at to clean up.
      expire_at: admin.firestore.Timestamp.fromMillis(
          nowMs + 3 * 24 * 60 * 60 * 1000),
    }, {merge: true});
    return null;
  });
}

/**
 * Sends to one user's topic. Engagement pushes (the default) go through the
 * frequency cap and active-user skip; pass `transactional: true` for pushes
 * the user is waiting on (chat messages). Returns the FCM response, or
 * `{skipped: reason}` when the cap held it back.
 */
/**
 * At most one topic broadcast of this kind per push_social_proof_min_minutes.
 * @return {Promise<boolean>} true if this caller may send now.
 */
async function claimBroadcastSlot(kind) {
  const policy = await loadPolicy(admin, functions.logger);
  const ref = db.collection("push_throttle").doc(kind);
  const nowMs = Date.now();
  return db.runTransaction(async (tx) => {
    const last = asNumber(((await tx.get(ref)).data() || {}).last_sent_ms);
    if (last && nowMs - last < policy.socialProofMinMinutes * 60 * 1000) {
      return false;
    }
    tx.set(ref, {last_sent_ms: nowMs}, {merge: true});
    return true;
  });
}

async function sendPushToUser(userId, options) {
  const safeUserId = asString(userId);
  if (!safeUserId) {
    return null;
  }
  const {transactional = false, ...pushOptions} = options;
  if (!transactional) {
    const reason = await reserveEngagementPush(safeUserId);
    if (reason) {
      functions.logger.info("Push skipped by frequency policy", {
        userId: safeUserId,
        reason,
        type: pushOptions.data && pushOptions.data.type,
      });
      return {skipped: reason};
    }
  }
  return sendPushToTopic(userTopic(safeUserId), pushOptions);
}

function miniGamesCampaignForToday(now = new Date()) {
  const daysSinceEpoch = Math.floor(now.getTime() / (24 * 60 * 60 * 1000));
  return MINI_GAMES_DAILY_CAMPAIGNS[
      daysSinceEpoch % MINI_GAMES_DAILY_CAMPAIGNS.length
  ];
}

async function sendTemplateNotification(topic, templateId, data) {
  const templateDoc = await db
      .collection("notification_templates")
      .doc(templateId)
      .get();

  if (!templateDoc.exists) {
    throw new Error(`Notification template not found: ${templateId}`);
  }

  const template = templateDoc.data() || {};

  let title = asString(template.title);
  let body = asString(template.body);

  Object.keys(data).forEach((key) => {
    title = title.replace(`{${key}}`, data[key]);
    body = body.replace(`{${key}}`, data[key]);
  });

  return sendPushToTopic(topic, {
    title,
    body,
    data: {
      type: "offer",
      template_id: templateId,
    },
    channelId: "offer_channel",
  });
}

function buildChatBody(message) {
  const type = asString(message.type).toLowerCase();
  const senderName = asString(message.sender_name) || "Someone";
  const rawText = asString(message.text);
  const meta = message.meta || {};

  if (type === "arena_booking_invite") {
    const cafeName = asString(meta.cafe_name);
    return cafeName
      ? `${senderName} shared a squad booking for ${cafeName}`
      : `${senderName} shared a squad booking with you`;
  }

  return rawText || "New message";
}

function buildLeaderboardEntries(snapshot) {
  return snapshot.docs.map((doc) => ({
    userId: doc.id,
    displayName: asString(doc.get("displayName")) || "Player",
    totalScore: asNumber(doc.get("totalScore")),
  }));
}

function buildRankMap(entries) {
  const sorted = [...entries].sort((a, b) => {
    if (b.totalScore !== a.totalScore) {
      return b.totalScore - a.totalScore;
    }
    return a.userId.localeCompare(b.userId);
  });

  const map = new Map();
  sorted.forEach((entry, index) => {
    map.set(entry.userId, index + 1);
  });
  return map;
}

function buildPreviousEntries(currentEntries, moverId, previousTotalScore) {
  return currentEntries.map((entry) => {
    if (entry.userId !== moverId) {
      return {...entry};
    }
    return {
      ...entry,
      totalScore: previousTotalScore,
    };
  });
}

function buildNextFunnelState(currentState, eventType, eventAtMs) {
  const nextState = {
    ...currentState,
    lastEventType: eventType,
    lastEventAtMs: eventAtMs,
  };

  const timestampField = eventTimestampField(eventType);
  if (timestampField) {
    nextState[timestampField] = eventAtMs;
  }

  if (eventType === "cafe_viewed") {
    nextState.cafeViewedCount = asNumber(currentState.cafeViewedCount) + 1;
  }

  if (eventType === "booking_summary_viewed") {
    nextState.bookingSummaryViewedCount =
      asNumber(currentState.bookingSummaryViewedCount) + 1;
  }

  if (eventType === "booking_started" || eventType === "booking_confirmed") {
    nextState.cafeViewedCount = 0;
    nextState.bookingSummaryViewedCount = 0;
  }

  return nextState;
}

function cancellationKeysForEvent(eventType) {
  const keys = [];

  if (eventType === "app_open") {
    keys.push("inactivity_24h", "inactivity_3d");
  }

  if (eventType === "cafe_viewed") {
    keys.push("app_open_idle");
  }

  if (eventType === "booking_summary_viewed") {
    keys.push("app_open_idle", "cafe_viewed_followup", "multiple_cafe_views_followup");
  }

  if (eventType === "booking_started") {
    keys.push(
        "app_open_idle",
        "cafe_viewed_followup",
        "booking_summary_followup",
        "high_intent_followup",
        "multiple_cafe_views_followup",
        "wallet_viewed_followup",
    );
  }

  if (eventType === "booking_confirmed") {
    keys.push(
        "app_open_idle",
        "cafe_viewed_followup",
        "booking_summary_followup",
        "booking_started_followup",
        "booking_cancelled_followup",
        "high_intent_followup",
        "multiple_cafe_views_followup",
        "wallet_viewed_followup",
    );
  }

  return keys;
}

function scheduleKeysForEvent(eventType, nextState) {
  const keys = [];

  if (eventType === "app_open") {
    keys.push("app_open_idle", "inactivity_24h", "inactivity_3d");
  }

  if (eventType === "cafe_viewed") {
    keys.push("cafe_viewed_followup");
    if (asNumber(nextState.cafeViewedCount) >= 3) {
      keys.push("multiple_cafe_views_followup");
    }
  }

  if (eventType === "booking_summary_viewed") {
    keys.push("booking_summary_followup");
    if (asNumber(nextState.bookingSummaryViewedCount) >= 2) {
      keys.push("high_intent_followup");
    }
  }

  if (eventType === "booking_started") {
    keys.push("booking_started_followup");
  }

  if (eventType === "booking_cancelled") {
    keys.push("booking_cancelled_followup");
  }

  if (eventType === "booking_confirmed") {
    keys.push("booking_confirmed_followup");
  }

  if (eventType === "wallet_viewed") {
    keys.push("wallet_viewed_followup");
  }

  if (eventType === "reward_unlocked" || eventType === "coin_earned") {
    keys.push("reward_unlocked_followup");
  }

  return keys;
}

async function cancelPendingCampaigns(userId, campaignKeys, reason, eventType) {
  const uniqueKeys = [...new Set(campaignKeys)].filter(Boolean);
  if (!userId || uniqueKeys.length === 0) {
    return;
  }

  for (const campaignKey of uniqueKeys) {
    const snapshot = await db.collection(FUNNEL_JOBS_COLLECTION)
        .where("userId", "==", userId)
        .where("campaignKey", "==", campaignKey)
        .get();

    if (snapshot.empty) {
      continue;
    }

    const batch = db.batch();
    snapshot.docs.forEach((doc) => {
      if (asString(doc.get("status")) !== "pending") {
        return;
      }
      batch.update(doc.ref, {
        status: "cancelled",
        cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
        cancelledAtMs: Date.now(),
        cancelReason: reason,
        cancelledByEvent: eventType,
      });
    });
    await batch.commit();
  }
}

async function scheduleCampaignJob(userId, campaignKey, baseEventType, baseEventAtMs, payload) {
  const campaign = FUNNEL_CAMPAIGNS[campaignKey];
  if (!campaign || !userId) {
    return null;
  }

  await cancelPendingCampaigns(
      userId,
      [campaignKey],
      "replaced_by_newer_job",
      baseEventType,
  );

  const sendAtMs = baseEventAtMs + campaign.delayMs;
  const job = {
    userId,
    campaignKey,
    status: "pending",
    title: campaign.title,
    body: campaign.body,
    channelId: campaign.channelId,
    baseEventType,
    baseEventAtMs,
    excludeEvents: campaign.excludeEvents,
    cooldownMs: campaign.cooldownMs,
    payload: payload || {},
    sendAtMs,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    createdAtMs: Date.now(),
  };

  functions.logger.info("Scheduling funnel notification job", job);
  return db.collection(FUNNEL_JOBS_COLLECTION).add(job);
}

function isJobObsolete(job, state) {
  const excludeEvents = asStringList(job.excludeEvents);
  const baseEventAtMs = asNumber(job.baseEventAtMs);
  for (const eventType of excludeEvents) {
    if (latestEventAt(state, eventType) > baseEventAtMs) {
      return `excluded_by_${eventType}`;
    }
  }

  if (job.campaignKey === "multiple_cafe_views_followup" &&
      asNumber(state.cafeViewedCount) < 3) {
    return "multiple_cafe_view_threshold_not_met";
  }

  if (job.campaignKey === "high_intent_followup" &&
      asNumber(state.bookingSummaryViewedCount) < 2) {
    return "high_intent_threshold_not_met";
  }

  return "";
}

async function markJobState(docRef, status, fields = {}) {
  await docRef.update({
    status,
    processedAt: admin.firestore.FieldValue.serverTimestamp(),
    processedAtMs: Date.now(),
    ...fields,
  });
}

exports.bookingSocialProof = functions.firestore
    .document("bookings/{bookingId}")
    .onCreate(async (snap, context) => {
      const booking = snap.data() || {};
      const cafeName = asString(booking.cafe_name);

      functions.logger.info("bookingSocialProof triggered", {
        bookingId: context.params.bookingId,
        booking,
      });

      try {
        // Every booking used to broadcast to all users. Topic sends can't be
        // capped per user, so throttle the broadcast itself.
        if (!(await claimBroadcastSlot("social_proof"))) {
          functions.logger.info("bookingSocialProof throttled", {
            bookingId: context.params.bookingId,
          });
          return null;
        }
        await sendTemplateNotification(
            "mira_road_users",
            "social_proof",
            {
              players_online: 6,
              cafe_name: cafeName,
            },
        );
      } catch (error) {
        functions.logger.error("bookingSocialProof failed", {
          bookingId: context.params.bookingId,
          error: error instanceof Error ? error.message : String(error),
        });
        throw error;
      }
    });

exports.chatMessagePush = functions.firestore
    .document("chat_rooms/{roomId}/messages/{messageId}")
    .onCreate(async (snap, context) => {
      const roomId = asString(context.params.roomId);
      const message = snap.data() || {};
      const senderId = asString(message.sender_id);
      if (!roomId || !senderId) {
        functions.logger.warn("chatMessagePush skipped because roomId or senderId is missing", {
          roomId,
          senderId,
          messageId: context.params.messageId,
          message,
        });
        return null;
      }

      const roomSnap = await db.collection("chat_rooms").doc(roomId).get();
      if (!roomSnap.exists) {
        functions.logger.warn("chatMessagePush skipped because room does not exist", {
          roomId,
          messageId: context.params.messageId,
        });
        return null;
      }

      const room = roomSnap.data() || {};
      const members = asStringList(room.members);
      const mutedUsers = new Set(asStringList(room.muted_uids));
      const deletedUsers = new Set(asStringList(room.deleted_for_uids));
      const roomType = asString(room.type).toLowerCase();
      const senderName = asString(message.sender_name) || "New message";
      const roomName = asString(room.name);
      const title = roomType === "group" ? (roomName || "Group Chat") : senderName;
      const body = buildChatBody(message);

      const pushTasks = members
          .filter((memberId) => memberId && memberId !== senderId)
          .filter((memberId) => !mutedUsers.has(memberId))
          .filter((memberId) => !deletedUsers.has(memberId))
          .map((memberId) => sendPushToUser(memberId, {
            transactional: true,
            title,
            body,
            channelId: "chat_channel",
            data: {
              type: "chat",
              room_id: roomId,
              chat_room_id: roomId,
              sender_id: senderId,
              sender_name: senderName,
              chat_title: roomName || title,
              message: body,
            },
          }));

      functions.logger.info("chatMessagePush resolved recipients", {
        roomId,
        messageId: context.params.messageId,
        senderId,
        members,
        mutedUsers: Array.from(mutedUsers),
        deletedUsers: Array.from(deletedUsers),
        recipientCount: pushTasks.length,
      });

      const results = await Promise.allSettled(pushTasks);
      functions.logger.info("chatMessagePush completed", {
        roomId,
        messageId: context.params.messageId,
        results,
      });
      return null;
    });

exports.leaderboardRankPush = functions.firestore
    .document("mini_game_leaderboard/{userId}")
    .onWrite(async (change, context) => {
      if (!change.after.exists) {
        return null;
      }

      const moverId = asString(context.params.userId);
      const afterData = change.after.data() || {};
      const beforeData = change.before.exists ? change.before.data() || {} : {};
      const previousTotalScore = asNumber(beforeData.totalScore);
      const nextTotalScore = asNumber(afterData.totalScore);

      if (nextTotalScore <= previousTotalScore) {
        functions.logger.info("leaderboardRankPush skipped because score did not increase", {
          userId: moverId,
          previousTotalScore,
          nextTotalScore,
        });
        return null;
      }

      const leaderboardSnapshot = await db
          .collection("mini_game_leaderboard")
          .orderBy("totalScore", "desc")
          .limit(25)
          .get();

      const currentEntries = buildLeaderboardEntries(leaderboardSnapshot);
      const previousEntries = buildPreviousEntries(
          currentEntries,
          moverId,
          previousTotalScore,
      );

      const currentRanks = buildRankMap(currentEntries);
      const previousRanks = buildRankMap(previousEntries);
      const moverRank = currentRanks.get(moverId) || null;
      const previousMoverRank = previousRanks.get(moverId) || null;
      const moverName = asString(afterData.displayName) || "A player";

      const pushTasks = [];

      if (moverRank && moverRank <= 4 &&
        (!previousMoverRank || moverRank < previousMoverRank)) {
        const body = !previousMoverRank || previousMoverRank > 4
          ? `You climbed to #${moverRank} on the overall arcade leaderboard.`
          : `You moved up from #${previousMoverRank} to #${moverRank} on the overall arcade leaderboard.`;
        pushTasks.push(sendPushToUser(moverId, {
          title: "Leaderboard climb",
          body,
          data: {
            type: "leaderboard",
            event: "climb",
            rank: moverRank,
            leaderboard_scope: "overall",
          },
        }));
      }

      currentEntries.forEach((entry) => {
        if (entry.userId === moverId) {
          return;
        }

        const previousRank = previousRanks.get(entry.userId) || null;
        const currentRank = currentRanks.get(entry.userId) || null;
        const slipped =
          previousRank &&
          previousRank <= 4 &&
          (!currentRank || currentRank > previousRank);

        if (!slipped) {
          return;
        }

        const body = !currentRank || currentRank > 4
          ? `${moverName} moved ahead of you. You slipped out of the top 4 overall.`
          : `${moverName} moved ahead of you. You are now #${currentRank} overall.`;

        pushTasks.push(sendPushToUser(entry.userId, {
          title: "Leaderboard update",
          body,
          data: {
            type: "leaderboard",
            event: "overtaken",
            moved_by: moverName,
            rank: currentRank || "",
            leaderboard_scope: "overall",
          },
        }));
      });

      functions.logger.info("leaderboardRankPush resolved recipients", {
        userId: moverId,
        previousTotalScore,
        nextTotalScore,
        moverRank,
        previousMoverRank,
        recipientCount: pushTasks.length,
      });

      const results = await Promise.allSettled(pushTasks);
      functions.logger.info("leaderboardRankPush completed", {
        userId: moverId,
        results,
      });
      return null;
    });

exports.funnelEventIngested = functions.firestore
    .document(`${FUNNEL_EVENTS_COLLECTION}/{eventId}`)
    .onCreate(async (snap, context) => {
      const event = snap.data() || {};
      const eventType = asString(event.eventType).toLowerCase();
      const userId = asString(event.firebaseUid);
      const payload = asObject(event.payload);
      const eventAtMs = asNumber(event.occurredAtMs) || Date.now();

      if (!userId || !eventType) {
        functions.logger.warn("Skipping funnel event because userId or eventType is missing", {
          eventId: context.params.eventId,
          event,
        });
        return null;
      }

      const stateRef = db.collection(FUNNEL_STATE_COLLECTION).doc(userId);
      const stateSnap = await stateRef.get();
      const currentState = stateSnap.exists ? stateSnap.data() || {} : {};
      const nextState = buildNextFunnelState(currentState, eventType, eventAtMs);

      await stateRef.set({
        ...nextState,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAtMs: Date.now(),
      }, {merge: true});

      const cancelKeys = cancellationKeysForEvent(eventType);
      await cancelPendingCampaigns(
          userId,
          cancelKeys,
          "cancelled_by_progression_event",
          eventType,
      );

      const scheduleKeys = scheduleKeysForEvent(eventType, nextState);
      for (const campaignKey of scheduleKeys) {
        await scheduleCampaignJob(
            userId,
            campaignKey,
            eventType,
            eventAtMs,
            payload,
        );
      }

      functions.logger.info("Funnel event processed", {
        eventId: context.params.eventId,
        userId,
        eventType,
        cancelKeys,
        scheduleKeys,
        nextState,
      });

      return null;
    });

exports.processFunnelNotificationJobs = functions.pubsub
    .schedule("every 1 minutes")
    .onRun(async () => {
      const now = Date.now();
      const jobsSnapshot = await db.collection(FUNNEL_JOBS_COLLECTION)
          .where("sendAtMs", "<=", now)
          .orderBy("sendAtMs", "asc")
          .limit(MAX_FUNNEL_JOBS_PER_RUN * 3)
          .get();

      if (jobsSnapshot.empty) {
        functions.logger.info("No funnel notification jobs due");
        return null;
      }

      for (const doc of jobsSnapshot.docs) {
        const job = doc.data() || {};
        if (asString(job.status) !== "pending") {
          continue;
        }
        const campaignKey = asString(job.campaignKey);
        const campaign = FUNNEL_CAMPAIGNS[campaignKey];
        const userId = asString(job.userId);

        if (!campaign || !userId) {
          await markJobState(doc.ref, "failed", {
            failureReason: "invalid_job_configuration",
          });
          continue;
        }

        const stateRef = db.collection(FUNNEL_STATE_COLLECTION).doc(userId);
        const stateSnap = await stateRef.get();
        const state = stateSnap.exists ? stateSnap.data() || {} : {};
        const obsoleteReason = isJobObsolete(job, state);
        if (obsoleteReason) {
          await markJobState(doc.ref, "cancelled", {
            cancelReason: obsoleteReason,
          });
          continue;
        }

        const lastSentByCampaign = asObject(state.lastSentAtByCampaign);
        const lastSentAtMs = asNumber(lastSentByCampaign[campaignKey]);
        if (lastSentAtMs && now - lastSentAtMs < campaign.cooldownMs) {
          await markJobState(doc.ref, "cancelled", {
            cancelReason: "cooldown_active",
          });
          continue;
        }

        try {
          const payload = asObject(job.payload);
          const title = renderPersonalizedCopy(campaign.title, payload);
          const body = renderPersonalizedCopy(campaign.body, payload);
          const response = await sendPushToUser(userId, {
            title,
            body,
            channelId: campaign.channelId,
            data: {
              type: "funnel_notification",
              campaign_key: campaignKey,
              event_type: asString(job.baseEventType),
              ...payload,
              title,
              body,
            },
          });

          if (response && response.skipped) {
            await markJobState(doc.ref, "cancelled", {
              cancelReason: `push_${response.skipped}`,
            });
            continue;
          }

          await markJobState(doc.ref, "sent", {
            providerResponse: response,
            sentAt: admin.firestore.FieldValue.serverTimestamp(),
            sentAtMs: now,
          });

          await stateRef.set({
            lastSentAtByCampaign: {
              ...lastSentByCampaign,
              [campaignKey]: now,
            },
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAtMs: now,
          }, {merge: true});
        } catch (error) {
          functions.logger.error("Failed to send funnel notification job", {
            jobId: doc.id,
            campaignKey,
            userId,
            error: error instanceof Error ? error.message : String(error),
          });
          await markJobState(doc.ref, "failed", {
            failureReason: error instanceof Error ? error.message : String(error),
          });
        }
      }

      return null;
    });

exports.dailyMiniGamesPush = functions.pubsub
    .schedule("0 19 * * *")
    .timeZone("Asia/Kolkata")
    .onRun(async () => {
      const campaign = miniGamesCampaignForToday();
      const campaignId = `daily_mini_games_${campaign.content}`;
      const response = await sendPushToTopic(MINI_GAMES_TOPIC, {
        title: campaign.title,
        body: campaign.body,
        channelId: "system_channel",
        data: {
          type: "game",
          campaign_key: "daily_mini_games",
          campaign_id: campaignId,
          deep_link: campaign.deepLink,
          content: campaign.content,
        },
      });

      functions.logger.info("Daily mini-games notification sent", {
        topic: MINI_GAMES_TOPIC,
        campaignId,
        deepLink: campaign.deepLink,
        response,
      });
      return null;
    });

// HashWallet rewards (streak, missions, match/invite/weekly rewards).
const rewards = require("./rewards");
exports.rewardsStatus = rewards.rewardsStatus;
exports.claimDailyStreak = rewards.claimDailyStreak;
exports.markRewardPaid = rewards.markRewardPaid;
