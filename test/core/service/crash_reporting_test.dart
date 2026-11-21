import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hash/core/service/crash_reporting.dart';

void main() {
  group('isExpectedFailure', () {
    test('network and download failures are not crashes', () {
      expect(
        CrashReporting.isExpectedFailure(const SocketException('x')),
        true,
      );
      expect(
        CrashReporting.isExpectedFailure(
          const HttpException('Invalid statusCode: 403'),
        ),
        true,
      );
      expect(CrashReporting.isExpectedFailure(TimeoutException('t')), true);
      expect(
        CrashReporting.isExpectedFailure(
          Exception('Failed to load font with url https://fonts.gstatic.com'),
        ),
        true,
      );
      expect(
        CrashReporting.isExpectedFailure(
          FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
        ),
        true,
      );
    });

    test('real defects stay fatal', () {
      expect(CrashReporting.isExpectedFailure(StateError('bad')), false);
      expect(CrashReporting.isExpectedFailure(TypeError()), false);
      expect(
        CrashReporting.isExpectedFailure(
          FirebaseException(
            plugin: 'cloud_firestore',
            code: 'permission-denied',
          ),
        ),
        false,
      );
    });
  });
}
