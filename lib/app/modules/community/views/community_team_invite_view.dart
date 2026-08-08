import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/chat/models/chat_room_model.dart';
import 'package:hash/app/modules/chat/services/chat_service.dart';
import 'package:hash/app/modules/community/services/community_api.dart';
import 'package:hash/app/modules/social/friends_view.dart';

/// Sends Community tournament invitations only after the target is added to
/// the backend roster. The backend then owns acceptance/rejection state.
class CommunityTeamInviteView extends StatefulWidget {
  const CommunityTeamInviteView({
    super.key,
    required this.tournamentId,
    required this.teamId,
    required this.teamName,
  });

  final String tournamentId;
  final String teamId;
  final String teamName;

  @override
  State<CommunityTeamInviteView> createState() =>
      _CommunityTeamInviteViewState();
}

class _CommunityTeamInviteViewState extends State<CommunityTeamInviteView> {
  final CommunityApi _api = CommunityApi();
  late final ChatService _chat = Get.isRegistered<ChatService>()
      ? Get.find<ChatService>()
      : Get.put(ChatService(), permanent: true);
  bool _inviting = false;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      title: Text(
        'Invite teammates',
        style: GoogleFonts.inter(fontWeight: FontWeight.w700),
      ),
    ),
    body: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.teamName,
            style: GoogleFonts.orbitron(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add friends to your roster, then they can accept their team invitation. You can also share it in Hash Hub chats.',
            style: GoogleFonts.inter(color: Colors.white70, height: 1.45),
          ),
          const SizedBox(height: 28),
          _actionCard(
            icon: Icons.people_alt_rounded,
            title: 'Invite added friends',
            subtitle: 'Add a friend to the tournament roster',
            onTap: _inviting ? null : _pickFriend,
          ),
          const SizedBox(height: 12),
          _actionCard(
            icon: Icons.forum_rounded,
            title: 'Share in Hash Hub chats',
            subtitle: 'Send this team invitation to a chat',
            onTap: _inviting ? null : _openChatPicker,
          ),
          if (_inviting) ...[
            const SizedBox(height: 24),
            const Center(
              child: CircularProgressIndicator(color: Color(0xff00DC00)),
            ),
          ],
        ],
      ),
    ),
  );

  Widget _actionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) => Material(
    color: const Color(0xFF171717),
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xff00DC00).withValues(alpha: .14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xff00DC00)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      color: Colors.white60,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white54),
          ],
        ),
      ),
    ),
  );

  Future<void> _pickFriend() async {
    await Get.to(() => FriendsView(onPlayerSelected: _inviteFriend));
  }

  Future<void> _inviteFriend(Map<String, dynamic> profile) async {
    final userId = _readUserId(profile);
    if (userId == null) {
      _showError('This friend does not have a Hash player account yet.');
      return;
    }
    final gameId = await _askForGameId();
    if (gameId == null || gameId.isEmpty) return;
    setState(() => _inviting = true);
    try {
      final teams = await _api.tournamentTeams(widget.tournamentId);
      final team = teams.firstWhere((item) => item.id == widget.teamId);
      final alreadyAdded = team.members.any(
        (member) => member.userId == userId,
      );
      if (!alreadyAdded) {
        final roster = team.members
            .where(
              (member) =>
                  member.userId != null && member.gameId.trim().isNotEmpty,
            )
            .map(
              (member) => <String, dynamic>{
                'user_id': member.userId,
                'game_id': member.gameId,
                'role': member.role,
              },
            )
            .toList();
        roster.add({'user_id': userId, 'game_id': gameId, 'role': 'player'});
        await _api.replaceTeamRoster(
          widget.tournamentId,
          widget.teamId,
          members: roster,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invitation sent. Your friend can now accept it.'),
          backgroundColor: Color(0xff00DC00),
        ),
      );
    } on DioException catch (error) {
      final response = error.response;
      debugPrint(
        '[COMMUNITY_TEAM_INVITE_ERROR] '
        'operation=load_or_replace_roster tournament_id=${widget.tournamentId} '
        'team_id=${widget.teamId} status=${response?.statusCode} '
        'response=${response?.data}',
      );
      _showError(
        _backendMessage(response?.data) ?? 'Unable to send invitation.',
      );
    } catch (error) {
      debugPrint('[COMMUNITY_TEAM_INVITE_ERROR] $error');
      _showError(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _inviting = false);
    }
  }

  int? _readUserId(Map<String, dynamic> profile) => int.tryParse(
    (profile['backend_user_id'] ?? profile['user_id'] ?? profile['id'] ?? '')
        .toString(),
  );

  Future<String?> _askForGameId() async {
    final controller = TextEditingController();
    // The dialog still rebuilds briefly while its route is being removed, so
    // keep the controller alive for that final frame. It is short-lived and
    // becomes unreachable with the dialog after this method returns.
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF171717),
        title: const Text(
          'Friend in-game ID',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: 'Enter their in-game ID'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Invite'),
          ),
        ],
      ),
    );
  }

  Future<void> _openChatPicker() async {
    if (!_chat.isLoggedIn) {
      _showError('Please sign in to share via Hash Hub chat.');
      return;
    }
    await _chat.ensureCurrentUserProfile();
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF111111),
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(sheetContext).size.height * .58,
          child: StreamBuilder<List<ChatRoomModel>>(
            stream: _chat.streamCurrentUserRooms(),
            builder: (context, snapshot) {
              final rooms = snapshot.data ?? const <ChatRoomModel>[];
              if (rooms.isEmpty) {
                return const Center(
                  child: Text(
                    'No Hash Hub chats found.',
                    style: TextStyle(color: Colors.white70),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: rooms.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, index) {
                  final room = rooms[index];
                  final title = room.displayTitleFor(_chat.currentUid ?? '');
                  return ListTile(
                    tileColor: const Color(0xFF1A1A1A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    leading: const Icon(
                      Icons.forum_rounded,
                      color: Color(0xff00DC00),
                    ),
                    title: Text(
                      title,
                      style: const TextStyle(color: Colors.white),
                    ),
                    onTap: () async {
                      final navigator = Navigator.of(sheetContext);
                      final messenger = ScaffoldMessenger.of(this.context);
                      await _chat.sendTeamInviteMessage(
                        roomId: room.id,
                        eventId: widget.tournamentId,
                        teamId: widget.teamId,
                        teamName: widget.teamName,
                        communityTeam: true,
                      );
                      if (!mounted) return;
                      navigator.pop();
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('Invitation shared to $title'),
                          backgroundColor: const Color(0xff00DC00),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  String? _backendMessage(dynamic value) {
    if (value is Map) {
      for (final key in const ['message', 'detail', 'error']) {
        final message = value[key]?.toString().trim();
        if (message != null && message.isNotEmpty) return message;
      }
    }
    return null;
  }
}
