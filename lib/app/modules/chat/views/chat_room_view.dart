import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hash/utils/widgets/loader.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/chat/models/chat_message_model.dart';
import 'package:hash/app/modules/chat/models/chat_room_model.dart';
import 'package:hash/app/modules/chat/models/chat_user_model.dart';
import 'package:hash/app/modules/chat/services/chat_service.dart';
import 'package:hash/app/modules/chat/theme/chat_palette.dart';
import 'package:hash/app/modules/chat/views/chat_group_details_view.dart';
import 'package:hash/app/modules/community/services/community_api.dart';
import 'package:hash/app/modules/tournaments_section/models/tournament_model.dart';
import 'package:hash/app/modules/tournaments_section/pages/tournaments_details_view.dart';
import 'package:hash/app/routes/app_routes.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service/fb_events_service.dart';
import 'package:hash/core/service/segment_sdk_service.dart';
import 'package:hash/core/service/squad_missions_service.dart';
import 'package:hash/core/service_locator.dart';
import 'package:hash/core/utils/haptics.dart';

class ChatRoomView extends StatefulWidget {
  final String roomId;
  final String? roomCollection;

  const ChatRoomView({super.key, required this.roomId, this.roomCollection});

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
    unawaited(
      _chatService.setTyping(
        roomId: widget.roomId,
        isTyping: false,
        collection: widget.roomCollection,
      ),
    );
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

  String _formatBookingDateLabel(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    final parsed = DateTime.tryParse(trimmed);
    if (parsed == null) return trimmed;
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
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
    final weekday = weekdays[parsed.weekday - 1];
    final month = months[parsed.month - 1];
    return '$weekday, ${parsed.day} $month';
  }

  String _formatClockLabel(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    final parts = trimmed.split(':');
    if (parts.length < 2) return trimmed;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return trimmed;
    final normalizedHour = hour % 24;
    final h12 = normalizedHour == 0
        ? 12
        : normalizedHour > 12
        ? normalizedHour - 12
        : normalizedHour;
    final suffix = normalizedHour >= 12 ? 'PM' : 'AM';
    if (minute == 0) return '$h12 $suffix';
    return '$h12:${minute.toString().padLeft(2, '0')} $suffix';
  }

  String _formatSlotLabel(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    final parts = trimmed.split(' - ');
    if (parts.length != 2) return trimmed;
    final start = _formatClockLabel(parts[0]);
    final end = _formatClockLabel(parts[1]);
    if (start.isEmpty || end.isEmpty) return trimmed;
    return '$start to $end';
  }

  Future<void> _sendMessage() async {
    if (_isSending) return;
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);
    try {
      await _chatService.sendTextMessage(
        roomId: widget.roomId,
        text: text,
        collection: widget.roomCollection,
      );
      _messageController.clear();
      await _chatService.setTyping(
        roomId: widget.roomId,
        isTyping: false,
        collection: widget.roomCollection,
      );
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
    if (message.type == 'tournament_deep_link') {
      return _buildTournamentDeepLink(message: message, isMine: isMine);
    }
    if (message.type == 'arena_booking_invite') {
      return _buildArenaBookingInviteCard(message: message, isMine: isMine);
    }

    final alignment = isMine ? Alignment.centerRight : Alignment.centerLeft;
    final bubbleColor = isMine ? ChatPalette.primary : ChatPalette.surfaceAlt;
    final textColor = isMine ? Colors.black : ChatPalette.textPrimary;

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
            border: isMine ? null : Border.all(color: ChatPalette.border),
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
                  color: isMine ? Colors.black54 : ChatPalette.textSecondary,
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
                            ? Colors.black
                            : Colors.black54,
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

  Widget _buildTournamentDeepLink({
    required ChatMessageModel message,
    required bool isMine,
  }) {
    final meta = _messageMeta(message);
    final eventId = (meta['event_id'] ?? '').toString().trim();
    final communityTeam = meta['community_team'] == true;
    final link = (meta['deep_link'] ?? message.text).toString().trim();
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * .82,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF101B12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ChatPalette.primary),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tournament link',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 7),
            SelectableText(
              link,
              style: GoogleFonts.inter(
                color: ChatPalette.primary,
                fontSize: 12,
                decoration: TextDecoration.underline,
                decorationColor: ChatPalette.primary,
              ),
            ),
            const SizedBox(height: 9),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: eventId.isEmpty
                    ? null
                    : () => _openTournamentInvite(
                        eventId: eventId,
                        communityTeam: communityTeam,
                      ),
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                label: const Text('Open Tournament'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ChatPalette.primary,
                  foregroundColor: Colors.black,
                ),
              ),
            ),
          ],
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
    final storedDeepLink = (meta['deep_link'] ?? '').toString().trim();
    final deepLink = storedDeepLink.isNotEmpty
        ? storedDeepLink
        : (eventId.isEmpty
              ? ''
              : Uri(
                  scheme: 'hashforgamers',
                  host: 'tournaments',
                  path: '/$eventId',
                  queryParameters: {if (teamId.isNotEmpty) 'team_id': teamId},
                ).toString());
    final communityTeam = meta['community_team'] == true;
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
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: eventId.isEmpty
                      ? null
                      : () => _openTournamentInvite(
                          eventId: eventId,
                          communityTeam: communityTeam,
                        ),
                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                  label: const Text('View Tournament'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ChatPalette.primary,
                    side: BorderSide(
                      color: ChatPalette.primary.withValues(alpha: .7),
                    ),
                    minimumSize: const Size.fromHeight(36),
                  ),
                ),
              ),
              if (deepLink.isNotEmpty) ...[
                const SizedBox(height: 5),
                SelectableText(
                  deepLink,
                  maxLines: 1,
                  style: GoogleFonts.inter(
                    color: ChatPalette.primary,
                    fontSize: 11,
                    decoration: TextDecoration.underline,
                    decorationColor: ChatPalette.primary,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              if (actionState != null)
                Text(
                  actionState == 'joined'
                      ? 'JOINED'
                      : actionState == 'already_member'
                      ? 'ALREADY IN TEAM'
                      : 'UNABLE TO JOIN',
                  style: GoogleFonts.inter(
                    color: actionState == 'joined'
                        ? ChatPalette.success
                        : Colors.redAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .4,
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
                            communityTeam: communityTeam,
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

  Widget _buildArenaBookingInviteCard({
    required ChatMessageModel message,
    required bool isMine,
  }) {
    final meta = _messageMeta(message);
    final cafeName = (meta['cafe_name'] ?? 'Gaming Cafe').toString().trim();
    final consoleType = (meta['console_type'] ?? 'Setup').toString().trim();
    final bookingDate = _formatBookingDateLabel(
      (meta['booking_date'] ?? '').toString(),
    );
    final playerCount =
        int.tryParse((meta['player_count'] ?? '1').toString()) ?? 1;
    final slotLabels = ((meta['slot_labels'] as List?) ?? const [])
        .map((e) => _formatSlotLabel(e.toString()))
        .where((e) => e.isNotEmpty)
        .toList();
    final previewSlots = slotLabels.take(3).toList();
    final extraSlotCount = slotLabels.length > previewSlots.length
        ? slotLabels.length - previewSlots.length
        : 0;
    final accentColor = isMine
        ? const Color(0xFFB9FFB0)
        : const Color(0xFF8BFF72);
    final edgeColor = isMine
        ? const Color(0xFF6BE061)
        : const Color(0xFF53DA47);

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.86,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: const Color(0xFF101010),
            border: Border.all(color: edgeColor, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: edgeColor.withValues(alpha: 0.14),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.07),
                  ),
                  gradient: LinearGradient(
                    colors: isMine
                        ? const [Color(0xFF203F24), Color(0xFF101812)]
                        : const [Color(0xFF172317), Color(0xFF0E120E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -16,
                      top: -20,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accentColor.withValues(alpha: 0.08),
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: edgeColor,
                                  width: 1.15,
                                ),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'SQUAD BOOKING',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 9.8,
                                  letterSpacing: 0.55,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.08),
                                ),
                              ),
                              child: Icon(
                                Icons.event_available_rounded,
                                size: 16,
                                color: accentColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          cafeName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _socialProofChip(
                                icon: Icons.desktop_windows_rounded,
                                label: consoleType.toUpperCase(),
                                color: accentColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _socialProofChip(
                                icon: Icons.groups_2_rounded,
                                label:
                                    '$playerCount ${playerCount == 1 ? 'Player' : 'Players'}',
                                color: const Color(0xFFFFC857),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (bookingDate.isNotEmpty)
                    _socialProofChip(
                      icon: Icons.calendar_today_rounded,
                      label: bookingDate,
                      color: ChatPalette.accent,
                    ),
                  if (slotLabels.isNotEmpty)
                    _socialProofChip(
                      icon: Icons.schedule_rounded,
                      label:
                          '${slotLabels.length} ${slotLabels.length == 1 ? 'slot' : 'slots'}',
                      color: const Color(0xFFFFB84D),
                    ),
                  _socialProofChip(
                    icon: Icons.lock_clock_rounded,
                    label: isMine ? 'Shared' : 'Received',
                    color: edgeColor,
                  ),
                ],
              ),
              if (previewSlots.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161616),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_send_rounded,
                            size: 15,
                            color: accentColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Selected Slots',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...previewSlots.map(
                        (slotLabel) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 5),
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: accentColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  slotLabel,
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 11.8,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (extraSlotCount > 0)
                        Text(
                          '+$extraSlotCount more ${extraSlotCount == 1 ? 'slot' : 'slots'} included',
                          style: GoogleFonts.inter(
                            color: ChatPalette.textSecondary,
                            fontSize: 10.8,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                isMine ? 'Shared with your squad' : 'Shared with you',
                style: GoogleFonts.inter(
                  color: ChatPalette.textSecondary,
                  fontSize: 10.8,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            color: ChatPalette.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 10,
          ),
        ),
      ],
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
    bool communityTeam = false,
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

      if (communityTeam) {
        await CommunityApi().respondToTeamInvitation(
          eventId,
          teamId,
          action: 'accept',
        );
      } else {
        await _remoteRepo.joinEventTeam(
          eventId: eventId,
          teamId: teamId,
          userId: userId,
        );
      }

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

  Future<void> _openTournamentInvite({
    required String eventId,
    required bool communityTeam,
  }) async {
    if (communityTeam) {
      await Get.toNamed(
        AppRoutes.TOURNAMENT_DETAIL,
        arguments: {'id': eventId},
      );
      return;
    }

    try {
      final payload = await _remoteRepo.fetchEventById(eventId: eventId);
      if (!mounted) return;
      await Get.to(
        () => TournamentsDetailsView(
          tournament: TournamentModel.fromJson(payload),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      Get.snackbar(
        'Tournament',
        error.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        colorText: Colors.white,
      );
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
                    collection: widget.roomCollection,
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
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: ChatPalette.border.withValues(alpha: 0.7),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: ChatPalette.border.withValues(alpha: 0.7),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
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
                  borderRadius: BorderRadius.circular(8),
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
                        child: AppLinearLoader(width: 24, height: 3),
                      )
                    : const Icon(Icons.send_rounded, color: Colors.black),
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
        backgroundColor: ChatPalette.bgBottom,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        title: StreamBuilder<ChatRoomModel?>(
          stream: _chatService.streamRoom(
            widget.roomId,
            collection: widget.roomCollection,
          ),
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
            stream: _chatService.streamRoom(
              widget.roomId,
              collection: widget.roomCollection,
            ),
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
                stream: _chatService.streamRoom(
                  widget.roomId,
                  collection: widget.roomCollection,
                ),
                builder: (context, roomSnapshot) {
                  final room = roomSnapshot.data;
                  final isGroup = room?.isGroup == true;

                  return StreamBuilder<List<ChatMessageModel>>(
                    stream: _chatService.streamRoomMessages(
                      widget.roomId,
                      collection: widget.roomCollection,
                    ),
                    builder: (context, messagesSnapshot) {
                      if (messagesSnapshot.connectionState ==
                              ConnectionState.waiting &&
                          !(messagesSnapshot.hasData)) {
                        return const AppLinearLoader.screen();
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
