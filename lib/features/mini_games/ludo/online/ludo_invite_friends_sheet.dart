import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:hash/app/modules/chat/models/chat_user_model.dart';
import 'package:hash/app/modules/chat/services/chat_service.dart';
import 'package:hash/app/modules/social/friend_service.dart';
import 'package:hash/utils/widgets/game_button.dart';
import 'package:hash/utils/widgets/game_panel.dart';

import '../widgets/ludo_seat_token.dart';

/// Bottom sheet listing the player's accepted friends so the host can invite
/// them to a Ludo match. Each invite posts a `ludo_invite` chat message
/// (which surfaces a notification on the friend's device).
class LudoInviteFriendsSheet extends StatefulWidget {
  const LudoInviteFriendsSheet({super.key, required this.matchId});

  final String matchId;

  @override
  State<LudoInviteFriendsSheet> createState() => _LudoInviteFriendsSheetState();
}

class _LudoInviteFriendsSheetState extends State<LudoInviteFriendsSheet> {
  static const _accent = Color(0xFF00DC00);

  final FriendService _friends = FriendService();
  final ChatService _chat = Get.find<ChatService>();

  bool _loading = true;
  String? _error;
  List<ChatUserModel> _friendList = const [];
  List<ChatUserModel> _allList = const [];
  bool _showEveryone = false;
  String _query = '';
  final Set<String> _inviting = {};
  final Set<String> _invited = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final uid = _friends.currentUid;
      final relationships = await _friends.watchRelationships().first;
      final accepted = relationships
          .where((r) => r.status == 'accepted')
          .map((r) => r.otherUid(uid ?? ''))
          .where((id) => id.isNotEmpty)
          .toList();

      final results = await Future.wait([
        Future.wait(
          accepted.map((id) async {
            final p = await _friends.userProfile(id);
            return p == null ? null : ChatUserModel.fromMap({...p, 'uid': id});
          }),
        ),
        // Everyone else on Hash — lets you match with players who aren't
        // already friends.
        _friends.allPlayers(limit: 200).then(
          (rows) => rows.map(ChatUserModel.fromMap).toList(),
        ),
      ]);

      if (!mounted) return;
      setState(() {
        _friendList =
            (results[0]).whereType<ChatUserModel>().toList();
        _allList = (results[1]).whereType<ChatUserModel>().toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<ChatUserModel> get _visibleList {
    final base = _showEveryone ? _allList : _friendList;
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return base;
    return base
        .where((u) =>
            u.displayName.toLowerCase().contains(q) ||
            u.username.toLowerCase().contains(q))
        .toList();
  }

  Future<void> _invite(ChatUserModel friend) async {
    setState(() => _inviting.add(friend.uid));
    try {
      await _chat.sendLudoInviteMessage(friend: friend, matchId: widget.matchId);
      if (!mounted) return;
      setState(() {
        _inviting.remove(friend.uid);
        _invited.add(friend.uid);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _inviting.remove(friend.uid));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invite failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: GameColors.outline,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      padding: const EdgeInsets.fromLTRB(3, 3, 3, 0),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(23)),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [GameColors.bodyTop, GameColors.bodyBottom],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GameHeaderBand(
                colors: GameColors.purple,
                height: 64,
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GameText('INVITE PLAYERS', size: 22),
                        ],
                      ),
                    ),
                    GameIconButton(
                      icon: Icons.close_rounded,
                      size: 38,
                      colors: GameColors.red,
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    14,
                    12,
                    14,
                    16 + MediaQuery.of(context).padding.bottom,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'They’ll get a match invite in chat.',
                        style: gameFont(14, GameColors.soft),
                      ),
                      const SizedBox(height: 10),
                      _segmentedToggle(),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: GameColors.socket,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: GameColors.trayEdge,
                            width: 2,
                          ),
                        ),
                        child: TextField(
                          onChanged: (v) => setState(() => _query = v),
                          style: gameFont(15, Colors.white),
                          cursorColor: _accent,
                          decoration: InputDecoration(
                            hintText: _showEveryone
                                ? 'Search players'
                                : 'Search friends',
                            hintStyle: gameFont(15, GameColors.soft.withValues(alpha: 0.5)),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: GameColors.soft,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Flexible(child: _content()),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _segmentedToggle() {
    Widget seg(String label, bool everyone) {
      final selected = _showEveryone == everyone;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _showEveryone = everyone),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: selected
                  ? LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [GameColors.green.$1, GameColors.green.$2],
                    )
                  : null,
              borderRadius: BorderRadius.circular(11),
              border: selected
                  ? Border.all(color: GameColors.outline, width: 2)
                  : null,
            ),
            child: selected
                ? GameText(label, size: 16)
                : Text(label, style: gameFont(16, GameColors.soft)),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: GameColors.socket,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GameColors.trayEdge, width: 2),
      ),
      child: Row(children: [seg('Friends', false), seg('Everyone', true)]),
    );
  }

  Widget _content() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(30),
        child: Center(child: CircularProgressIndicator(color: _accent)),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          'Couldn’t load players: $_error',
          style: gameFont(14, GameColors.soft),
        ),
      );
    }
    final list = _visibleList;
    if (list.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          _query.isNotEmpty
              ? 'No players match “$_query”.'
              : (_showEveryone
                    ? 'No players found.'
                    : 'No friends yet. Switch to Everyone to invite any player.'),
          textAlign: TextAlign.center,
          style: gameFont(14, GameColors.soft),
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      itemCount: list.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _friendRow(list[i]),
    );
  }

  Widget _friendRow(ChatUserModel friend) {
    final busy = _inviting.contains(friend.uid);
    final done = _invited.contains(friend.uid);
    return GameTray(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
      child: Row(
        children: [
          LudoSeatToken(
            color: GameColors.purple.$1,
            name: friend.displayName.isEmpty ? '?' : friend.displayName,
            photo: friend.photoUrl,
            size: 40,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              friend.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: gameFont(15, Colors.white),
            ),
          ),
          SizedBox(
            width: 100,
            child: done
                ? const Center(child: GameBadge(label: '✓ SENT'))
                : GameButton(
                    label: busy ? '...' : 'Invite',
                    tone: GameButtonTone.green,
                    height: 40,
                    onPressed: busy ? null : () => _invite(friend),
                  ),
          ),
        ],
      ),
    );
  }
}
