import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:get/get.dart';
import 'package:hash/app/modules/chat/models/chat_room_model.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/chat/models/chat_user_model.dart';
import 'package:hash/app/modules/chat/services/chat_service.dart';
import 'package:hash/app/modules/tournaments_section/cubit/tournament_team_members_cubit.dart';
import 'package:hash/app/modules/tournaments_section/widgets/tournaments_loader.dart';
import 'package:hash/core/service/fb_events_service.dart';
import 'package:hash/core/service/segment_sdk_service.dart';
import 'package:hash/core/service_locator.dart';
import 'package:share_plus/share_plus.dart';

class TournamentsTeamMembersView extends StatefulWidget {
  const TournamentsTeamMembersView({
    super.key,
    required this.eventId,
    required this.teamId,
    required this.teamName,
  });

  final String eventId;
  final String teamId;
  final String teamName;

  @override
  State<TournamentsTeamMembersView> createState() =>
      _TournamentsTeamMembersViewState();
}

class _TournamentsTeamMembersViewState
    extends State<TournamentsTeamMembersView> {
  late final TournamentTeamMembersCubit _cubit;
  late final TextEditingController _teamNameController;
  late String _teamName;
  int? _currentUserId;
  ChatService get _chatService => Get.find<ChatService>();
  final SegmentSdkService _segmentService = locator<SegmentSdkService>();
  final FbEventsService _fbEventsService = locator<FbEventsService>();

  @override
  void initState() {
    super.initState();
    _cubit = TournamentTeamMembersCubit()
      ..fetchTeamMembers(eventId: widget.eventId, teamId: widget.teamId);
    _teamName = widget.teamName;
    _teamNameController = TextEditingController(text: widget.teamName);
    _loadCurrentUserId();
  }

  @override
  void dispose() {
    _teamNameController.dispose();
    _cubit.close();
    super.dispose();
  }

  Future<void> _loadCurrentUserId() async {
    final userId = await _cubit.resolveCurrentUserId();
    if (!mounted) return;
    setState(() {
      _currentUserId = userId;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(
            'Team Members',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              onPressed: _openEditTeamDialog,
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              onPressed: _openAddMemberSheet,
              icon: const Icon(Icons.person_add_alt_1),
            ),
            IconButton(
              onPressed: _confirmLeaveTeam,
              icon: const Icon(Icons.logout_rounded),
            ),
            IconButton(
              tooltip: 'Share to chat',
              onPressed: _openShareToChatSheet,
              icon: const Icon(Icons.forum_rounded),
            ),
            IconButton(
              onPressed: () => _shareTeamInvite(context),
              icon: const Icon(Icons.share),
            ),
          ],
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xff291702), Color(0xff000000)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            children: [
              _buildTeamHeader(context),
              Expanded(
                child:
                    BlocBuilder<
                      TournamentTeamMembersCubit,
                      TournamentTeamMembersState
                    >(
                      builder: (context, state) {
                        if (state is TournamentTeamMembersLoading) {
                          return const TournamentsLoader.screen();
                        }
                        if (state is TournamentTeamMembersError) {
                          return Center(
                            child: Text(
                              state.message,
                              style: const TextStyle(color: Colors.white70),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }
                        if (state is TournamentTeamMembersLoaded) {
                          if (state.members.isEmpty) {
                            return const Center(
                              child: Text(
                                'No members found for this team.',
                                style: TextStyle(color: Colors.white70),
                              ),
                            );
                          }
                          return ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: state.members.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final member = state.members[index];
                              final gameUsername =
                                  (member['gameUserName'] ??
                                          member['game_username'] ??
                                          member['game_user_name'] ??
                                          member['username'] ??
                                          member['user_name'] ??
                                          '')
                                      .toString()
                                      .trim();
                              final name =
                                  (member['name'] ??
                                          member['display_name'] ??
                                          member['displayName'] ??
                                          member['full_name'] ??
                                          (gameUsername.isNotEmpty
                                              ? gameUsername
                                              : member['email']) ??
                                          'Player')
                                      .toString()
                                      .trim();
                              final role =
                                  (member['role'] ?? member['team_role'] ?? '')
                                      .toString();
                              final photoUrl =
                                  (member['photo_url'] ??
                                          member['photoUrl'] ??
                                          member['avatar_path'] ??
                                          member['avatarUrl'] ??
                                          '')
                                      .toString()
                                      .trim();
                              final memberUserId = _parseInt(
                                member['user_id'] ??
                                    member['userId'] ??
                                    member['id'],
                              );
                              final effectivePhotoUrl = _resolveMemberPhotoUrl(
                                memberUserId: memberUserId,
                                memberPhotoUrl: photoUrl,
                              );
                              final isCaptain = _isCurrentUserCaptain(
                                state.members,
                              );
                              final memberRole = role.trim().toLowerCase();
                              final canRemove =
                                  isCaptain &&
                                  memberUserId != null &&
                                  memberUserId != _currentUserId &&
                                  memberRole != 'captain';

                              final card = _buildMemberCard(
                                index: index,
                                name: name,
                                gameUsername: gameUsername,
                                role: role,
                                photoUrl: effectivePhotoUrl,
                              );
                              if (!canRemove) return card;

                              return Dismissible(
                                key: ValueKey('member_$memberUserId'),
                                direction: DismissDirection.endToStart,
                                confirmDismiss: (_) =>
                                    _confirmForceRemoveMember(
                                      memberUserId: memberUserId,
                                      memberName: name,
                                      fromSwipe: true,
                                    ),
                                background: Container(
                                  margin: const EdgeInsets.only(bottom: 0),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.person_remove_alt_1_rounded,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'Remove',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                child: card,
                              );
                            },
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            colors: [Color(0xFF121212), Color(0xFF1A1A1A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _teamName,
                    style: GoogleFonts.orbitron(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => _shareTeamInvite(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff00DC00),
                foregroundColor: Colors.black,
                minimumSize: const Size(88, 38),
              ),
              child: const Text('Invite'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberCard({
    required int index,
    required String name,
    required String gameUsername,
    required String role,
    required String photoUrl,
  }) {
    final displayRole = role.isEmpty
        ? (index == 0 ? 'Leader' : 'Member')
        : role;
    final isLeader = displayRole.toLowerCase() == 'leader' || index == 0;
    final cleanUsername = gameUsername.trim();
    final initials = _initialsForText(name);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isLeader
              ? [const Color(0xFF1C2219), const Color(0xFF151515)]
              : [const Color(0xFF1A1A1A), const Color(0xFF131313)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(1.4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: isLeader
                        ? [const Color(0xff00DC00), const Color(0xFF6CFF6C)]
                        : [Colors.white30, Colors.white10],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: CircleAvatar(
                  radius: 20,
                  backgroundImage: photoUrl.isNotEmpty
                      ? CachedNetworkImageProvider(photoUrl)
                      : null,
                  backgroundColor: const Color(0xFF0F0F0F),
                  child: photoUrl.isEmpty
                      ? Text(
                          initials,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      : null,
                ),
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B0B0B),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white24, width: 0.8),
                  ),
                  child: Text(
                    '#${index + 1}',
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (isLeader)
                      const Padding(
                        padding: EdgeInsets.only(left: 6),
                        child: Icon(
                          Icons.workspace_premium_rounded,
                          size: 14,
                          color: Color(0xff00DC00),
                        ),
                      ),
                  ],
                ),
                if (cleanUsername.isNotEmpty &&
                    cleanUsername.toLowerCase() != name.toLowerCase())
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      cleanUsername.startsWith('@')
                          ? cleanUsername
                          : '@$cleanUsername',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: Colors.white60,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: isLeader
                  ? const Color(0xff00DC00).withValues(alpha: 0.14)
                  : Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: isLeader ? const Color(0xff00DC00) : Colors.white12,
              ),
            ),
            child: Text(
              displayRole,
              style: GoogleFonts.inter(
                color: isLeader ? const Color(0xff00DC00) : Colors.white70,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _resolveMemberPhotoUrl({
    required int? memberUserId,
    required String memberPhotoUrl,
  }) {
    final direct = memberPhotoUrl.trim();
    if (direct.isNotEmpty) return direct;

    // If this row is current user, prefer Google photo fallback.
    if (memberUserId != null &&
        _currentUserId != null &&
        memberUserId == _currentUserId) {
      final googlePhoto =
          (firebase_auth.FirebaseAuth.instance.currentUser?.photoURL ?? '')
              .trim();
      if (googlePhoto.isNotEmpty) return googlePhoto;
    }
    return '';
  }

  String _initialsForText(String value) {
    final source = value.trim();
    if (source.isEmpty) return 'U';
    final parts = source.split(RegExp(r'\s+')).where((e) => e.isNotEmpty);
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  Future<void> _openEditTeamDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF171717),
          title: const Text('Edit Team', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: _teamNameController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Team name',
              hintStyle: TextStyle(color: Colors.white54),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _cubit.renameTeam(
                    eventId: widget.eventId,
                    teamId: widget.teamId,
                    teamName: _teamNameController.text,
                  );
                  if (!mounted) return;
                  setState(() {
                    _teamName = _teamNameController.text.trim();
                  });
                  Navigator.of(this.context).pop();
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(
                      content: Text('Team updated successfully'),
                      backgroundColor: Color(0xff00DC00),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(
                      content: Text(
                        e.toString().replaceFirst('Exception: ', ''),
                      ),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmLeaveTeam() async {
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF171717),
          title: const Text(
            'Leave Team',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Do you want to leave "$_teamName"?',
            style: GoogleFonts.inter(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Leave'),
            ),
          ],
        );
      },
    );

    if (shouldLeave != true) return;

    final userId = await _cubit.resolveCurrentUserId();
    if (userId == null || userId <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to identify current user.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    try {
      await _cubit.leaveTeam(
        eventId: widget.eventId,
        teamId: widget.teamId,
        userId: userId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You left the team successfully.'),
          backgroundColor: Color(0xff00DC00),
        ),
      );
      Navigator.of(context).maybePop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _openAddMemberSheet() async {
    final chatService = Get.find<ChatService>();
    List<ChatUserModel> results = const [];
    bool isSearching = false;
    int? invitingUserId;
    String inlineError = '';
    String queryText = '';
    bool isSheetActive = true;
    final existingMemberIds = _existingMemberIds();

    final inviterUserId = await _cubit.resolveCurrentUserId();
    if (inviterUserId == null || inviterUserId <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to identify your user account. Please re-login.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    if (!mounted) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0C0C0C),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> runSearch(String value) async {
              final q = value.trim();
              if (!isSheetActive) return;
              if (q.length < 2) {
                if (!isSheetActive || !context.mounted) return;
                setModalState(() {
                  queryText = value;
                  results = const [];
                  isSearching = false;
                  inlineError = '';
                });
                return;
              }
              if (!isSheetActive) return;
              setModalState(() {
                queryText = value;
                isSearching = true;
                inlineError = '';
              });
              try {
                final users = await chatService.searchUsers(q, limit: 20);
                if (!isSheetActive || !context.mounted) return;
                setModalState(() {
                  results = users;
                });
              } catch (_) {
                if (!isSheetActive || !context.mounted) return;
                setModalState(() {
                  inlineError = 'Unable to search users right now.';
                });
              } finally {
                if (isSheetActive && context.mounted) {
                  setModalState(() {
                    isSearching = false;
                  });
                }
              }
            }

            return SafeArea(
              top: false,
              child: AnimatedPadding(
                duration: const Duration(milliseconds: 120),
                curve: Curves.easeOut,
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 12,
                ),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.72,
                  child: Column(
                    children: [
                      Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color(
                                0xff00DC00,
                              ).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.person_add_alt_1_rounded,
                              color: Color(0xff00DC00),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Invite Teammate',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                                Text(
                                  'Search by username or email and send invite',
                                  style: GoogleFonts.inter(
                                    color: Colors.white60,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: const LinearGradient(
                            colors: [Color(0xff2E2E2E), Color(0xff3D3D3D)],
                          ),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF171717),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: TextField(
                            style: const TextStyle(color: Colors.white),
                            onChanged: runSearch,
                            decoration: const InputDecoration(
                              hintText: 'Search username/email',
                              hintStyle: TextStyle(color: Colors.white54),
                              prefixIcon: Icon(
                                Icons.search,
                                color: Colors.white70,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (inlineError.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.red.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Text(
                            inlineError,
                            style: GoogleFonts.inter(
                              color: Colors.red.shade200,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      SizedBox(
                        height: 280,
                        child: isSearching
                            ? const Center(child: TournamentsLoader.button())
                            : results.isEmpty
                            ? Center(
                                child: Text(
                                  queryText.trim().length < 2
                                      ? 'Type at least 2 letters to search'
                                      : 'No users found',
                                  style: GoogleFonts.inter(
                                    color: Colors.white60,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                itemCount: results.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (_, index) {
                                  final user = results[index];
                                  final memberId =
                                      user.backendUserId ??
                                      int.tryParse(user.uid);
                                  final canInvite = memberId != null;
                                  final isInviting =
                                      memberId != null &&
                                      invitingUserId == memberId;
                                  final isAlreadyMember =
                                      memberId != null &&
                                      existingMemberIds.contains(memberId);

                                  return Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF171717),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.white10),
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 20,
                                          backgroundImage:
                                              user.photoUrl.trim().isNotEmpty
                                              ? NetworkImage(
                                                  user.photoUrl.trim(),
                                                )
                                              : null,
                                          backgroundColor: Colors.white12,
                                          child: user.photoUrl.trim().isEmpty
                                              ? Text(
                                                  _initialsForUser(user),
                                                  style: GoogleFonts.inter(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 12,
                                                  ),
                                                )
                                              : null,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                user.displayName,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.inter(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 13,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                user.username.isNotEmpty
                                                    ? '@${user.username}'
                                                    : user.email,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.inter(
                                                  color: Colors.white70,
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton(
                                          onPressed:
                                              !canInvite ||
                                                  isInviting ||
                                                  isAlreadyMember
                                              ? null
                                              : () async {
                                                  if (!isSheetActive) return;
                                                  setModalState(() {
                                                    invitingUserId = memberId;
                                                    inlineError = '';
                                                  });
                                                  try {
                                                    await _cubit
                                                        .inviteTeamMember(
                                                          eventId:
                                                              widget.eventId,
                                                          teamId: widget.teamId,
                                                          inviterUserId:
                                                              inviterUserId,
                                                          invitedUserId:
                                                              memberId,
                                                        );
                                                    if (!isSheetActive ||
                                                        !context.mounted) {
                                                      return;
                                                    }
                                                    if (!mounted) return;
                                                    isSheetActive = false;
                                                    Navigator.of(
                                                      this.context,
                                                    ).pop();
                                                    _cubit.fetchTeamMembers(
                                                      eventId: widget.eventId,
                                                      teamId: widget.teamId,
                                                    );
                                                    _segmentService
                                                        .onCustomEvent(
                                                          'Friend Invited',
                                                          {
                                                            'inviter_user_id':
                                                                inviterUserId,
                                                            'target_user_id':
                                                                memberId
                                                                    .toString(),
                                                            'channel':
                                                                'team_invite',
                                                          },
                                                        );
                                                    _fbEventsService
                                                        .onFriendInvited(
                                                          targetUserId: memberId
                                                              .toString(),
                                                          source: 'team_invite',
                                                        );
                                                    ScaffoldMessenger.of(
                                                      this.context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          'Invite sent to ${user.displayName}',
                                                        ),
                                                        backgroundColor:
                                                            const Color(
                                                              0xff00DC00,
                                                            ),
                                                      ),
                                                    );
                                                  } catch (e) {
                                                    if (!isSheetActive ||
                                                        !context.mounted) {
                                                      return;
                                                    }
                                                    setModalState(() {
                                                      invitingUserId = null;
                                                      inlineError = e
                                                          .toString()
                                                          .replaceFirst(
                                                            'Exception: ',
                                                            '',
                                                          );
                                                    });
                                                  }
                                                },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xff00DC00,
                                            ),
                                            foregroundColor: Colors.black,
                                            disabledBackgroundColor:
                                                isAlreadyMember
                                                ? const Color(
                                                    0xff00DC00,
                                                  ).withValues(alpha: 0.2)
                                                : Colors.white12,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 10,
                                            ),
                                            minimumSize: const Size(82, 36),
                                          ),
                                          child: isAlreadyMember
                                              ? const Icon(
                                                  Icons.check_rounded,
                                                  size: 16,
                                                  color: Color(0xff00DC00),
                                                )
                                              : isInviting
                                              ? const SizedBox(
                                                  width: 14,
                                                  height: 14,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2.2,
                                                        color: Colors.black,
                                                      ),
                                                )
                                              : Text(
                                                  'Invite',
                                                  style: GoogleFonts.inter(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      isSheetActive = false;
    });
  }

  Set<int> _existingMemberIds() {
    final state = _cubit.state;
    if (state is! TournamentTeamMembersLoaded) return <int>{};
    final ids = <int>{};
    for (final member in state.members) {
      final raw =
          member['id'] ??
          member['user_id'] ??
          member['userId'] ??
          member['member_id'] ??
          member['memberId'];
      final parsed = _parseInt(raw);
      if (parsed != null && parsed > 0) {
        ids.add(parsed);
      }
    }
    return ids;
  }

  bool _isCurrentUserCaptain(List<Map<String, dynamic>> members) {
    final current = _currentUserId;
    if (current == null || current <= 0) return false;
    for (final member in members) {
      final memberId = _parseInt(
        member['user_id'] ?? member['userId'] ?? member['id'],
      );
      if (memberId != current) continue;
      final role = (member['role'] ?? member['team_role'] ?? '')
          .toString()
          .trim()
          .toLowerCase();
      if (role == 'captain') {
        return true;
      }
    }
    return false;
  }

  Future<bool> _confirmForceRemoveMember({
    required int memberUserId,
    required String memberName,
    bool fromSwipe = false,
  }) async {
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF171717),
          title: const Text(
            'Remove Member',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Remove $memberName from this team?',
            style: GoogleFonts.inter(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (shouldRemove != true) return false;
    final actingUserId = _currentUserId;
    if (actingUserId == null || actingUserId <= 0) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to identify current user.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return false;
    }

    try {
      await _cubit.remoteRepo.forceRemoveEventTeamMember(
        eventId: widget.eventId,
        teamId: widget.teamId,
        actingUserId: actingUserId,
        targetUserId: memberUserId,
      );
      if (!mounted) return false;
      _cubit.fetchTeamMembers(eventId: widget.eventId, teamId: widget.teamId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$memberName removed from team'),
          backgroundColor: const Color(0xff00DC00),
        ),
      );
      return fromSwipe;
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.redAccent,
        ),
      );
      return false;
    }
  }

  int? _parseInt(dynamic source) {
    if (source == null) return null;
    if (source is int) return source;
    if (source is num) return source.toInt();
    return int.tryParse(source.toString().trim());
  }

  String _initialsForUser(ChatUserModel user) {
    final source = user.displayName.trim().isNotEmpty
        ? user.displayName.trim()
        : (user.username.trim().isNotEmpty ? user.username.trim() : 'U');
    final parts = source.split(RegExp(r'\s+')).where((e) => e.isNotEmpty);
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  void _shareTeamInvite(BuildContext context) {
    final deepLink =
        'hashforgamers://team/join?event_id=${widget.eventId}&team_id=${widget.teamId}';
    final webLink =
        'https://hashforgamers.com/team/join?event_id=${widget.eventId}&team_id=${widget.teamId}';
    SharePlus.instance.share(
      ShareParams(
        text:
            'Join my team "$_teamName" on HashForGamers.\n$deepLink\n$webLink',
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Team invite shared'),
        backgroundColor: Color(0xff00DC00),
      ),
    );
  }

  Future<void> _openShareToChatSheet() async {
    if (!_chatService.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to share via chat.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    await _chatService.ensureCurrentUserProfile();
    if (!mounted) return;

    final currentUid = _chatService.currentUid ?? '';
    if (currentUid.isEmpty) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF111111),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: SizedBox(
            height: MediaQuery.of(sheetContext).size.height * 0.62,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                  child: Row(
                    children: [
                      Text(
                        'Share Team to Chat',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: StreamBuilder<List<ChatRoomModel>>(
                    stream: _chatService.streamCurrentUserRooms(),
                    builder: (context, snapshot) {
                      final rooms = snapshot.data ?? const <ChatRoomModel>[];
                      if (snapshot.connectionState == ConnectionState.waiting &&
                          rooms.isEmpty) {
                        return const TournamentsLoader.screen();
                      }
                      if (rooms.isEmpty) {
                        return Center(
                          child: Text(
                            'No chats found. Start a chat first.',
                            style: GoogleFonts.inter(color: Colors.white70),
                          ),
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                        itemCount: rooms.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final room = rooms[index];
                          final title = room.displayTitleFor(currentUid);
                          final subtitle = room.subtitleFor(currentUid);
                          final prefix = title.isNotEmpty
                              ? title.substring(0, 1).toUpperCase()
                              : 'C';

                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () async {
                                await _chatService.sendTeamInviteMessage(
                                  roomId: room.id,
                                  eventId: widget.eventId,
                                  teamId: widget.teamId,
                                  teamName: _teamName,
                                );
                                if (!mounted) return;
                                Get.back<void>();
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Shared to $title',
                                      style: GoogleFonts.inter(),
                                    ),
                                    backgroundColor: const Color(0xff00DC00),
                                  ),
                                );
                              },
                              child: Ink(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: const Color(0xFF1A1A1A),
                                  border: Border.all(color: Colors.white12),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: const Color(0xFF2A2A2A),
                                      child: Text(
                                        prefix,
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.inter(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            subtitle,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.inter(
                                              color: Colors.white60,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.send_rounded,
                                      color: Color(0xff00DC00),
                                      size: 18,
                                    ),
                                  ],
                                ),
                              ),
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
      },
    );
  }
}
