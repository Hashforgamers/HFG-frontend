import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:hash/app/modules/chat/models/chat_user_model.dart';
import 'package:hash/app/modules/chat/services/chat_service.dart';
import 'package:hash/app/modules/social/friend_service.dart';

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
      decoration: const BoxDecoration(
        color: Color(0xFF101319),
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Invite players',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'They’ll get a match invite in chat.',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 14),
          _segmentedToggle(),
          const SizedBox(height: 10),
          TextField(
            onChanged: (v) => setState(() => _query = v),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: _showEveryone ? 'Search players' : 'Search friends',
              hintStyle: const TextStyle(color: Colors.white38),
              prefixIcon: const Icon(Icons.search_rounded, color: Colors.white38),
              filled: true,
              fillColor: const Color(0xFF171A21),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Flexible(child: _content()),
        ],
      ),
    );
  }

  Widget _segmentedToggle() {
    Widget seg(String label, bool everyone) {
      final selected = _showEveryone == everyone;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _showEveryone = everyone),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 9),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? _accent : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: selected ? const Color(0xFF06130B) : Colors.white70,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF171A21),
        borderRadius: BorderRadius.circular(999),
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
        child: Text('Couldn’t load players: $_error',
            style: const TextStyle(color: Colors.white54)),
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
          style: const TextStyle(color: Colors.white54),
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _friendRow(list[i]),
    );
  }

  Widget _friendRow(ChatUserModel friend) {
    final busy = _inviting.contains(friend.uid);
    final done = _invited.contains(friend.uid);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF171A21),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFF23262E),
            backgroundImage:
                friend.photoUrl.isNotEmpty ? NetworkImage(friend.photoUrl) : null,
            child: friend.photoUrl.isEmpty
                ? Text(
                    (friend.displayName.isNotEmpty
                            ? friend.displayName[0]
                            : '?')
                        .toUpperCase(),
                    style: const TextStyle(color: Colors.white70),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              friend.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (done)
            const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_rounded, color: _accent, size: 18),
                SizedBox(width: 4),
                Text('Invited',
                    style: TextStyle(
                        color: _accent, fontWeight: FontWeight.w700)),
              ],
            )
          else
            SizedBox(
              height: 34,
              child: ElevatedButton(
                onPressed: busy ? null : () => _invite(friend),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: const Color(0xFF06130B),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: busy
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white54,
                        ),
                      )
                    : const Text('Invite',
                        style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
        ],
      ),
    );
  }
}
