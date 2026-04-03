import { cookies } from "next/headers";
import { redirect } from "next/navigation";
import { getAdminAuth } from "@/lib/firebase-admin";
import { getSessionCookieName, isAllowedAdminEmail } from "@/lib/env";

export async function getAdminSession() {
  try {
    const cookieStore = await cookies();
    const session = cookieStore.get(getSessionCookieName())?.value;

    if (!session) {
      return null;
    }

    const adminAuth = getAdminAuth();
    const decoded = await adminAuth.verifySessionCookie(session, true);
    if (!isAllowedAdminEmail(decoded.email)) {
      return null;
    }
    return decoded;
  } catch {
    return null;
  }
}

export async function requireAdminSession() {
  const session = await getAdminSession();
  if (!session) {
    redirect("/login");
  }
  return session;
}
