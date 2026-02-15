import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/chat/models/chat_user_model.dart';
import 'package:hash/app/modules/chat/services/chat_service.dart';
import 'package:hash/app/modules/chat/theme/chat_palette.dart';
import 'package:hash/app/modules/chat/views/chat_room_view.dart';
import 'package:hash/core/utils/haptics.dart';

class ChatCreateGroupView extends StatefulWidget {
  const ChatCreateGroupView({super.key});

  @override
  State<ChatCreateGroupView> createState() => _ChatCreateGroupViewState();
}

class _ChatCreateGroupViewState extends State<ChatCreateGroupView> {
  final ChatService _chatService = Get.find<ChatService>();
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  final Map<String, ChatUserModel> _userCacheById = <String, ChatUserModel>{};
  final Set<String> _selectedUserIds = <String>{};
  final List<ChatUserModel> _visibleUsers = <ChatUserModel>[];

  Timer? _searchDebounce;
  String _query = '';
  String? _searchError;
  int _searchRequestId = 0;
  bool _isLoadingUsers = true;
  bool _isCreatingGroup = false;

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
    _groupNameController.dispose();
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

      setState(() {
        for (final user in users) {
          _userCacheById[user.uid] = user;
        }
        _visibleUsers
          ..clear()
          ..addAll(users);
        _isLoadingUsers = false;
      });
    } catch (e) {
      if (!mounted || requestId != _searchRequestId) return;
      setState(() {
        _visibleUsers.clear();
        _searchError = 'Unable to load users right now.';
        _isLoadingUsers = false;
      });
    }
  }

  Future<void> _createGroup() async {
    if (_isCreatingGroup) return;

    final name = _groupNameController.text.trim();
    final selectedUsers = _selectedUserIds
        .map((id) => _userCacheById[id])
        .whereType<ChatUserModel>()
        .toList();

    if (name.isEmpty) {
      Get.snackbar(
        'Group Chat',
        'Please enter a group name.',
        snackPosition: SnackPosition.BOTTOM,
        colorText: Colors.white,
      );
      return;
    }

    if (selectedUsers.isEmpty) {
      Get.snackbar(
        'Group Chat',
        'Select at least one participant.',
        snackPosition: SnackPosition.BOTTOM,
        colorText: Colors.white,
      );
      return;
    }

    setState(() => _isCreatingGroup = true);

    try {
      final roomId = await _chatService.createGroupRoom(
        name: name,
        selectedUsers: selectedUsers,
      );

      if (!mounted) return;
      Haptics.medium();
      Get.off(() => ChatRoomView(roomId: roomId));
    } catch (e) {
      if (!mounted) return;
      Get.snackbar(
        'Group Chat',
        e.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) {
        setState(() => _isCreatingGroup = false);
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
          'Create Group',
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
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: TextField(
                controller: _groupNameController,
                style: GoogleFonts.inter(color: ChatPalette.textPrimary),
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  hintText: 'Group name',
                  hintStyle: GoogleFonts.inter(
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
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
            if (_selectedUserIds.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    Text(
                      'Selected: ${_selectedUserIds.length}',
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
                        'No users found.',
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
                      final isSelected = _selectedUserIds.contains(user.uid);
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
                                _selectedUserIds.add(user.uid);
                              } else {
                                _selectedUserIds.remove(user.uid);
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
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isCreatingGroup ? null : _createGroup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ChatPalette.primary,
                      disabledBackgroundColor: ChatPalette.primaryDark,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isCreatingGroup
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Create Group',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
