import { NextResponse } from "next/server";
import { getAdminSession } from "@/lib/auth";
import { writeVariants, type Brief } from "@/lib/ai";

export async function POST(request: Request) {
  if (!(await getAdminSession())) return NextResponse.json({ error: "Not signed in." }, { status: 401 });
  try {
    const brief = (await request.json()) as Brief;
    if (!brief.goal?.trim()) return NextResponse.json({ error: "Describe the goal first." }, { status: 400 });
    return NextResponse.json({ variants: await writeVariants(brief) });
  } catch (error) {
    return NextResponse.json(
      { error: error instanceof Error ? error.message : "AI request failed." },
      { status: 500 },
    );
  }
}
