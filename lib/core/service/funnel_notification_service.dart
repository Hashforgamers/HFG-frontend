import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:get/get.dart';
import 'package:hash/app/data/services/user_controller.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service_locator.dart';

class FunnelNotificationService {
  FunnelNotificationService({
    FirebaseFirestore? firestore,
    firebase_auth.FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? firebase_auth.FirebaseAuth.instance;

  static const String _eventsCollection = 'notification_funnel_events';

  final FirebaseFirestore _firestore;
  final firebase_auth.FirebaseAuth _auth;

  Future<void> trackEvent(
    String eventType, {
    Map<String, dynamic> payload = const <String, dynamic>{},
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return;
    }

    final firebaseUid = currentUser.uid.trim();
    if (firebaseUid.isEmpty) {
      return;
    }

    final backendUserId = await _resolveBackendUserId();
    final sanitizedPayload = _sanitizeMap(payload);
    final now = DateTime.now();

    await _firestore.collection(_eventsCollection).add({
      'eventType': eventType.trim(),
      'firebaseUid': firebaseUid,
      'backendUserId': backendUserId,
      'payload': sanitizedPayload,
      'occurredAtMs': now.millisecondsSinceEpoch,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<String> _resolveBackendUserId() async {
    try {
      if (Get.isRegistered<UserController>()) {
        final userId = Get.find<UserController>().id.value.trim();
        if (userId.isNotEmpty) {
          return userId;
        }
      }
    } catch (_) {}

    try {
      final userData = await locator<RemoteRepoInterface>()
          .getUserFromPreferences();
      return (userData?['id'] ?? userData?['user_id'] ?? '').toString().trim();
    } catch (_) {
      return '';
    }
  }

  Map<String, dynamic> _sanitizeMap(Map<String, dynamic> payload) {
    final sanitized = <String, dynamic>{};
    payload.forEach((key, value) {
      if (value == null) {
        return;
      }
      if (value is String || value is num || value is bool) {
        sanitized[key] = value;
        return;
      }
      if (value is List) {
        sanitized[key] = value.map((item) => item?.toString() ?? '').toList();
        return;
      }
      sanitized[key] = value.toString();
    });
    return sanitized;
  }
}
