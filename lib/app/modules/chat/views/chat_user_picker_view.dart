import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hash/utils/widgets/loader.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/chat/models/chat_user_model.dart';
import 'package:hash/app/modules/chat/services/chat_service.dart';
import 'package:hash/app/modules/chat/theme/chat_palette.dart';
import 'package:hash/app/modules/chat/views/chat_room_view.dart';
import 'package:hash/core/service/fb_events_service.dart';
import 'package:hash/core/service/segment_sdk_service.dart';
import 'package:hash/core/service_locator.dart';
import 'package:hash/core/utils/haptics.dart';

class ChatUserPickerView extends StatefulWidget {
  const ChatUserPickerView({super.key});

  @override
  State<ChatUserPickerView> createState() => _ChatUserPickerViewState();
}

class _ChatUserPickerViewState extends State<ChatUserPickerView> {
  final ChatService _chatService = Get.find<ChatService>();
  final SegmentSdkService _segmentService = locator<SegmentSdkService>();
  final FbEventsService _fbEventsService = locator<FbEventsService>();
  final TextEditingController _searchController = TextEditingController();

  final List<ChatUserModel> _users = <ChatUserModel>[];
  Timer? _searchDebounce;

  String _query = '';
  String? _searchError;
  int _searchRequestId = 0;
  bool _isLoadingUsers = true;
  bool _isStartingChat = false;
  bool _isMutatingHistory = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChange);
    _runSearch();
    unawaited(
      _segmentService.onCustomEvent('Chat User Picker Viewed', {
        'source': 'new_chat',
      }),
    );
    unawaited(
      _fbEventsService.logEvent('Chat User Picker Viewed', {
        'source': 'new_chat',
      }),
    );
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.removeListener(_onSearchChange);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChange() {
    final next = _searchController.text.trim().toLowerCase();
    if (next == _query) return;
    _query = next;

    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), _runSearch);
  }

  Future<void> _runSearch() async {
    final requestId = ++_searchRequestId;

    if (mounted) {
      setState(() {
        _isLoadingUsers = true;
        _searchError = null;
      });
    }

    try {
      final users = _query.isEmpty
          ? await _chatService.recentChatUsers()
          : await _chatService.searchUsers(_query);
      if (!mounted || requestId != _searchRequestId) return;

      setState(() {
        _users
          ..clear()
          ..addAll(users);
        _isLoadingUsers = false;
      });
    } catch (e) {
      if (!mounted || requestId != _searchRequestId) return;
      setState(() {
        _users.clear();
        _searchError = 'Unable to load users right now.';
        _isLoadingUsers = false;
      });
    }
  }

  Future<void> _startDirectChat(ChatUserModel user) async {
    if (_isStartingChat) return;

    setState(() => _isStartingChat = true);
    try {
      final roomId = await _chatService.getOrCreateDirectRoom(otherUser: user);
      if (!mounted) return;
      unawaited(
        _segmentService.onCustomEvent('Direct Chat Started', {
          'room_id': roomId,
          'target_uid': user.uid,
        }),
      );
      unawaited(
        _segmentService.onCustomEvent('Chat Started', {
          'chat_type': 'direct',
          'room_id': roomId,
        }),
      );
      unawaited(
        _fbEventsService.onChatStarted(chatType: 'direct', roomId: roomId),
      );
      Haptics.medium();
      Get.off(() => ChatRoomView(roomId: roomId));
    } catch (e) {
      if (!mounted) return;
      Get.snackbar(
        'Chat',
        e.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) {
        setState(() => _isStartingChat = false);
      }
    }
  }

  Future<void> _removeFromHistory(ChatUserModel user) async {
    if (_query.isNotEmpty || _isMutatingHistory) return;
    setState(() => _isMutatingHistory = true);
    try {
      await _chatService.removeUserFromRecentSearchHistory(user.uid);
      await _runSearch();
      if (!mounted) return;
      Get.snackbar(
        'History updated',
        'Removed from recent search history',
        snackPosition: SnackPosition.BOTTOM,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) {
        setState(() => _isMutatingHistory = false);
      }
    }
  }

  Future<void> _clearHistory() async {
    if (_query.isNotEmpty || _isMutatingHistory || _users.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Clear search history?',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'This removes all recent users from your search history list.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('Cancel', style: GoogleFonts.inter()),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('Clear', style: GoogleFonts.inter()),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isMutatingHistory = true);
    try {
      await _chatService.clearRecentSearchHistory();
      await _runSearch();
      if (!mounted) return;
      Get.snackbar(
        'History cleared',
        'Recent search history removed',
        snackPosition: SnackPosition.BOTTOM,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) {
        setState(() => _isMutatingHistory = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChatPalette.bgBottom,
      appBar: AppBar(
        backgroundColor: ChatPalette.bgBottom,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Start New Chat',
          style: GoogleFonts.inter(
            color: ChatPalette.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          if (_query.isEmpty && _users.isNotEmpty)
            TextButton(
              onPressed: _isMutatingHistory ? null : _clearHistory,
              child: Text(
                'Clear',
                style: GoogleFonts.inter(
                  color: ChatPalette.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
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
                  hintText: 'Search players',
                  hintStyle: GoogleFonts.inter(
                    color: ChatPalette.textSecondary,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: ChatPalette.textSecondary,
                  ),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          onPressed: _searchController.clear,
                          icon: const Icon(
                            Icons.close_rounded,
                            color: ChatPalette.textSecondary,
                            size: 18,
                          ),
                        ),
                  filled: true,
                  fillColor: ChatPalette.inputFill,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: ChatPalette.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: ChatPalette.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: ChatPalette.primary),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Builder(
                builder: (_) {
                  if (_isLoadingUsers) {
                    return const AppLinearLoader.screen();
                  }

                  if (_searchError != null) {
                    return Center(
                      child: Text(
                        _searchError!,
                        style: GoogleFonts.inter(
                          color: ChatPalette.textSecondary,
                        ),
                      ),
                    );
                  }

                  if (_users.isEmpty) {
                    return Center(
                      child: Text(
                        _query.isEmpty
                            ? 'No recent chats yet. Search to start a new chat.'
                            : 'No users found.',
                        style: GoogleFonts.inter(
                          color: ChatPalette.textSecondary,
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                    itemCount: _users.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1, color: ChatPalette.border),
                    itemBuilder: (context, index) {
                      final user = _users[index];
                      final display = user.displayName.trim().isEmpty
                          ? 'Player'
                          : user.displayName;
                      final username = user.username.trim();
                      final prefix = display[0].toUpperCase();
                      final isHistoryMode = _query.isEmpty;

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.zero,
                          onTap: _isStartingChat
                              ? null
                              : () => _startDirectChat(user),
                          child: Ink(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 17,
                                    backgroundColor: ChatPalette.primaryDark,
                                    backgroundImage: user.photoUrl.isNotEmpty
                                        ? NetworkImage(user.photoUrl)
                                        : null,
                                    child: user.photoUrl.isEmpty
                                        ? Text(
                                            prefix,
                                            style: GoogleFonts.inter(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12,
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          display,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.inter(
                                            color: ChatPalette.textPrimary,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                        if (username.isNotEmpty)
                                          Text(
                                            '@$username',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.inter(
                                              color: ChatPalette.primary,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        if (user.email.isNotEmpty)
                                          Text(
                                            user.email,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.inter(
                                              color: ChatPalette.textSecondary,
                                              fontSize: 11,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (isHistoryMode)
                                    IconButton(
                                      tooltip: 'Remove from history',
                                      splashRadius: 16,
                                      visualDensity: const VisualDensity(
                                        horizontal: -4,
                                        vertical: -4,
                                      ),
                                      onPressed: _isMutatingHistory
                                          ? null
                                          : () => _removeFromHistory(user),
                                      icon: const Icon(
                                        Icons.close_rounded,
                                        color: ChatPalette.textSecondary,
                                        size: 18,
                                      ),
                                    )
                                  else if (_isStartingChat)
                                    const AppLinearLoader(width: 28, height: 3)
                                  else
                                    const Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      color: ChatPalette.textSecondary,
                                      size: 14,
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
