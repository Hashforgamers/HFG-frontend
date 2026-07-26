import 'dart:math';

enum TournamentBannerSource { generated, uploaded, defaultBanner }

enum TournamentBannerStatus {
  initial,
  ready,
  generating,
  generated,
  uploading,
  selected,
  failure,
}

class TournamentBannerResult {
  const TournamentBannerResult({
    required this.imageUrl,
    required this.prompt,
    required this.seed,
    required this.provider,
  });

  final String imageUrl;
  final String prompt;
  final int seed;
  final String provider;
}

abstract class TournamentBannerRepository {
  Future<TournamentBannerResult> generate({
    required String gameName,
    required String gameType,
    String? tournamentFormat,
    String? teamSize,
    String? tournamentName,
    int? seed,
  });
}

class TournamentBannerPromptBuilder {
  static const gameVisualStyles = <String, String>{
    'bgmi':
        'realistic mobile battle royale environment, tactical squads, military-inspired equipment, abandoned urban battleground and survival competition',
    'free fire':
        'fast-paced stylised battle royale environment, vibrant tropical battleground and energetic mobile esports atmosphere',
    'free fire max':
        'fast-paced stylised battle royale environment, vibrant tropical battleground and energetic mobile esports atmosphere',
    'valorant':
        'futuristic tactical hero-shooter arena, clean angular architecture, ability-inspired energy effects and precise team competition',
    'cod mobile':
        'modern tactical combat arena, professional mobile esports atmosphere and fast military action',
    'call of duty mobile':
        'modern tactical combat arena, professional mobile esports atmosphere and fast military action',
    'pubg':
        'realistic survival battleground, tactical squads, vehicles, open terrain and tense final-zone atmosphere',
    'fortnite':
        'colourful stylised battle arena, dynamic structures, energetic action and playful competitive atmosphere',
    'counter-strike 2':
        'realistic tactical esports arena, attackers versus defenders, precise team formations and professional competition',
    'ea fc':
        'premium football stadium under esports lighting, opposing football teams and championship atmosphere',
  };

  static const modeVisualStyles = <String, String>{
    'battle royale':
        'Large survival battleground, multiple squads, aerial drop atmosphere, shrinking-zone tension, vehicles, distant combat and a final-circle competitive mood.',
    'team deathmatch':
        'Two opposing esports teams facing each other in a compact tactical combat arena with fast-paced action.',
    'search and destroy':
        'Tactical attackers and defenders, objective-focused arena, high-stakes competitive tension and strategic team positioning.',
    'clash squad':
        'Two compact squads confronting each other in an energetic close-range arena with bold competitive composition.',
    '1v1':
        'Two elite competitors facing each other in a symmetrical versus composition with a dramatic central divide.',
    '2v2':
        'Two organised two-player teams facing each other, clearly communicating the selected team size without text.',
    '4v4':
        'Two organised four-player teams facing each other, clearly communicating the selected team size without text.',
    '5v5':
        'Two organised five-player teams facing each other, clearly communicating the selected team size without text.',
    'solo':
        'One dominant competitor standing at the centre of a large competitive arena.',
    'duo':
        'Two coordinated teammates standing together against opposing competitors.',
    'squad':
        'A coordinated four-player esports squad prepared for a major competitive match.',
    'knockout':
        'High-stakes elimination tournament atmosphere, decisive final battle and championship-level tension.',
    'league':
        'Professional esports league atmosphere with multiple teams, arena lighting and season-long championship prestige.',
  };

  String build({
    required String gameName,
    required String gameType,
    String? tournamentFormat,
    String? teamSize,
    String? tournamentName,
  }) {
    final safeGame = _sanitize(gameName, fallback: 'competitive video game');
    final safeMode = _sanitize(gameType, fallback: 'competitive multiplayer');
    final safeFormat = _sanitize(
      tournamentFormat,
      fallback: 'competitive tournament',
    );
    final safeTeam = _sanitize(teamSize, fallback: 'team');
    final visual =
        gameVisualStyles[safeGame.toLowerCase()] ??
        'original competitive gaming environment tailored to the selected gameplay style';
    final mode =
        modeVisualStyles[safeMode.toLowerCase()] ??
        modeVisualStyles[safeTeam.toLowerCase()] ??
        'Organised competitors facing each other in a clear, high-energy esports composition.';

    return 'Create a premium cinematic esports tournament banner inspired by '
        'the competitive atmosphere of $safeGame. Game mode: $safeMode. '
        'Tournament format: $safeFormat. Team configuration: $safeTeam. '
        'Visual direction: $visual. $mode '
        'Show original competitive gaming characters and environments without '
        'copying official characters, logos, copyrighted artwork, exact maps or '
        'game UI. Use a dramatic esports arena composition, energetic action, '
        'professional tournament presentation, cinematic lighting, atmospheric '
        'smoke, particles, depth, intense competition and premium production '
        'quality. Use HASH brand-inspired orange and amber accent lighting '
        'over a dark background. Landscape banner composition, 4:3 aspect '
        'ratio, subjects safely centred, clean negative space for tournament '
        'information overlays. No written text, no letters, no numbers, no '
        'logos, no watermarks, no distorted faces, no duplicate characters, '
        'no malformed hands, no low-quality details.';
  }

  String _sanitize(String? raw, {required String fallback}) {
    final value = (raw ?? '')
        .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (value.isEmpty) return fallback;
    return value.length > 80 ? value.substring(0, 80).trim() : value;
  }
}

class PollinationsTournamentBannerRepository
    implements TournamentBannerRepository {
  PollinationsTournamentBannerRepository({
    TournamentBannerPromptBuilder? promptBuilder,
    String apiKey = const String.fromEnvironment('POLLINATIONS_API_KEY'),
    Random? random,
  }) : _promptBuilder = promptBuilder ?? TournamentBannerPromptBuilder(),
       _apiKey = apiKey.trim(),
       _random = random ?? Random.secure();

  final TournamentBannerPromptBuilder _promptBuilder;
  final String _apiKey;
  final Random _random;

  @override
  Future<TournamentBannerResult> generate({
    required String gameName,
    required String gameType,
    String? tournamentFormat,
    String? teamSize,
    String? tournamentName,
    int? seed,
  }) async {
    if (_apiKey.isEmpty || !_apiKey.startsWith('pk_')) {
      throw const TournamentBannerException(
        'AI banner generation is not configured. Upload a custom banner instead.',
        type: 'unauthorized',
      );
    }
    final nextSeed = seed ?? _random.nextInt(999999999);
    final prompt = _promptBuilder.build(
      gameName: gameName,
      gameType: gameType,
      tournamentFormat: tournamentFormat,
      teamSize: teamSize,
      tournamentName: tournamentName,
    );
    final uri = Uri(
      scheme: 'https',
      host: 'gen.pollinations.ai',
      pathSegments: ['image', prompt],
      queryParameters: {
        'model': 'flux',
        'width': '1536',
        'height': '1152',
        'seed': nextSeed.toString(),
        'nologo': 'true',
        'key': _apiKey,
      },
    );
    return TournamentBannerResult(
      imageUrl: uri.toString(),
      prompt: prompt,
      seed: nextSeed,
      provider: 'pollinations',
    );
  }
}

class TournamentBannerException implements Exception {
  const TournamentBannerException(this.message, {this.type = 'unexpected'});
  final String message;
  final String type;

  @override
  String toString() => message;
}
