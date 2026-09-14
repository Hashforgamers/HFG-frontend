import 'package:flutter_test/flutter_test.dart';
import 'package:hash/core/service/deeplink_service.dart';

void main() {
  group('DeepLinkService.parse', () {
    test('parses tournament attribution', () {
      final destination = DeepLinkService.parse(
        Uri.parse(
          'https://hashforgamers.co.in/tournament/123?utm_source=instagram&utm_campaign=valorant_weekend&creator_id=78',
        ),
      );
      expect(destination.type, DeepLinkType.tournament);
      expect(destination.id, '123');
      expect(destination.growthContext.source, 'instagram');
      expect(destination.growthContext.campaign, 'valorant_weekend');
      expect(destination.growthContext.creatorId, '78');
      expect(destination.growthContext.tournamentId, '123');
    });

    test('parses tournament sub-destinations', () {
      expect(
        DeepLinkService.parse(
          Uri.parse('https://hashforgamers.co.in/tournament/123/leaderboard'),
        ).type,
        DeepLinkType.tournamentLeaderboard,
      );
      final match = DeepLinkService.parse(
        Uri.parse('https://hashforgamers.co.in/tournament/123/match/456'),
      );
      expect(match.type, DeepLinkType.tournamentMatch);
      expect(match.secondaryId, '456');
    });

    test('parses all canonical resource links', () {
      const cases = {
        '/host/1': DeepLinkType.host,
        '/cafe/1': DeepLinkType.cafe,
        '/game/1': DeepLinkType.game,
        '/profile/player': DeepLinkType.profile,
        '/team/1': DeepLinkType.team,
        '/referral/CODE': DeepLinkType.referral,
        '/wallet': DeepLinkType.wallet,
        '/rewards': DeepLinkType.rewards,
        '/passes': DeepLinkType.passes,
        '/bookings/1': DeepLinkType.booking,
      };
      for (final entry in cases.entries) {
        expect(
          DeepLinkService.parse(
            Uri.parse('https://hashforgamers.co.in${entry.key}'),
          ).type,
          entry.value,
          reason: entry.key,
        );
      }
    });

    test('supports legacy team invites and rejects incomplete links', () {
      final valid = DeepLinkService.parse(
        Uri.parse(
          'hashforgamers://team/join?event_id=e1&team_id=t1&invite_id=i1',
        ),
      );
      expect(valid.type, DeepLinkType.teamInvite);
      expect(valid.inviteId, 'i1');
      expect(
        DeepLinkService.parse(
          Uri.parse('https://hashforgamers.co.in/tournament'),
        ).isValid,
        isFalse,
      );
    });

    test('resolves resources addressed by the custom scheme authority', () {
      // Custom-scheme links put the resource in the authority rather than the
      // first path segment, so `hash://cafe/1` has to resolve the same way
      // `https://host/cafe/1` does.
      const cases = {
        'hash://host/1': DeepLinkType.host,
        'hash://cafe/1': DeepLinkType.cafe,
        'hash://game/1': DeepLinkType.game,
        'hash://profile/player': DeepLinkType.profile,
        'hash://team/1': DeepLinkType.team,
        'hash://referral/CODE': DeepLinkType.referral,
        'hash://bookings/1': DeepLinkType.booking,
        'hash://wallet': DeepLinkType.wallet,
        'hash://offer': DeepLinkType.offer,
      };
      for (final entry in cases.entries) {
        final destination = DeepLinkService.parse(Uri.parse(entry.key));
        expect(destination.type, entry.value, reason: entry.key);
      }
      expect(DeepLinkService.parse(Uri.parse('hash://cafe/1')).id, '1');
    });

    test('resolves contest links in both registered forms', () {
      expect(
        DeepLinkService.parse(Uri.parse('hash://contest/c1')).id,
        'c1',
      );
      expect(
        DeepLinkService.parse(Uri.parse('hash://contest?id=c9')).id,
        'c9',
      );
      expect(
        DeepLinkService.parse(
          Uri.parse('https://hashforgamers.co.in/contest/c1'),
        ).id,
        'c1',
      );
    });

    test('resolves tournament sub-destinations on the custom scheme', () {
      final match = DeepLinkService.parse(
        Uri.parse('hashforgamers://tournaments/123/match/456'),
      );
      expect(match.type, DeepLinkType.tournamentMatch);
      expect(match.id, '123');
      expect(match.secondaryId, '456');
      expect(
        DeepLinkService.parse(
          Uri.parse('hashforgamers://tournaments/123/leaderboard'),
        ).type,
        DeepLinkType.tournamentLeaderboard,
      );
    });

    test('rejects links with no destination', () {
      for (final raw in const [
        'https://hashforgamers.co.in/',
        'https://hashforgamers.co.in/blog/post',
        'hash://system',
        'https://hashforgamers.co.in/team/join?event_id=e1',
        'https://hashforgamers.co.in/cafe',
      ]) {
        expect(
          DeepLinkService.parse(Uri.parse(raw)).isValid,
          isFalse,
          reason: raw,
        );
      }
    });
  });
}
