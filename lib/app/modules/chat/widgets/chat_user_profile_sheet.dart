import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/chat/models/chat_user_model.dart';
import 'package:hash/app/modules/chat/services/chat_service.dart';
import 'package:hash/app/modules/chat/theme/chat_palette.dart';
import 'package:hash/app/modules/chat/views/chat_room_view.dart';
import 'package:hash/core/utils/app_snackbar.dart';

/// Another player's profile card, opened by tapping their name or avatar in
/// a chat. [canMessage] is false inside the direct chat with that player.
Future<void> showChatUserProfileSheet(
  BuildContext context, {
  required ChatService chatService,
  required String uid,
  required String fallbackName,
  bool canMessage = true,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: ChatPalette.roomBar,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (sheetContext) => SafeArea(
      child: StreamBuilder<ChatUserModel?>(
        stream: chatService.streamUserById(uid),
        builder: (context, snapshot) {
          final user = snapshot.data;
          final name = (user?.displayName.trim().isNotEmpty ?? false)
              ? user!.displayName.trim()
              : fallbackName;
          final username = user?.username.trim() ?? '';
          final photoUrl = user?.photoUrl.trim() ?? '';
          final status = user == null
              ? ''
              : user.isOnline
              ? 'Online'
              : 'Last seen recently';
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 38,
                  backgroundColor: ChatPalette.roomAccent,
                  backgroundImage: photoUrl.isEmpty
                      ? null
                      : CachedNetworkImageProvider(photoUrl),
                  child: photoUrl.isNotEmpty
                      ? null
                      : Text(
                          name.isEmpty
                              ? '#'
                              : name.characters.first.toUpperCase(),
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
                const SizedBox(height: 12),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: ChatPalette.roomText,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (username.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    '@$username',
                    style: GoogleFonts.inter(
                      color: ChatPalette.roomTextMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
                if (status.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    status,
                    style: GoogleFonts.inter(
                      color: user!.isOnline
                          ? ChatPalette.roomAccent
                          : ChatPalette.roomTextMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
                if (canMessage && user != null) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final navigator = Navigator.of(sheetContext);
                        try {
                          final roomId = await chatService
                              .getOrCreateDirectRoom(otherUser: user);
                          navigator.pop();
                          Get.to(() => ChatRoomView(roomId: roomId));
                        } catch (e) {
                          AppSnackbar.show(
                            'Chat',
                            e.toString().replaceFirst('Exception: ', ''),
                            snackPosition: SnackPosition.BOTTOM,
                            colorText: Colors.white,
                          );
                        }
                      },
                      icon: const Icon(Icons.chat_bubble_rounded, size: 18),
                      label: const Text('Message'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ChatPalette.roomAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    ),
  );
}
