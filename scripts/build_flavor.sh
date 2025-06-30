#!/bin/bash

# Script to build Flutter app with different flavors
# Usage: ./scripts/build_flavor.sh [dev|prod] [android|ios|apk|aab|ipa]

FLAVOR=${1:-dev}
BUILD_TYPE=${2:-apk}

echo "Building HFG app with $FLAVOR flavor for $BUILD_TYPE..."

case $FLAVOR in
  "dev")
    case $BUILD_TYPE in
      "android"|"apk")
        flutter build apk --flavor dev -t lib/main_dev.dart
        ;;
      "aab")
        flutter build appbundle --flavor dev -t lib/main_dev.dart
        ;;
      "ios"|"ipa")
        flutter build ios --flavor dev -t lib/main_dev.dart
        ;;
      *)
        echo "Invalid build type. Use 'android', 'apk', 'aab', 'ios', or 'ipa'"
        exit 1
        ;;
    esac
    ;;
  "prod")
    case $BUILD_TYPE in
      "android"|"apk")
        flutter build apk --flavor prod -t lib/main_prod.dart
        ;;
      "aab")
        flutter build appbundle --flavor prod -t lib/main_prod.dart
        ;;
      "ios"|"ipa")
        flutter build ios --flavor prod -t lib/main_prod.dart
        ;;
      *)
        echo "Invalid build type. Use 'android', 'apk', 'aab', 'ios', or 'ipa'"
        exit 1
        ;;
    esac
    ;;
  *)
    echo "Invalid flavor. Use 'dev' or 'prod'"
    echo "Usage: ./scripts/build_flavor.sh [dev|prod] [android|apk|aab|ios|ipa]"
    exit 1
    ;;
esac 