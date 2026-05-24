import 'dart:math';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hash/app/modules/arena/models/nearby_teammate.dart';

class NearbyTeammatesMockService {
  static const List<String> _games = [
    'BGMI',
    'Valorant',
    'Free Fire',
    'COD Mobile',
    'Fortnite',
    'EA FC',
  ];
  static const List<String> _ranks = [
    'Gold',
    'Platinum',
    'Diamond',
    'Ace',
    'Immortal',
    'Radiant',
  ];
  static const List<String> _languages = [
    'Hindi',
    'English',
    'Marathi',
    'Tamil',
    'Telugu',
  ];
  static const List<String> _playStyles = ['Casual', 'Competitive', 'Chill'];
  static const List<String> _usernames = [
    'ClutchRaja',
    'PixelNawab',
    'RushSensei',
    'AimPandit',
    'ZoneHunter',
    'LootLegend',
    'NeonYodha',
    'FragMaven',
    'SmokeCaller',
    'AceKiller',
    'RankWarden',
    'TiltProof',
    'SilentIGL',
    'DropMaster',
    'MetaMonk',
    'HeadshotDev',
    'QueueBoss',
    'StormByte',
    'SharpScope',
    'SquadAnchor',
  ];

  Future<List<NearbyTeammate>> fetchNearbyTeammates(LatLng userLocation) async {
    // TODO: Replace this mock generator with the backend nearby-teammates API.
    final random = Random(42);
    await Future<void>.delayed(const Duration(milliseconds: 350));

    return List<NearbyTeammate>.generate(20, (index) {
      final angle = random.nextDouble() * pi * 2;
      final radiusKm = 0.4 + random.nextDouble() * 6.5;
      final latOffset = (radiusKm / 111.0) * cos(angle);
      final lngOffset =
          (radiusKm / (111.0 * cos(userLocation.latitude * pi / 180))) *
          sin(angle);
      final gameStart = index % _games.length;
      final languageStart = index % _languages.length;

      return NearbyTeammate(
        id: 'teammate_${index + 1}',
        username: _usernames[index],
        avatar:
            'https://api.dicebear.com/9.x/bottts/png?seed=${_usernames[index]}',
        latitude: userLocation.latitude + latOffset,
        longitude: userLocation.longitude + lngOffset,
        games: [
          _games[gameStart],
          _games[(gameStart + 1 + random.nextInt(2)) % _games.length],
        ],
        rank: _ranks[(index + random.nextInt(3)) % _ranks.length],
        languages: [
          _languages[languageStart],
          _languages[(languageStart + 1) % _languages.length],
        ],
        micEnabled: index % 3 != 0,
        compatibilityScore: 68 + random.nextInt(31) + random.nextDouble(),
        playStyle:
            _playStyles[(index + random.nextInt(2)) % _playStyles.length],
        online: index % 4 != 0,
      );
    });
  }
}
