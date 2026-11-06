import { NextResponse } from "next/server";
import { getAdminSession } from "@/lib/auth";
import { toCsv } from "@/lib/csv";
import { getCafeDetail } from "@/lib/firestore";

type RouteContext = {
  params: Promise<{
    cafeId: string;
  }>;
};

export async function GET(_: Request, context: RouteContext) {
  const session = await getAdminSession();
  if (!session) {
    return NextResponse.json({ error: "Unauthorized." }, { status: 401 });
  }

  const { cafeId } = await context.params;
  const detail = await getCafeDetail(decodeURIComponent(cafeId));

  if (!detail) {
    return NextResponse.json({ error: "Cafe not found." }, { status: 404 });
  }

  const csv = toCsv(
    detail.likes.map((like) => ({
      user_key: like.id,
      user_id: like.userId,
      firebase_uid: like.firebaseUid,
      device_id: like.deviceId,
      created_at: like.createdAt,
    })),
  );

  return new NextResponse(csv, {
    headers: {
      "Content-Type": "text/csv; charset=utf-8",
      "Content-Disposition": `attachment; filename="${detail.cafe.id}-likes.csv"`,
    },
  });
}
