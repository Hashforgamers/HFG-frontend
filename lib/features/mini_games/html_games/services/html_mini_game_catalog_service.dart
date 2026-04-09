import '../models/html_mini_game.dart';

class HtmlMiniGameCatalogService {
  const HtmlMiniGameCatalogService();

  static const supportedGameIds = <String>['racing_limits'];

  static const games = <HtmlMiniGame>[
    HtmlMiniGame(
      gameId: 'racing_limits',
      name: 'Racing Limits',
      thumbnail:
          'https://imgs.crazygames.com/racing-limits_16x9/20250711091800/racing-limits_16x9-cover?metadata=none&quality=100&width=1200&height=630&fit=crop',
      gameUrl: 'https://www.crazygames.com/game/racing-limits',
      description: 'CrazyGames URL test inside the Mini Games WebView.',
    ),
  ];

  List<HtmlMiniGame> getGames() => List<HtmlMiniGame>.unmodifiable(games);
}
