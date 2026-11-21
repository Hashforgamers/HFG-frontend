# Hash Arcade integration

The game talks to its host only through `HashArcadeAdapter` (`src/integration/HashArcadeAdapter.ts`):

```ts
getPlayer() · startSession() · submitScore() · getLeaderboard() · getRewardEligibility() · track() · haptic()
```

`createAdapter()` picks an implementation at start-up:

| Environment | Adapter | Behaviour |
| --- | --- | --- |
| Hash app WebView (`window.flutter_inappwebview` present) | `FlutterBridgeAdapter` | Uses only the handlers `game_web_view.dart` registers today: `gameScore`, `analytics`, `haptic`. |
| Anything else | `MockAdapter` | Guest player, in-memory scores, sample leaderboard. No account value. |

## What is sent
- `gameScore` — after every **win**: `{ score, runId, level, levelScore, stars, durationMs, enemiesKilled, peakArmy,
  gateActivations, unitsLost }`. `score` is the career score. `runId` is unique per run (the bridge de-duplicates on it).
  If the call fails the submission is kept in the save and retried on the next launch.
- `analytics` — `{ event: 'hash_rush_<name>', params }` for `game_open, game_start, level_start, gate_activated,
  enemy_defeated, boss_defeated, level_complete, level_failed, upgrade_purchased, game_exit`.
  `gate_activated` fires once per gate and `enemy_defeated` is batched (a count every ~5 s), so analytics never runs
  per kill or per frame. **The app currently forwards WebView analytics for Super Over only** — these are dropped until
  `_registerAnalyticsHandler` is extended.
- `haptic` — `'light' | 'medium' | 'heavy'`.
- `coinContinue` — `{ quote: true }` → `{ cost }` (0 = not sold); `{ quote: false }` → `{ ok }` after the app has
  debited the player through `MiniGameCoins.spend`. The price is a constant in the app; the page cannot name an
  amount, and the handler only ever sells the calling game's own continue. Added to `game_web_view.dart` for Hash Rush.
- `coinShop` — `{ action: 'catalog' }` → `{ balance, upgrades: { id: [price per level] }, skins: { id: price } }`;
  `{ action: 'buy', kind: 'upgrade', id, level }` or `{ action: 'buy', kind: 'skin', slot, id }` → `{ ok, balance }`
  after the app has debited the player. Prices live in the app (`HashRushShop`); the page only names the item. What the
  player owns is still stored in the page's save, so the `level` in a buy request is the page's own claim.

No token, user id or secret ever enters the page; the app attaches the signed-in user when it records the score.
`getLeaderboard()` returns `null` in the app (no such handler exists), and the game points players at Hash Arcade's board.

## Trust
Everything above is a claim from an untrusted client. `MiniGameScoreService.recordScore` currently grants HashCoins
(daily play reward, rank rewards) off the submitted score, with only a `maxScore` ceiling in front of it.
**Before Hash Rush is listed with rewards on, the score needs server-side validation** — e.g. a server-issued session
token at `startSession`, plausibility checks on `durationMs` / `levelScore` / the proof fields (a level cannot be won in
under ~35 s or score above 20,000), and the reward decided by the server. `SessionInfo.token` and `ScoreSubmission.proof`
exist for that.

## Listing in the app — done (12 Oct 2026)
- `pubspec.yaml` bundles `assets/html_games/hash_rush/` (+ `app/`, `models/`).
- `HtmlMiniGameCatalogService` lists `hash_rush` (`maxScore: 800000`, `landscape: false`) and adds it to `supportedGameIds`.
- `HtmlMiniGame.landscape` is new: the player screen used to force landscape for every HTML game; Hash Rush plays in portrait.
- Thumbnail: `assets/mini_game_icons/hash_rush.png` (a crop of the menu screen — replace with real key art).
- Inside the app the game adds the `in-app` class to its stage, which moves its top-left controls clear of the app's back button.

Rewards are therefore **live**: a submitted career score goes through `MiniGameScoreService.recordScore` like any other
arcade game. The validation gap described under *Trust* is still open.
