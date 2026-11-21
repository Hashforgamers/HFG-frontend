# Road Rumble — bundled assets

| Path | Source | Licence |
|---|---|---|
| `../super_over/lib/**` | three.js r170, shared with Super Over | MIT |
| `../super_over/sky/kloofendal_puresky_1k.hdr` | "Kloofendal 48d Partly Cloudy (Pure Sky)" — https://polyhaven.com, shared with Super Over | CC0 |
| `tex/asphalt_track_*`, `tex/bark_brown_02_*`, `tex/coast_sand_01_*`, `tex/dirt_floor_*`, `tex/forest_ground_04_*`, `tex/rocks_ground_01_*` | Poly Haven textures of the same names (1k JPG; colour kept at 1024 px, normal and ARM maps reduced to 512 px) — https://polyhaven.com | CC0 |
| `models/rock_07.glb`, `models/rock_09.glb`, `models/rock_face_01.glb`, `models/shrub_03.glb` | Poly Haven models of the same names, decimated in Blender (1,400–3,500 triangles) with 512 px textures — https://polyhaven.com | CC0 |
| `models/sports_bike.glb` | "Sports Bike" by Futurealiti — https://sketchfab.com/3d-models/sports-bike-a80259b859c842d5824c25c61e0fc421 (decimated from 641k to 75k triangles, joined per material, bodywork recoloured per rider) | CC BY 4.0 — credit Futurealiti |
| `engine_low.wav`, `engine_high.wav` | "2002 Suzuki GSXR 600" from the "Bike Engine Sounds" collection — https://archive.org/details/bike-engine-sounds (two narrow bands of the run-up near the end of the recording, each re-timed to one steady pitch and laid over itself in short pieces to make a held rev) | CC0 |
| `models/sports_bike_far.glb` | The same "Sports Bike" by Futurealiti, cut to 9k triangles in Blender and joined into two pieces (bodywork, and the rest with each part's colour baked into its vertices) for riders away from the camera | CC BY 4.0 — credit Futurealiti |
| `models/firs.glb` | "Realistic fir trees pack (LODS, gameready)" by LOLIPOP — Sketchfab (four of the nine trees, LOD2 and the billboard LOD, textures reduced to 512 px) | CC BY 4.0 — credit LOLIPOP |
| `models/van.glb` | "Suzuki Carry Blind Van" by Dave Love — Sketchfab (decimated from 158k to 9.6k triangles, textures reduced to 256 px) | CC BY 4.0 — credit Dave Love |
| `models/truck.glb` | "Tata Signa Cargo Truck, Low Poly Game Ready PBR" by kevin_k_5124 — Sketchfab (textures reduced to 512 px, drawn at 0.8 scale) | CC BY 4.0 — credit kevin_k_5124 |
| `models/rider.glb` | "bike rider 3d" by Atrikumar Das — Sketchfab (rigged; stray helper mesh removed, textures at 512 px; suit and helmet re-coloured per rider at run time) | CC BY 4.0 — credit Atrikumar Das |
| `models/police_bike.glb` | "Harley-Davidson Police" by Comrade1280 — Sketchfab (display floor removed, stood upright, decimated from 658k to 61k triangles, textures reduced to 512 px) | CC BY 4.0 — credit Comrade1280 |

Outside this folder, in `assets/road_rumble/`:

| Path | Source | Licence |
|---|---|---|
| `dash.png` | Dashboard picture supplied for the game (background cut away; needles and readouts painted out so the game can draw its own) | Supplied by the project |

The CC BY models require their authors to be credited where players can
see it; the game's HOW TO PLAY screen carries that line. The van, lorry
and police bike carry real makers' names (Suzuki, Tata, Harley-Davidson).

Downloaded but deliberately not bundled, because their licences forbid
commercial use: "BMW S1000 RR" by VTX and "2024 Suzuki S-Cross" by Ddiaz
Design (both CC BY-NC-SA 4.0), and "Suzuki Eeco Cargo" by MidaZ_3D (CC BY-NC
4.0). "Police 3D Model" by Aayush.Bhattarai (CC BY 4.0) is not bundled either:
it has no skeleton, so it cannot be posed on a bike.

The remaining bikes, cars, trees and the rest of the scenery are built in code in
`index.html`; the road markings, foliage and grass textures are drawn there
too.
