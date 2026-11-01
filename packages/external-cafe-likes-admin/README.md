# External Cafe Likes Admin

Next.js admin dashboard for the existing `cafes_external` Firestore data in the `hash-ee6fc` Firebase project.

## What It Includes

- Firebase Auth admin login
- Protected server-side reads through Firebase Admin SDK
- Leaderboard ordered by `total_likes desc`
- Search by cafe `name` and `place_id`
- Cafe drilldown with recent like documents
- Global recent likes panel
- CSV export for leaderboard and per-cafe likes

## Required Environment Variables

Copy `.env.example` to `.env.local` and fill in the admin credentials:

- `NEXT_PUBLIC_FIREBASE_*`: web SDK config
- `FIREBASE_PROJECT_ID`
- `FIREBASE_CLIENT_EMAIL`
- `FIREBASE_PRIVATE_KEY`
- `ADMIN_EMAILS`: comma-separated allowlist for admin emails
- `SESSION_COOKIE_NAME`: optional session cookie name override

## Setup

1. Create a Firebase service account with Firestore read access for this project.
2. Put the credentials into `.env.local`.
3. Create at least one Firebase Auth user whose email is present in `ADMIN_EMAILS`.
4. Install dependencies:

```bash
npm install
```

5. Run locally:

```bash
npm run dev
```

## Routes

- `/login`
- `/dashboard`
- `/cafes/[cafeId]`
- `/api/export/cafes`
- `/api/export/cafes/[cafeId]/likes`

## Firestore Assumptions

Top-level collection:

```txt
cafes_external
```

Per-cafe likes subcollection:

```txt
cafes_external/{cafeId}/likes/{userKey}
```

The admin site uses server-side Firebase Admin reads and does not rely on open client-side Firestore reads for analytics.

## Push Studio (`/push`)

A MoEngage/WebEngage-style console for Hash pushes and deep links, behind the same admin login.

- `/push`: AI copywriter (Claude writes A/B variants plus the deep link to use), message editor with length limits, Android/iOS preview, deep-link builder with UTM tags, audience (all users via `mira_road_users`, one uid via `hfg_user_<uid>`, any FCM topic), send now or schedule, and a test send to a single FCM token.
- `/push/campaigns`: history of every send with status, audience, link and errors; scheduled ones can be cancelled.
- `/push/deeplinks`: link builder for WhatsApp/Instagram/QR (`hash://` and `https://www.hashforgamers.com/…`), a checker for existing links, and the full destination catalog with which links actually open a screen today.

Pushes use the same payload as `functions/index.js` (`deep_link` or `route` in `data`, plus `campaign_id`), so the app's `PushRouter` handles them and logs `notification_opened` with that `campaign_id` in Firebase Analytics.

Setup:

- Set `ANTHROPIC_API_KEY` in `.env.local` for the AI copywriter.
- The service account needs Firebase Cloud Messaging send rights and Firestore write access (`push_campaigns`).
- Scheduled campaigns are sent by the `dispatchScheduledPushCampaigns` Cloud Function (every 5 minutes): `cd functions && npm run deploy`.
- The destination catalog lives in `lib/deeplinks.ts` and mirrors `lib/core/service/deeplink_service.dart`; update `opens` when the app gains a screen. Self-check: `node --experimental-strip-types lib/deeplinks.check.ts`.
