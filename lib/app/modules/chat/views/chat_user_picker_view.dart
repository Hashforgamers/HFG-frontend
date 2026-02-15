import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/chat/models/chat_user_model.dart';
import 'package:hash/app/modules/chat/services/chat_service.dart';
import 'package:hash/app/modules/chat/theme/chat_palette.dart';
import 'package:hash/app/modules/chat/views/chat_room_view.dart';
import 'package:hash/core/utils/haptics.dart';

class ChatUserPickerView extends StatefulWidget {
  const ChatUserPickerView({super.key});

  @override
  State<ChatUserPickerView> createState() => _ChatUserPickerViewState();
}

class _ChatUserPickerViewState extends State<ChatUserPickerView> {
  final ChatService _chatService = Get.find<ChatService>();
  final TextEditingController _searchController = TextEditingController();

  final List<ChatUserModel> _users = <ChatUserModel>[];
  Timer? _searchDebounce;

  String _query = '';
  String? _searchError;
  int _searchRequestId = 0;
  bool _isLoadingUsers = true;
  bool _isStartingChat = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChange);
    _runSearch();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChatPalette.bgBottom,
      appBar: AppBar(
        backgroundColor: ChatPalette.surface,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Start New Chat',
          style: GoogleFonts.inter(
            color: ChatPalette.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
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
                  hintText: 'Search players',
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
              child: Builder(
                builder: (_) {
                  if (_isLoadingUsers) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: ChatPalette.primary,
                      ),
                    );
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
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final user = _users[index];
                      final display = user.displayName.trim().isEmpty
                          ? 'Player'
                          : user.displayName;
                      final username = user.username.trim();
                      final prefix = display[0].toUpperCase();

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: _isStartingChat
                              ? null
                              : () => _startDirectChat(user),
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
                                  CircleAvatar(
                                    radius: 20,
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
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          display,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.inter(
                                            color: ChatPalette.textPrimary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (username.isNotEmpty)
                                          Text(
                                            '@$username',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.inter(
                                              color: ChatPalette.primary,
                                              fontSize: 12,
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
                                              fontSize: 12,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (_isStartingChat)
                                    const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: ChatPalette.primary,
                                      ),
                                    )
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
