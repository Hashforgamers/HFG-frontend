import '../models/html_mini_game.dart';

class HtmlMiniGameCatalogService {
  const HtmlMiniGameCatalogService();

  static const supportedGameIds = <String>['super_over', 'hash_rush'];

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
  ];

  List<HtmlMiniGame> getGames() => List<HtmlMiniGame>.unmodifiable(games);
}
