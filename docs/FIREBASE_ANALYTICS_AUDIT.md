# Firebase Analytics: esports lifecycle

## Architecture and privacy rules

`AnalyticsService` is the only Firebase entry point for the new lifecycle. It
removes null/empty parameters, blocks known PII keys, normalizes booleans, owns
user identity/properties, and provides the shared `FirebaseAnalyticsObserver`.
All three app entry points install that observer, so GA4 receives readable GetX
route names such as `/login`, `/tournaments`, and `/tournament-detail` instead
of relying on Android/iOS native activity or view-controller names.

Events are emitted from controller callbacks or `initState`, never `build`.
Screen/view events use a session deduplication key. Mutation success events are
emitted only after the API or payment-verification response succeeds.

Never add email, phone/mobile, full name, address, government ID, or UPI ID to
an analytics payload. The central guard is defense in depth, not permission to
pass those values at call sites.

## Event map

| Event | Trigger | Parameters |
| --- | --- | --- |
| `onboarding_started` | `OnboardingScreen.initState` | `source_screen` |
| `game_selected` | Game card tap | `game_id`, `game_name`, `source_screen` |
| `city_selected` | Arena resolves the user's selected/current city | `city`, `source_screen` |
| `sign_up` | Backend signup completion through `FbEventsService.onSignupCompleted` | `method`, `source_screen` |
| `login` | Successful Firebase authentication through `FbEventsService.onLoginSuccess` | `method`, `source_screen` |
| `tournament_list_viewed` | Community list API succeeds | `tournament_mode`, `participant_count`, `source_screen` |
| `tournament_viewed` | Community detail and registration state load | tournament context below |
| `tournament_join_started` | Valid registration CTA submission | tournament context below |
| `team_created` | Team creation API returns a team ID | tournament context below |
| `free_agent_selected` | Reserved for free-agent selection confirmation | tournament context below |
| `payment_started` | Paid tournament opens Razorpay | tournament context below |
| `payment_success` | Backend payment verification reports paid and confirmed | tournament context below |
| `payment_failed` | Checkout cancellation, timeout, initialization, or network failure | tournament context, `failure_reason` |
| `tournament_joined` | Backend confirms free registration or paid registration settlement | tournament context below |
| `match_checked_in` | Host check-in mutation succeeds | tournament context below |
| `result_viewed` | Completed tournament detail renders result/match data | tournament context below |
| `host_verification_started` | Host onboarding controller initializes | `source_screen` |
| `host_verification_submitted` | Verification API succeeds | `source_screen`, `host_verified` |
| `tournament_created` | Create tournament API succeeds | tournament context below |
| `tournament_published` | Create-and-publish or management publish API succeeds | tournament context below |

Tournament context is included when the model/API provides it:
`tournament_id`, `game_id`, `game_name`, `tournament_mode`, `city`,
`entry_fee`, `prize_pool`, `host_id`, `host_verified`, `team_status`,
`participant_count`, `slots_remaining`, and `source_screen`. Null values are
removed centrally. Registration screens currently use their legacy aggregate
model, which does not expose `host_verified` or a canonical city.

Normalized payment failure reasons are: `user_cancelled`, `timeout`,
`network_error`, `payment_declined`, `insufficient_funds`,
`confirmation_failed`, and `unknown`.

## User identity and properties

Firebase user ID is set only from a successful authentication callback. The
supported properties are `primary_game`, `user_role`, `city`, `skill_tier`,
`app_language`, and `acquisition_source`. Current app data populates primary
game after a game selection, city after location selection, role after login or
host verification, and language after login. `skill_tier` and
`acquisition_source` require authoritative profile/attribution data.

## Recommended GA4 key events

Configure `sign_up`, `tournament_joined`, `payment_success`,
`host_verification_submitted`, `tournament_created`, and
`tournament_published` as key events. Keep `login` as a key event only if the
team uses repeat authentication as its retention proxy; normal app opens are a
better repeat-usage measure.

## DebugView validation

1. Enable Analytics debug mode on the test device: Android with
   `adb shell setprop debug.firebase.analytics.app <application-id>`; iOS by
   adding `-FIRDebugEnabled` to the Runner scheme launch arguments.
2. Run the same flavor/project whose Firebase console you will inspect.
3. Open Firebase Console > Analytics > DebugView and select the device.
4. Exercise this order: first open, onboarding, login/signup, game/city,
   tournament list/detail, join, payment, registration confirmation, check-in,
   result, host verification, create, publish.
5. Open each event and verify readable `firebase_screen` values, required
   tournament context, normalized failures, and the absence of null/PII fields.
6. Repeat navigation and rebuild/rotate screens; deduplicated view events must
   appear once per logical screen/context while explicit CTA attempts may recur.
7. Disable debug mode afterward with Android's `.none.` property or remove the
   iOS launch argument.

## Audit report

Retained: existing Segment/Meta product events and non-tournament Firebase
events remain for compatibility. Existing Firebase event names are normalized
by the legacy adapter and now have PII keys stripped before both Firebase and
Meta dispatch.

Removed or corrected: automatic game-list loading no longer reports game
preferences; game selection is tied to a user tap. New tournament success
events are not emitted before API/payment confirmation. Route observation is
configured identically in `main.dart`, `main_dev.dart`, and `main_prod.dart`.

Newly instrumented: onboarding, game and city selection, authentication,
Community discovery/detail, join/payment/registration, team creation, completed
result view, host onboarding/submission, tournament creation/publishing, and
host-operated participant check-in.

Backend/product gaps: Community team registration/free-agent selection is not
supported, so `free_agent_selected` has no honest trigger yet. Participant
self-check-in has no app/API action; current `match_checked_in` represents the
confirmed host roster mutation. Canonical game ID, tournament city,
`host_verified`, `skill_tier`, acquisition attribution, and consistent capacity
fields must be added to backend/profile responses to populate them everywhere.
