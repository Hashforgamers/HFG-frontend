import { cert, getApps, initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { getFirestore } from "firebase-admin/firestore";
import { getAdminEnv } from "@/lib/env";

export function getAdminApp() {
  const existing = getApps()[0];
  if (existing) {
    return existing;
  }

  // A downloaded service-account JSON (GOOGLE_APPLICATION_CREDENTIALS) beats pasting the key into env.
  if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
    return initializeApp({ credential: cert(process.env.GOOGLE_APPLICATION_CREDENTIALS) });
  }
  const adminEnv = getAdminEnv();
  return initializeApp({
    credential: cert({
      projectId: adminEnv.projectId,
      clientEmail: adminEnv.clientEmail,
      privateKey: adminEnv.privateKey,
    }),
  });
}

export function getAdminAuth() {
  return getAuth(getAdminApp());
}

export function getAdminDb() {
  return getFirestore(getAdminApp());
}
