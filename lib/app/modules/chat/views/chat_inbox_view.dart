import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/chat/models/chat_user_model.dart';
import 'package:hash/app/modules/chat/models/chat_room_model.dart';
import 'package:hash/app/modules/chat/services/chat_service.dart';
import 'package:hash/app/modules/chat/theme/chat_palette.dart';
import 'package:hash/app/modules/chat/views/chat_create_group_view.dart';
import 'package:hash/app/modules/chat/views/chat_room_view.dart';
import 'package:hash/app/modules/chat/views/chat_user_picker_view.dart';
import 'package:hash/core/service/fb_events_service.dart';
import 'package:hash/core/service/segment_sdk_service.dart';
import 'package:hash/core/service_locator.dart';
import 'package:hash/core/utils/haptics.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class ChatInboxView extends StatefulWidget {
  const ChatInboxView({super.key});

  @override
  State<ChatInboxView> createState() => _ChatInboxViewState();
}

class _ChatInboxViewState extends State<ChatInboxView> {
  final ChatService _chatService = Get.find<ChatService>();
  final SegmentSdkService _segmentService = locator<SegmentSdkService>();
  final FbEventsService _fbEventsService = locator<FbEventsService>();
  final TextEditingController _searchController = TextEditingController();
  bool _didHandleInitialRoomNavigation = false;

  String _query = '';
  _InboxFilter _selectedFilter = _InboxFilter.all;

  @override
  void initState() {
    super.initState();
    _chatService.ensureCurrentUserProfile();
    _searchController.addListener(_handleSearchChanged);
    unawaited(
      _segmentService.onCustomEvent('Chat Inbox Viewed', {
        'source': 'chat_tab',
      }),
    );
    unawaited(
      _fbEventsService.logEvent('Chat Inbox Viewed', {'source': 'chat_tab'}),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didHandleInitialRoomNavigation) return;
    _didHandleInitialRoomNavigation = true;

    final args = Get.arguments;
    final roomId = (args is Map && args['roomId'] is String)
        ? (args['roomId'] as String).trim()
        : '';
    if (roomId.isEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Get.to(() => ChatRoomView(roomId: roomId));
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_handleSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearchChanged() {
    final next = _searchController.text.trim().toLowerCase();
    if (next == _query) return;
    setState(() => _query = next);
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';

    final month = _monthShort(dateTime.month);
    return '${dateTime.day} $month';
  }

  String _monthShort(int month) {
    const labels = [
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
    return labels[(month - 1).clamp(0, 11)];
  }

  List<ChatRoomModel> _filterRooms(
    List<ChatRoomModel> rooms,
    String currentUid,
  ) {
    final filteredByType = rooms.where((room) {
      switch (_selectedFilter) {
        case _InboxFilter.groups:
          return room.isGroup;
        case _InboxFilter.direct:
          return !room.isGroup;
        case _InboxFilter.all:
          return true;
      }
    });
    if (_query.isEmpty) return filteredByType.toList();

    return filteredByType.where((room) {
      final title = room.displayTitleFor(currentUid).toLowerCase();
      final subtitle = room.subtitleFor(currentUid).toLowerCase();
      return title.contains(_query) || subtitle.contains(_query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = _chatService.currentUid;
    if (currentUid == null) {
      return Scaffold(
        backgroundColor: ChatPalette.bgBottom,
        appBar: AppBar(
          backgroundColor: ChatPalette.surface,
          surfaceTintColor: Colors.transparent,
          title: Text(
            'Hash Hub Chats',
            style: GoogleFonts.inter(
              color: ChatPalette.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: DecoratedBox(
          decoration: const BoxDecoration(gradient: ChatPalette.pageGradient),
          child: Center(
            child: Text(
              'Please sign in to use chat.',
              style: GoogleFonts.inter(color: ChatPalette.textSecondary),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: ChatPalette.bgBottom,
      appBar: AppBar(
        backgroundColor: ChatPalette.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Hash Hub Chats',
          style: GoogleFonts.inter(
            color: ChatPalette.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Create group',
            onPressed: () {
              Haptics.tap();
              Get.to(() => const ChatCreateGroupView());
            },
            icon: const Icon(
              Icons.group_add_rounded,
              color: ChatPalette.textPrimary,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Haptics.medium();
          Get.to(() => const ChatUserPickerView());
        },
        backgroundColor: ChatPalette.primary,
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: const Icon(Icons.add_rounded, size: 30, color: Colors.white),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: ChatPalette.pageGradient),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.inter(color: ChatPalette.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search chats',
                  hintStyle: GoogleFonts.inter(
                    color: ChatPalette.textSecondary,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: ChatPalette.textSecondary,
                  ),
                  filled: true,
                  fillColor: ChatPalette.inputFill,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(
                      color: ChatPalette.border.withValues(alpha: 0.8),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(
                      color: ChatPalette.border.withValues(alpha: 0.8),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: ChatPalette.primary),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  _buildFilterChip(_InboxFilter.all, 'All'),
                  const SizedBox(width: 8),
                  _buildFilterChip(_InboxFilter.groups, 'Groups'),
                  const SizedBox(width: 8),
                  _buildFilterChip(_InboxFilter.direct, 'Direct'),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<List<ChatRoomModel>>(
                stream: _chatService.streamCurrentUserRooms(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !(snapshot.hasData)) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: ChatPalette.primary,
                      ),
                    );
                  }

                  final rooms = _filterRooms(
                    snapshot.data ?? const [],
                    currentUid,
                  );

                  if (rooms.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          'No conversations yet. Tap New Chat to start.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            color: ChatPalette.textSecondary,
                          ),
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 90),
                    itemCount: rooms.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final room = rooms[index];
                      final title = room.displayTitleFor(currentUid);
                      final subtitle = room.subtitleFor(currentUid);
                      final typingPeers = room.typingUserIds
                          .where((id) => id != currentUid)
                          .toList();
                      final otherId = room.isGroup
                          ? ''
                          : room.members.firstWhere(
                              (id) => id != currentUid,
                              orElse: () => '',
                            );
                      final stamp = room.lastMessageAt ?? room.updatedAt;
                      final prefix = title.isEmpty
                          ? 'C'
                          : title[0].toUpperCase();
                      final hasAvatar = room.imageUrl.trim().startsWith('http');
                      final badgeText = room.isGroup ? 'GROUP' : 'DIRECT';

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            Haptics.selection();
                            Get.to(() => ChatRoomView(roomId: room.id));
                          },
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: ChatPalette.cardGradient,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: ChatPalette.border.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: room.isGroup
                                          ? ChatPalette.accent
                                          : ChatPalette.primary,
                                    ),
                                    child: Center(
                                      child: hasAvatar
                                          ? CircleAvatar(
                                              radius: 19,
                                              backgroundImage:
                                                  CachedNetworkImageProvider(
                                                    room.imageUrl.trim(),
                                                  ),
                                            )
                                          : room.isGroup
                                          ? const Icon(
                                              Icons.groups_rounded,
                                              color: Colors.white,
                                              size: 20,
                                            )
                                          : StreamBuilder<ChatUserModel?>(
                                              stream: _chatService
                                                  .streamUserById(otherId),
                                              builder: (context, snap) {
                                                final photoFromChat =
                                                    snap.data?.photoUrl
                                                        .trim() ??
                                                    '';
                                                final selfGoogle =
                                                    (otherId == currentUid
                                                            ? firebase_auth
                                                                  .FirebaseAuth
                                                                  .instance
                                                                  .currentUser
                                                                  ?.photoURL
                                                            : null)
                                                        ?.trim() ??
                                                    '';
                                                final effectivePhoto =
                                                    photoFromChat.isNotEmpty
                                                    ? photoFromChat
                                                    : selfGoogle;
                                                if (effectivePhoto.isNotEmpty) {
                                                  return CircleAvatar(
                                                    radius: 19,
                                                    backgroundImage:
                                                        CachedNetworkImageProvider(
                                                          effectivePhoto,
                                                        ),
                                                  );
                                                }
                                                return Text(
                                                  prefix,
                                                  style: GoogleFonts.inter(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                );
                                              },
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.inter(
                                            color: ChatPalette.textPrimary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        _proofBadge(
                                          badgeText,
                                          room.isGroup
                                              ? ChatPalette.accent
                                              : ChatPalette.primary,
                                        ),
                                        const SizedBox(height: 4),
                                        if (room.isGroup)
                                          Text(
                                            typingPeers.isNotEmpty
                                                ? 'typing...'
                                                : subtitle,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.inter(
                                              color: typingPeers.isNotEmpty
                                                  ? ChatPalette.success
                                                  : ChatPalette.textSecondary,
                                              fontSize: 12,
                                            ),
                                          )
                                        else
                                          StreamBuilder<ChatUserModel?>(
                                            stream: _chatService.streamUserById(
                                              otherId,
                                            ),
                                            builder: (context, snap) {
                                              final user = snap.data;
                                              final status =
                                                  typingPeers.isNotEmpty
                                                  ? 'typing...'
                                                  : user == null
                                                  ? subtitle
                                                  : user.isOnline
                                                  ? 'Online'
                                                  : user.lastSeenAt == null
                                                  ? subtitle
                                                  : 'Last seen ${_formatTime(user.lastSeenAt!)}';
                                              return Text(
                                                status,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.inter(
                                                  color: typingPeers.isNotEmpty
                                                      ? ChatPalette.success
                                                      : user?.isOnline == true
                                                      ? ChatPalette.success
                                                      : ChatPalette
                                                            .textSecondary,
                                                  fontSize: 12,
                                                ),
                                              );
                                            },
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _formatTime(stamp),
                                    style: GoogleFonts.inter(
                                      color: ChatPalette.textSecondary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    color: ChatPalette.textSecondary,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(_InboxFilter filter, String label) {
    final selected = _selectedFilter == filter;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = filter),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: selected ? ChatPalette.primary : ChatPalette.surfaceAlt,
          border: Border.all(
            color: selected
                ? Colors.transparent
                : ChatPalette.border.withValues(alpha: 0.7),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: selected ? Colors.white : ChatPalette.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _proofBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 9.5,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

enum _InboxFilter { all, groups, direct }
