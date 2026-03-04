import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/chat/models/chat_message_model.dart';
import 'package:hash/app/modules/chat/models/chat_room_model.dart';
import 'package:hash/app/modules/chat/models/chat_user_model.dart';
import 'package:hash/app/modules/chat/services/chat_service.dart';
import 'package:hash/app/modules/chat/theme/chat_palette.dart';
import 'package:hash/app/modules/chat/views/chat_group_details_view.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service/fb_events_service.dart';
import 'package:hash/core/service/segment_sdk_service.dart';
import 'package:hash/core/service/squad_missions_service.dart';
import 'package:hash/core/service_locator.dart';
import 'package:hash/core/utils/haptics.dart';

class ChatRoomView extends StatefulWidget {
  final String roomId;

  const ChatRoomView({super.key, required this.roomId});

  @override
  State<ChatRoomView> createState() => _ChatRoomViewState();
}

class _ChatRoomViewState extends State<ChatRoomView> {
  final ChatService _chatService = Get.find<ChatService>();
  final RemoteRepoInterface _remoteRepo = locator<RemoteRepoInterface>();
  final SegmentSdkService _segmentService = locator<SegmentSdkService>();
  final FbEventsService _fbEventsService = locator<FbEventsService>();
  final SquadMissionsService _squadMissionsService =
      locator<SquadMissionsService>();
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocus = FocusNode();
  bool _isSending = false;
  bool _isTyping = false;
  final Set<String> _joiningInviteMessageIds = <String>{};
  final Map<String, String> _inviteActionStateByMessageId = <String, String>{};

  @override
  void initState() {
    super.initState();
    unawaited(
      _segmentService.onCustomEvent('Chat Room Viewed', {
        'room_id': widget.roomId,
      }),
    );
    unawaited(
      _fbEventsService.logEvent('Chat Room Viewed', {'room_id': widget.roomId}),
    );
    unawaited(
      _segmentService.onCustomEvent('Chat Started', {
        'chat_type': 'room_open',
        'room_id': widget.roomId,
      }),
    );
    unawaited(
      _fbEventsService.onChatStarted(
        chatType: 'room_open',
        roomId: widget.roomId,
      ),
    );
  }

  @override
  void dispose() {
    unawaited(_chatService.setTyping(roomId: widget.roomId, isTyping: false));
    _messageController.dispose();
    _messageFocus.dispose();
    super.dispose();
  }

  String _formatTime(DateTime dateTime) {
    final hours = dateTime.hour;
    final h12 = hours == 0
        ? 12
        : hours > 12
        ? hours - 12
        : hours;
    final suffix = hours >= 12 ? 'PM' : 'AM';
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$h12:$minute $suffix';
  }

  Future<void> _sendMessage() async {
    if (_isSending) return;
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);
    try {
      await _chatService.sendTextMessage(roomId: widget.roomId, text: text);
      _messageController.clear();
      await _chatService.setTyping(roomId: widget.roomId, isTyping: false);
      _isTyping = false;
      unawaited(
        _segmentService.onCustomEvent('Chat Message Sent', {
          'room_id': widget.roomId,
          'message_length': text.length,
          'message_type': 'text',
        }),
      );
      unawaited(
        _fbEventsService.logEvent('Chat Message Sent', {
          'room_id': widget.roomId,
          'message_length': text.length,
          'message_type': 'text',
        }),
      );
      unawaited(
        _fbEventsService.onChatMessageSent(
          roomId: widget.roomId,
          messageType: 'text',
        ),
      );
      Haptics.light();
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
        setState(() => _isSending = false);
      }
    }
  }

  Widget _buildMessageBubble({
    required ChatMessageModel message,
    required bool isMine,
    required bool isGroup,
  }) {
    if (message.type == 'team_invite') {
      return _buildTeamInviteCard(message: message, isMine: isMine);
    }

    final alignment = isMine ? Alignment.centerRight : Alignment.centerLeft;
    final bubbleColor = isMine ? ChatPalette.primary : ChatPalette.surfaceAlt;
    final textColor = isMine ? Colors.white : ChatPalette.textPrimary;

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.76,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(14),
              topRight: const Radius.circular(14),
              bottomLeft: Radius.circular(isMine ? 14 : 4),
              bottomRight: Radius.circular(isMine ? 4 : 14),
            ),
            border: Border.all(
              color: isMine
                  ? Colors.white.withValues(alpha: 0.2)
                  : ChatPalette.border.withValues(alpha: 0.6),
            ),
          ),
          child: Column(
            crossAxisAlignment: isMine
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              if (isGroup && !isMine)
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    message.senderName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: ChatPalette.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              Text(
                message.text,
                style: GoogleFonts.inter(
                  color: textColor,
                  fontSize: 14,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatTime(message.createdAt),
                style: GoogleFonts.inter(
                  color: isMine
                      ? Colors.white.withValues(alpha: 0.85)
                      : ChatPalette.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (isMine)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        message.seenBy.length > 1
                            ? Icons.done_all_rounded
                            : Icons.done_rounded,
                        size: 14,
                        color: message.seenBy.length > 1
                            ? Colors.white
                            : ChatPalette.textSecondary,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamInviteCard({
    required ChatMessageModel message,
    required bool isMine,
  }) {
    final meta = _messageMeta(message);
    final eventId = (meta['event_id'] ?? '').toString().trim();
    final teamId = (meta['team_id'] ?? '').toString().trim();
    final teamName = (meta['team_name'] ?? 'Team').toString().trim();
    final isLoading = _joiningInviteMessageIds.contains(message.id);
    final actionState = _inviteActionStateByMessageId[message.id];
    final isInvalid = eventId.isEmpty || teamId.isEmpty;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.86,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF171717), Color(0xFF0F0F0F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isMine
                  ? Colors.white.withValues(alpha: 0.22)
                  : ChatPalette.border.withValues(alpha: 0.7),
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
                      color: ChatPalette.primary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.groups_rounded,
                      size: 16,
                      color: ChatPalette.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Team Invite',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                teamName.isEmpty ? 'Team' : teamName,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isMine
                    ? 'You shared this invite in chat.'
                    : 'Tap join to join this team.',
                style: GoogleFonts.inter(
                  color: ChatPalette.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _socialProofChip(
                    icon: Icons.workspace_premium_rounded,
                    label: 'Team',
                    color: ChatPalette.accent,
                  ),
                  const SizedBox(width: 6),
                  StreamBuilder<int>(
                    stream: _squadMissionsService.watchCurrentStreakForSquad(
                      squadKey: teamId,
                    ),
                    builder: (context, snap) {
                      final streak = snap.data ?? 0;
                      return _socialProofChip(
                        icon: Icons.local_fire_department_rounded,
                        label: '${streak}d Streak',
                        color: const Color(0xFFFF8A00),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (actionState != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: actionState == 'joined'
                        ? ChatPalette.success.withValues(alpha: 0.18)
                        : Colors.redAccent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: actionState == 'joined'
                          ? ChatPalette.success
                          : Colors.redAccent,
                    ),
                  ),
                  child: Text(
                    actionState == 'joined'
                        ? 'Joined'
                        : actionState == 'already_member'
                        ? 'Already in team'
                        : 'Unable to join',
                    style: GoogleFonts.inter(
                      color: actionState == 'joined'
                          ? ChatPalette.success
                          : Colors.redAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (isMine || isLoading || isInvalid)
                        ? null
                        : () => _joinTeamInvite(
                            messageId: message.id,
                            eventId: eventId,
                            teamId: teamId,
                          ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ChatPalette.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.white12,
                      disabledForegroundColor: Colors.white54,
                      minimumSize: const Size.fromHeight(36),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            isInvalid ? 'Unavailable' : 'Join Team',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                  ),
                ),
              const SizedBox(height: 6),
              Text(
                _formatTime(message.createdAt),
                style: GoogleFonts.inter(
                  color: ChatPalette.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _socialProofChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _messageMeta(ChatMessageModel message) {
    try {
      final dynamicMessage = message as dynamic;
      final raw = dynamicMessage.meta;
      if (raw is Map<String, dynamic>) return raw;
      if (raw is Map) return Map<String, dynamic>.from(raw);
    } catch (_) {}
    return const <String, dynamic>{};
  }

  Future<void> _joinTeamInvite({
    required String messageId,
    required String eventId,
    required String teamId,
  }) async {
    if (_joiningInviteMessageIds.contains(messageId)) return;

    setState(() {
      _joiningInviteMessageIds.add(messageId);
    });

    try {
      final userId = await _chatService.resolveCurrentBackendUserId();
      if (userId == null || userId <= 0) {
        throw Exception('Unable to identify your account. Please relogin.');
      }

      await _remoteRepo.joinEventTeam(
        eventId: eventId,
        teamId: teamId,
        userId: userId,
      );

      if (!mounted) return;
      setState(() {
        _inviteActionStateByMessageId[messageId] = 'joined';
      });
      Get.snackbar(
        'Team Joined',
        'You have joined the team successfully.',
        snackPosition: SnackPosition.BOTTOM,
        colorText: Colors.white,
      );
    } catch (e) {
      if (!mounted) return;
      final error = e.toString().replaceFirst('Exception: ', '');
      final lowered = error.toLowerCase();
      setState(() {
        _inviteActionStateByMessageId[messageId] =
            lowered.contains('already') || lowered.contains('member')
            ? 'already_member'
            : 'failed';
      });
      Get.snackbar(
        'Unable to Join',
        error,
        snackPosition: SnackPosition.BOTTOM,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) {
        setState(() {
          _joiningInviteMessageIds.remove(messageId);
        });
      }
    }
  }

  Widget _buildComposer() {
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: ChatPalette.surface.withValues(alpha: 0.94),
          border: Border(
            top: BorderSide(color: ChatPalette.border.withValues(alpha: 0.8)),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                focusNode: _messageFocus,
                style: GoogleFonts.inter(color: ChatPalette.textPrimary),
                minLines: 1,
                maxLines: 4,
                onChanged: (value) async {
                  final nextTyping = value.trim().isNotEmpty;
                  if (nextTyping == _isTyping) return;
                  _isTyping = nextTyping;
                  await _chatService.setTyping(
                    roomId: widget.roomId,
                    isTyping: nextTyping,
                  );
                },
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: 'Type a message',
                  hintStyle: GoogleFonts.inter(
                    color: ChatPalette.textSecondary,
                  ),
                  filled: true,
                  fillColor: ChatPalette.inputFill,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide(
                      color: ChatPalette.border.withValues(alpha: 0.7),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide(
                      color: ChatPalette.border.withValues(alpha: 0.7),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: const BorderSide(color: ChatPalette.primary),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _isSending ? null : _sendMessage,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _isSending
                      ? ChatPalette.surfaceAlt
                      : ChatPalette.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _isSending
                        ? ChatPalette.primary.withValues(alpha: 0.35)
                        : ChatPalette.primary,
                    width: 1.6,
                  ),
                ),
                child: _isSending
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: ChatPalette.primary,
                        ),
                      )
                    : const Icon(Icons.send_rounded, color: Colors.white),
              ),
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
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        title: StreamBuilder<ChatRoomModel?>(
          stream: _chatService.streamRoom(widget.roomId),
          builder: (context, snapshot) {
            final room = snapshot.data;
            final title = room == null || currentUid == null
                ? 'Chat'
                : room.displayTitleFor(currentUid);
            final typingPeers =
                room?.typingUserIds.where((id) => id != currentUid).toList() ??
                const [];

            if (room == null) {
              return Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: ChatPalette.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              );
            }

            if (room.isGroup) {
              final subtitle = typingPeers.isNotEmpty
                  ? 'typing...'
                  : '${room.members.length} members';
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: ChatPalette.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      color: typingPeers.isNotEmpty
                          ? ChatPalette.success
                          : ChatPalette.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              );
            }

            final otherId = room.members.firstWhere(
              (id) => id != currentUid,
              orElse: () => '',
            );
            return StreamBuilder<ChatUserModel?>(
              stream: _chatService.streamUserById(otherId),
              builder: (context, otherSnap) {
                final other = otherSnap.data;
                final subtitle = typingPeers.isNotEmpty
                    ? 'typing...'
                    : other == null
                    ? 'Offline'
                    : other.isOnline
                    ? 'Online'
                    : other.lastSeenAt == null
                    ? 'Last seen recently'
                    : 'Last seen ${_formatTime(other.lastSeenAt!)}';

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: ChatPalette.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        color: typingPeers.isNotEmpty
                            ? ChatPalette.success
                            : other?.isOnline == true
                            ? ChatPalette.success
                            : ChatPalette.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
        actions: [
          StreamBuilder<ChatRoomModel?>(
            stream: _chatService.streamRoom(widget.roomId),
            builder: (context, snapshot) {
              final room = snapshot.data;
              final canOpenDetails = room?.isGroup == true;
              if (!canOpenDetails) {
                return const SizedBox.shrink();
              }

              return IconButton(
                tooltip: 'Group details',
                onPressed: () async {
                  Haptics.tap();
                  final didLeaveGroup = await Get.to<bool>(
                    () => ChatGroupDetailsView(roomId: widget.roomId),
                  );
                  if (!mounted || didLeaveGroup != true) return;
                  Get.back();
                },
                icon: const Icon(
                  Icons.info_outline_rounded,
                  color: ChatPalette.textPrimary,
                ),
              );
            },
          ),
        ],
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: ChatPalette.pageGradient),
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<ChatRoomModel?>(
                stream: _chatService.streamRoom(widget.roomId),
                builder: (context, roomSnapshot) {
                  final room = roomSnapshot.data;
                  final isGroup = room?.isGroup == true;

                  return StreamBuilder<List<ChatMessageModel>>(
                    stream: _chatService.streamRoomMessages(widget.roomId),
                    builder: (context, messagesSnapshot) {
                      if (messagesSnapshot.connectionState ==
                              ConnectionState.waiting &&
                          !(messagesSnapshot.hasData)) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: ChatPalette.primary,
                          ),
                        );
                      }

                      final messages = messagesSnapshot.data ?? const [];

                      if (messages.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 28),
                            child: Text(
                              'No messages yet. Say hi and start the conversation.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                color: ChatPalette.textSecondary,
                              ),
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        reverse: true,
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final isMine = message.senderId == currentUid;

                          return _buildMessageBubble(
                            message: message,
                            isMine: isMine,
                            isGroup: isGroup,
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
            _buildComposer(),
          ],
        ),
      ),
    );
  }
}
