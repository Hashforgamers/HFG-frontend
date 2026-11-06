import { cert, getApps, initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { getFirestore } from "firebase-admin/firestore";
import { getAdminEnv } from "@/lib/env";

function getAdminApp() {
  const existing = getApps()[0];
  if (existing) {
    return existing;
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
