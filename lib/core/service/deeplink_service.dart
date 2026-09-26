import 'package:hash/features/mini_games/snakes_ladders/snl_match_screen.dart';
import 'dart:async';
import 'dart:convert';

import 'package:app_links/app_links.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:hash/app/modules/tournaments_section/pages/tournaments_team_invite_join_view.dart';
import 'package:hash/features/mini_games/ludo/online/ludo_match_screen.dart';
import 'package:hash/app/routes/app_routes.dart';
import 'package:hash/core/service/analytics_service.dart';
import 'package:hash/core/service_locator.dart';
import 'package:hash/core/utils/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DeepLinkType {
  tournament,
  tournamentLeaderboard,
  tournamentMatch,
  host,
  cafe,
  game,
  profile,
  team,
  teamInvite,
  referral,
  wallet,
  rewards,
  passes,
  booking,
  contest,
  offer,
  unknown,
}

class GrowthContext {
  const GrowthContext({
    this.source,
    this.medium,
    this.campaign,
    this.content,
    this.creatorId,
    this.hostId,
    this.cafeId,
    this.referralCode,
    this.tournamentId,
    this.deepLink,
  });
  final String? source,
      medium,
      campaign,
      content,
      creatorId,
      hostId,
      cafeId,
      referralCode,
      tournamentId,
      deepLink;

  factory GrowthContext.fromUri(
    Uri uri, {
    String? tournamentId,
  }) => GrowthContext(
    source: uri.queryParameters['utm_source'] ?? uri.queryParameters['source'],
    medium: uri.queryParameters['utm_medium'] ?? uri.queryParameters['medium'],
    campaign:
        uri.queryParameters['utm_campaign'] ?? uri.queryParameters['campaign'],
    content:
        uri.queryParameters['utm_content'] ?? uri.queryParameters['content'],
    creatorId:
        uri.queryParameters['creator_id'] ?? uri.queryParameters['shared_by'],
    hostId: uri.queryParameters['host_id'],
    cafeId: uri.queryParameters['cafe_id'],
    referralCode: uri.queryParameters['referral_code'],
    tournamentId: tournamentId ?? uri.queryParameters['tournament_id'],
    deepLink: uri.toString(),
  );

  Map<String, Object?> toAnalytics() => {
    'source': source,
    'medium': medium,
    'campaign': campaign,
    'content': content,
    'creator_id': creatorId,
    'host_id': hostId,
    'cafe_id': cafeId,
    'referral_code': referralCode,
    'tournament_id': tournamentId,
    'deep_link': deepLink,
  };
}

class DeepLinkDestination {
  const DeepLinkDestination({
    required this.type,
    required this.uri,
    required this.growthContext,
    this.id,
    this.secondaryId,
    this.inviteId,
  });
  final DeepLinkType type;
  final Uri uri;
  final GrowthContext growthContext;
  final String? id, secondaryId, inviteId;
  bool get isValid => type != DeepLinkType.unknown;
}

class DeepLinkService extends GetxController {
  DeepLinkService({AppLinks? appLinks, SharedPreferences? preferences})
    : _appLinks = appLinks ?? AppLinks(),
      _preferences = preferences;
  static const _pendingKey = 'growth_pending_deep_link',
      _firstTouchKey = 'growth_first_touch',
      _lastTouchKey = 'growth_last_touch';

  static const _tournamentRoots = {'tournament', 'tournaments'};

  /// Resources addressed as `<root>/<id>`.
  static const _resourceTypes = <String, DeepLinkType>{
    'host': DeepLinkType.host,
    'cafe': DeepLinkType.cafe,
    'game': DeepLinkType.game,
    'profile': DeepLinkType.profile,
    'team': DeepLinkType.team,
    'referral': DeepLinkType.referral,
    'bookings': DeepLinkType.booking,
  };

  /// Destinations that take no id.
  static const _standaloneTypes = <String, DeepLinkType>{
    'wallet': DeepLinkType.wallet,
    'rewards': DeepLinkType.rewards,
    'passes': DeepLinkType.passes,
    'offer': DeepLinkType.offer,
  };

  static bool _isKnownRoot(String value) =>
      _tournamentRoots.contains(value) ||
      _resourceTypes.containsKey(value) ||
      _standaloneTypes.containsKey(value) ||
      value == 'contest';
  final AppLinks _appLinks;
  SharedPreferences? _preferences;
  StreamSubscription<Uri>? _linkSub;
  GrowthContext? currentGrowthContext;

  /// The service is constructed before `runApp`, so a cold-start link can
  /// resolve before there is a navigator - and before `SplashController` makes
  /// its own `offAllNamed` call, which would wipe whatever we pushed. Splash
  /// signals here once it has routed, and deep-link navigation waits for it.
  static final Completer<void> _appReady = Completer<void>();

  static void markAppReady() {
    if (!_appReady.isCompleted) _appReady.complete();
  }

  static Future<void> _waitForApp() {
    if (_appReady.isCompleted) return Future<void>.value();
    // Never strand a link if splash somehow never reports in.
    return _appReady.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {},
    );
  }

  static DeepLinkDestination parse(Uri uri) {
    final original = uri.pathSegments
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final segments = original.map((e) => e.toLowerCase()).toList();
    final host = uri.host.toLowerCase();
    String? at(int i) => i >= 0 && i < original.length ? original[i] : null;
    DeepLinkDestination out(
      DeepLinkType type, {
      String? id,
      String? secondaryId,
      String? inviteId,
    }) => DeepLinkDestination(
      type: type,
      uri: uri,
      id: id,
      secondaryId: secondaryId,
      inviteId: inviteId,
      growthContext: GrowthContext.fromUri(
        uri,
        tournamentId: type.name.startsWith('tournament') ? id : null,
      ),
    );
    final teamJoin =
        (host == 'team' && segments.contains('join')) ||
        (segments.length >= 2 &&
            segments[0] == 'team' &&
            segments[1] == 'join') ||
        segments.contains('team-join');
    if (teamJoin) {
      final eventId = uri.queryParameters['event_id'],
          teamId = uri.queryParameters['team_id'];
      return (eventId ?? '').isNotEmpty && (teamId ?? '').isNotEmpty
          ? out(
              DeepLinkType.teamInvite,
              id: eventId,
              secondaryId: teamId,
              inviteId: uri.queryParameters['invite_id'],
            )
          : out(DeepLinkType.unknown);
    }
    // Web links carry the resource in the first path segment
    // (https://host/cafe/123); custom-scheme links carry it in the authority
    // (hash://cafe/123). Resolve both, then index the remaining segments from
    // wherever the id actually starts.
    final fromHost =
        (segments.isEmpty || !_isKnownRoot(segments.first)) &&
        _isKnownRoot(host);
    final root = fromHost
        ? host
        : (segments.isNotEmpty ? segments.first : host);
    final offset = fromHost ? 0 : 1;
    String? idAt(int i) => at(offset + i);
    String? lowerAt(int i) =>
        offset + i < segments.length ? segments[offset + i] : null;
    final id = idAt(0);
    if (_tournamentRoots.contains(root)) {
      final tournamentId = id;
      if ((tournamentId ?? '').isEmpty) return out(DeepLinkType.unknown);
      final suffix = lowerAt(1);
      if (suffix == 'leaderboard') {
        return out(DeepLinkType.tournamentLeaderboard, id: tournamentId);
      }
      if (suffix == 'match' && (idAt(2) ?? '').isNotEmpty) {
        return out(
          DeepLinkType.tournamentMatch,
          id: tournamentId,
          secondaryId: idAt(2),
        );
      }
      return out(DeepLinkType.tournament, id: tournamentId);
    }
    if (_resourceTypes.containsKey(root) && (id ?? '').isNotEmpty) {
      return out(_resourceTypes[root]!, id: id);
    }
    if (_standaloneTypes.containsKey(root)) {
      return out(_standaloneTypes[root]!);
    }
    if (root == 'contest') {
      return out(DeepLinkType.contest, id: id ?? uri.queryParameters['id']);
    }
    return out(DeepLinkType.unknown);
  }

  @override
  void onInit() {
    super.onInit();
    unawaited(handleColdStart());
    _linkSub = _appLinks.uriLinkStream.listen(
      handleUri,
      onError: (Object error) {
        AppLogger.d('Deep link stream failed: $error');
        unawaited(_trackFailure(null, 'stream_error'));
      },
    );
  }

  Future<void> handleColdStart() async {
    try {
      final uri = await _appLinks.getInitialLink();
      if (uri != null) await handleUri(uri);
    } catch (error) {
      AppLogger.d('Initial deep link failed: $error');
      await _trackFailure(null, 'cold_start_error');
    }
  }

  Future<void> handleUri(Uri uri) async {
    final destination = parse(uri);
    if (!destination.isValid) {
      unawaited(_trackFailure(uri, 'invalid_link'));
      await _waitForApp();
      // An unrecognised link still opened the app, so it has to leave the user
      // somewhere usable rather than on whatever the splash left behind.
      if (await _isLoggedIn() && Get.currentRoute != AppRoutes.HOME) {
        Get.offAllNamed(AppRoutes.HOME);
      }
      return;
    }
    currentGrowthContext = destination.growthContext;
    await _persistAttribution(destination.growthContext);
    // Reporting must not sit between the tap and the screen: these providers
    // make network calls, and the user is waiting on navigation.
    unawaited(
      _track('deep_link_opened', {
        ...destination.growthContext.toAnalytics(),
        'deep_link_type': destination.type.name,
      }),
    );
    await _waitForApp();
    if (!await _isLoggedIn()) {
      await storePendingLink(uri);
      if (Get.currentRoute != AppRoutes.LOGIN) {
        Get.offAllNamed(AppRoutes.LOGIN);
      }
      return;
    }
    await navigate(destination);
  }

  /// Consumes a link stored while the user was signed out. Safe to call from
  /// any auth path, whether or not the service is registered.
  static Future<bool> resumePendingAfterAuth() async {
    if (!Get.isRegistered<DeepLinkService>()) return false;
    try {
      return await Get.find<DeepLinkService>().resumePendingLinkAfterAuth();
    } catch (error) {
      AppLogger.d('Failed to resume pending deep link: $error');
      return false;
    }
  }

  Future<void> storePendingLink(Uri uri) async =>
      (await _prefs).setString(_pendingKey, uri.toString());
  Future<bool> resumePendingLinkAfterAuth() async {
    final prefs = await _prefs, raw = prefs.getString(_pendingKey);
    if (raw == null || raw.isEmpty) return false;
    await prefs.remove(_pendingKey);
    final uri = Uri.tryParse(raw);
    if (uri == null) return false;
    final destination = parse(uri);
    if (!destination.isValid) return false;
    currentGrowthContext = destination.growthContext;
    await navigate(destination, replaceStack: true);
    return true;
  }

  Future<void> navigate(
    DeepLinkDestination destination, {
    bool replaceStack = false,
  }) async {
    if (destination.type == DeepLinkType.teamInvite) {
      Widget page() => TournamentsTeamInviteJoinView(
        eventId: destination.id!,
        teamId: destination.secondaryId!,
        inviteId: destination.inviteId ?? '',
      );
      replaceStack ? Get.offAll(page) : Get.to(page);
      return;
    }

    // Ludo match invite: `.../game/ludomatch_<matchId>` opens the match lobby.
    if (destination.type == DeepLinkType.game &&
        (destination.id ?? '').startsWith('ludomatch_')) {
      final matchId = destination.id!.substring('ludomatch_'.length);
      if (matchId.isNotEmpty) {
        Widget page() => LudoMatchScreen(matchId: matchId);
        replaceStack ? Get.offAll(page) : Get.to(page);
        return;
      }
    }
    // Snakes & Ladders invite: `.../game/snlmatch_<matchId>`.
    if (destination.type == DeepLinkType.game &&
        (destination.id ?? '').startsWith('snlmatch_')) {
      final matchId = destination.id!.substring('snlmatch_'.length);
      if (matchId.isNotEmpty) {
        Widget page() => SnlMatchScreen(matchId: matchId);
        replaceStack ? Get.offAll(page) : Get.to(page);
        return;
      }
    }
    final route = _routeFor(destination.type);
    if (route == AppRoutes.HOME && destination.type != DeepLinkType.unknown) {
      // The link parsed, but its destination has no screen yet. Land on home
      // rather than a dead tap, and record the demand so the gap is visible.
      unawaited(
        _track('deep_link_unrouted', {
          ...destination.growthContext.toAnalytics(),
          'deep_link_type': destination.type.name,
        }),
      );
    }
    final arguments = <String, dynamic>{
      'id': destination.id,
      'match_id': destination.secondaryId,
      'deep_link_type': destination.type.name,
      'growth_context': destination.growthContext,
    };
    replaceStack
        ? Get.offAllNamed(route, arguments: arguments)
        : Get.toNamed(route, arguments: arguments);
  }

  /// Deep link types map only to routes that are registered in `AppPages`.
  /// Everything else deliberately falls through to home - see
  /// `deep_link_unrouted` in [navigate].
  static String _routeFor(DeepLinkType type) {
    switch (type) {
      case DeepLinkType.tournament:
      case DeepLinkType.tournamentLeaderboard:
      case DeepLinkType.tournamentMatch:
        return AppRoutes.TOURNAMENT_DETAIL;
      case DeepLinkType.wallet:
      // Rewards are presented inside the wallet today.
      case DeepLinkType.rewards:
        return AppRoutes.WALLET;
      // No dedicated screen exists yet for the destinations below. `contest`
      // and `offer` previously pointed at '/contestPage' and '/offerPage',
      // neither of which is registered, so both landed on GetX's route-not-
      // found page.
      case DeepLinkType.host:
      case DeepLinkType.cafe:
      case DeepLinkType.game:
      case DeepLinkType.profile:
      case DeepLinkType.team:
      case DeepLinkType.teamInvite:
      case DeepLinkType.referral:
      case DeepLinkType.booking:
      case DeepLinkType.passes:
      case DeepLinkType.contest:
      case DeepLinkType.offer:
      case DeepLinkType.unknown:
        return AppRoutes.HOME;
    }
  }

  Future<void> _persistAttribution(GrowthContext context) async {
    final prefs = await _prefs,
        data = context.toAnalytics()
          ..removeWhere((_, value) => value == null || value == '');
    final encoded = jsonEncode(data);
    if (!prefs.containsKey(_firstTouchKey)) {
      await prefs.setString(_firstTouchKey, encoded);
    }
    await prefs.setString(_lastTouchKey, encoded);
  }

  Future<bool> _isLoggedIn() async =>
      firebase_auth.FirebaseAuth.instance.currentUser != null ||
      (await _prefs).getBool('isLoggedIn') == true;
  Future<SharedPreferences> get _prefs async =>
      _preferences ??= await SharedPreferences.getInstance();

  /// Analytics is optional plumbing here: the locator may not hold the service
  /// yet during a cold start, and these calls are fired unawaited.
  Future<void> _track(String name, Map<String, Object?> parameters) async {
    try {
      await locator<AnalyticsService>().log(name, parameters: parameters);
    } catch (error) {
      AppLogger.d('Deep link analytics skipped for $name: $error');
    }
  }

  Future<void> _trackFailure(Uri? uri, String reason) => _track(
    'deep_link_failed',
    {'deep_link': uri?.toString(), 'failure_reason': reason},
  );
  @override
  void onClose() {
    _linkSub?.cancel();
    super.onClose();
  }
}
