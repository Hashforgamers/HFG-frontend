import { NextResponse } from "next/server";
import { getAdminSession } from "@/lib/auth";
import { cancelCampaign } from "@/lib/push";

export async function DELETE(_request: Request, { params }: { params: Promise<{ id: string }> }) {
  if (!(await getAdminSession())) return NextResponse.json({ error: "Not signed in." }, { status: 401 });
  try {
    await cancelCampaign((await params).id);
    return NextResponse.json({ ok: true });
  } catch (error) {
    return NextResponse.json(
      { error: error instanceof Error ? error.message : "Cancel failed." },
      { status: 400 },
    );
  }
}
