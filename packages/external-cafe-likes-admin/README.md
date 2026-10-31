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
