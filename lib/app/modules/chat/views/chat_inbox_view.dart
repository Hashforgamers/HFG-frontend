import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
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
  bool _showArchived = false;
  final Set<String> _actionInProgressRoomIds = <String>{};

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

  bool _isRoomActionInProgress(String roomId) {
    return _actionInProgressRoomIds.contains(roomId);
  }

  Future<void> _runRoomAction(
    String roomId,
    Future<void> Function() action,
  ) async {
    if (_isRoomActionInProgress(roomId)) return;
    if (!mounted) return;
    setState(() => _actionInProgressRoomIds.add(roomId));
    try {
      await action();
    } finally {
      if (mounted) {
        setState(() => _actionInProgressRoomIds.remove(roomId));
      }
    }
  }

  void _showSnack({
    required String message,
    Color? backgroundColor,
    SnackBarAction? action,
  }) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        action: action,
      ),
    );
  }

  Future<bool> _confirmDeleteChat(String roomTitle) async {
    final answer = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: ChatPalette.surface,
          title: Text(
            'Delete chat?',
            style: GoogleFonts.inter(
              color: ChatPalette.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'This removes "$roomTitle" from your inbox only. You can start a fresh chat anytime.',
            style: GoogleFonts.inter(
              color: ChatPalette.textSecondary,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: ChatPalette.textSecondary),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFC84B4B),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                'Delete',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
    return answer == true;
  }

  Future<void> _toggleMute({
    required String roomId,
    required bool currentlyMuted,
  }) async {
    await _runRoomAction(roomId, () async {
      final nextMuted = !currentlyMuted;
      await _chatService.setRoomMutedForCurrentUser(
        roomId: roomId,
        muted: nextMuted,
      );
      _showSnack(
        message: nextMuted ? 'Notifications muted' : 'Notifications unmuted',
        backgroundColor: nextMuted
            ? const Color(0xFF2A4E22)
            : const Color(0xFF2D2D2D),
      );
    });
  }

  Future<void> _toggleArchive({
    required String roomId,
    required bool currentlyArchived,
  }) async {
    await _runRoomAction(roomId, () async {
      final nextArchived = !currentlyArchived;
      await _chatService.setRoomArchivedForCurrentUser(
        roomId: roomId,
        archived: nextArchived,
      );
      _showSnack(
        message: nextArchived ? 'Chat archived' : 'Chat moved to inbox',
        backgroundColor: const Color(0xFF303030),
      );
    });
  }

  Future<bool> _deleteChatWithConfirmation({
    required String roomId,
    required String roomTitle,
  }) async {
    final confirmed = await _confirmDeleteChat(roomTitle);
    if (!confirmed) return false;

    var deleted = false;
    await _runRoomAction(roomId, () async {
      await _chatService.deleteRoomForCurrentUser(roomId);
      deleted = true;
      _showSnack(
        message: 'Chat deleted',
        backgroundColor: const Color(0xFF6D1B1B),
        action: SnackBarAction(
          label: 'Undo',
          textColor: Colors.white,
          onPressed: () {
            unawaited(
              _restoreRoomForCurrentUser(roomId).catchError((_) {
                _showSnack(message: 'Unable to restore chat right now.');
              }),
            );
          },
        ),
      );
    });
    return deleted;
  }

  Future<void> _restoreRoomForCurrentUser(String roomId) async {
    final uid = _chatService.currentUid;
    if (uid == null) return;
    await FirebaseFirestore.instance.collection('chat_rooms').doc(roomId).set({
      'deleted_for_uids': FieldValue.arrayRemove(<String>[uid]),
      'updated_at': FieldValue.serverTimestamp(),
      'client_updated_at': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
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

                  final activeRooms = rooms
                      .where(
                        (room) => !room.archivedUserIds.contains(currentUid),
                      )
                      .toList();
                  final archivedRooms = rooms
                      .where(
                        (room) => room.archivedUserIds.contains(currentUid),
                      )
                      .toList();
                  final hasVisibleRooms =
                      activeRooms.isNotEmpty ||
                      (_showArchived && archivedRooms.isNotEmpty);

                  if (!hasVisibleRooms) {
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

                  final items = <Widget>[
                    ...activeRooms.map(
                      (room) =>
                          _buildRoomTile(room: room, currentUid: currentUid),
                    ),
                  ];

                  if (_showArchived && archivedRooms.isNotEmpty) {
                    items.add(
                      Padding(
                        padding: const EdgeInsets.fromLTRB(6, 14, 6, 8),
                        child: Text(
                          'Archived Chats',
                          style: GoogleFonts.inter(
                            color: ChatPalette.textSecondary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                    items.addAll(
                      archivedRooms.map(
                        (room) =>
                            _buildRoomTile(room: room, currentUid: currentUid),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    color: ChatPalette.primary,
                    backgroundColor: ChatPalette.surface,
                    onRefresh: () async {
                      await _chatService.ensureCurrentUserProfile();
                      if (!mounted) return;
                      setState(() => _showArchived = true);
                    },
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 90),
                      itemCount: items.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) => items[index],
                    ),
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

  Widget _buildRoomTile({
    required ChatRoomModel room,
    required String currentUid,
  }) {
    final title = room.displayTitleFor(currentUid);
    final subtitle = room.subtitleFor(currentUid);
    final typingPeers = room.typingUserIds
        .where((id) => id != currentUid)
        .toList();
    final otherId = room.isGroup
        ? ''
        : room.members.firstWhere((id) => id != currentUid, orElse: () => '');
    final stamp = room.lastMessageAt ?? room.updatedAt;
    final prefix = title.isEmpty ? 'C' : title[0].toUpperCase();
    final hasAvatar = room.imageUrl.trim().startsWith('http');
    final badgeText = room.isGroup ? 'GROUP' : 'DIRECT';
    final isMuted = room.mutedUserIds.contains(currentUid);
    final isArchived = room.archivedUserIds.contains(currentUid);
    final actionInProgress = _isRoomActionInProgress(room.id);

    return Dismissible(
      key: ValueKey('chat_${room.id}_${stamp.millisecondsSinceEpoch}'),
      direction: DismissDirection.horizontal,
      background: Container(
        decoration: BoxDecoration(
          color: isMuted ? const Color(0xFF2D2D2D) : const Color(0xFF2A4E22),
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Icon(
              isMuted ? Icons.volume_up_rounded : Icons.volume_off_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              isMuted ? 'Unmute' : 'Mute',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF6D1B1B),
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Delete',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.delete_rounded, color: Colors.white),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        try {
          if (actionInProgress) return false;
          if (direction == DismissDirection.startToEnd) {
            await _toggleMute(roomId: room.id, currentlyMuted: isMuted);
            return false;
          }
          if (direction == DismissDirection.endToStart) {
            return _deleteChatWithConfirmation(
              roomId: room.id,
              roomTitle: title,
            );
          }
        } catch (_) {
          _showSnack(message: 'Action failed. Please try again.');
        }
        return false;
      },
      dismissThresholds: const {
        DismissDirection.startToEnd: 0.18,
        DismissDirection.endToStart: 0.22,
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onLongPress: actionInProgress
              ? null
              : () async {
                  try {
                    Haptics.medium();
                    await _toggleArchive(
                      roomId: room.id,
                      currentlyArchived: isArchived,
                    );
                  } catch (_) {
                    _showSnack(message: 'Action failed. Please try again.');
                  }
                },
          onTap: actionInProgress
              ? null
              : () {
                  Haptics.selection();
                  Get.to(() => ChatRoomView(roomId: room.id));
                },
          child: Ink(
            decoration: BoxDecoration(
              gradient: ChatPalette.cardGradient,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: ChatPalette.border.withValues(alpha: 0.6),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Stack(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: room.isGroup
                              ? ChatPalette.accent
                              : ChatPalette.primary,
                        ),
                        child: Center(
                          child: hasAvatar
                              ? CircleAvatar(
                                  radius: 18,
                                  backgroundImage: CachedNetworkImageProvider(
                                    room.imageUrl.trim(),
                                  ),
                                )
                              : room.isGroup
                              ? const Icon(
                                  Icons.groups_rounded,
                                  color: Colors.white,
                                  size: 18,
                                )
                              : StreamBuilder<ChatUserModel?>(
                                  stream: _chatService.streamUserById(otherId),
                                  builder: (context, snap) {
                                    final photoFromChat =
                                        snap.data?.photoUrl.trim() ?? '';
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
                                        radius: 18,
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
                                        fontSize: 13,
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                color: ChatPalette.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 3),
                            if (room.isGroup)
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
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
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  _typeTag(room.isGroup, badgeText),
                                ],
                              )
                            else
                              StreamBuilder<ChatUserModel?>(
                                stream: _chatService.streamUserById(otherId),
                                builder: (context, snap) {
                                  final user = snap.data;
                                  final status = typingPeers.isNotEmpty
                                      ? 'typing...'
                                      : user == null
                                      ? subtitle
                                      : user.isOnline
                                      ? 'Online'
                                      : user.lastSeenAt == null
                                      ? subtitle
                                      : 'Last seen ${_formatTime(user.lastSeenAt!)}';
                                  return Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          status,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.inter(
                                            color: typingPeers.isNotEmpty
                                                ? ChatPalette.success
                                                : user?.isOnline == true
                                                ? ChatPalette.success
                                                : ChatPalette.textSecondary,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      _typeTag(room.isGroup, badgeText),
                                    ],
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatTime(stamp),
                            style: GoogleFonts.inter(
                              color: ChatPalette.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (isMuted) ...[
                            const SizedBox(height: 3),
                            const Icon(
                              Icons.volume_off_rounded,
                              color: ChatPalette.textSecondary,
                              size: 13,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        splashRadius: 16,
                        visualDensity: const VisualDensity(
                          horizontal: -4,
                          vertical: -4,
                        ),
                        tooltip: 'Actions',
                        onPressed: actionInProgress
                            ? null
                            : () => _showRoomActionsSheet(
                                room: room,
                                currentUid: currentUid,
                              ),
                        icon: const Icon(
                          Icons.more_vert_rounded,
                          color: ChatPalette.textSecondary,
                          size: 17,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: ChatPalette.textSecondary,
                        size: 18,
                      ),
                    ],
                  ),
                  if (actionInProgress)
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.28),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: ChatPalette.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _typeTag(bool isGroup, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: (isGroup ? ChatPalette.accent : ChatPalette.primary)
              .withValues(alpha: 0.4),
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: isGroup ? ChatPalette.accent : ChatPalette.primary,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.25,
        ),
      ),
    );
  }

  Future<void> _showRoomActionsSheet({
    required ChatRoomModel room,
    required String currentUid,
  }) async {
    final isMuted = room.mutedUserIds.contains(currentUid);
    final isArchived = room.archivedUserIds.contains(currentUid);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: ChatPalette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  isMuted ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                  color: ChatPalette.textPrimary,
                ),
                title: Text(
                  isMuted ? 'Unmute chat' : 'Mute chat',
                  style: GoogleFonts.inter(color: ChatPalette.textPrimary),
                ),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  try {
                    await _toggleMute(roomId: room.id, currentlyMuted: isMuted);
                  } catch (_) {
                    _showSnack(message: 'Action failed. Please try again.');
                  }
                },
              ),
              ListTile(
                leading: Icon(
                  isArchived ? Icons.unarchive_rounded : Icons.archive_rounded,
                  color: ChatPalette.textPrimary,
                ),
                title: Text(
                  isArchived ? 'Move to inbox' : 'Archive chat',
                  style: GoogleFonts.inter(color: ChatPalette.textPrimary),
                ),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  try {
                    await _toggleArchive(
                      roomId: room.id,
                      currentlyArchived: isArchived,
                    );
                  } catch (_) {
                    _showSnack(message: 'Action failed. Please try again.');
                  }
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_rounded,
                  color: Color(0xFFCD5A5A),
                ),
                title: Text(
                  'Delete chat',
                  style: GoogleFonts.inter(color: const Color(0xFFCD5A5A)),
                ),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  try {
                    await _deleteChatWithConfirmation(
                      roomId: room.id,
                      roomTitle: room.displayTitleFor(currentUid),
                    );
                  } catch (_) {
                    _showSnack(message: 'Action failed. Please try again.');
                  }
                },
              ),
              const SizedBox(height: 4),
            ],
          ),
        );
      },
    );
  }
}

enum _InboxFilter { all, groups, direct }
