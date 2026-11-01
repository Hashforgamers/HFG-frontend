function readEnv(name: string, value = process.env[name]) {
  if (!value) {
    throw new Error(`Missing environment variable: ${name}`);
  }
  return value;
}

// Next.js only inlines NEXT_PUBLIC_* into browser code when written literally.
export function getPublicFirebaseEnv() {
  return {
    apiKey: readEnv("NEXT_PUBLIC_FIREBASE_API_KEY", process.env.NEXT_PUBLIC_FIREBASE_API_KEY),
    authDomain: readEnv("NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN", process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN),
    projectId: readEnv("NEXT_PUBLIC_FIREBASE_PROJECT_ID", process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID),
    storageBucket: readEnv("NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET", process.env.NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET),
    messagingSenderId: readEnv("NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID", process.env.NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID),
    appId: readEnv("NEXT_PUBLIC_FIREBASE_APP_ID", process.env.NEXT_PUBLIC_FIREBASE_APP_ID),
    measurementId: process.env.NEXT_PUBLIC_FIREBASE_MEASUREMENT_ID,
  };
}

export function getAdminEnv() {
  return {
    projectId: readEnv("FIREBASE_PROJECT_ID"),
    clientEmail: readEnv("FIREBASE_CLIENT_EMAIL"),
    privateKey: readEnv("FIREBASE_PRIVATE_KEY").replace(/\\n/g, "\n"),
  };
}

export function getSessionCookieName() {
  return process.env.SESSION_COOKIE_NAME || "hfg_external_likes_admin";
}

export function getAdminEmailAllowlist() {
  return (process.env.ADMIN_EMAILS || "")
    .split(",")
    .map((email) => email.trim().toLowerCase())
    .filter(Boolean);
}

export function isAllowedAdminEmail(email?: string | null) {
  if (!email) return false;
  // An empty allowlist denies everyone: every app user is also a Firebase user.
  return getAdminEmailAllowlist().includes(email.toLowerCase());
}
