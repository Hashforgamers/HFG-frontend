List<String> extractArenaAvailableGames(
  Map<String, dynamic> cafe, {
  int limit = 12,
}) {
  final sources = <dynamic>[
    cafe['available_games'],
    cafe['games'],
    cafe['game_titles'],
    cafe['supported_games'],
    cafe['game_list'],
  ];

  final details = cafe['vendor_details'];
  if (details is Map) {
    sources.addAll([
      details['available_games'],
      details['games'],
      details['game_titles'],
      details['supported_games'],
      details['game_list'],
    ]);
  }

  final profile = cafe['profile'];
  if (profile is Map) {
    sources.addAll([
      profile['available_games'],
      profile['games'],
      profile['game_titles'],
      profile['supported_games'],
      profile['game_list'],
    ]);
  }

  return sanitizeArenaGameList(sources, limit: limit);
}

List<String> sanitizeArenaGameList(
  Iterable<dynamic> sources, {
  int limit = 12,
}) {
  final normalized = <String>[];
  final seen = <String>{};

  for (final source in sources) {
    for (final item in _extractGameValues(source)) {
      final clean = item.trim();
      if (clean.isEmpty || !_isLikelyGameTitle(clean)) continue;

      final key = clean.toLowerCase();
      if (!seen.add(key)) continue;

      normalized.add(clean);
      if (normalized.length >= limit) {
        return normalized;
      }
    }
  }

  return normalized;
}

List<String> _extractGameValues(dynamic source) {
  final values = <String>[];
  if (source == null) return values;

  if (source is List) {
    for (final item in source) {
      values.addAll(_extractGameValues(item));
    }
    return values;
  }

  if (source is Map) {
    const candidateKeys = [
      'game_name',
      'gameName',
      'game_title',
      'gameTitle',
      'title',
      'name',
      'game',
    ];
    for (final key in candidateKeys) {
      if (source[key] != null) {
        values.addAll(_extractGameValues(source[key]));
      }
    }
    if (values.isNotEmpty) return values;

    const nestedKeys = [
      'games',
      'available_games',
      'game_titles',
      'supported_games',
      'game_list',
      'items',
      'list',
      'data',
    ];
    for (final key in nestedKeys) {
      if (source[key] != null) {
        values.addAll(_extractGameValues(source[key]));
      }
    }
    return values;
  }

  final label = source.toString().trim();
  if (label.isNotEmpty) {
    values.add(label);
  }
  return values;
}

bool _isLikelyGameTitle(String value) {
  final normalized = value
      .toLowerCase()
      .replaceAll(RegExp(r'[_-]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  if (normalized.isEmpty) return false;
  if (_looksLikeConsoleLabel(normalized)) return false;
  if (_looksLikeFacilityLabel(normalized)) return false;

  return true;
}

bool _looksLikeConsoleLabel(String value) {
  const consoleLabels = {
    'pc',
    'pcs',
    'gaming pc',
    'gaming pcs',
    'console',
    'consoles',
    'playstation',
    'ps4',
    'ps5',
    'xbox',
    'nintendo switch',
    'switch',
  };
  return consoleLabels.contains(value);
}

bool _looksLikeFacilityLabel(String value) {
  const exactMatches = {
    'high speed internet',
    'internet',
    'wifi',
    'wi fi',
    'gaming setup',
    'gaming setups',
    'air conditioning',
    'ac',
    'parking',
    'food',
    'snacks',
    'beverages',
    'drinks',
    'restroom',
    'washroom',
    'cafe',
    'vip lounge',
    'lounge',
  };
  if (exactMatches.contains(value)) return true;

  const keywords = [
    'internet',
    'wifi',
    'air condition',
    'parking',
    'snack',
    'beverage',
    'drink',
    'coffee',
    'tea',
    'food',
    'meal',
    'restroom',
    'washroom',
    'lounge',
    'chair',
    'seat',
    'table',
    'power backup',
    'charging',
    'printer',
    'scanner',
    'smoking',
    'non smoking',
    'locker',
  ];
  return keywords.any(value.contains);
}
