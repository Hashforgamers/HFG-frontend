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

Recommended (local file):

1. Create `.env.dev.json` at project root.
2. Run with `flutter run --dart-define-from-file=.env.dev.json`

`.env.dev.json` using your keys:

```json
{
  "RAWG_API_KEY": "5161e75d1d234431ac34d3947d01ea1e",
  "GAMESPOT_API_KEY": "...",
  "NEWS_API_KEYS": "51a460406b4c42c49acf3b06fd7aebcb,8e619f80f675482fa9d9a7428ab8a3cd,25f277808858445e9ad83230a2af5c4b,ce0ee2717a214c128e7bb8bce624578d",
  "SERPAPI_KEYS": "ff0566d621126eb6442cc76e33807d74dde7473b9417be93dd1cbc757a6c6baf,5a448e4cd243fdd57fc92a6e61c3448872c7b7d82588803889c0aa45cb96af7e,f5da7e32d9509302cc38341904d9a8f80ba82d5d68789c892826a25683865628,cc44766411da5696ca811b64e8ce3dc89051cb19c2e01458f7f2be9b65b3cab2,1192bba44b96ef7ec567bb0bbe8efc43fdc12a91f0b0343ec11c2df3b026cd6a,cb4a2ea410db5d47ff0872165bd7138201fb21ad96e75957148de122491473f2,2356e63291af937037ab58415767e80c2c086b676284aeb0d1b35a16b8ada363",
  "GOOGLE_MAPS_API_KEY": "...",
  "FRUIT_NINJA_SECRET_KEY": "dev"
}
```

Direct command example:

```bash
flutter run \
  --dart-define=RAWG_API_KEY=5161e75d1d234431ac34d3947d01ea1e \
  --dart-define=GAMESPOT_API_KEY=... \
  --dart-define=NEWS_API_KEYS=51a460406b4c42c49acf3b06fd7aebcb,8e619f80f675482fa9d9a7428ab8a3cd,25f277808858445e9ad83230a2af5c4b,ce0ee2717a214c128e7bb8bce624578d \
  --dart-define=SERPAPI_KEYS=ff0566d621126eb6442cc76e33807d74dde7473b9417be93dd1cbc757a6c6baf,5a448e4cd243fdd57fc92a6e61c3448872c7b7d82588803889c0aa45cb96af7e,f5da7e32d9509302cc38341904d9a8f80ba82d5d68789c892826a25683865628,cc44766411da5696ca811b64e8ce3dc89051cb19c2e01458f7f2be9b65b3cab2,1192bba44b96ef7ec567bb0bbe8efc43fdc12a91f0b0343ec11c2df3b026cd6a,cb4a2ea410db5d47ff0872165bd7138201fb21ad96e75957148de122491473f2,2356e63291af937037ab58415767e80c2c086b676284aeb0d1b35a16b8ada363 \
  --dart-define=GOOGLE_MAPS_API_KEY=... \
  --dart-define=FRUIT_NINJA_SECRET_KEY=dev
```
