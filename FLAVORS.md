# Flutter Flavors Setup

This project has been configured with two flavors: `dev` and `prod` to support different environments.

## Flavors Overview

- **dev**: Development environment with debug features enabled
- **prod**: Production environment with optimized settings

## Configuration Files

### Flavor Configuration
- `lib/config/flavor_config.dart`: Main flavor configuration class
- `lib/main_dev.dart`: Development entry point
- `lib/main_prod.dart`: Production entry point
- `lib/main.dart`: Default entry point (uses dev configuration)

### Android Configuration
- `android/app/build.gradle`: Product flavors configuration
- `android/app/src/dev/AndroidManifest.xml`: Dev-specific manifest
- `android/app/src/prod/AndroidManifest.xml`: Prod-specific manifest

### iOS Configuration
- `ios/Flutter/Dev.xcconfig`: Development configuration
- `ios/Flutter/Prod.xcconfig`: Production configuration
- `ios/Runner/Info.plist`: Updated to use flavor-specific app names

## Running the App

### Using Scripts (Recommended)

#### Run Development Version
```bash
# Android
./scripts/run_flavor.sh dev android

# iOS
./scripts/run_flavor.sh dev ios
```

#### Run Production Version
```bash
# Android
./scripts/run_flavor.sh prod android

# iOS
./scripts/run_flavor.sh prod ios
```

### Using Flutter Commands Directly

#### Development
```bash
# Android
flutter run --flavor dev -t lib/main_dev.dart

# iOS
flutter run --flavor dev -t lib/main_dev.dart
```

#### Production
```bash
# Android
flutter run --flavor prod -t lib/main_prod.dart

# iOS
flutter run --flavor prod -t lib/main_prod.dart
```

## Building for Release

### Using Scripts

#### Build APK
```bash
# Development APK
./scripts/build_flavor.sh dev apk

# Production APK
./scripts/build_flavor.sh prod apk
```

#### Build App Bundle (Android)
```bash
# Development AAB
./scripts/build_flavor.sh dev aab

# Production AAB
./scripts/build_flavor.sh prod aab
```

#### Build iOS
```bash
# Development IPA
./scripts/build_flavor.sh dev ipa

# Production IPA
./scripts/build_flavor.sh prod ipa
```

### Using Flutter Commands Directly

```bash
# Development APK
flutter build apk --flavor dev -t lib/main_dev.dart

# Production APK
flutter build apk --flavor prod -t lib/main_prod.dart

# Development App Bundle
flutter build appbundle --flavor dev -t lib/main_dev.dart

# Production App Bundle
flutter build appbundle --flavor prod -t lib/main_prod.dart
```

## Flavor Differences

### Development (dev)
- App Name: "HFG Dev"
- Package ID: `com.hfg.hash.dev`
- Debug banner: Enabled
- API Base URL: `https://dev-api.hfg.com`
- Primary Color: Blue
- Debug features enabled

### Production (prod)
- App Name: "Hash"
- Package ID: `com.hfg.hash`
- Debug banner: Disabled
- API Base URL: `https://api.hfg.com`
- Primary Color: Purple
- Optimized for release

## Customizing Flavors

### Adding New Configuration
1. Update `lib/config/flavor_config.dart` with new properties
2. Modify `lib/main_dev.dart` and `lib/main_prod.dart` with new values
3. Update Android and iOS configurations accordingly

### Changing API URLs
Update the `apiBaseUrl` in the respective main files:
- `lib/main_dev.dart` for development
- `lib/main_prod.dart` for production

### Changing App Names
- Android: Update `resValue "string", "app_name"` in `android/app/build.gradle`
- iOS: Update `APP_NAME` in the respective `.xcconfig` files

## Troubleshooting

### Common Issues

1. **Flavor not found**: Make sure you're using the correct flavor name (`dev` or `prod`)
2. **Build fails**: Ensure all flavor-specific files exist
3. **Wrong app name**: Check the configuration files for the specific platform

### Cleaning Build
```bash
flutter clean
flutter pub get
```

## Notes

- The default `main.dart` uses development configuration for safety
- Always test both flavors before releasing
- Keep API URLs and other sensitive information secure
- Consider using environment variables for sensitive configuration 