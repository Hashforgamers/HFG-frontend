# hash

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Configuration

This project uses `--dart-define` for API keys and secrets. Required keys:

1. `RAWG_API_KEY`
2. `GAMESPOT_API_KEY`
3. `NEWS_API_KEYS` (comma-separated list)
4. `SERPAPI_KEYS` (comma-separated list)
5. `GOOGLE_MAPS_API_KEY`
6. `FRUIT_NINJA_SECRET_KEY` (optional; defaults to `dev`)

Example:

```bash
flutter run \
  --dart-define=RAWG_API_KEY=... \
  --dart-define=GAMESPOT_API_KEY=... \
  --dart-define=NEWS_API_KEYS=key1,key2 \
  --dart-define=SERPAPI_KEYS=key1,key2 \
  --dart-define=GOOGLE_MAPS_API_KEY=... \
  --dart-define=FRUIT_NINJA_SECRET_KEY=...
```
