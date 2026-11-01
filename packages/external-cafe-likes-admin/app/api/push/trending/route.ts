import { NextResponse } from "next/server";
import { getAdminSession } from "@/lib/auth";
import { getTrendingState, runTrending, setTrendingEnabled } from "@/lib/trending";

export const maxDuration = 60;

export async function GET() {
  if (!(await getAdminSession())) return NextResponse.json({ error: "Not signed in." }, { status: 401 });
  return NextResponse.json(await getTrendingState());
}

/** `{action: "enable" | "disable"}` toggles the autopilot; `"preview"` dry-runs it. */
export async function POST(request: Request) {
  const session = await getAdminSession();
  if (!session) return NextResponse.json({ error: "Not signed in." }, { status: 401 });
  try {
    const { action } = (await request.json()) as { action?: string };
    if (action === "enable" || action === "disable") {
      await setTrendingEnabled(action === "enable", session.email ?? session.uid);
      return NextResponse.json(await getTrendingState());
    }
    if (action === "preview") return NextResponse.json(await runTrending({ preview: true }));
    return NextResponse.json({ error: "Unknown action." }, { status: 400 });
  } catch (error) {
    return NextResponse.json({ error: error instanceof Error ? error.message : "Request failed." }, { status: 500 });
  }
}
