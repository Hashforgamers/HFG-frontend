import { NextResponse } from "next/server";
import { getAdminAuth } from "@/lib/firebase-admin";
import { getSessionCookieName, isAllowedAdminEmail } from "@/lib/env";

const SESSION_EXPIRES_MS = 1000 * 60 * 60 * 24 * 5;

export async function POST(request: Request) {
  try {
    const body = (await request.json()) as { idToken?: string };
    const idToken = body.idToken;

    if (!idToken) {
      return NextResponse.json({ error: "Missing ID token." }, { status: 400 });
    }

    const adminAuth = getAdminAuth();
    const decoded = await adminAuth.verifyIdToken(idToken);
    if (!isAllowedAdminEmail(decoded.email)) {
      return NextResponse.json(
        { error: "This account is not allowed to access the admin dashboard." },
        { status: 403 },
      );
    }

    const sessionCookie = await adminAuth.createSessionCookie(idToken, {
      expiresIn: SESSION_EXPIRES_MS,
    });

    const response = NextResponse.json({ ok: true });
    response.cookies.set(getSessionCookieName(), sessionCookie, {
      httpOnly: true,
      secure: process.env.NODE_ENV === "production",
      sameSite: "lax",
      path: "/",
      maxAge: SESSION_EXPIRES_MS / 1000,
    });
    return response;
  } catch (error) {
    return NextResponse.json(
      {
        error:
          error instanceof Error ? error.message : "Failed to create session.",
      },
      { status: 500 },
    );
  }
}

export async function DELETE() {
  const response = NextResponse.json({ ok: true });
  response.cookies.set(getSessionCookieName(), "", {
    httpOnly: true,
    secure: process.env.NODE_ENV === "production",
    sameSite: "lax",
    path: "/",
    maxAge: 0,
  });
  return response;
}
