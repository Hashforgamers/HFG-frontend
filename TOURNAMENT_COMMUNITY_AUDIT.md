# Tournament Community implementation audit

Audit date: 2026-07-25

Scope traced: `lib/app/modules/community`, its GetX routes, the shared
`tournaments_section` registration Cubit/payment service, notification/deep-link
services, analytics services, and existing tests.

The repository contains two tournament implementations:

1. `app/modules/tournaments_section` is the established cafe/event experience.
2. `app/modules/community` is a newer GetX community-hosted tournament module.

The community detail screen deliberately adapts a community tournament into the
older registration UI. This is currently the only connection between the two
state-management paths.

## Implementation matrix

| Lifecycle area | Existing files | Current status | Missing frontend | Missing backend | Action |
|---|---|---|---|---|---|
| Host program | `host_onboarding_*`, `host_program.dart` | Partially implemented | Full status history and safe draft restore | Verification history/config version | Preserve current program API; extend typed states |
| Host verification | `host_verification_*`, `verification_checkout_*` | Partially implemented | Real private upload with progress/retry; review screen | Secure upload, resubmit, suspend/reactivate, fee-specific order/recovery | Keep current flow; do not expose document URL |
| Discovery | `tournaments_*` | Partially implemented | Live/completed/my-registration facets, filter persistence | Stable cursor/page contract | Existing pagination retained |
| Detail | `tournament_detail_*` | Partially implemented | Host profile, participants, bracket, reviews, precise registration CTA | Detail aggregates and current-user registration | Central status parsing added |
| Draft/create/edit | `create_tournament_*` | Partially implemented | Team size, visibility code, check-in/roster lock, evidence, banner upload, field errors, local draft restore | Readiness endpoint and restricted-edit policy | Existing server fields preserved |
| Free solo registration | shared `tournaments_register_*` + `CommunityApi` | Partially implemented | Invite/eligibility preflight and cancellation policy | Eligibility/status endpoint | Existing confirmed-server check retained |
| Paid registration | `tournament_payment_service.dart`, registration Cubit | Broken | Safe pending-order recovery UI | Tournament-owned create/reuse-order endpoint and status reconciliation | Do not rely on current booking order path for production |
| Teams/rosters | shared cafe UI; E2E contract team endpoints | API only | Player create/invite UX and full roster editor | Existing at pinned backend commit; deployment unverified | Typed clients/models added; host team inbox connected |
| Brackets/schedule | E2E contract match generation/list/leaderboard | API only | Dedicated bracket renderer and participant highlighting | Existing at pinned backend commit; deployment unverified | Typed clients/models and host schedule tab added |
| Match operation | generic result list plus E2E match endpoints | Partially implemented | Match detail, lobby editor, captain submission and evidence upload | Existing at pinned backend commit; deployment unverified | Typed match operations client added |
| Disputes | `Dispute`, create/list/admin API methods | API only | Player submission and timeline; authorized resolution UI | Structured resolution and duplicate guard | Blocked |
| Completion | verified result → winners in manager | Partially implemented | Final standings review | Readiness and winner completion exist in pinned contract | Readiness gate connected; sends documented `amount: 0` for backend calculation |
| Prizes/commission | `Payout` and tournament summary numbers | API only | Separate player-prize/commission/refund presentation | Separate ledgers/status APIs | Blocked |
| Cancellation/refunds | tournament cancel and registration delete | API only | Quote/consequence/refund tracking | Cancellation quote + idempotent refund APIs | Blocked |
| Reviews/reputation | E2E review/profile endpoints | API only | Review form and organizer profile presentation | Existing at pinned backend commit; deployment unverified | Typed API methods added |
| Notifications/deep links | generic notification and legacy invite link | Partially implemented | Community resource router and deleted-resource state | Stable typed payloads | Blocked |
| Permissions | `can_manage` plus host status checks | Partially implemented | Current-user roles/capabilities from a trusted response | Resource capabilities or role claims | Central pure capability model added |
| Analytics | existing Segment/Facebook abstractions; join events | Partially implemented | Lifecycle events without sensitive data | None required | Reuse existing abstractions |
| Admin | admin-token methods in mobile client | Broken | No privileged credential flow should exist in production mobile UI | Proper admin JWT/RBAC | Remove/disable once backend migration is agreed |
| Tests | one room-details model test | Missing | Model, permission, validation, state and widget coverage | Stable fixtures/contracts | Foundational unit tests added |

## Confirmed contract and safety conflicts

- The community base URL is hard-coded to production because the dev service
  returns 404. This means a dev-flavor app can mutate production community data.
- `CommunityApi` constructs a bare authenticated `Dio`, bypassing the standard
  timing/retry/auth interceptor setup. This was done to avoid a stale-token
  overwrite, but it is still a parallel networking path that should be resolved
  in the shared interceptor.
- Community paid registration creates an order through
  `/api/create_order` on the booking service using an amount derived from UI
  text. The authoritative tournament service must create/reuse the order from
  its own entry-fee record.
- Community team registration still throws “not supported yet” in the shared
  registration Cubit even though the pinned backend contract contains team and
  roster endpoints. The new community clients are now available, but the player
  creation/invitation UI remains to be connected.
- Tournament amounts are represented as `double`. Migration to integer minor
  units requires a backend contract/version because changing current fields
  silently would break existing payloads.
- Host/admin review methods accept an `X-Admin-Token` in the Flutter process.
  No admin secret should be shipped to a client application.
- The pinned contract defines winner `amount: 0` as an explicit instruction for
  the backend to calculate from its authoritative prize distribution. The
  manager never calculates payout amounts locally.
- The current result model is tournament-level, not match-level, and therefore
  cannot safely drive brackets or opponent confirmation.

## Existing validation baseline

Before changes, scoped static analysis compiled with 42 informational lints and
no errors. The working tree already contained unrelated staged deletions under
`android/build`; they were not modified.
