/// Hash Live only plays YouTube streams, so every link is checked against an
/// exact host list and a strict video-id shape. Anything else (other sites,
/// channel pages, shorts, look-alike domains) is rejected.
class LiveYoutubeUtils {
  static const _hosts = {
    'youtube.com',
    'www.youtube.com',
    'm.youtube.com',
    'youtu.be',
  };
  static final _idPattern = RegExp(r'^[A-Za-z0-9_-]{11}$');

  /// Accepts youtube.com/live/ID, youtube.com/watch?v=ID and youtu.be/ID.
  static String? extractVideoId(String input) {
    final raw = input.trim();
    if (raw.isEmpty || raw.contains(RegExp(r'\s'))) return null;

    final uri = Uri.tryParse(raw.contains('://') ? raw : 'https://$raw');
    if (uri == null || (uri.scheme != 'https' && uri.scheme != 'http')) {
      return null;
    }
    final host = uri.host.toLowerCase();
    if (!_hosts.contains(host)) return null;

    final segments = uri.pathSegments.where((e) => e.isNotEmpty).toList();
    String? id;
    if (host == 'youtu.be') {
      if (segments.length == 1) id = segments.first;
    } else if (segments.length == 1 && segments.first == 'watch') {
      id = uri.queryParameters['v'];
    } else if (segments.length == 2 && segments.first == 'live') {
      id = segments[1];
    }
    return id != null && _idPattern.hasMatch(id) ? id : null;
  }

  static bool isSupportedUrl(String input) => extractVideoId(input) != null;

  /// The one link shape we store, so tracking params and junk never persist.
  static String? canonicalUrl(String input) {
    final id = extractVideoId(input);
    return id == null ? null : 'https://www.youtube.com/live/$id';
  }

  static String? thumbnailUrl(String input) {
    final id = extractVideoId(input);
    if (id == null) return null;
    return 'https://img.youtube.com/vi/$id/hqdefault.jpg';
  }
}
