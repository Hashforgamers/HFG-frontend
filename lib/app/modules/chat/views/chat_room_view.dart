import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/chat/models/chat_message_model.dart';
import 'package:hash/app/modules/chat/models/chat_room_model.dart';
import 'package:hash/app/modules/chat/services/chat_service.dart';
import 'package:hash/app/modules/chat/theme/chat_palette.dart';
import 'package:hash/app/modules/chat/views/chat_group_details_view.dart';
import 'package:hash/core/utils/haptics.dart';

class ChatRoomView extends StatefulWidget {
  final String roomId;

  const ChatRoomView({super.key, required this.roomId});

  @override
  State<ChatRoomView> createState() => _ChatRoomViewState();
}

class _ChatRoomViewState extends State<ChatRoomView> {
  final ChatService _chatService = Get.find<ChatService>();
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocus = FocusNode();
  static const Color _neonGreen = Color(0xff00DC00);

  bool _isSending = false;

  @override
  void dispose() {
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
    final alignment = isMine ? Alignment.centerRight : Alignment.centerLeft;
    final bubbleColor = isMine ? Colors.black : ChatPalette.surfaceAlt;
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
                  ? _neonGreen.withValues(alpha: 0.75)
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
                      color: _neonGreen,
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
                      ? _neonGreen.withValues(alpha: 0.82)
                      : ChatPalette.textSecondary,
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
                    borderSide: BorderSide.none,
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
                  color: Colors.black,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _isSending
                        ? _neonGreen.withValues(alpha: 0.35)
                        : _neonGreen,
                    width: 1.6,
                  ),
                ),
                child: _isSending
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _neonGreen,
                        ),
                      )
                    : const Icon(Icons.send_rounded, color: _neonGreen),
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
            final subtitle = room == null
                ? null
                : room.isGroup
                ? '${room.members.length} members'
                : 'Direct chat';

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
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      color: ChatPalette.textSecondary,
                      fontSize: 11,
                    ),
                  ),
              ],
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
