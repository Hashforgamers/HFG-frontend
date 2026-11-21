# Backend: game-specific (GTA 6) app checkout

Status: requested by the Flutter app. The app already lets the customer pick a game-specific card (e.g. GTA 6 Premium) and shows a display estimate. It still charges standard slot pricing because the server does not price game-specific app bookings yet. This spec covers the server work needed to charge the card rate safely.

Builds on: `frontend-pricing-integration.md` (pricing endpoint, rule semantics) and `frontend-slot-availability.md`.

## Principle

The server decides the payable amount. The app sends *what* the customer chose (card profile + revision + slots + player count), never *how much* to charge. Any amount sent by the app is ignored.

## 1. Enable the channel

- Rate cards: allow `"app"` in `booking_channels` (dashboard rate-card editor toggle per card).
- Pricing response (`GET /api/games/vendor/{vendor_id}/pricing`): set `app_game_specific_booking_supported: true` once steps 2–4 are deployed. The app hides the game picker's paid flow while this is `false`.

## 2. Quote endpoint (server-side premium quote)

Extend `GET /api/bookings/pricing-estimate` (or add `POST /api/bookings/pricing-quote`, whichever is simpler):

Request (what the app will send):

```json
{
  "vendor_id": 112,
  "game_id": 10,
  "book_date": "2026-12-01",
  "pricing_profile": "gta6",
  "pricing_revision": 1,
  "player_count": 1,
  "selections": [
    { "console_index": 1, "slot_ids": [123, 124] },
    { "console_index": 2, "slot_ids": [123] }
  ]
}
```

`game_id` is the café platform row (`available_game_id`), not a catalog game ID.

Server logic:

1. Load the card by `(vendor_id, available_game_id, profile)`. Reject if missing, archived, inactive, or `"app"` not in `booking_channels` → `409 PRICING_CARD_UNAVAILABLE`.
2. If `pricing_revision` ≠ current revision → `409 PRICING_REVISION_CHANGED` with the current card in the body, so the app can re-show the price.
3. Per console: session minutes = sum of the selected slots' durations (handle slots crossing midnight).
4. Apply the existing dashboard rule engine: exactly one inclusive rule must match (minutes, players); `amount × players` if `per_player`; `× minutes / unit_minutes` if `unit_minutes ≠ 0`; round half-up to 2 decimals. No match → `422 NO_MATCHING_RULE` (no fallback to standard, same as the dashboard).
5. Order total = sum of console sessions, then existing squad/controller adjustments and offers if they apply to premium cards (please state which do), then app fee.

Response:

```json
{
  "success": true,
  "quote_id": "q_abc123",
  "expires_at": "2026-12-01T10:15:00+05:30",
  "pricing_profile": "gta6",
  "pricing_revision": 1,
  "lines": [
    { "console_index": 1, "minutes": 60, "amount": "250.00" },
    { "console_index": 2, "minutes": 30, "amount": "125.00" }
  ],
  "subtotal": "375.00",
  "app_fee_amount": "10.00",
  "payable_amount": "385.00",
  "currency": "INR"
}
```

Store the quote server-side (short TTL, e.g. 10 min), bound to the user, vendor, slots and revision.

## 3. Payment order from the quote

`POST /api/create_order` currently takes `amount` from the app. For premium bookings:

- Accept `quote_id` instead of `amount`, and create the Razorpay order for the stored `payable_amount`.
- Reject a request that sends both, or a `quote_id` that is expired, used, or owned by another user.
- Recommended: do the same for standard bookings later, so no client-chosen amounts remain.

## 4. Booking confirmation

`POST /api/bookings/confirm` with `quote_id` (+ Razorpay payment ids):

1. Verify the Razorpay signature and that the captured amount == the quote's `payable_amount`.
2. Re-check slot availability (same check as `getSlots`) inside the booking transaction; if slots were taken, refund/void and return `409 SLOTS_UNAVAILABLE`.
3. Persist on the booking: `pricing_type: "game_specific"`, `pricing_profile`, `pricing_revision`, per-console line amounts, and the final total. The dashboard, receipts and refunds must read these stored values, not re-price from current cards.
4. Mark the quote used (idempotent: a retried confirm with the same payment returns the same booking).

Pay-at-café: if allowed for premium cards, the same quote is attached to the booking with status unpaid; the dashboard collects the stored amount.

## 5. Errors the app will handle

| Code | App behaviour |
|------|---------------|
| `PRICING_CARD_UNAVAILABLE` | Drop the card, return to the game picker |
| `PRICING_REVISION_CHANGED` | Show the new price, ask the customer to confirm |
| `NO_MATCHING_RULE` | "No rate for this duration, choose another" |
| `SLOTS_UNAVAILABLE` | Refresh slots, ask the customer to choose again |
| `QUOTE_EXPIRED` | Re-quote silently and show the price again if it changed |
| HTTP 503 | "Pricing unavailable" with retry; never treat as ₹0 |

## 6. Acceptance checks

1. GTA 6 card at ₹250/hr, 1 console × 60 min → quote 250 + app fee; Razorpay order and stored booking match.
2. Tampered app sends `amount: 1` → ignored; order uses the quote.
3. Card edited in the dashboard after the quote (revision 2) → confirm with revision 1 is rejected.
4. Card archived, or `"app"` removed from channels → quote rejected.
5. Duration outside every rule → `NO_MATCHING_RULE`, no standard fallback.
6. Two customers race for the last console → one booking succeeds, the other gets `SLOTS_UNAVAILABLE` and is refunded.
7. Standard bookings (no `pricing_profile`) behave exactly as today.
8. Vendor isolation: a profile from café A cannot be quoted for café B.

## App work once deployed (for reference)

The app already sends `pricing_profile` and `pricing_revision` with each selected slot. Remaining: call the quote endpoint on the summary screen, show `payable_amount`, pass `quote_id` to create-order and confirm, and handle the errors above. Gated on `app_game_specific_booking_supported == true`.
