import '../models/html_mini_game.dart';

class HtmlMiniGameCatalogService {
  const HtmlMiniGameCatalogService();

  static const supportedGameIds = <String>['racing_limits'];

  static const games = <HtmlMiniGame>[
    HtmlMiniGame(
      gameId: 'racing_limits',
      name: 'Racing Limits',
      thumbnail:
          'https://racinglimits.com/racinglimitsgamefile/racing-limits/logo.png',
      gameUrl: 'https://www.crazygames.com/game/racing-limits',
      description: 'CrazyGames URL test inside the Mini Games WebView.',
    ),
  ];

  List<HtmlMiniGame> getGames() => List<HtmlMiniGame>.unmodifiable(games);
}
