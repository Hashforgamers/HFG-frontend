class AppKeys {
  static const String rawgApiKey = String.fromEnvironment('RAWG_API_KEY');
  static const String gameSpotApiKey = String.fromEnvironment('GAMESPOT_API_KEY');
  static const String googleMapsApiKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');
  static const String fruitNinjaSecretKey =
      String.fromEnvironment('FRUIT_NINJA_SECRET_KEY', defaultValue: 'dev');

  static List<String> get newsApiKeys {
    const raw = String.fromEnvironment('NEWS_API_KEYS');
    if (raw.trim().isEmpty) return const [];
    return raw
        .split(',')
        .map((key) => key.trim())
        .where((key) => key.isNotEmpty)
        .toList(growable: false);
  }

  static List<String> get serpApiKeys {
    const raw = String.fromEnvironment('SERPAPI_KEYS');
    if (raw.trim().isEmpty) return const [];
    return raw
        .split(',')
        .map((key) => key.trim())
        .where((key) => key.isNotEmpty)
        .toList(growable: false);
  }
}
