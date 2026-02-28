import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/notifications/controllers/app_notifications_controller.dart';

class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  late final AppNotificationsController _controller;

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
          return const Center(
            child: CircularProgressIndicator(color: Color(0xff00DC00)),
          );
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
                    border: Border.all(
                      color: isRead ? Colors.white10 : const Color(0xff00DC00),
                      width: isRead ? 1 : 1.2,
                    ),
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
                        createdAt,
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
                                  side: const BorderSide(color: Colors.white24),
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
}
