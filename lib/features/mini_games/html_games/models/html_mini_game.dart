class HtmlMiniGame {
  final String gameId;
  final String name;
  final String thumbnail;
  final String gameUrl;
  final String description;

  /// Highest score the game can legitimately produce; anything above it is
  /// rejected before it reaches the leaderboard. `null` = no ceiling.
  final int? maxScore;

  const HtmlMiniGame({
    required this.gameId,
    required this.name,
    required this.thumbnail,
    required this.gameUrl,
    required this.description,
    this.maxScore,
  });

  bool get isRemoteUrl {
    final uri = Uri.tryParse(gameUrl);
    return uri != null &&
        (uri.scheme.toLowerCase() == 'http' ||
            uri.scheme.toLowerCase() == 'https');
  }

  bool get hasThumbnail => thumbnail.trim().isNotEmpty;

  bool get isRemoteThumbnail {
    final uri = Uri.tryParse(thumbnail);
    return uri != null &&
        (uri.scheme.toLowerCase() == 'http' ||
            uri.scheme.toLowerCase() == 'https');
  }
}
