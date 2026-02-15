import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/chat/models/chat_user_model.dart';
import 'package:hash/app/modules/chat/services/chat_service.dart';
import 'package:hash/app/modules/chat/theme/chat_palette.dart';
import 'package:hash/core/utils/haptics.dart';

class ChatInviteMembersView extends StatefulWidget {
  final Set<String> existingMemberIds;

  const ChatInviteMembersView({super.key, required this.existingMemberIds});

  @override
  State<ChatInviteMembersView> createState() => _ChatInviteMembersViewState();
}

class _ChatInviteMembersViewState extends State<ChatInviteMembersView> {
  final ChatService _chatService = Get.find<ChatService>();
  final TextEditingController _searchController = TextEditingController();

  final Map<String, ChatUserModel> _cacheById = <String, ChatUserModel>{};
  final List<ChatUserModel> _visibleUsers = <ChatUserModel>[];
  final Set<String> _selectedIds = <String>{};

  Timer? _searchDebounce;
  String _query = '';
  String? _searchError;
  int _searchRequestId = 0;
  bool _isLoadingUsers = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _runSearch();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
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
      final users = await _chatService.searchUsers(_query);
      if (!mounted || requestId != _searchRequestId) return;

      final filteredUsers = users.where((user) {
        return !widget.existingMemberIds.contains(user.uid);
      }).toList();

      setState(() {
        for (final user in filteredUsers) {
          _cacheById[user.uid] = user;
        }
        _visibleUsers
          ..clear()
          ..addAll(filteredUsers);
        _isLoadingUsers = false;
      });
    } catch (_) {
      if (!mounted || requestId != _searchRequestId) return;
      setState(() {
        _visibleUsers.clear();
        _searchError = 'Unable to load users right now.';
        _isLoadingUsers = false;
      });
    }
  }

  void _submitSelection() {
    if (_selectedIds.isEmpty) {
      Get.back<List<ChatUserModel>>(result: const <ChatUserModel>[]);
      return;
    }

    final selectedUsers = _selectedIds
        .map((id) => _cacheById[id])
        .whereType<ChatUserModel>()
        .toList();

    Haptics.medium();
    Get.back<List<ChatUserModel>>(result: selectedUsers);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChatPalette.bgBottom,
      appBar: AppBar(
        backgroundColor: ChatPalette.surface,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Invite Members',
          style: GoogleFonts.inter(
            color: ChatPalette.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _submitSelection,
            child: Text(
              _selectedIds.isEmpty ? 'Done' : 'Add (${_selectedIds.length})',
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
            if (_selectedIds.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    Text(
                      'Selected: ${_selectedIds.length}',
                      style: GoogleFonts.inter(
                        color: ChatPalette.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
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

                  if (_visibleUsers.isEmpty) {
                    return Center(
                      child: Text(
                        'No users available to invite.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: ChatPalette.textSecondary,
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                    itemCount: _visibleUsers.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final user = _visibleUsers[index];
                      final isSelected = _selectedIds.contains(user.uid);
                      final name = user.displayName.trim().isEmpty
                          ? 'Player'
                          : user.displayName;
                      final username = user.username.trim();

                      return Ink(
                        decoration: BoxDecoration(
                          gradient: ChatPalette.cardGradient,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? ChatPalette.primary
                                : ChatPalette.border.withValues(alpha: 0.6),
                          ),
                        ),
                        child: CheckboxListTile(
                          value: isSelected,
                          activeColor: ChatPalette.primary,
                          checkColor: Colors.white,
                          title: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: ChatPalette.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: user.email.isNotEmpty
                              ? Text(
                                  username.isNotEmpty
                                      ? '@$username • ${user.email}'
                                      : user.email,
                                  style: GoogleFonts.inter(
                                    color: ChatPalette.textSecondary,
                                    fontSize: 12,
                                  ),
                                )
                              : (username.isNotEmpty
                                    ? Text(
                                        '@$username',
                                        style: GoogleFonts.inter(
                                          color: ChatPalette.primary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      )
                                    : null),
                          onChanged: (checked) {
                            Haptics.selection();
                            setState(() {
                              if (checked == true) {
                                _selectedIds.add(user.uid);
                              } else {
                                _selectedIds.remove(user.uid);
                              }
                            });
                          },
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
