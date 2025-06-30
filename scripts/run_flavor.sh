#!/bin/bash

# Script to run Flutter app with different flavors
# Usage: ./scripts/run_flavor.sh [dev|prod] [android|ios]

FLAVOR=${1:-dev}
PLATFORM=${2:-android}

echo "Running HFG app with $FLAVOR flavor on $PLATFORM..."

case $FLAVOR in
  "dev")
    case $PLATFORM in
      "android")
        flutter run --flavor dev -t lib/main_dev.dart
        ;;
      "ios")
        flutter run --flavor dev -t lib/main_dev.dart
        ;;
      *)
        echo "Invalid platform. Use 'android' or 'ios'"
        exit 1
        ;;
    esac
    ;;
  "prod")
    case $PLATFORM in
      "android")
        flutter run --flavor prod -t lib/main_prod.dart
        ;;
      "ios")
        flutter run --flavor prod -t lib/main_prod.dart
        ;;
      *)
        echo "Invalid platform. Use 'android' or 'ios'"
        exit 1
        ;;
    esac
    ;;
  *)
    echo "Invalid flavor. Use 'dev' or 'prod'"
    echo "Usage: ./scripts/run_flavor.sh [dev|prod] [android|ios]"
    exit 1
    ;;
esac 