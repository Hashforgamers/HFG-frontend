import { getAdminDb } from "@/lib/firebase-admin";
import type { CafeRecord, LikeRecord, RecentLikeRecord } from "@/lib/types";

function toIsoString(value: unknown) {
  if (!value) return null;
  if (typeof value === "string") return value;
  if (typeof value === "object" && value !== null && "toDate" in value) {
    const date = (value as { toDate: () => Date }).toDate();
    return date.toISOString();
  }
  return null;
}

function normalizeCafe(
  id: string,
  data: FirebaseFirestore.DocumentData | undefined,
): CafeRecord {
  return {
    id,
    placeId: data?.place_id ?? "",
    name: data?.name ?? "Unknown cafe",
    vicinity: data?.vicinity ?? "",
    rating: typeof data?.rating === "number" ? data.rating : null,
    totalLikes: typeof data?.total_likes === "number" ? data.total_likes : 0,
    createdAt: toIsoString(data?.created_at),
    updatedAt: toIsoString(data?.updated_at),
    lastLikedAt: typeof data?.last_liked_at === "string" ? data.last_liked_at : null,
  };
}

function normalizeLike(
  id: string,
  data: FirebaseFirestore.DocumentData | undefined,
): LikeRecord {
  return {
    id,
    userId: data?.user_id ?? null,
    firebaseUid: data?.firebase_uid ?? null,
    deviceId: data?.device_id ?? null,
    createdAt: toIsoString(data?.created_at),
  };
}

export async function getLeaderboard(search = "", limit = 100) {
  const adminDb = getAdminDb();
  const snapshot = await adminDb
    .collection("cafes_external")
    .orderBy("total_likes", "desc")
    .limit(Math.max(limit, 250))
    .get();

  const cafes = snapshot.docs.map((doc) => normalizeCafe(doc.id, doc.data()));
  const query = search.trim().toLowerCase();

  if (!query) {
    return cafes.slice(0, limit);
  }

  return cafes
    .filter(
      (cafe) =>
        cafe.name.toLowerCase().includes(query) ||
        cafe.placeId.toLowerCase().includes(query),
    )
    .slice(0, limit);
}

export async function getCafeDetail(cafeId: string) {
  const adminDb = getAdminDb();
  const cafeRef = adminDb.collection("cafes_external").doc(cafeId);
  const cafeSnap = await cafeRef.get();

  if (!cafeSnap.exists) {
    return null;
  }

  const likesRef = cafeRef.collection("likes");
  const [recentLikesSnap, countSnap] = await Promise.all([
    likesRef.orderBy("created_at", "desc").limit(100).get(),
    likesRef.count().get(),
  ]);

  return {
    cafe: normalizeCafe(cafeSnap.id, cafeSnap.data()),
    likes: recentLikesSnap.docs.map((doc) => normalizeLike(doc.id, doc.data())),
    likesCount: countSnap.data().count,
  };
}

export async function getRecentLikes(limit = 25) {
  const adminDb = getAdminDb();
  const snapshot = await adminDb
    .collectionGroup("likes")
    .orderBy("created_at", "desc")
    .limit(limit)
    .get();

  const cafeIds = Array.from(
    new Set(
      snapshot.docs
        .map((doc) => doc.ref.parent.parent?.id)
        .filter((value): value is string => Boolean(value)),
    ),
  );

  const cafes = await Promise.all(
    cafeIds.map(async (cafeId) => {
      const cafeSnap = await adminDb.collection("cafes_external").doc(cafeId).get();
      return [cafeId, normalizeCafe(cafeSnap.id, cafeSnap.data())] as const;
    }),
  );

  const cafeMap = new Map(cafes);

  return snapshot.docs.map((doc) => {
    const cafeId = doc.ref.parent.parent?.id ?? "unknown";
    const cafe = cafeMap.get(cafeId);
    const like = normalizeLike(doc.id, doc.data());

    return {
      ...like,
      cafeId,
      cafeName: cafe?.name ?? "Unknown cafe",
      placeId: cafe?.placeId ?? "",
    } satisfies RecentLikeRecord;
  });
}
