import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hash/core/utils/app_logger.dart';

part 'tournaments_details_state.dart';

class TournamentsDetailsCubit extends Cubit<TournamentsDetailsState> {
  TournamentsDetailsCubit(Map<String, dynamic> tournament)
      : super(TournamentsDetailsLoaded(tournament: _enrichWithFullData(tournament))) {
    AppLogger.d('Details Cubit: ${tournament['title']}');
  }

  // Enrich compact data with full details (mock)
  static Map<String, dynamic> _enrichWithFullData(Map<String, dynamic> t) {
    final id = t['id'] as String;

    // Full details per tournament
    final Map<String, Map<String, dynamic>> fullData = {
      '1': {
        'title': 'Major I Tournament',
        'banner': 'assets/hash_store_images/tournament_banner.png',
        'entryFee': '250',
        'prizePool': '2500',
        'players': '32/50',
        'teamMode': '5v5 Team',
        'timeLeft': '4d 3h 16m',
        'status': 'completed',
        'description':
        'Players will face off in intense 5v5 matches, showcasing their aim, strategy, and teamwork across iconic Valorant maps.\n\n'
            'Open to all skill levels, this online event gives everyone a chance to climb the ranks, earn rewards, and prove they’re the best. '
            'Whether you’re a solo entry or part of a squad, the Valorant Clash Cup is your shot at esports fame.\n\n'
            'Register now for Rs.250.00/- only.',
        'hostedBy': 'SkyGames',
        'teams': [
          {
            'rank': '147',
            'name': 'SnareHex',
            'photoUrl': 'assets/hash_store_images/team_fallback.png',
            'points': '1500',
            'matchesWon': '21',
          },
          {
            'rank': '248',
            'name': 'CrimsonForce',
            'photoUrl': 'assets/hash_store_images/team_fallback.png',
            'points': '1200',
            'matchesWon': '17',
          },
          {
            'rank': '249',
            'name': 'D&DBand',
            'photoUrl': 'assets/hash_store_images/team_fallback.png',
            'points': '1200',
            'matchesWon': '17',
          },
        ],
      },
      '2': {
        'title': 'Major II Tournament',
        'banner': 'assets/hash_store_images/tournament_banner.png',
        'entryFee': '250',
        'prizePool': '2500',
        'players': '32/50',
        'teamMode': '5v5 Team',
        'timeLeft': '4d 3h 16m',
        'status': 'live',
        'description':
        'Players will face off in intense 5v5 matches, showcasing their aim, strategy, and teamwork across iconic Valorant maps.\n\n'
            'Open to all skill levels, this online event gives everyone a chance to climb the ranks, earn rewards, and prove they’re the best. '
            'Whether you’re a solo entry or part of a squad, the Valorant Clash Cup is your shot at esports fame.\n\n'
            'Register now for Rs.250.00/- only.',
        'hostedBy': 'SkyGames',
        'teams': [
          {
            'rank': '147',
            'name': 'SnareHex',
            'photoUrl': 'assets/hash_store_images/team_fallback.png',
            'points': '1500',
            'matchesWon': '21',
          },
          {
            'rank': '248',
            'name': 'CrimsonForce',
            'photoUrl': 'assets/hash_store_images/team_fallback.png',
            'points': '1200',
            'matchesWon': '17',
          },
          {
            'rank': '249',
            'name': 'D&DBand',
            'photoUrl': 'assets/hash_store_images/team_fallback.png',
            'points': '1200',
            'matchesWon': '17',
          },
        ],
      },
      '3': {
        'title': 'Valorant Major III Tournament',
        'banner': 'assets/hash_store_images/tournament_banner.png',
        'entryFee': '250',
        'prizePool': '2500',
        'players': '32/50',
        'teamMode': '5v5 Team',
        'timeLeft': '4d 3h 16m',
        'status': 'live',
        'description':
        'Players will face off in intense 5v5 matches, showcasing their aim, strategy, and teamwork across iconic Valorant maps.\n\n'
            'Open to all skill levels, this online event gives everyone a chance to climb the ranks, earn rewards, and prove they’re the best. '
            'Whether you’re a solo entry or part of a squad, the Valorant Clash Cup is your shot at esports fame.\n\n'
            'Register now for Rs.250.00/- only.',
        'hostedBy': 'SkyGames',
        'teams': [
          {
            'rank': '147',
            'name': 'SnareHex',
            'photoUrl': 'assets/hash_store_images/team_fallback.png',
            'points': '1500',
            'matchesWon': '21',
          },
          {
            'rank': '248',
            'name': 'CrimsonForce',
            'photoUrl': 'assets/hash_store_images/team_fallback.png',
            'points': '1200',
            'matchesWon': '17',
          },
          {
            'rank': '249',
            'name': 'D&DBand',
            'photoUrl': 'assets/hash_store_images/team_fallback.png',
            'points': '1200',
            'matchesWon': '17',
          },
        ],
      },
      '4': {
        'title': 'NBA Finals Clash',
        'banner': 'assets/hash_store_images/tournament_banner.png',
        'entryFee': '250',
        'prizePool': '2500',
        'players': '32/50',
        'teamMode': '5v5 Team',
        'timeLeft': '4d 3h 16m',
        'status': 'upcoming',
        'description':
        'Players will face off in intense 5v5 matches, showcasing their aim, strategy, and teamwork across iconic Valorant maps.\n\n'
            'Open to all skill levels, this online event gives everyone a chance to climb the ranks, earn rewards, and prove they’re the best. '
            'Whether you’re a solo entry or part of a squad, the Valorant Clash Cup is your shot at esports fame.\n\n'
            'Register now for Rs.250.00/- only.',
        'hostedBy': 'SkyGames',
        'teams': [
          {
            'rank': '147',
            'name': 'SnareHex',
            'photoUrl': 'assets/hash_store_images/team_fallback.png',
            'points': '1500',
            'matchesWon': '21',
          },
          {
            'rank': '248',
            'name': 'CrimsonForce',
            'photoUrl': 'assets/hash_store_images/team_fallback.png',
            'points': '1200',
            'matchesWon': '17',
          },
          {
            'rank': '249',
            'name': 'D&DBand',
            'photoUrl': 'assets/hash_store_images/team_fallback.png',
            'points': '1200',
            'matchesWon': '17',
          },
        ],
      },
      '5': {
        'title': 'Valorant Major IV Tournament',
        'banner': 'assets/hash_store_images/tournament_banner.png',
        'entryFee': '250',
        'prizePool': '2500',
        'players': '32/50',
        'teamMode': '5v5 Team',
        'timeLeft': '4d 3h 16m',
        'status': 'upcoming',
        'description':
        'Players will face off in intense 5v5 matches, showcasing their aim, strategy, and teamwork across iconic Valorant maps.\n\n'
            'Open to all skill levels, this online event gives everyone a chance to climb the ranks, earn rewards, and prove they’re the best. '
            'Whether you’re a solo entry or part of a squad, the Valorant Clash Cup is your shot at esports fame.\n\n'
            'Register now for Rs.250.00/- only.',
        'hostedBy': 'SkyGames',
        'teams': [
          {
            'rank': '147',
            'name': 'SnareHex',
            'photoUrl': 'assets/hash_store_images/team_fallback.png',
            'points': '1500',
            'matchesWon': '21',
          },
          {
            'rank': '248',
            'name': 'CrimsonForce',
            'photoUrl': 'assets/hash_store_images/team_fallback.png',
            'points': '1200',
            'matchesWon': '17',
          },
          {
            'rank': '249',
            'name': 'D&DBand',
            'photoUrl': 'assets/hash_store_images/team_fallback.png',
            'points': '1200',
            'matchesWon': '17',
          },
          {
            'rank': '310',
            'name': 'PhantomElite',
            'photoUrl': 'assets/hash_store_images/team_fallback.png',
            'points': '980',
            'matchesWon': '12',
          },
          {
            'rank': '341',
            'name': 'NightRaiders',
            'photoUrl': 'assets/hash_store_images/team_fallback.png',
            'points': '920',
            'matchesWon': '11',
          },
          {
            'rank': '376',
            'name': 'VortexKings',
            'photoUrl': 'assets/hash_store_images/team_fallback.png',
            'points': '890',
            'matchesWon': '10',
          },
          {
            'rank': '402',
            'name': 'CyberNova',
            'photoUrl': 'assets/hash_store_images/team_fallback.png',
            'points': '860',
            'matchesWon': '9',
          },
          {
            'rank': '417',
            'name': 'OmegaSquad',
            'photoUrl': 'assets/hash_store_images/team_fallback.png',
            'points': '840',
            'matchesWon': '9',
          },
          {
            'rank': '438',
            'name': 'ShadowMinds',
            'photoUrl': 'assets/hash_store_images/team_fallback.png',
            'points': '810',
            'matchesWon': '8',
          },
          {
            'rank': '462',
            'name': 'NovaStrike',
            'photoUrl': 'assets/hash_store_images/team_fallback.png',
            'points': '785',
            'matchesWon': '7',
          },
          {
            'rank': '489',
            'name': 'RogueLegion',
            'photoUrl': 'assets/hash_store_images/team_fallback.png',
            'points': '760',
            'matchesWon': '7',
          },
          {
            'rank': '503',
            'name': 'TalonForce',
            'photoUrl': 'assets/hash_store_images/team_fallback.png',
            'points': '730',
            'matchesWon': '6',
          },
          {
            'rank': '527',
            'name': 'CrystalClash',
            'photoUrl': 'assets/hash_store_images/team_fallback.png',
            'points': '705',
            'matchesWon': '6',
          },
        ],
      },
      // Add more as needed
    };

    return {
      ...t,
      ...?fullData[id], // Merge full data if exists
      'entryFee': t['entryFee'] ?? fullData[id]?['entryFee'] ?? 'Free',
      'prizePool': t['prizePool'] ?? fullData[id]?['prizePool'] ?? 'N/A',
      'players': t['players'] ?? fullData[id]?['players'] ?? '0/0',
      'teamMode': t['teamMode'] ?? fullData[id]?['teamMode'] ?? 'Solo',
      'timeLeft': t['timeLeft'] ?? '',
      'banner': t['banner'] ?? fullData[id]?['banner'] ?? t['imageUrl'],
      'description': t['description'] ?? fullData[id]?['description'] ?? 'No description.',
      'hostedBy': t['hostedBy'] ?? fullData[id]?['hostedBy'] ?? 'Hash',
    };
  }
}