# Testing

## Automated (`npm test` — 90 tests, all passing at hand-off)
`tests/gameplay.test.ts`, `tests/progression.test.ts`, `tests/features.test.ts` (bad gates, skins, endless, continue), `tests/balance.report.test.ts`. They run the real simulation in Node.

| Area | Covered |
| --- | --- |
| Gate multiplication | every ×k and +n value; strength-weighted multiply; additive cooldown; each unit doubled exactly once in a live run; ×100 hitting the population cap and reporting the clipped amount |
| Crowd count | count = Σ strength; agent budget never exceeded with 5,000 units; slot reuse |
| Damage | unit/enemy formulas; pooled HP losing whole units; pod direct hit vs deploy; pod pool exhaustion; barrel radii; boss shield |
| Traps | bridge, falling platform, laser timing, crusher warning order |
| Upgrades | every upgrade changes its stat; monotonic values and costs; clamping; effect inside a real run |
| Level progression | 30 levels validate; worlds/bosses of levels 1–5; every trap, enemy and gate value appears; determinism; unlock rules; rewards; career score |
| Save / load | round trip; missing, corrupt and tampered data; storage failure; reload mid-run |
| Win / loss | scripted win; scripted loss; zero units ≠ loss; finished run is frozen; determinism; boss overload ends stalemates |
| Edge cases | ±1e6 / NaN / Infinity input; 20 Hz steps (low frame rate); loop catch-up cap after a 5 s stall; bounded event queue; network failure and duplicate submissions (mock adapter); adaptive-quality step-down and recovery |

`npm run balance` plays all 30 levels with three scripted players. Current result: the "good" bot (picks the better
gate, lines up with bridges, dodges boss shots, but never dodges walls, blades, crushers or lasers) wins 29/30 with
expected upgrades; level 28 is the exception. The test asserts levels 1–5 are won and ≥ 85 % overall.

## Browser checks performed (Chromium, 375×812 emulation and 1280×760)
Driven through the real UI and `window.__hashRush.debug`:
- boot with no console errors from the dev server **and** from the production build served as static files;
- levels 1–5 played, level 1 to the victory screen; reward applied and persisted;
- real pointer drag steers; arrow keys and Space (Overdrive) work; `pointercancel` ends a drag without moving the cannon;
- hiding the tab pauses the run and freezes the simulation; returning leaves it paused; Esc and the pause button work;
- level select lock state, upgrade purchase (+ localStorage), settings toggles, quality switch at runtime, mock leaderboard;
- portrait column with side panels on a wide window.

## Device check — Samsung Galaxy S20 FE (SM-G781B), 12 Oct 2026
- Chrome on the phone (dev server over `adb reverse`): 57–60 fps at the medium preset with bloom, 113–201 agents on
  screen, 65–94 draw calls, 71k–100k triangles, 14 MB JS heap, models loaded in 65–96 ms.
- Inside the Hash app (dev debug build, in-app WebView): launches from the arcade row in portrait, full screen;
  played through level 1 and into the level 2 boss fight.

## Still not tested
iPhone Safari, desktop Safari/Edge, low-end Android, and any device other than the one above. Audio was not
auditioned by me. Notch/safe-area insets on iOS, orientation change, audio interruption by a call, GPU frame time and
long-session memory growth are unverified. The numbers below are from the automation browser, which throttles
rendering, and say nothing about a phone:
43–89 draw calls, 9k–142k triangles (low preset, 316 instances), 13–19 MB JS heap.

`?debug` shows fps, frame ms, draw calls, triangles, instance and particle counts, quality level, resolution scale and
heap — use it for further device passes.
