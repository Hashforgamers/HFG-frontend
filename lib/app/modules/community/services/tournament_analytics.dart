import 'package:hash/core/service/analytics_service.dart';
import 'package:hash/core/service_locator.dart';

import '../models/tournament.dart';

class TournamentAnalytics {
  static AnalyticsService get _analytics => locator<AnalyticsService>();

  static Map<String, Object?> parameters(
    Tournament tournament, {
    String? sourceScreen,
    String? teamStatus,
    bool? hostVerified,
  }) => {
    'tournament_id': tournament.id,
    'game_id': tournament.game,
    'game_name': tournament.game,
    'tournament_mode': tournament.teamMode ?? tournament.tournamentType,
    'city': tournament.region,
    'entry_fee': tournament.entryFee,
    'prize_pool': tournament.prizePool,
    'host_id': tournament.hostUserId,
    'host_verified': hostVerified,
    'team_status': teamStatus,
    'participant_count': tournament.registeredPlayersCount,
    'slots_remaining':
        (tournament.maxPlayers - tournament.registeredPlayersCount).clamp(
          0,
          tournament.maxPlayers,
        ),
    'source_screen': sourceScreen,
  };

  static Future<void> log(
    String event,
    Tournament tournament, {
    String? sourceScreen,
    String? teamStatus,
    bool? hostVerified,
    Map<String, Object?> extra = const {},
    String? deduplicationKey,
  }) => _analytics.log(
    event,
    parameters: {
      ...parameters(
        tournament,
        sourceScreen: sourceScreen,
        teamStatus: teamStatus,
        hostVerified: hostVerified,
      ),
      ...extra,
    },
    deduplicationKey: deduplicationKey,
  );
}
