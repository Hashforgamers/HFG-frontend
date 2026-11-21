import 'package:flutter_test/flutter_test.dart';
import 'package:hash/core/service/analytics_service.dart';
import 'package:hash/features/mini_games/html_games/super_over_analytics.dart';

void main() {
  setUp(SuperOverAnalytics.resetForTest);

  group('Super Over event names', () {
    test('are the twelve funnel events, unique and valid for Firebase', () {
      const names = AnalyticsEvent.superOverFunnel;
      expect(names, hasLength(12));
      expect(names.toSet(), hasLength(12));
      for (final name in names) {
        expect(name, matches(RegExp(r'^[a-z][a-z0-9_]{0,39}$')), reason: name);
        expect(name, startsWith('super_over_'), reason: name);
      }
    });
  });

  group('mapWebEvent', () {
    test('maps the game page events to funnel names', () {
      expect(
        SuperOverAnalytics.mapWebEvent({'event': 'started'})?.name,
        AnalyticsEvent.superOverStarted,
      );
      expect(
        SuperOverAnalytics.mapWebEvent({'event': 'ball_played'})?.name,
        AnalyticsEvent.superOverBallPlayed,
      );
      expect(
        SuperOverAnalytics.mapWebEvent({'event': 'completed'})?.name,
        AnalyticsEvent.superOverCompleted,
      );
      expect(
        SuperOverAnalytics.mapWebEvent({'event': 'replay_tapped'})?.name,
        AnalyticsEvent.superOverReplayTapped,
      );
    });

    test('rejects unknown events and malformed payloads', () {
      expect(
        SuperOverAnalytics.mapWebEvent({'event': 'booking_confirmed'}),
        isNull,
      );
      expect(SuperOverAnalytics.mapWebEvent({'event': 'opened'}), isNull);
      expect(SuperOverAnalytics.mapWebEvent('started'), isNull);
      expect(SuperOverAnalytics.mapWebEvent(null), isNull);
    });

    test('keeps only whitelisted params with plain values', () {
      final mapped = SuperOverAnalytics.mapWebEvent({
        'event': 'completed',
        'params': {
          'score': 42,
          'balls_played': 6,
          'result': 'win',
          'is_replay': true,
          'email': 'someone@example.com',
          'mode': {'nested': 1},
          'runs': double.nan,
          'difficulty': '',
        },
      });
      expect(mapped?.params, {
        'score': 42,
        'balls_played': 6,
        'result': 'win',
        'is_replay': 'true',
      });
    });

    test('caps long strings', () {
      final mapped = SuperOverAnalytics.mapWebEvent({
        'event': 'started',
        'params': {'run_id': 'x' * 80},
      });
      expect(mapped?.params['run_id'], hasLength(40));
    });
  });

  group('booking attribution', () {
    test('is off until the game has been played', () {
      expect(SuperOverAnalytics.attributionForTest(), isNull);
    });

    test('credits a play earlier in the session', () {
      SuperOverAnalytics.markPlayedForTest();
      final attribution = SuperOverAnalytics.attributionForTest();
      expect(attribution?['attribution'], 'played_this_session');
      expect(attribution?['minutes_since_play'], 0);
    });

    test('prefers the book CTA once tapped', () {
      SuperOverAnalytics.markPlayedForTest();
      // logging without a registered AnalyticsService must not throw
      SuperOverAnalytics.bookCtaTapped(placement: 'result_screen');
      expect(
        SuperOverAnalytics.attributionForTest()?['attribution'],
        'book_cta',
      );
    });
  });
}
