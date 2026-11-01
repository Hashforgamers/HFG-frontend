import { FieldValue, Timestamp } from "firebase-admin/firestore";
import { getMessaging, type Message } from "firebase-admin/messaging";
import { getAdminApp, getAdminDb } from "@/lib/firebase-admin";

export const CAMPAIGNS = "push_campaigns";
/** Every signed-in device subscribes to this (NotificationService._initTokens). */
export const ALL_USERS_TOPIC = "mira_road_users";
export const CHANNELS = ["system_channel", "offer_channel", "contest_channel", "chat_channel"] as const;

export type Audience =
  | { kind: "all" }
  | { kind: "user"; value: string }
  | { kind: "topic"; value: string }
  | { kind: "token"; value: string };

export type CampaignInput = {
  name: string;
  title: string;
  body: string;
  imageUrl?: string;
  link?: { kind: "deep_link" | "route"; value: string };
  channel: (typeof CHANNELS)[number];
  audience: Audience;
  /** ISO time; omitted or past means send now. */
  sendAt?: string;
  test?: boolean;
};

export type CampaignRecord = {
  id: string;
  name: string;
  title: string;
  body: string;
  imageUrl: string;
  link: string;
  channel: string;
  audience: string;
  status: "sent" | "scheduled" | "failed" | "cancelled";
  test: boolean;
  createdBy: string;
  createdAt: string | null;
  sendAt: string | null;
  sentAt: string | null;
  error: string;
  messageId: string;
};

const TOPIC_RE = /^[a-zA-Z0-9-_.~%]{1,900}$/;

/** Throws a user-facing message when the input cannot be sent. */
export function validate(input: CampaignInput) {
  if (!input.title?.trim() || !input.body?.trim()) throw new Error("Title and body are required.");
  if (input.title.length > 65) throw new Error("Title is over 65 characters; it will be cut off.");
  if (input.body.length > 240) throw new Error("Body is over 240 characters.");
  if (!CHANNELS.includes(input.channel)) throw new Error("Unknown Android channel.");
  if (input.imageUrl && !/^https:\/\//.test(input.imageUrl)) throw new Error("Image URL must be https.");
  const a = input.audience;
  if (a.kind !== "all" && !a.value?.trim()) throw new Error("Audience value is required.");
  if ((a.kind === "topic" || a.kind === "user") && !TOPIC_RE.test(target(a).topic!))
    throw new Error("Invalid topic or user id.");
  if (a.kind === "token" && input.sendAt && new Date(input.sendAt) > new Date())
    throw new Error("Device-token sends are for testing and cannot be scheduled.");
  if (input.link && !(input.link.kind === "route" ? input.link.value.startsWith("/") : /^hash:\/\//.test(input.link.value)))
    throw new Error("Link must be hash://… or a /route.");
}

function target(a: Audience): { topic?: string; token?: string } {
  switch (a.kind) {
    case "all":
      return { topic: ALL_USERS_TOPIC };
    case "user":
      return { topic: `hfg_user_${a.value.trim()}` };
    case "topic":
      return { topic: a.value.trim() };
    case "token":
      return { token: a.value.trim() };
  }
}

export function describeAudience(a: Audience) {
  return a.kind === "all" ? "All users" : a.kind === "token" ? "Test device" : `${a.kind}: ${a.value.trim()}`;
}

/** Same shape as functions/index.js sendPushToTopic, so PushRouter handles it identically. */
export function buildMessage(input: CampaignInput, campaignId: string): Message {
  const data: Record<string, string> = {
    type: "campaign",
    campaign_id: campaignId,
    title: input.title,
    body: input.body,
  };
  if (input.link) data[input.link.kind] = input.link.value;
  const image = input.imageUrl?.trim() || undefined;
  return {
    ...(target(input.audience) as { topic: string }),
    notification: { title: input.title, body: input.body, ...(image ? { imageUrl: image } : {}) },
    data,
    android: { priority: "high", notification: { channelId: input.channel, sound: "default" } },
    apns: {
      payload: { aps: { sound: "default", badge: 1, contentAvailable: true, ...(image ? { mutableContent: true } : {}) } },
      ...(image ? { fcmOptions: { imageUrl: image } } : {}),
    },
  };
}

export async function createCampaign(input: CampaignInput, createdBy: string) {
  validate(input);
  const db = getAdminDb();
  const ref = db.collection(CAMPAIGNS).doc();
  const message = buildMessage(input, ref.id);
  const sendAt = input.sendAt ? new Date(input.sendAt) : null;
  const scheduled = !!sendAt && sendAt.getTime() > Date.now() + 60_000;
  const base = {
    name: input.name?.trim() || input.title,
    title: input.title,
    body: input.body,
    image_url: input.imageUrl ?? "",
    link: input.link?.value ?? "",
    channel: input.channel,
    audience: describeAudience(input.audience),
    test: !!input.test,
    created_by: createdBy,
    created_at: FieldValue.serverTimestamp(),
    // Read by functions/index.js dispatchScheduledPushCampaigns.
    message: JSON.parse(JSON.stringify(message)),
  };
  if (scheduled) {
    await ref.set({ ...base, status: "scheduled", send_at: Timestamp.fromDate(sendAt) });
    return { id: ref.id, status: "scheduled" as const };
  }
  try {
    const messageId = await getMessaging(getAdminApp()).send(message);
    await ref.set({ ...base, status: "sent", sent_at: FieldValue.serverTimestamp(), message_id: messageId });
    return { id: ref.id, status: "sent" as const, messageId };
  } catch (error) {
    const msg = error instanceof Error ? error.message : String(error);
    await ref.set({ ...base, status: "failed", error: msg });
    throw new Error(`FCM rejected the push: ${msg}`);
  }
}

export async function cancelCampaign(id: string) {
  const db = getAdminDb();
  const ref = db.collection(CAMPAIGNS).doc(id);
  await db.runTransaction(async (tx) => {
    const doc = await tx.get(ref);
    if (doc.data()?.status !== "scheduled") throw new Error("Only scheduled campaigns can be cancelled.");
    tx.update(ref, { status: "cancelled", cancelled_at: FieldValue.serverTimestamp() });
  });
}

const iso = (v: unknown) => (v instanceof Timestamp ? v.toDate().toISOString() : null);

export async function listCampaigns(limit = 50): Promise<CampaignRecord[]> {
  const snap = await getAdminDb().collection(CAMPAIGNS).orderBy("created_at", "desc").limit(limit).get();
  return snap.docs.map((doc) => {
    const d = doc.data();
    return {
      id: doc.id,
      name: d.name ?? "",
      title: d.title ?? "",
      body: d.body ?? "",
      imageUrl: d.image_url ?? "",
      link: d.link ?? "",
      channel: d.channel ?? "",
      audience: d.audience ?? "",
      status: d.status,
      test: !!d.test,
      createdBy: d.created_by ?? "",
      createdAt: iso(d.created_at),
      sendAt: iso(d.send_at),
      sentAt: iso(d.sent_at),
      error: d.error ?? "",
      messageId: d.message_id ?? "",
    };
  });
}
