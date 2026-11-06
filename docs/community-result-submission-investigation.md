# Community result submission investigation

## Observed failure

The app logged this backend response while submitting a player/captain result:

```text
POST /api/v1/community/tournaments/{tournament_id}/matches/{match_id}/result-submissions
HTTP 409 Conflict
{ "error": "conflict", "message": "results can be submitted only after the match starts" }
```

This is not a Firebase Storage/evidence-upload error. The request reached the
Community backend and was rejected by the match-lifecycle guard.

## E2E contract implemented by HFG

| Actor | Endpoint | Payload |
| --- | --- | --- |
| Captain/player | `POST /tournaments/{tournament_id}/matches/{match_id}/result-submissions` | `winner_team_id`, `team_a_score`, `team_b_score`, optional `evidence_asset_ids`, `notes` |
| Host | `POST /tournaments/{tournament_id}/matches/{match_id}/result-proposals` | `winner_team_id`, `team_a_score`, `team_b_score`, optional `evidence_asset_ids`, `evidence_urls`, `ocr_data` |

The host proposal workflow is recorded in the repository history as commit
`44a76dd` (`fix: submit host results through proposal workflow`). The app's
captain submission client is in
`lib/app/modules/community/controllers/tournament_detail_controller.dart`,
and the host workflow is in
`lib/app/modules/community/controllers/manage_tournament_controller.dart`.

## Why submission currently fails

The E2E contract requires the host to explicitly start a match first:

```text
PATCH /tournaments/{tournament_id}/matches/{match_id}
{ "action": "start" }
```

Only after that transition can a captain submit through
`result-submissions`, or a host create a `result-proposals` review.

The API is the authority for whether a match has transitioned to the state
that permits result submission. The observed `409` says that transition had
not happened for the target match.

The HFG host management screen already contains **Start match**, which invokes
the required `PATCH ... { "action": "start" }` request. Start the individual
match there, wait for the match status to become `in_progress`/`live`, then
submit the captain result or host proposal. A passed scheduled time alone is
not sufficient.

## Question for the Community backend team

Please confirm the lifecycle rules for a match result submission:

1. Which `match.status` values permit `POST .../result-submissions`?
2. Which endpoint/action transitions a scheduled match to that eligible state?
   Is it host-only `PATCH /tournaments/{tournament_id}/matches/{match_id}`
   with an action such as `start`, or does the tournament `start` endpoint
   transition all matches automatically?
3. Does the API require the caller to be the registered team captain, and how
   is that role verified for Community teams?
4. For a host, should the app use only `result-proposals`; for a captain,
   should it use only `result-submissions`?
5. Please provide an example of a successful response and the minimum valid
   preconditions for both endpoints.

## Suggested diagnostic response from backend

For a rejected request, return the current match status and the required next
action, for example:

```json
{
  "error": "conflict",
  "message": "results can be submitted only after the match starts",
  "match_status": "scheduled",
  "required_action": "host_start_match"
}
```

This allows the app to show a useful next step instead of a generic failure.
