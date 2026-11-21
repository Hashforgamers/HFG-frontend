import { NextResponse } from "next/server";
import { getAdminSession } from "@/lib/auth";
import { toCsv } from "@/lib/csv";
import { getLeaderboard } from "@/lib/firestore";

export async function GET(request: Request) {
  const session = await getAdminSession();
  if (!session) {
    return NextResponse.json({ error: "Unauthorized." }, { status: 401 });
  }

  const { searchParams } = new URL(request.url);
  const query = searchParams.get("q")?.trim() ?? "";
  const cafes = await getLeaderboard(query, 1000);

  const csv = toCsv(
    cafes.map((cafe) => ({
      cafe_id: cafe.id,
      place_id: cafe.placeId,
      name: cafe.name,
      vicinity: cafe.vicinity,
      rating: cafe.rating,
      total_likes: cafe.totalLikes,
      created_at: cafe.createdAt,
      updated_at: cafe.updatedAt,
      last_liked_at: cafe.lastLikedAt,
    })),
  );

  return new NextResponse(csv, {
    headers: {
      "Content-Type": "text/csv; charset=utf-8",
      "Content-Disposition": 'attachment; filename="external-cafe-leaderboard.csv"',
    },
  });
}
