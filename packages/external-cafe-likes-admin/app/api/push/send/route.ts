import { NextResponse } from "next/server";
import { getAdminSession } from "@/lib/auth";
import { createCampaign, type CampaignInput } from "@/lib/push";

export async function POST(request: Request) {
  const session = await getAdminSession();
  if (!session) return NextResponse.json({ error: "Not signed in." }, { status: 401 });
  try {
    const input = (await request.json()) as CampaignInput;
    const result = await createCampaign(input, session.email ?? session.uid);
    return NextResponse.json(result);
  } catch (error) {
    return NextResponse.json(
      { error: error instanceof Error ? error.message : "Send failed." },
      { status: 400 },
    );
  }
}
