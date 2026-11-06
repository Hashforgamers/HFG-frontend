# HASH RUSH

3D crowd shooter / multiplier runner for Hash Arcade. TypeScript + Three.js + Vite, no game engine, no physics engine.

```bash
npm install
npm run dev        # http://localhost:5183  (add ?debug for the profiler overlay)
npm test           # 90 unit + headless-playthrough tests
npm run balance    # prints the 30-level progression table (scripted bots)
npm run build      # typecheck + bundle into ../../assets/html_games/hash_rush
npm run assets     # regenerate the GLB models with Blender (tools/build_assets.py)
```

## Layout

| Path | What |
| --- | --- |
| `src/gameplay/` | The whole game as a deterministic 60 Hz simulation. No Three.js, no DOM — this is what the tests run. |
| `src/levels/` | Level data: 5 handcrafted levels, a seeded generator for 6–30, a validator. |
| `src/rendering/` | Views that read simulation state: instanced crowds, worlds, gates, traps, bosses, particles, camera. |
| `src/core/` | Game orchestration, fixed-step loop, save data, asset loading. |
| `src/ui/` | DOM/CSS screens and HUD. |
| `src/audio/` | Web Audio synthesiser (SFX + step-sequenced music). |
| `src/integration/` | `HashArcadeAdapter` interface, the Hash app WebView adapter, the mock adapter. |
| `src/optimization/` | Object pool, adaptive quality manager. |
| `tools/build_assets.py` | Blender script that builds every model in `public/models/`. |
| `docs/` | Gameplay rules, integration, testing, unfinished work. |

## Deploying

`npm run build` writes a static site (`index.html`, `app/`, `models/`, ~1.4 MB, ~0.5 MB gzipped) with relative
URLs. It runs from any static host or sub-path, and from the Hash app's loopback asset server.
It is listed in the Hash app's arcade (see `docs/INTEGRATION.md`); re-run `npm run build` before building the app to pick up changes.
