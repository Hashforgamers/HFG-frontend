import 'package:flutter/material.dart';
import 'package:hash/utils/widgets/loader.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/notifications/controllers/app_notifications_controller.dart';
import 'package:hash/core/service/fb_events_service.dart';
import 'package:hash/core/service/segment_sdk_service.dart';
import 'package:hash/core/service_locator.dart';

class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  late final AppNotificationsController _controller;
  final SegmentSdkService _segmentService = locator<SegmentSdkService>();
  final FbEventsService _fbEventsService = locator<FbEventsService>();

  @override
  void initState() {
    super.initState();
    _controller = Get.isRegistered<AppNotificationsController>()
        ? Get.find<AppNotificationsController>()
        : Get.put(AppNotificationsController(), permanent: true);
    final args = Get.arguments;
    if (args is Map) {
      _controller.onPushNotificationData(Map<String, dynamic>.from(args));
    }
    _controller.refreshNotifications();
  }

  @override
  void dispose() {
    for (final item in _controller.notifications) {
      if (item['is_read'] == true) continue;
      final id = (item['id'] ?? '').toString().trim();
      if (id.isEmpty) continue;
      _segmentService.onCustomEvent('Notification Ignored', {
        'notification_id': id,
      });
      _fbEventsService.onNotificationIgnored(notificationId: id);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'Notifications',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
      body: Obx(() {
        if (_controller.isLoading.value && _controller.notifications.isEmpty) {
          return const AppLinearLoader.screen();
        }

        if (_controller.notifications.isEmpty) {
          return Center(
            child: Text(
              'No notifications yet',
              style: GoogleFonts.inter(color: Colors.white70),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => _controller.refreshNotifications(),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
            itemCount: _controller.notifications.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (_, index) {
              final item = _controller.notifications[index];
              final id = (item['id'] ?? '').toString();
              final title = (item['title'] ?? 'Notification').toString();
              final message = (item['message'] ?? '').toString();
              final type = (item['type'] ?? '').toString().toLowerCase();
              final isRead = item['is_read'] == true;
              final createdAt = (item['created_at'] ?? '').toString();
              final canRespond = _controller.canRespondToInvite(item);
              final hasInviteMetadata = _controller.hasInviteMetadata(item);
              final actionLoading =
                  _controller.actionNotificationId.value == id;

              return InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () async {
                  if (!isRead && id.isNotEmpty) {
                    await _controller.markAsRead(id);
                  }
                },
                onLongPress: () async {
                  if (id.isEmpty) return;
                  _segmentService.onCustomEvent('Notification Dismissed', {
                    'notification_id': id,
                  });
                  _fbEventsService.onNotificationDismissed(notificationId: id);
                  if (!isRead) {
                    await _controller.markAsRead(id);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF1A1A1A),
                        const Color(0xFF121212),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: type == 'team_invite'
                                  ? const Color(
                                      0xff00DC00,
                                    ).withValues(alpha: 0.12)
                                  : Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              type == 'team_invite'
                                  ? Icons.groups_2_outlined
                                  : Icons.notifications_none_rounded,
                              size: 16,
                              color: type == 'team_invite'
                                  ? const Color(0xff00DC00)
                                  : Colors.white70,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              title,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          if (!isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xff00DC00),
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        message,
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatNotificationTime(createdAt),
                        style: GoogleFonts.inter(
                          color: Colors.white38,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (type == 'team_invite' && canRespond) ...[
                        const SizedBox(height: 10),
                        if (!hasInviteMetadata)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              'Invite details are syncing. Please try again in a moment.',
                              style: GoogleFonts.inter(
                                color: Colors.orange.shade200,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: actionLoading || !hasInviteMetadata
                                    ? null
                                    : () async {
                                        try {
                                          await _controller.respondToInvite(
                                            notification: item,
                                            action: 'reject',
                                          );
                                          if (!mounted) return;
                                          ScaffoldMessenger.of(
                                            this.context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text('Invite rejected'),
                                            ),
                                          );
                                        } catch (e) {
                                          if (!mounted) return;
                                          ScaffoldMessenger.of(
                                            this.context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                e.toString().replaceFirst(
                                                  'Exception: ',
                                                  '',
                                                ),
                                              ),
                                              backgroundColor: Colors.redAccent,
                                            ),
                                          );
                                        }
                                      },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: BorderSide.none,
                                  backgroundColor: Colors.white.withValues(
                                    alpha: 0.08,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text('Decline'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: actionLoading || !hasInviteMetadata
                                    ? null
                                    : () async {
                                        try {
                                          await _controller.respondToInvite(
                                            notification: item,
                                            action: 'accept',
                                          );
                                          if (!mounted) return;
                                          ScaffoldMessenger.of(
                                            this.context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text('Invite accepted'),
                                              backgroundColor: Color(
                                                0xff00DC00,
                                              ),
                                            ),
                                          );
                                        } catch (e) {
                                          if (!mounted) return;
                                          ScaffoldMessenger.of(
                                            this.context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                e.toString().replaceFirst(
                                                  'Exception: ',
                                                  '',
                                                ),
                                              ),
                                              backgroundColor: Colors.redAccent,
                                            ),
                                          );
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xff00DC00),
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: actionLoading
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.black,
                                        ),
                                      )
                                    : const Text('Accept'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }

  String _formatNotificationTime(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;

    final local = parsed.toLocal();
    final now = DateTime.now();
    final diff = now.difference(local);

    if (diff.inSeconds < 45) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24 &&
        now.day == local.day &&
        now.month == local.month &&
        now.year == local.year) {
      return '${diff.inHours}h ago';
    }

    final yesterday = now.subtract(const Duration(days: 1));
    final time = _formatTwelveHour(local);
    if (local.day == yesterday.day &&
        local.month == yesterday.month &&
        local.year == yesterday.year) {
      return 'Yesterday, $time';
    }

    return '${_dayMonth(local)} • $time';
  }

  String _formatTwelveHour(DateTime dt) {
    final hour = dt.hour == 0
        ? 12
        : dt.hour > 12
        ? dt.hour - 12
        : dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final suffix = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }

  String _dayMonth(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = months[(dt.month - 1).clamp(0, 11)];
    return '${dt.day} $month';
  }
}
