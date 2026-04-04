class HtmlMiniGame {
  final String gameId;
  final String name;
  final String thumbnail;
  final String gameUrl;
  final String description;

  const HtmlMiniGame({
    required this.gameId,
    required this.name,
    required this.thumbnail,
    required this.gameUrl,
    required this.description,
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
