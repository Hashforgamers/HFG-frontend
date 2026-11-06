import { NextResponse } from "next/server";
import { getAdminSession } from "@/lib/auth";
import { readFlags, setFlag } from "@/lib/flags";

export async function GET() {
  const session = await getAdminSession();
  if (!session) return NextResponse.json({ error: "Not signed in." }, { status: 401 });
  try {
    return NextResponse.json({ flags: await readFlags() });
  } catch (error) {
    return NextResponse.json(
      { error: error instanceof Error ? error.message : "Could not read flags." },
      { status: 500 },
    );
  }
}

export async function POST(request: Request) {
  const session = await getAdminSession();
  if (!session) return NextResponse.json({ error: "Not signed in." }, { status: 401 });
  try {
    const body = (await request.json()) as { key?: unknown; platform?: unknown; enabled?: unknown };
    if (typeof body.key !== "string" || typeof body.platform !== "string" || typeof body.enabled !== "boolean") {
      return NextResponse.json({ error: "Send { key, platform, enabled }." }, { status: 400 });
    }
    await setFlag(body.key, body.platform, body.enabled);
    return NextResponse.json({ flags: await readFlags() });
  } catch (error) {
    return NextResponse.json(
      { error: error instanceof Error ? error.message : "Could not update the flag." },
      { status: 400 },
    );
  }
}
