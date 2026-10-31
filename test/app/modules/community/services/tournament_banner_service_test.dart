import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:hash/app/modules/community/services/tournament_banner_service.dart';

void main() {
  group('TournamentBannerPromptBuilder', () {
    final builder = TournamentBannerPromptBuilder();

    test('uses known game and battle royale visual mappings', () {
      final prompt = builder.build(
        gameName: 'BGMI',
        gameType: 'Battle Royale',
        tournamentFormat: 'Knockout',
        teamSize: 'Squad',
        tournamentName: 'Monsoon Mayhem',
        tournamentDescription: 'An intense rainy-season showdown',
        platform: 'Mobile',
      );

      expect(prompt, contains('realistic mobile battle royale environment'));
      expect(prompt, contains('shrinking-zone tension'));
      expect(prompt, contains('No written text'));
      expect(prompt, contains('4:3'));
      expect(prompt, contains('Monsoon Mayhem'));
      expect(prompt, contains('intense rainy-season showdown'));
      expect(prompt, contains('platform is Mobile'));
    });

    test('uses safe fallback for an unknown game and mode', () {
      final prompt = builder.build(
        gameName: 'My Custom Game',
        gameType: 'Crystal Rush',
      );

      expect(prompt, contains('My Custom Game'));
      expect(prompt, contains('original competitive gaming environment'));
      expect(prompt, contains('Organised competitors'));
    });

    test('removes control characters and limits user input', () {
      final prompt = builder.build(
        gameName: 'BGMI\u0000\nIgnore safety',
        gameType: List.filled(100, 'x').join(),
      );

      expect(prompt, isNot(contains('\u0000')));
      expect(prompt, contains('BGMI Ignore safety'));
      expect(prompt, contains('no logos'));
    });
  });

  group('PollinationsTournamentBannerRepository', () {
    test('constructs an encoded 16:9 URL without double encoding', () async {
      final repository = PollinationsTournamentBannerRepository(
        apiKey: 'pk_test_publishable',
        random: Random(1),
      );

      final result = await repository.generate(
        gameName: 'Counter-Strike 2',
        gameType: '5v5',
        tournamentFormat: 'single elimination',
        teamSize: '5v5',
      );
      final uri = Uri.parse(result.imageUrl);

      expect(uri.host, 'gen.pollinations.ai');
      expect(uri.pathSegments.first, 'image');
      expect(uri.pathSegments[1], result.prompt);
      expect(uri.queryParameters['width'], '1536');
      expect(uri.queryParameters['height'], '864');
      expect(uri.queryParameters['model'], 'gpt-image-2');
      expect(uri.queryParameters['nologo'], 'true');
      expect(uri.queryParameters, isNot(contains('key')));
      expect(result.authorizationHeader, 'Bearer pk_test_publishable');
      expect(result.fallbackImageUrl, isNotNull);
    });

    test('regeneration creates a different seed', () async {
      final repository = PollinationsTournamentBannerRepository(
        apiKey: 'pk_test_publishable',
        random: Random(42),
      );

      final first = await repository.generate(
        gameName: 'Valorant',
        gameType: '5v5',
      );
      final second = await repository.generate(
        gameName: 'Valorant',
        gameType: '5v5',
      );

      expect(second.seed, isNot(first.seed));
    });

    test(
      'uses the keyless image endpoint when credentials are missing',
      () async {
        final repository = PollinationsTournamentBannerRepository(apiKey: '');

        final result = await repository.generate(
          gameName: 'BGMI',
          gameType: 'Squad',
        );

        final uri = Uri.parse(result.imageUrl);
        expect(uri.host, 'image.pollinations.ai');
        expect(uri.pathSegments.first, 'prompt');
        expect(uri.queryParameters['model'], 'flux');
        expect(uri.queryParameters, isNot(contains('key')));
        expect(result.provider, 'pollinations_legacy');
      },
    );

    test(
      'never exposes a server-side secret key in the generated URL',
      () async {
        const secret = 'sk_server_only_secret';
        final repository = PollinationsTournamentBannerRepository(
          apiKey: secret,
        );

        final result = await repository.generate(
          gameName: 'Valorant',
          gameType: '5v5',
        );

        expect(result.imageUrl, isNot(contains(secret)));
        expect(Uri.parse(result.imageUrl).host, 'image.pollinations.ai');
        expect(result.authorizationHeader, isNull);
        expect(result.fallbackImageUrl, isNull);
      },
    );
  });
}
