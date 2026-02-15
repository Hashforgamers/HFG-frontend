import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/chat/models/chat_room_model.dart';
import 'package:hash/app/modules/chat/services/chat_service.dart';
import 'package:hash/app/modules/chat/theme/chat_palette.dart';
import 'package:hash/app/modules/chat/views/chat_create_group_view.dart';
import 'package:hash/app/modules/chat/views/chat_room_view.dart';
import 'package:hash/app/modules/chat/views/chat_user_picker_view.dart';
import 'package:hash/core/utils/haptics.dart';

class ChatInboxView extends StatefulWidget {
  const ChatInboxView({super.key});

  @override
  State<ChatInboxView> createState() => _ChatInboxViewState();
}

class _ChatInboxViewState extends State<ChatInboxView> {
  final ChatService _chatService = Get.find<ChatService>();
  final TextEditingController _searchController = TextEditingController();
  bool _didHandleInitialRoomNavigation = false;

  String _query = '';

  @override
  void initState() {
    super.initState();
    _chatService.ensureCurrentUserProfile();
    _searchController.addListener(_handleSearchChanged);
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
    if (_query.isEmpty) return rooms;

    return rooms.where((room) {
      final title = room.displayTitleFor(currentUid).toLowerCase();
      final subtitle = room.subtitleFor(currentUid).toLowerCase();
      return title.contains(_query) || subtitle.contains(_query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = _chatService.currentUid;
    const neonGreen = Color(0xff00DC00);

    if (currentUid == null) {
      return Scaffold(
        backgroundColor: ChatPalette.bgBottom,
        appBar: AppBar(
          backgroundColor: ChatPalette.surface,
          surfaceTintColor: Colors.transparent,
          title: Text(
            'Chats',
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
          'Chats',
          style: GoogleFonts.inter(
            color: ChatPalette.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Haptics.medium();
          Get.to(() => const ChatUserPickerView());
        },
        backgroundColor: Colors.black,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: neonGreen, width: 1.6),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
            bottomLeft: Radius.circular(28),
            bottomRight: Radius.circular(0),
          ),
        ),
        icon: Image.asset(
          'assets/chat.png',
          width: 20,
          height: 20,
          color: neonGreen,
          fit: BoxFit.contain,
        ),
        label: Text(
          'New Chat',
          style: GoogleFonts.inter(
            color: neonGreen,
            fontWeight: FontWeight.w600,
          ),
        ),
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
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
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
                      final stamp = room.lastMessageAt ?? room.updatedAt;
                      final prefix = title.isEmpty
                          ? 'C'
                          : title[0].toUpperCase();

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
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: ChatPalette.border.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
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
                                          : ChatPalette.primaryDark,
                                    ),
                                    child: Center(
                                      child: room.isGroup
                                          ? const Icon(
                                              Icons.groups_rounded,
                                              color: Colors.white,
                                              size: 20,
                                            )
                                          : Text(
                                              prefix,
                                              style: GoogleFonts.inter(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                              ),
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
                                        const SizedBox(height: 4),
                                        Text(
                                          subtitle,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.inter(
                                            color: ChatPalette.textSecondary,
                                            fontSize: 12,
                                          ),
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
}
