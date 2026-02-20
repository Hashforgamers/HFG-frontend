import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/chat/models/chat_user_model.dart';
import 'package:hash/app/modules/chat/services/chat_service.dart';
import 'package:hash/app/modules/tournaments_section/cubit/tournament_team_members_cubit.dart';
import 'package:hash/app/modules/tournaments_section/widgets/tournaments_loader.dart';
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

class _TournamentsTeamMembersViewState extends State<TournamentsTeamMembersView> {
  late final TournamentTeamMembersCubit _cubit;
  late final TextEditingController _teamNameController;
  late String _teamName;

  @override
  void initState() {
    super.initState();
    _cubit = TournamentTeamMembersCubit()
      ..fetchTeamMembers(eventId: widget.eventId, teamId: widget.teamId);
    _teamName = widget.teamName;
    _teamNameController = TextEditingController(text: widget.teamName);
  }

  @override
  void dispose() {
    _teamNameController.dispose();
    _cubit.close();
    super.dispose();
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
                child: BlocBuilder<TournamentTeamMembersCubit, TournamentTeamMembersState>(
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
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final member = state.members[index];
                          final name =
                              (member['name'] ??
                                      member['user_name'] ??
                                      member['username'] ??
                                      member['email'] ??
                                      'Member ${index + 1}')
                                  .toString();
                          final role =
                              (member['role'] ?? member['team_role'] ?? '')
                                  .toString();
                          return _buildMemberCard(
                            index: index,
                            name: name,
                            role: role,
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
                  const SizedBox(height: 4),
                  Text(
                    'Team ID: ${widget.teamId}',
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
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
    required String role,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: index == 0 ? const Color(0xff00DC00) : Colors.white10,
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white12,
            child: Text(
              '${index + 1}',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              name,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            role.isEmpty ? (index == 0 ? 'Leader' : 'Member') : role,
            style: GoogleFonts.inter(
              color: const Color(0xff00DC00),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
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
                  Navigator.pop(context);
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(
                      content: Text('Team updated successfully'),
                      backgroundColor: Color(0xff00DC00),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString().replaceFirst('Exception: ', '')),
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

  Future<void> _openAddMemberSheet() async {
    final chatService = Get.find<ChatService>();
    final searchController = TextEditingController();
    List<ChatUserModel> results = const [];

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF101010),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> runSearch(String value) async {
              final q = value.trim();
              if (q.length < 2) {
                setModalState(() => results = const []);
                return;
              }
              final users = await chatService.searchUsers(q, limit: 20);
              setModalState(() => results = users);
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 12,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: searchController,
                    style: const TextStyle(color: Colors.white),
                    onChanged: runSearch,
                    decoration: const InputDecoration(
                      hintText: 'Search username/email',
                      hintStyle: TextStyle(color: Colors.white54),
                      prefixIcon: Icon(Icons.search, color: Colors.white70),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 280,
                    child: ListView.builder(
                      itemCount: results.length,
                      itemBuilder: (_, index) {
                        final user = results[index];
                        return ListTile(
                          title: Text(
                            user.displayName,
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            user.username.isNotEmpty
                                ? '@${user.username}'
                                : user.email,
                            style: const TextStyle(color: Colors.white70),
                          ),
                          trailing: TextButton(
                            onPressed: () async {
                              final memberId =
                                  user.backendUserId ??
                                  int.tryParse(user.uid);
                              if (memberId == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('User ID not available for invite'),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                                return;
                              }
                              try {
                                await _cubit.addTeamMemberByUserId(
                                  eventId: widget.eventId,
                                  teamId: widget.teamId,
                                  userId: memberId,
                                );
                                if (!mounted) return;
                                Navigator.pop(context);
                                _cubit.fetchTeamMembers(
                                  eventId: widget.eventId,
                                  teamId: widget.teamId,
                                );
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  SnackBar(
                                    content: Text('Added ${user.displayName}'),
                                    backgroundColor: const Color(0xff00DC00),
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
                            child: const Text('Add'),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    searchController.dispose();
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
}

