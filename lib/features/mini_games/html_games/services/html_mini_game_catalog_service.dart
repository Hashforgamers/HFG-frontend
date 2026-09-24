import '../models/html_mini_game.dart';

class HtmlMiniGameCatalogService {
  const HtmlMiniGameCatalogService();

  static const supportedGameIds = <String>[];

  // No HTML games are shipped yet. The previous "Racing Limits" entry loaded a
  // third-party CrazyGames landing page inside the WebView — it could never call
  // the `gameScore` bridge, so it never scored or awarded coins and showed a
  // permanently-empty tile/leaderboard. The WebView + score-bridge infra is kept
  // intact; add a genuinely embeddable, scoreable game here to re-enable it.
  static const games = <HtmlMiniGame>[];

  List<HtmlMiniGame> getGames() => List<HtmlMiniGame>.unmodifiable(games);
}
