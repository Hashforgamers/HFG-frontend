# Hash Super Over — bundled assets

| Path | Source | Licence |
|---|---|---|
| `lib/three.module.min.js`, `lib/jsm/**` | three.js r170 (npm `three@0.170.0`) | MIT (`lib/LICENSE-three.txt`) |
| (fallback, CDN only) | "Casual Character" by Quaternius — https://poly.pizza/m/kZ3DmIoGip | CC0 |
| `images/hash_logo.png` | Hash for Gamers badge (from `assets/nologoblack.png`) | Hash for Gamers |
| `sky/kloofendal_puresky_1k.hdr` | "Kloofendal 48d Partly Cloudy (Pure Sky)" — https://polyhaven.com | CC0 |
| `audio/voice/*.mp3` | Match commentary recorded for Hash for Gamers (see `audio/voice/SCRIPT.md`); `tie_*` and `newbest_*` are still from Kenney "Voiceover Pack" — https://opengameart.org/content/voiceover-pack-40-lines (trimmed, levelled) | Hash for Gamers; Kenney clips CC0 (`audio/voice/LICENSE-kenney-*.txt`) |
| `audio/crowd/*.mp3` | "Free Crowd Cheering Sounds" by **Gregor Quendel** — https://opengameart.org/content/free-crowd-cheering-sounds (trimmed, looped, levelled) | CC-BY 4.0 — credit Gregor Quendel |
| `anims/dance_*.glb`, `anims/emote_*.glb` | Ready Player Me Animation Library: masculine `M_Dances_001`–`011` (`dance_NNN`), the `F_Dances_001`/`004`–`007` set from the masculine folder (`dance_fNNN`), and `M_Standing_Expressions_NNN` (`emote_NNN`) — https://github.com/readyplayerme/animation-library | Ready Player Me Animation Library licence: free incl. commercial use, **only with Ready Player Me avatars** (our cricketer is one); no redistribution of the files on their own |
| `models/cheer_f.glb`, `anims/cheer_*.glb` | Ready Player Me Animation Library: `feminine/glb/Feminine_TPose.glb` (the cheer squad's avatar) and the feminine-skeleton dances `F_Dances_001`/`004`–`007` (`cheer_NNN`) and `M_Dances_001`–`011` (`cheer_mNNN`) — https://github.com/readyplayerme/animation-library | Same Ready Player Me Animation Library licence as above: free incl. commercial use with Ready Player Me avatars; no redistribution of the files on their own |
| `audio/intro.mp3` | First 24 s of a track supplied by Hash for Gamers (`game.mp3`); plays through the intro and fades out as the menu opens | Supplied by Hash for Gamers — distribution rights must be held by the publisher |

Served to the WebView from the app bundle (local HTTP server). If that is
unavailable the page falls back to the same files on jsDelivr / poly.pizza /
Poly Haven.
