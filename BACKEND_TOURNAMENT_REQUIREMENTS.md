# Backend requirements: Tournament Community

This handover is based on the frontend audit in
`TOURNAMENT_COMMUNITY_AUDIT.md`, not on a hypothetical greenfield API.

Current base route: `https://hfg-user-onboard.onrender.com/api/v1/community`.
The dev user-onboard deployment reportedly returns 404 for this module. A
flavor-aware staging deployment is required before production release.

## Existing envelope and migration

The client currently consumes inconsistent shapes: direct objects, `items` plus
`pagination`, `verification`, and `data`. Preserve these during migration.
New/versioned endpoints should return:

```json
{"success":true,"data":{},"message":"Done","requestId":"req_123"}
```

Validation failures should return HTTP 422:

```json
{
  "success":false,
  "code":"VALIDATION_ERROR",
  "message":"Please correct the highlighted fields.",
  "fieldErrors":{"registrationCloseAt":"Must be before tournament start."},
  "requestId":"req_123"
}
```

Every mutation should accept `Idempotency-Key`, echo a `requestId`, use UTC ISO
8601 server timestamps, and return the current authoritative resource.

## Authentication and authorization

Existing: bearer JWT for user routes; `X-Admin-Token` for two admin methods.
Current consumers: `community_api.dart`.

Required:

- `GET /me/capabilities`: authenticated; returns user id, roles
  (`player`, `captain`, `verified_host`, `suspended_host`, `admin`), host status,
  and JWT expiry. Never put privileged admin secrets in Flutter.
- Resource responses should include explicit capabilities such as
  `can_manage`, `can_register`, and denial code where appropriate.
- Return 401 for absent/expired identity and 403 for an authenticated but
  unauthorized identity. Support refresh through the application's shared auth
  contract.
- Enforce suspended-host restrictions server-side for create, publish, match
  operation, completion, and commission changes.

## Endpoint inventory and required contracts

All amounts below are integer minor units with `currency: "INR"`. Existing
decimal fields must remain available until clients migrate.

### Host verification

| Feature | Status / existing endpoint | Required contract |
|---|---|---|
| Program config | Existing `GET /hosts/program`, public | Include fee minor units, config version, eligibility and terms version |
| Current status | Existing `GET /hosts/me/verification`, auth | Include full safe status, rejection/suspension reason, masked payout value and timestamps; never return government-document URL |
| Submit | Existing `POST /hosts/verification`, auth | Validate identity/contact/address/UPI and private asset id; idempotent; return 422 field errors |
| Private upload | Missing | `POST /uploads/intents`, auth; purpose `government_id`; MIME/size policy and signed upload; private object |
| Fee order | Missing | `POST /hosts/verification/payment-order`, auth; create/reuse backend-priced order |
| Fee verify/recover | Incomplete generic `/api/payments/verify` | `POST /hosts/verification/payment-verify`; `GET /hosts/verification/payment`; signature/order/amount verification and webhook reconciliation |
| Resubmit | Missing | `POST /hosts/verification/resubmit`, rejected host; retain immutable audit history |
| Admin lifecycle | Incomplete `PATCH /admin/hosts/{id}/verification` | Admin JWT/RBAC: approve/reject/suspend/reactivate with required reason and audit actor |

### Tournament CRUD and discovery

Existing: `GET /tournaments`, `GET /tournaments/public/{id}`,
`GET/PATCH /tournaments/{id}`, `POST /tournaments`,
`POST /tournaments/{id}/cancel`, `GET /me/tournaments`.

Required additions:

- `GET /tournaments/{id}/draft`, `POST /tournaments/{id}/validate`, and
  `POST /tournaments/{id}/publish`.
- Validation/publish body includes draft version; response includes field
  errors and authoritative computed financial summary.
- Optimistic concurrency via `version`/`If-Match`. Return 409
  `RESOURCE_VERSION_CONFLICT`.
- Detail must include organizer summary, current-user registration, invite
  requirement, capacity, team rules, check-in/roster times, evidence policy,
  cancellation policy, and capabilities.
- Discovery supports cursor or current page/per-page shape consistently,
  filters for lifecycle/game/fee, and stable sort.
- Published edits must be field allow-listed. Reject financial changes after a
  paid registration unless an explicit backend workflow allows them.
- Cancellation requires a preview endpoint:
  `POST /tournaments/{id}/cancellation-quote`, then idempotent
  `POST /tournaments/{id}/cancel`; atomically creates affected refunds.

Current consumers: create, discovery, detail, dashboard, my-tournaments and
manager controllers under `lib/app/modules/community`.

### Invite, registration and Razorpay

Existing: `POST /tournaments/{id}/registrations`,
`DELETE /tournaments/{id}/registrations/me`, host list/update registration.

Required:

- `POST /tournaments/{id}/invite/validate`: auth; body `{code}`; does not consume
  the invite.
- `GET /tournaments/{id}/registration-eligibility`: auth; returns eligible,
  stable denial code, capacity/waitlist and team requirements.
- `POST /tournaments/{id}/registrations`: auth and idempotent; free registration
  confirms atomically or waitlists. Unique `(tournament_id,user_id)`.
- `POST /registrations/{id}/payment-order`: auth owner; create or reuse an
  order priced exclusively from the stored tournament/registration. Response:
  `{registrationId,orderId,keyId,amountMinor,currency,status,reusableUntil}`.
- `POST /registrations/{id}/payment-verify`: body contains Razorpay payment id,
  order id and signature; server verifies signature, amount, currency,
  registration ownership, and replay. Atomically confirms capacity and
  registration or initiates refund when capacity was lost.
- `GET /registrations/{id}/payment-status`: recovery after callback/app loss.
- `POST /registrations/{id}/cancellation-quote` and idempotent
  `POST /registrations/{id}/cancel`.

Webhook handling must tolerate out-of-order/duplicate callbacks. Unique provider
order/payment ids and idempotency records prevent duplicate charge,
confirmation, or replay. The current frontend's booking-service order creation
must be retired for community tournaments after these endpoints ship.

### Teams and rosters

Status: present in backend commit
`fca76b77d262e4898236c45b13c933890c3e0fa3`; deployment compatibility remains
to be verified. The current shared frontend registration Cubit still blocks
community team mode.

Required authenticated routes:

- `POST /tournaments/{id}/teams`, `PATCH /teams/{id}`
- `POST /teams/{id}/invitations`, `GET /me/team-invitations`
- `POST /team-invitations/{id}/accept|reject`
- `DELETE /teams/{id}/members/{userId}`, `POST /teams/{id}/leave`
- `POST /teams/{id}/captain-transfer` if supported
- `POST /teams/{id}/submit`, host `POST /teams/{id}/approve|reject|request-info`
- `POST /teams/{id}/check-in` and optional member check-in

Responses include captain/members/substitutes, invite expiry, required/maximum
size, completeness, approval, roster-lock/check-in state and seed. Use unique
membership per tournament, invitation uniqueness, row/version locks for
simultaneous changes, and transactionally reject edits when roster lock occurs.

### Brackets, schedules and matches

Status: present in the pinned backend contract. Do not derive authoritative
advancement in Flutter.

- `POST /tournaments/{id}/schedule/generate` for supported format only;
  `POST /tournaments/{id}/schedule/publish`; admin/host authorized.
- `GET /tournaments/{id}/bracket`, `/schedule`, `/standings`, `/rounds`.
- Return `version`/`updatedAt`, rounds, fixtures, participants, status,
  reschedule reason and server-authoritative advancement.
- Match routes: `GET /matches/{id}`, `POST /matches/{id}/lobby`,
  `/start`, `/reschedule`, `/results`, `/results/{id}/confirm|contest`,
  host `/review`, and `/complete`.
- Lobby credentials are returned only to eligible participants during the
  release window.
- Result body supports winner, score, placement, kills, penalties and private
  evidence asset ids as format permits. Enforce deadline and one active
  submission per party. Use a transaction for verification, match completion,
  advancement and leaderboard update.

### Disputes

Existing incomplete: create/list tournament disputes and admin status patch.

Required:

- `POST /matches/{id}/disputes`, eligible party, structured reason,
  explanation and private evidence; unique active `(match, reporter, reason)`.
- `GET /disputes/{id}` and paginated tournament/admin queues.
- `POST /disputes/{id}/resolve`, authorized role; resolution enum:
  retain, override, rematch, penalty, disqualify, reject; reason required.
- Resolution transaction locks result/match, updates bracket/leaderboard and
  keeps an immutable audit timeline.

### Completion and financial ledger

Status: incomplete winner submission and generic payout list.

- `GET /tournaments/{id}/completion-readiness`: incomplete matches, open
  disputes, standings version and validation issues.
- `POST /tournaments/{id}/complete`: idempotent, expected standings version and
  optional final winners. Transactionally freezes standings, completes the
  tournament, and creates prize/commission records exactly once.
- Separate APIs/resources: `entryPayments`, `refunds`, `playerPrizes`,
  `organizerCommissions`. Never return one ambiguous transaction type.
- Each record: id, amount minor, currency, status
  (`queued`,`under_review`,`approved`,`processing`,`paid`,`failed`,`cancelled`),
  safe provider reference, internal reference, recipient, tournament,
  registration where applicable, timestamps and failure reason.
- `GET /tournaments/{id}/financial-summary` returns authoritative registration
  revenue, refund deductions, prize pool, platform deductions and commission.
- Admin JWT/RBAC endpoints approve/process/retry payouts; reconciliation jobs
  and unique ledger keys prevent double settlement.
- If settlement is an internal wallet credit, respond with
  `settlementMethod:"wallet_credit"`; never label it bank/UPI paid.

### Refunds

Required quote and create routes described above, plus `GET /refunds/{id}`.
The backend calculates eligibility and amount, calls Razorpay, reconciles
webhooks, updates registration and prize-pool summary transactionally, and
supports tournament-cancellation batches. Duplicate requests return the
original refund. Partial-refund policy must be explicit server config.

### Reviews and reputation

Status: present in the pinned backend contract: one review per confirmed
participant after completion and a public organizer profile.

- `GET /tournaments/{id}/review-eligibility`
- `POST /tournaments/{id}/reviews`, unique eligible participant/tournament
- `GET /hosts/{id}` and paginated `/hosts/{id}/reviews|tournaments`

Return aggregate rating/count, hosting statistics, completed history and public
review fields. Define whether edits are allowed and provide abuse reporting.

### Notifications and deep links

Every event payload must include `type`, stable `tournamentId`, and relevant
`teamId`, `matchId`, `disputeId`, `registrationId`, `paymentId`, `refundId`, or
`payoutId`. Required types cover host verification, publish/cancel,
registration/payment/refund, invitations/roster/check-in, lobby/schedule,
results/disputes, completion and prize/commission. The referenced GET endpoint
must return 404/410 cleanly so the app can show “no longer available”.

### Upload security

Use signed upload intents. Public: tournament banners after moderation. Private:
government IDs, result/dispute evidence and lobby material. Configure explicit
MIME allow-lists, file-size limits, checksum, malware/content scanning,
authorization-scoped signed downloads, expiry, deletion and retention policy.
Never persist unrestricted public URLs for government IDs or dispute evidence.

## Concurrency and state transitions

Use database transactions, unique constraints, state-transition validation and
idempotency records for:

- capacity reservation versus simultaneous registration/payment;
- duplicate/out-of-order payment and refund callbacks;
- simultaneous roster changes and roster lock;
- competing result submissions and dispute resolution;
- completion versus an open dispute;
- prize/commission generation.

Return 409 with a stable machine code and current resource/version when a race
is lost.

## Required stable error codes

`AUTH_REQUIRED`, `TOKEN_EXPIRED`, `FORBIDDEN`, `HOST_NOT_VERIFIED`,
`HOST_SUSPENDED`, `TOURNAMENT_NOT_FOUND`, `INVALID_TOURNAMENT_STATE`,
`REGISTRATION_NOT_OPEN`, `REGISTRATION_CLOSED`, `CAPACITY_REACHED`,
`ALREADY_REGISTERED`, `INVALID_INVITE_CODE`, `PAYMENT_REQUIRED`,
`PAYMENT_PENDING`, `PAYMENT_VERIFICATION_FAILED`, `TEAM_INCOMPLETE`,
`ALREADY_IN_TOURNAMENT_TEAM`, `ROSTER_LOCKED`, `CHECK_IN_NOT_OPEN`,
`VALIDATION_ERROR`, `RESOURCE_VERSION_CONFLICT`, `DUPLICATE_SUBMISSION`,
`DISPUTE_DEADLINE_PASSED`, `REFUND_NOT_ELIGIBLE`.
