import 'package:flutter_test/flutter_test.dart';
import 'package:hash/app/modules/community/models/tournament.dart';

void main() {
  group('RoomDetailsData', () {
    test('round-trips shared and unknown game-specific fields', () {
      final input = <String, dynamic>{
        'schema_version': 1,
        'join': {
          'method': 'in_game',
          'lobby_id': '12345',
          'access_code': '6789',
          'server_region': 'Mumbai',
          'game_mode': 'ranked',
        },
        'schedule': {'opens_at': '2026-07-25T09:50:00Z'},
        'contacts': [
          {'channel': 'Discord', 'value': 'https://discord.gg/example'},
        ],
        'custom_fields': [
          {'label': 'Map', 'value': 'Erangel'},
        ],
        'game_extension': {
          'rounds': 3,
          'maps': ['Erangel', 'Miramar'],
        },
      };

      final result = RoomDetailsData.fromJson(input).toJson();

      expect(result, input);
    });

    test('uses safe defaults for malformed optional sections', () {
      final details = RoomDetailsData.fromJson({
        'schema_version': 2,
        'join': 'invalid',
        'contacts': 'invalid',
      });

      expect(details.schemaVersion, 2);
      expect(details.join, isEmpty);
      expect(details.contacts, isEmpty);
      expect(details.toJson(), {'schema_version': 2});
    });
  });
}
