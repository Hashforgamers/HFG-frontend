import '../models/html_mini_game.dart';

class HtmlMiniGameCatalogService {
  const HtmlMiniGameCatalogService();

  static const supportedGameIds = <String>[
    'super_over',
    'hash_rush',
    'odd_one_out',
    'hash_arcade',
  ];

  // Every entry must call the `gameScore` bridge itself — a third-party page
  // that can't (like the old "Racing Limits" CrazyGames embed) never scores or
  // awards coins and leaves a permanently-empty tile/leaderboard.
  static const games = <HtmlMiniGame>[
    HtmlMiniGame(
      gameId: 'super_over',
      name: 'Hash Super Over',
      thumbnail: 'assets/mini_game_icons/super_over.png',
      // 3D (three.js); loads its player models and sky from CDNs at runtime.
      gameUrl: 'assets/html_games/super_over/index.html',
      description: 'Chase the target · time your swing · clear the ropes',
      // best possible innings on Legend (×1.5) tops out around 157 points
      maxScore: 160,
    ),
    HtmlMiniGame(
      gameId: 'hash_rush',
      name: 'Hash Rush',
      thumbnail: 'assets/mini_game_icons/hash_rush.png',
      // 3D (three.js) crowd shooter; built from games/hash_rush, fully bundled.
      gameUrl: 'assets/html_games/hash_rush/index.html',
      description: 'Fire · multiply your army · crush the boss',
      // career score = per-level bests (30 × 20,000) + best endless run (capped at 200,000)
      maxScore: 800000,
      landscape: false,
    ),
    HtmlMiniGame(
      gameId: 'odd_one_out',
      name: 'Hash: Odd One Out',
      thumbnail: 'assets/mini_game_icons/odd_one_out.png',
      // React + Tailwind, built from games/odd_one_out, fully bundled.
      gameUrl: 'assets/html_games/odd_one_out/index.html',
      description: 'One different · find it fast',
      // no hard ceiling (time refills on every hit); this only stops garbage payloads
      maxScore: 1000000,
      landscape: false,
    ),
    HtmlMiniGame(
      gameId: 'hash_arcade',
      name: 'Hash Arcade',
      thumbnail: 'assets/mini_game_icons/hash_arcade.png',
      // React arcade of quick brain games, built from games/hash_arcade.
      gameUrl: 'assets/html_games/hash_arcade/index.html',
      description: 'Brain, reflex & puzzle games',
      // career score = each game's best normalised to 0–1000, × 60 games
      maxScore: 60000,
      landscape: false,
    ),
  ];

  List<HtmlMiniGame> getGames() => List<HtmlMiniGame>.unmodifiable(games);
}
