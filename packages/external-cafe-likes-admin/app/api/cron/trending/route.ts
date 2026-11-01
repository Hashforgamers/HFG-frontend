import { timingSafeEqual } from "node:crypto";
import { NextResponse } from "next/server";
import { runTrending } from "@/lib/trending";

export const dynamic = "force-dynamic";
export const maxDuration = 60;

/** Vercel Cron calls this with `Authorization: Bearer $CRON_SECRET` (see vercel.json). */
export async function GET(request: Request) {
  const secret = process.env.CRON_SECRET;
  const given = request.headers.get("authorization") ?? "";
  const expected = `Bearer ${secret}`;
  // No secret configured means nobody may trigger a broadcast.
  if (!secret || given.length !== expected.length || !timingSafeEqual(Buffer.from(given), Buffer.from(expected))) {
    return NextResponse.json({ error: "Unauthorized." }, { status: 401 });
  }
  try {
    return NextResponse.json(await runTrending());
  } catch (error) {
    return NextResponse.json({ error: error instanceof Error ? error.message : "Run failed." }, { status: 500 });
  }
}
