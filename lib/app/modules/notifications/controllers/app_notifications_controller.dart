import 'dart:async';

import 'package:get/get.dart';
import 'package:hash/app/data/services/user_controller.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service_locator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppNotificationsController extends GetxController {
  final RemoteRepoInterface remoteRepo = locator<RemoteRepoInterface>();
  Timer? _pollTimer;

  final RxList<Map<String, dynamic>> notifications =
      <Map<String, dynamic>>[].obs;
  final RxInt unreadCount = 0.obs;
  final RxBool isLoading = false.obs;
  final RxString actionNotificationId = ''.obs;
  final Map<String, Map<String, dynamic>> _pushPayloadCacheByNotificationId =
      {};

  @override
  void onInit() {
    super.onInit();
    refreshNotifications(silent: true);
    _pollTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      refreshNotifications(silent: true);
    });
  }

  @override
  void onClose() {
    _pollTimer?.cancel();
    super.onClose();
  }

  Future<void> refreshNotifications({bool silent = false}) async {
    if (isLoading.value && !silent) return;
    if (!silent) {
      isLoading.value = true;
    }
    try {
      final response = await remoteRepo.fetchUserNotifications(
        limit: 50,
        unreadOnly: false,
      );
      final raw = response['notifications'];
      final list = raw is List
          ? raw
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList()
          : <Map<String, dynamic>>[];
      final byId = <String, Map<String, dynamic>>{};
      for (final item in list) {
        final id = (item['id'] ?? '').toString().trim();
        final key = id.isNotEmpty ? id : item.toString();
        final cached = id.isNotEmpty
            ? _pushPayloadCacheByNotificationId[id]
            : null;
        if (cached != null) {
          item['invite_id'] = item['invite_id'] ?? cached['invite_id'];
          item['event_id'] = item['event_id'] ?? cached['event_id'];
          item['reference_id'] = item['reference_id'] ?? cached['reference_id'];
          item['invite_status'] =
              item['invite_status'] ?? cached['invite_status'];
        }
        byId[key] = item;
      }
      final deduped = byId.values.toList();
      deduped.sort((a, b) {
        final aTime = DateTime.tryParse((a['created_at'] ?? '').toString());
        final bTime = DateTime.tryParse((b['created_at'] ?? '').toString());
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });
      notifications.assignAll(deduped);
      unreadCount.value = _parseInt(response['unread_count']) ?? 0;
    } catch (_) {
      // Keep current in-memory notifications on transient failures.
    } finally {
      if (!silent) {
        isLoading.value = false;
      }
    }
  }

  Future<void> markAsRead(String notificationId) async {
    final id = notificationId.trim();
    if (id.isEmpty) return;
    await remoteRepo.markNotificationAsRead(notificationId: id);

    final idx = notifications.indexWhere((e) => e['id'].toString() == id);
    if (idx >= 0) {
      final updated = Map<String, dynamic>.from(notifications[idx]);
      updated['is_read'] = true;
      notifications[idx] = updated;
    }
    unreadCount.value = unreadCount.value > 0 ? unreadCount.value - 1 : 0;
  }

  Future<void> respondToInvite({
    required Map<String, dynamic> notification,
    required String action,
  }) async {
    final normalizedAction = action.trim().toLowerCase();
    if (normalizedAction != 'accept' && normalizedAction != 'reject') {
      throw Exception('Invalid action.');
    }

    final inviteId = _readString(notification, const ['invite_id', 'inviteId']);
    final eventId = _readString(notification, const ['event_id', 'eventId']);
    final teamId = _readString(notification, const [
      'team_id',
      'reference_id',
      'referenceId',
    ]);
    final notificationId = _readString(notification, const ['id']);
    final localIndex = notifications.indexWhere(
      (e) => e['id']?.toString().trim() == notificationId,
    );

    if (inviteId.isEmpty || eventId.isEmpty || teamId.isEmpty) {
      throw Exception('Invite metadata missing. Please open from latest push.');
    }

    final currentUserId = await _resolveCurrentUserId();
    if (currentUserId == null || currentUserId <= 0) {
      throw Exception('Unable to identify current user.');
    }

    actionNotificationId.value = notificationId;
    try {
      await remoteRepo.respondToEventTeamInvite(
        eventId: eventId,
        teamId: teamId,
        inviteId: inviteId,
        userId: currentUserId,
        action: normalizedAction,
      );

      if (localIndex >= 0) {
        final updated = Map<String, dynamic>.from(notifications[localIndex]);
        updated['invite_status'] = normalizedAction == 'accept'
            ? 'accepted'
            : 'rejected';
        updated['status'] = updated['invite_status'];
        updated['is_read'] = true;
        notifications[localIndex] = updated;
      }

      if (notificationId.isNotEmpty) {
        await markAsRead(notificationId);
      }
      await refreshNotifications(silent: true);
    } finally {
      actionNotificationId.value = '';
    }
  }

  void onPushNotificationData(Map<String, dynamic> payload) {
    final type = (payload['type'] ?? '').toString().trim().toLowerCase();
    if (type != 'new_notification') return;

    final notificationId = (payload['notification_id'] ?? '').toString().trim();
    if (notificationId.isNotEmpty) {
      _pushPayloadCacheByNotificationId[notificationId] = {
        'invite_id': payload['invite_id'],
        'event_id': payload['event_id'],
        'reference_id': payload['reference_id'],
        'invite_status': payload['invite_status'] ?? 'pending',
      };
      final idx = notifications.indexWhere(
        (e) => e['id']?.toString().trim() == notificationId,
      );
      if (idx >= 0) {
        final updated = Map<String, dynamic>.from(notifications[idx]);
        updated['invite_id'] = payload['invite_id'];
        updated['event_id'] = payload['event_id'];
        updated['reference_id'] = payload['reference_id'];
        updated['invite_status'] = payload['invite_status'] ?? 'pending';
        updated['is_read'] = updated['is_read'] ?? false;
        notifications[idx] = updated;
      }
    }

    refreshNotifications(silent: true);
  }

  bool canRespondToInvite(Map<String, dynamic> notification) {
    final type = _readString(notification, const ['type']).toLowerCase();
    if (type != 'team_invite') return false;
    final status = _readString(notification, const [
      'invite_status',
      'status',
    ]).toLowerCase();
    final pending = status.isEmpty || status == 'pending';
    return pending;
  }

  bool hasInviteMetadata(Map<String, dynamic> notification) {
    final inviteId = _readString(notification, const ['invite_id', 'inviteId']);
    final eventId = _readString(notification, const ['event_id', 'eventId']);
    final teamId = _readString(notification, const ['team_id', 'reference_id']);
    return inviteId.isNotEmpty && eventId.isNotEmpty && teamId.isNotEmpty;
  }

  String _readString(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final direct = source[key];
      if (direct != null && direct.toString().trim().isNotEmpty) {
        return direct.toString().trim();
      }
    }

    for (final nestedKey in const ['data', 'payload', 'meta']) {
      final nested = source[nestedKey];
      if (nested is Map) {
        final nestedMap = Map<String, dynamic>.from(nested);
        for (final key in keys) {
          final value = nestedMap[key];
          if (value != null && value.toString().trim().isNotEmpty) {
            return value.toString().trim();
          }
        }
      }
    }
    return '';
  }

  int? _parseInt(dynamic source) {
    if (source == null) return null;
    if (source is int) return source;
    if (source is num) return source.toInt();
    return int.tryParse(source.toString().trim());
  }

  Future<int?> _resolveCurrentUserId() async {
    if (Get.isRegistered<UserController>()) {
      final controller = Get.find<UserController>();
      final fromController = _parseInt(controller.userId);
      if (fromController != null && fromController > 0) {
        return fromController;
      }
    }

    final userData = await remoteRepo.getUserFromPreferences();
    final fromUserData = _parseInt(
      userData?['id'] ?? userData?['user_id'] ?? userData?['userId'],
    );
    if (fromUserData != null && fromUserData > 0) {
      return fromUserData;
    }

    final prefs = locator<SharedPreferences>();
    final fromPrefs = _parseInt(prefs.getString('user_id'));
    if (fromPrefs != null && fromPrefs > 0) {
      return fromPrefs;
    }
    return null;
  }
}
