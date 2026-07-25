import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../chat/models/chat_user_model.dart';
import '../chat/services/chat_service.dart';
import '../chat/views/chat_room_view.dart';
import 'friend_service.dart';

class FriendsView extends StatefulWidget {
  const FriendsView({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<FriendsView> createState() => _FriendsViewState();
}

class _FriendsViewState extends State<FriendsView> {
  final FriendService _friends = FriendService();
  final TextEditingController _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      initialIndex: widget.initialTab.clamp(0, 2),
      child: Scaffold(
        backgroundColor: const Color(0xFF090B11),
        appBar: AppBar(
          backgroundColor: const Color(0xFF090B11),
          foregroundColor: Colors.white,
          title: const Text('Players & friends'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'FRIENDS'),
              Tab(text: 'REQUESTS'),
              Tab(text: 'ALL PLAYERS'),
            ],
          ),
        ),
        body: StreamBuilder<List<FriendRelationship>>(
          stream: _friends.watchRelationships(),
          builder: (context, snapshot) {
            final relationships = snapshot.data ?? const [];
            return TabBarView(
              children: [
                _relationshipList(
                  relationships
                      .where((item) => item.status == 'accepted')
                      .toList(),
                  empty: 'Your accepted friends will appear here.',
                ),
                _requests(relationships),
                _directory(relationships),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _relationshipList(
    List<FriendRelationship> items, {
    required String empty,
  }) {
    if (items.isEmpty) return _empty(empty);
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 9),
      itemBuilder: (_, index) {
        final relationship = items[index];
        return FutureBuilder<Map<String, dynamic>?>(
          future: _friends.userProfile(
            relationship.otherUid(_friends.currentUid ?? ''),
          ),
          builder: (_, profile) => _profileCard(
            profile.data,
            trailing: PopupMenuButton<String>(
              onSelected: (action) {
                if (action == 'message' && profile.data != null) {
                  _message(profile.data!);
                } else if (action == 'remove') {
                  _friends.remove(relationship);
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'message', child: Text('Message')),
                PopupMenuItem(value: 'remove', child: Text('Remove friend')),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _requests(List<FriendRelationship> relationships) {
    final pending = relationships
        .where((item) => item.status == 'pending')
        .toList();
    if (pending.isEmpty) return _empty('No pending friend requests.');
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: pending.length,
      separatorBuilder: (_, _) => const SizedBox(height: 9),
      itemBuilder: (_, index) {
        final relationship = pending[index];
        final incoming = relationship.isIncoming(_friends.currentUid ?? '');
        return FutureBuilder<Map<String, dynamic>?>(
          future: _friends.userProfile(
            relationship.otherUid(_friends.currentUid ?? ''),
          ),
          builder: (_, profile) => _profileCard(
            profile.data,
            trailing: incoming
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Decline',
                        onPressed: () => _friends.remove(relationship),
                        icon: const Icon(Icons.close_rounded),
                      ),
                      IconButton.filled(
                        tooltip: 'Accept',
                        onPressed: () => _friends.accept(relationship),
                        icon: const Icon(Icons.check_rounded),
                      ),
                    ],
                  )
                : const Chip(label: Text('REQUESTED')),
          ),
        );
      },
    );
  }

  Widget _directory(List<FriendRelationship> relationships) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _friends.allPlayers(),
      builder: (_, snapshot) {
        final players = (snapshot.data ?? const []).where((item) {
          final text = '${item['display_name'] ?? ''} ${item['username'] ?? ''}'
              .toLowerCase();
          return text.contains(_query);
        }).toList();
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _search,
                onChanged: (value) =>
                    setState(() => _query = value.trim().toLowerCase()),
                decoration: const InputDecoration(
                  hintText: 'Search all players',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
            ),
            Expanded(
              child: snapshot.connectionState == ConnectionState.waiting
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: players.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 9),
                      itemBuilder: (_, index) {
                        final player = players[index];
                        final uid =
                            (player['uid'] ?? player['firebase_uid'] ?? '')
                                .toString();
                        final relation = relationships
                            .where((item) => item.users.contains(uid))
                            .firstOrNull;
                        return _profileCard(
                          player,
                          trailing: relation?.status == 'accepted'
                              ? IconButton(
                                  tooltip: 'Message friend',
                                  onPressed: () => _message(player),
                                  icon: const Icon(Icons.chat_rounded),
                                )
                              : relation?.status == 'pending'
                              ? const Chip(label: Text('PENDING'))
                              : IconButton.filledTonal(
                                  tooltip: 'Add friend',
                                  onPressed: () => _friends.sendRequest(uid),
                                  icon: const Icon(
                                    Icons.person_add_alt_1_rounded,
                                  ),
                                ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _profileCard(
    Map<String, dynamic>? profile, {
    required Widget trailing,
  }) {
    final name = (profile?['display_name'] ?? profile?['username'] ?? 'Player')
        .toString();
    final photo = (profile?['photo_url'] ?? '').toString();
    final games = (profile?['games'] as List?)?.join(' · ') ?? 'Hash player';
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF151925),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2D3449)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: photo.isEmpty ? null : NetworkImage(photo),
          child: photo.isEmpty ? const Icon(Icons.person_rounded) : null,
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(games, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: trailing,
      ),
    );
  }

  Future<void> _message(Map<String, dynamic> profile) async {
    final user = ChatUserModel.fromMap(profile);
    if (user.uid.isEmpty) return;
    final chat = Get.isRegistered<ChatService>()
        ? Get.find<ChatService>()
        : Get.put(ChatService(), permanent: true);
    final roomId = await chat.getOrCreateDirectRoom(otherUser: user);
    Get.to(() => ChatRoomView(roomId: roomId));
  }

  Widget _empty(String text) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white54),
      ),
    ),
  );
}
