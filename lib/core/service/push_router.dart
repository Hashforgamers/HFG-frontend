/// Where a push notification should take the user, resolved purely from its
/// data payload so every app state (cold start, background, foreground tap)
/// lands on the same screen.
///
/// Payload contract (any of, in priority order):
/// - `deep_link`: a link `DeepLinkService` understands (`hash://wallet`).
/// - `type` (+ ids): `rematch`/`ludo_match` + `match_id`,
///   `quick_match_waiting` + `match_id` (join, or Quick Match if gone), `ludo`,
///   `leaderboard`, `wallet`/`reward`, `chat` + `room_id`, `live` +
///   `stream_id`, `new_notification`.
/// - `route`: a named app route such as `/wallet`.
sealed class PushTarget {
  const PushTarget();
}

/// Open through `DeepLinkService`, which waits for splash and sign-in.
final class PushDeepLink extends PushTarget {
  const PushDeepLink(this.uri);
  final Uri uri;
}

final class PushNamedRoute extends PushTarget {
  const PushNamedRoute(this.route, {this.arguments});
  final String route;
  final Object? arguments;
}

final class PushChat extends PushTarget {
  const PushChat(this.roomId);
  final String roomId;
}

final class PushLiveStream extends PushTarget {
  const PushLiveStream(this.streamId);
  final String streamId;
}

/// Nothing to open: the tap just brings the app forward.
final class PushNone extends PushTarget {
  const PushNone();
}

abstract final class PushRouter {
  static const notificationsRoute = '/notifications';
  static const chatRoute = '/chat';

  static String _s(Map<String, dynamic> data, String key) =>
      (data[key] ?? '').toString().trim();

  static Uri _link(String path) => Uri.parse('hash://$path');

  static PushTarget resolve(Map<String, dynamic> data) {
    final deepLink = _s(data, 'deep_link');
    if (deepLink.isNotEmpty) {
      final uri = Uri.tryParse(deepLink);
      if (uri != null) return PushDeepLink(uri);
    }

    final type = _s(data, 'type').toLowerCase();
    final matchId = _s(data, 'match_id');
    switch (type) {
      case 'rematch':
      case 'ludo_match':
      case 'ludo_invite':
        return PushDeepLink(
          _link(matchId.isEmpty ? 'game/ludo' : 'game/ludomatch_$matchId'),
        );
      case 'quick_match_waiting':
        return PushDeepLink(_link('game/ludojoin_$matchId'));
      case 'ludo':
        return PushDeepLink(_link('game/ludo'));
      case 'leaderboard':
        return PushDeepLink(_link('game/mini-games'));
      case 'wallet':
      case 'reward':
      case 'streak':
        return PushDeepLink(_link('wallet'));
      case 'chat':
        return PushChat(
          _s(data, 'room_id').isNotEmpty
              ? _s(data, 'room_id')
              : _s(data, 'chat_room_id'),
        );
      case 'live':
        final streamId = _s(data, 'stream_id');
        if (streamId.isNotEmpty) return PushLiveStream(streamId);
      case 'new_notification':
        return PushNamedRoute(notificationsRoute, arguments: data);
    }

    final route = _s(data, 'route');
    if (route.startsWith('/')) return PushNamedRoute(route);
    return const PushNone();
  }

  /// Short label for analytics (`notification_opened.target`).
  static String describe(PushTarget target) => switch (target) {
    PushDeepLink(:final uri) => uri.toString(),
    PushNamedRoute(:final route) => route,
    PushChat() => 'chat',
    PushLiveStream() => 'live',
    PushNone() => 'none',
  };
}
