import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../chat/services/chat_service.dart';
import '../controllers/manage_tournament_controller.dart';
import '../models/community_entities.dart';
import '../services/dispute_chat_auth.dart';
import '../views/community_theme.dart';

enum _ChatFilter { all, tournament, disputes }

class TournamentChatManagementPanel extends StatefulWidget {
  const TournamentChatManagementPanel({super.key, required this.controller});

  final ManageTournamentController controller;

  @override
  State<TournamentChatManagementPanel> createState() =>
      _TournamentChatManagementPanelState();
}

class _TournamentChatManagementPanelState
    extends State<TournamentChatManagementPanel> {
  final ChatService _chat = Get.find<ChatService>();
  ChatService? _disputeChat;
  _ChatFilter _filter = _ChatFilter.all;

  @override
  void initState() {
    super.initState();
    unawaited(_prepareDisputeChat());
  }

  Future<void> _prepareDisputeChat() async {
    try {
      final session = await DisputeChatAuth().authenticate();
      if (mounted) setState(() => _disputeChat = session.chatService);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) => Obx(() {
    final tournament = widget.controller.tournament.value;
    if (tournament == null) return const SizedBox.shrink();
    final disputes = widget.controller.disputes;
    return RefreshIndicator(
      onRefresh: widget.controller.load,
      color: CT.primary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
        children: [
          Text('MESSAGES / CHATS', style: CT.headline(17)),
          const SizedBox(height: 5),
          Text(
            'Tournament-wide conversation and private match disputes.',
            style: CT.body(12),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _filterButton(_ChatFilter.all, 'All'),
              const SizedBox(width: 8),
              _filterButton(_ChatFilter.tournament, 'Tournament Chat'),
              const SizedBox(width: 8),
              _filterButton(_ChatFilter.disputes, 'Dispute Chats'),
            ],
          ),
          const SizedBox(height: 16),
          if (_filter != _ChatFilter.disputes)
            _conversationCard(
              icon: Icons.forum_rounded,
              label: 'TOURNAMENT CHAT',
              title: tournament.title,
              details:
                  '${widget.controller.registrations.where((item) => {'confirmed', 'checked_in', 'active'}.contains(item.status)).length} registered players · Host moderation enabled',
              status: tournament.status,
              unread: _unread(_chat, 'community-tournament-${tournament.id}'),
              onTap: widget.controller.openTournamentChat,
            ),
          if (_filter != _ChatFilter.tournament) ...[
            if (_filter == _ChatFilter.all) const SizedBox(height: 12),
            if (disputes.isEmpty)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: CT.card(),
                child: Text('No dispute chats yet.', style: CT.body(12)),
              )
            else
              ...disputes.map(_disputeCard),
          ],
        ],
      ),
    );
  });

  Widget _filterButton(_ChatFilter value, String label) {
    final selected = _filter == value;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => setState(() => _filter = value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? CT.primary.withValues(alpha: .14) : CT.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: selected ? CT.primary : CT.outline),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: CT.mono(9, color: selected ? Colors.white : CT.muted),
          ),
        ),
      ),
    );
  }

  Widget _disputeCard(Dispute dispute) {
    final match = widget.controller.matchForDispute(dispute);
    final teams = [
      match?.teamA?.name,
      match?.teamB?.name,
    ].whereType<String>().where((name) => name.isNotEmpty).join(' vs ');
    final roomId = dispute.chatRoomId?.trim() ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _conversationCard(
        icon: Icons.gavel_rounded,
        label: 'DISPUTE CHAT',
        title: widget.controller.matchLabel(match).isEmpty
            ? 'Match dispute'
            : widget.controller.matchLabel(match),
        details: teams.isEmpty
            ? 'Private match participants · ${dispute.reporter?.displayName ?? 'Player'}'
            : '$teams · Private participants only',
        status: dispute.status,
        unread: roomId.isEmpty || _disputeChat == null
            ? const SizedBox.shrink()
            : _unread(_disputeChat!, roomId),
        onTap: roomId.isEmpty
            ? null
            : () => widget.controller.openDisputeChat(dispute),
      ),
    );
  }

  Widget _unread(ChatService service, String roomId) => StreamBuilder<int>(
    stream: service.streamUnreadCountForRoom(roomId),
    builder: (context, snapshot) {
      final count = snapshot.data ?? 0;
      if (count <= 0) return const SizedBox.shrink();
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: CT.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text('$count', style: CT.mono(9, color: Colors.white)),
      );
    },
  );

  Widget _conversationCard({
    required IconData icon,
    required String label,
    required String title,
    required String details,
    required String status,
    required Widget unread,
    required VoidCallback? onTap,
  }) => Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: CT.card(),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: CT.primary.withValues(alpha: .14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: CT.primary, size: 21),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: CT.mono(9, color: CT.primary)),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: CT.headline(13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    details,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: CT.body(11),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    status.replaceAll('_', ' ').toUpperCase(),
                    style: CT.mono(8, color: CT.muted),
                  ),
                ],
              ),
            ),
            unread,
            const SizedBox(width: 6),
            Icon(
              Icons.chevron_right_rounded,
              color: onTap == null ? CT.outline : Colors.white,
            ),
          ],
        ),
      ),
    ),
  );
}
