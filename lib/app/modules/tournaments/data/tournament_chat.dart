import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:hash/app/modules/chat/models/chat_user_model.dart';
import 'package:hash/app/modules/chat/services/chat_service.dart';
import 'package:hash/app/modules/chat/views/chat_room_view.dart';

import 'tournament_models.dart';

/// Tournament chat on top of the app's Firebase chat. Every message sent to a
/// room is pushed to its members by the `chatMessagePush` Cloud Function, so
/// posting an event message here is also how tournament notifications go out.
class TournamentChat {
  TournamentChat._();
  static final TournamentChat instance = TournamentChat._();

  ChatService get _chat => Get.find<ChatService>();
  final Map<int, ChatUserModel?> _users = {};

  static String teamRoomId(String teamId) => 'tournament-team-$teamId';
  static String matchRoomId(String matchId) => 'tournament-match-$matchId';
  static String allRoomId(String tournamentId) => 'tournament-all-$tournamentId';

  /// Backend user ids -> chat uid/name (users without a chat profile skipped).
  Future<Map<String, String>> _members(Iterable<int?> ids) async {
    final out = <String, String>{};
    await Future.wait(ids.whereType<int>().toSet().map((id) async {
      if (!_users.containsKey(id)) {
        try {
          _users[id] = await _chat.userByBackendId(id);
        } catch (_) {
          _users[id] = null;
        }
      }
      final u = _users[id];
      if (u != null && u.uid.isNotEmpty) out[u.uid] = u.displayName;
    }));
    return out;
  }

  void _open(String roomId) => Get.to(() => ChatRoomView(roomId: roomId));

  /// Best effort: a failed event message must never fail the action itself.
  Future<void> post(String roomId, String text) async {
    try {
      await _chat.sendTextMessage(roomId: roomId, text: text);
    } catch (e) {
      debugPrint('[TournamentChat] post to $roomId failed: $e');
    }
  }

  Iterable<int?> _teamIds(Team team) => [
    team.captainUserId,
    for (final m in team.members)
      if (m.accepted) m.userId,
  ];

  /// Team chat for accepted members of [team].
  Future<void> openTeam(Tournament t, Team team) async {
    final id = await _chat.ensureSharedRoom(
      roomId: teamRoomId(team.id),
      name: '${team.name} · ${t.title}',
      tournamentId: t.id,
      memberNames: await _members(_teamIds(team)),
    );
    _open(id);
  }

  /// Direct message with one user (host, entrant or invitee).
  Future<String?> directRoom(int userId) async {
    final user = (await _members([userId])).isEmpty ? null : _users[userId];
    if (user == null) return null;
    return _chat.getOrCreateDirectRoom(otherUser: user);
  }

  Future<bool> openDirect(int userId) async {
    final id = await directRoom(userId);
    if (id == null) return false;
    _open(id);
    return true;
  }

  /// Match chat. Players can open it once the host has created it.
  Future<bool> openMatch(MatchRow m) async {
    try {
      await _chat.requireAccessibleRoom(matchRoomId(m.id));
      _open(matchRoomId(m.id));
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Host side: the match room with every member of the playing teams.
  Future<String> ensureMatchRoom(Tournament t, MatchRow m, List<Team> teams) async {
    final playing = {m.teamAId, m.teamBId, ...m.participantIds}.whereType<String>().toSet();
    final members = await _members([
      for (final team in teams)
        if (playing.contains(team.id)) ..._teamIds(team),
    ]);
    return _chat.ensureSharedRoom(
      roomId: matchRoomId(m.id),
      name: '${m.title} · ${t.title}',
      tournamentId: t.id,
      memberNames: members,
    );
  }

  /// Host side: one room with every confirmed player and team member.
  Future<String> ensureAllRoom(Tournament t, List<Registration> regs, List<Team> teams) async {
    final members = await _members([
      for (final r in regs)
        if (r.isConfirmed) r.userId,
      for (final team in teams) ..._teamIds(team),
    ]);
    return _chat.ensureSharedRoom(
      roomId: allRoomId(t.id),
      name: '${t.title} · Players',
      tournamentId: t.id,
      memberNames: members,
    );
  }

  Future<bool> openAll(Tournament t) async {
    try {
      await _chat.requireAccessibleRoom(allRoomId(t.id));
      _open(allRoomId(t.id));
      return true;
    } catch (_) {
      return false;
    }
  }
}
