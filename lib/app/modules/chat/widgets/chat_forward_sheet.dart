import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/chat/models/chat_room_model.dart';
import 'package:hash/app/modules/chat/services/chat_service.dart';
import 'package:hash/app/modules/chat/theme/chat_palette.dart';

/// Lets the user pick which of their chats a message is forwarded to.
/// Resolves to the chosen rooms, or null when dismissed.
Future<List<ChatRoomModel>?> showChatForwardSheet(
  BuildContext context, {
  required ChatService chatService,
}) {
  return showModalBottomSheet<List<ChatRoomModel>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: ChatPalette.roomBar,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (_) => _ChatForwardSheet(chatService: chatService),
  );
}

class _ChatForwardSheet extends StatefulWidget {
  const _ChatForwardSheet({required this.chatService});

  final ChatService chatService;

  @override
  State<_ChatForwardSheet> createState() => _ChatForwardSheetState();
}

class _ChatForwardSheetState extends State<_ChatForwardSheet> {
  final Map<String, ChatRoomModel> _selected = {};

  @override
  Widget build(BuildContext context) {
    final uid = widget.chatService.currentUid ?? '';
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.7,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Forward to',
                      style: GoogleFonts.inter(
                        color: ChatPalette.roomText,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _selected.isEmpty
                        ? null
                        : () => Navigator.of(
                            context,
                          ).pop(_selected.values.toList()),
                    child: Text(
                      _selected.isEmpty ? 'Send' : 'Send (${_selected.length})',
                      style: GoogleFonts.inter(
                        color: _selected.isEmpty
                            ? ChatPalette.roomTextMuted
                            : ChatPalette.roomAccent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<List<ChatRoomModel>>(
                stream: widget.chatService.streamCurrentUserRooms(),
                builder: (context, snapshot) {
                  // Dispute and tournament rooms are managed by the backend.
                  final rooms = (snapshot.data ?? const <ChatRoomModel>[])
                      .where((room) => !room.isTournamentConversation)
                      .toList();
                  if (rooms.isEmpty) {
                    return Center(
                      child: Text(
                        snapshot.hasData
                            ? 'No chats to forward to yet.'
                            : 'Loading chats...',
                        style: GoogleFonts.inter(
                          color: ChatPalette.roomTextMuted,
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: rooms.length,
                    itemBuilder: (context, index) {
                      final room = rooms[index];
                      final title = room.displayTitleFor(uid);
                      final isSelected = _selected.containsKey(room.id);
                      return ListTile(
                        onTap: () => setState(() {
                          if (isSelected) {
                            _selected.remove(room.id);
                          } else {
                            _selected[room.id] = room;
                          }
                        }),
                        leading: CircleAvatar(
                          backgroundColor: ChatPalette.avatarFill,
                          child: Icon(
                            room.isGroup
                                ? Icons.groups_rounded
                                : Icons.person_rounded,
                            color: ChatPalette.roomTextMuted,
                          ),
                        ),
                        title: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(color: ChatPalette.roomText),
                        ),
                        trailing: Icon(
                          isSelected
                              ? Icons.check_circle_rounded
                              : Icons.circle_outlined,
                          color: isSelected
                              ? ChatPalette.roomAccent
                              : ChatPalette.roomTextMuted,
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
