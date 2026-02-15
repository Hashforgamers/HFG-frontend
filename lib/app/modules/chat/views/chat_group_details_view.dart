import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/chat/models/chat_room_model.dart';
import 'package:hash/app/modules/chat/models/chat_user_model.dart';
import 'package:hash/app/modules/chat/services/chat_service.dart';
import 'package:hash/app/modules/chat/theme/chat_palette.dart';
import 'package:hash/app/modules/chat/views/chat_invite_members_view.dart';
import 'package:hash/core/utils/haptics.dart';

class ChatGroupDetailsView extends StatefulWidget {
  final String roomId;

  const ChatGroupDetailsView({super.key, required this.roomId});

  @override
  State<ChatGroupDetailsView> createState() => _ChatGroupDetailsViewState();
}

class _ChatGroupDetailsViewState extends State<ChatGroupDetailsView> {
  final ChatService _chatService = Get.find<ChatService>();

  bool _isProcessing = false;
  bool _isLeaving = false;

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter(color: Colors.white)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Colors.redAccent : ChatPalette.surfaceAlt,
      ),
    );
  }

  String _dateLabel(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }

  Future<void> _renameGroup(ChatRoomModel room) async {
    if (_isProcessing) return;

    final controller = TextEditingController(text: room.name);
    final renamed = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: ChatPalette.surfaceAlt,
          title: Text(
            'Edit Group Name',
            style: GoogleFonts.inter(
              color: ChatPalette.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: GoogleFonts.inter(color: ChatPalette.textPrimary),
            decoration: InputDecoration(
              hintText: 'Group name',
              hintStyle: GoogleFonts.inter(color: ChatPalette.textSecondary),
              filled: true,
              fillColor: ChatPalette.inputFill,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: ChatPalette.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: ChatPalette.primary,
              ),
              child: Text(
                'Save',
                style: GoogleFonts.inter(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (renamed == null) return;

    final newName = renamed.trim();
    if (newName.isEmpty || newName == room.name.trim()) return;

    setState(() => _isProcessing = true);
    try {
      await _chatService.updateGroupName(roomId: room.id, newName: newName);
      Haptics.success();
      _showSnack('Group name updated.');
    } catch (e) {
      _showSnack(e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _inviteMembers(ChatRoomModel room) async {
    if (_isProcessing) return;

    final selectedUsers = await Get.to<List<ChatUserModel>>(
      () => ChatInviteMembersView(existingMemberIds: room.members.toSet()),
    );
    if (selectedUsers == null || selectedUsers.isEmpty) return;

    setState(() => _isProcessing = true);
    try {
      final addedCount = await _chatService.addGroupMembers(
        roomId: room.id,
        users: selectedUsers,
      );

      if (addedCount == 0) {
        _showSnack('Selected users are already in this group.');
      } else {
        Haptics.medium();
        _showSnack(
          addedCount == 1
              ? '1 member added to the group.'
              : '$addedCount members added to the group.',
        );
      }
    } catch (e) {
      _showSnack(e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _removeMember({
    required ChatRoomModel room,
    required String memberId,
    required String memberName,
  }) async {
    if (_isProcessing) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: ChatPalette.surfaceAlt,
          title: Text(
            'Remove Member',
            style: GoogleFonts.inter(
              color: ChatPalette.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'Remove $memberName from this group?',
            style: GoogleFonts.inter(color: ChatPalette.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: ChatPalette.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text(
                'Remove',
                style: GoogleFonts.inter(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);
    try {
      await _chatService.removeGroupMember(roomId: room.id, memberId: memberId);
      Haptics.warning();
      _showSnack('$memberName removed from the group.');
    } catch (e) {
      _showSnack(e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _leaveGroup(ChatRoomModel room) async {
    if (_isLeaving) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: ChatPalette.surfaceAlt,
          title: Text(
            'Leave Group',
            style: GoogleFonts.inter(
              color: ChatPalette.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'Are you sure you want to leave this group?',
            style: GoogleFonts.inter(color: ChatPalette.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: ChatPalette.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text(
                'Leave',
                style: GoogleFonts.inter(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() => _isLeaving = true);
    try {
      await _chatService.leaveGroup(room.id);
      Haptics.heavy();
      if (mounted) {
        Get.back<bool>(result: true);
      }
    } catch (e) {
      _showSnack(e.toString().replaceFirst('Exception: ', ''), isError: true);
      if (mounted) {
        setState(() => _isLeaving = false);
      }
    }
  }

  Widget _buildMemberCard({
    required ChatRoomModel room,
    required String memberId,
    required String currentUid,
  }) {
    final isAdmin = room.admins.contains(memberId);
    final isMe = memberId == currentUid;
    final memberName = (room.memberNames[memberId] ?? '').trim();
    final title = memberName.isEmpty
        ? (isMe ? 'You' : 'Member')
        : (isMe ? '$memberName (You)' : memberName);
    final canRemove = room.admins.contains(currentUid) && !isMe;
    final initial = title.trim().isEmpty ? 'M' : title.trim()[0].toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        gradient: ChatPalette.cardGradient,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ChatPalette.border.withValues(alpha: 0.6)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: isAdmin
              ? ChatPalette.accent
              : ChatPalette.primaryDark,
          child: Text(
            initial,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            color: ChatPalette.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          memberId,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            color: ChatPalette.textSecondary,
            fontSize: 11,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isAdmin)
              Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: ChatPalette.accent.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: ChatPalette.accent.withValues(alpha: 0.6),
                  ),
                ),
                child: Text(
                  'Admin',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            if (canRemove)
              IconButton(
                onPressed: _isProcessing
                    ? null
                    : () => _removeMember(
                        room: room,
                        memberId: memberId,
                        memberName: memberName.isEmpty ? 'Member' : memberName,
                      ),
                icon: const Icon(Icons.person_remove_alt_1_rounded),
                color: Colors.redAccent,
                tooltip: 'Remove member',
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = _chatService.currentUid;

    return Scaffold(
      backgroundColor: ChatPalette.bgBottom,
      appBar: AppBar(
        backgroundColor: ChatPalette.surface,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Group Details',
          style: GoogleFonts.inter(
            color: ChatPalette.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: ChatPalette.pageGradient),
        child: currentUid == null
            ? Center(
                child: Text(
                  'Please sign in to continue.',
                  style: GoogleFonts.inter(color: ChatPalette.textSecondary),
                ),
              )
            : StreamBuilder<ChatRoomModel?>(
                stream: _chatService.streamRoom(widget.roomId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: ChatPalette.primary,
                      ),
                    );
                  }

                  final room = snapshot.data;
                  if (room == null) {
                    return Center(
                      child: Text(
                        'Group not found.',
                        style: GoogleFonts.inter(
                          color: ChatPalette.textSecondary,
                        ),
                      ),
                    );
                  }

                  if (!room.isGroup) {
                    return Center(
                      child: Text(
                        'This conversation is not a group chat.',
                        style: GoogleFonts.inter(
                          color: ChatPalette.textSecondary,
                        ),
                      ),
                    );
                  }

                  final isCurrentUserAdmin = room.admins.contains(currentUid);
                  final members = List<String>.from(room.members)
                    ..sort((a, b) {
                      final aAdmin = room.admins.contains(a);
                      final bAdmin = room.admins.contains(b);
                      if (aAdmin != bAdmin) return aAdmin ? -1 : 1;
                      final aName = (room.memberNames[a] ?? a)
                          .toLowerCase()
                          .trim();
                      final bName = (room.memberNames[b] ?? b)
                          .toLowerCase()
                          .trim();
                      return aName.compareTo(bName);
                    });

                  return ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: ChatPalette.cardGradient,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: ChatPalette.border.withValues(alpha: 0.6),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        room.name.trim().isEmpty
                                            ? 'Group Chat'
                                            : room.name,
                                        style: GoogleFonts.inter(
                                          color: ChatPalette.textPrimary,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '${room.members.length} members • Created ${_dateLabel(room.createdAt)}',
                                        style: GoogleFonts.inter(
                                          color: ChatPalette.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isCurrentUserAdmin)
                                  IconButton(
                                    onPressed: _isProcessing
                                        ? null
                                        : () => _renameGroup(room),
                                    icon: const Icon(
                                      Icons.edit_rounded,
                                      color: ChatPalette.primary,
                                    ),
                                    tooltip: 'Rename group',
                                  ),
                              ],
                            ),
                            if (isCurrentUserAdmin)
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _isProcessing
                                        ? null
                                        : () => _inviteMembers(room),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: ChatPalette.primary,
                                      disabledBackgroundColor:
                                          ChatPalette.primaryDark,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 11,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.person_add_alt_1_rounded,
                                      color: Colors.white,
                                    ),
                                    label: Text(
                                      'Invite Members',
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Members',
                        style: GoogleFonts.inter(
                          color: ChatPalette.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...members.map(
                        (memberId) => _buildMemberCard(
                          room: room,
                          memberId: memberId,
                          currentUid: currentUid,
                        ),
                      ),
                      const SizedBox(height: 4),
                      OutlinedButton.icon(
                        onPressed: _isLeaving ? null : () => _leaveGroup(room),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: BorderSide(
                            color: Colors.redAccent.withValues(alpha: 0.7),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: _isLeaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.redAccent,
                                ),
                              )
                            : const Icon(Icons.logout_rounded),
                        label: Text(
                          _isLeaving ? 'Leaving...' : 'Leave Group',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }
}
