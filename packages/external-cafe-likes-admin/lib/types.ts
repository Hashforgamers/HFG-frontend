export type CafeRecord = {
  id: string;
  placeId: string;
  name: string;
  vicinity: string;
  rating: number | null;
  totalLikes: number;
  createdAt: string | null;
  updatedAt: string | null;
  lastLikedAt: string | null;
};

export type LikeRecord = {
  id: string;
  userId: string | null;
  firebaseUid: string | null;
  deviceId: string | null;
  createdAt: string | null;
};

export type RecentLikeRecord = LikeRecord & {
  cafeId: string;
  cafeName: string;
  placeId: string;
};
