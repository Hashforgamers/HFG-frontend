class LiveYoutubeUtils {
  static String? extractVideoId(String input) {
    final raw = input.trim();
    if (raw.isEmpty) return null;

    final normalized = raw.startsWith('http://') || raw.startsWith('https://')
        ? raw
        : 'https://$raw';
    final uri = Uri.tryParse(normalized);
    if (uri == null) return null;

    final host = uri.host.toLowerCase();
    final segments = uri.pathSegments.where((e) => e.isNotEmpty).toList();

    if (host.contains('youtu.be')) {
      if (segments.isNotEmpty && segments.first.length >= 6) {
        return _sanitize(segments.first);
      }
    }

    if (host.contains('youtube.com')) {
      final queryId = uri.queryParameters['v'];
      if (queryId != null && queryId.isNotEmpty) return _sanitize(queryId);

      final liveIndex = segments.indexOf('live');
      if (liveIndex != -1 && liveIndex + 1 < segments.length) {
        return _sanitize(segments[liveIndex + 1]);
      }

      final embedIndex = segments.indexOf('embed');
      if (embedIndex != -1 && embedIndex + 1 < segments.length) {
        return _sanitize(segments[embedIndex + 1]);
      }

      final shortsIndex = segments.indexOf('shorts');
      if (shortsIndex != -1 && shortsIndex + 1 < segments.length) {
        return _sanitize(segments[shortsIndex + 1]);
      }
    }

    final regex = RegExp(r'([0-9A-Za-z_-]{11})');
    final match = regex.firstMatch(raw);
    if (match != null) return _sanitize(match.group(1)!);

    return null;
  }

  static bool isSupportedUrl(String input) => extractVideoId(input) != null;

  static String? thumbnailUrl(String input) {
    final id = extractVideoId(input);
    if (id == null || id.isEmpty) return null;
    return 'https://img.youtube.com/vi/$id/hqdefault.jpg';
  }

  static String _sanitize(String value) {
    final cleaned = value.split('?').first.split('&').first.trim();
    return cleaned;
  }
}
