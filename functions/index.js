const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");

admin.initializeApp();

const db = admin.firestore();

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

function userTopic(userId) {
  return `hfg_user_${userId}`;
}

async function sendPushToTopic(topic, {title, body, data = {}, channelId = "system_channel"}) {
  if (!topic || !title || !body) {
    return null;
  }

  const payloadData = {};
  Object.entries({...data, title, body}).forEach(([key, value]) => {
    payloadData[key] = value == null ? "" : String(value);
  });

  return admin.messaging().send({
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
  });
}

async function sendPushToUser(userId, options) {
  const safeUserId = asString(userId);
  if (!safeUserId) {
    return null;
  }
  return sendPushToTopic(userTopic(safeUserId), options);
}

async function sendTemplateNotification(topic, templateId, data) {
  const templateDoc = await db
      .collection("notification_templates")
      .doc(templateId)
      .get();

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

exports.bookingSocialProof = functions.firestore
    .document("bookings/{bookingId}")
    .onCreate(async (snap) => {
      const booking = snap.data() || {};
      const cafeName = asString(booking.cafe_name);

      await sendTemplateNotification(
          "mira_road_users",
          "social_proof",
          {
            players_online: 6,
            cafe_name: cafeName,
          },
      );
    });

exports.chatMessagePush = functions.firestore
    .document("chat_rooms/{roomId}/messages/{messageId}")
    .onCreate(async (snap, context) => {
      const roomId = asString(context.params.roomId);
      const message = snap.data() || {};
      const senderId = asString(message.sender_id);
      if (!roomId || !senderId) {
        return null;
      }

      const roomSnap = await db.collection("chat_rooms").doc(roomId).get();
      if (!roomSnap.exists) {
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

      await Promise.allSettled(pushTasks);
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

      await Promise.allSettled(pushTasks);
      return null;
    });
