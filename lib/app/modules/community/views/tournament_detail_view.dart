import 'package:flutter/material.dart';
import 'package:hash/utils/widgets/loader.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controllers/tournament_detail_controller.dart';
import '../../chat/views/chat_inbox_view.dart';
import '../../chat/views/chat_room_view.dart';
import '../../chat/services/chat_service.dart';
import '../../../routes/app_routes.dart';
import '../models/tournament.dart';
import '../models/tournament_operations.dart';
import '../widgets/tournament_bracket.dart';
import '../../tournaments_section/models/tournament_model.dart';
import '../../tournaments_section/pages/tournaments_register_view.dart';
import 'community_theme.dart';
import 'tournament_share_poster_view.dart';
import 'tournaments_view.dart' show ctCurrency, ctAmount, ctStatus;

/// Tournament detail, including registration and live match operations.
class TournamentDetailView extends GetView<TournamentDetailController> {
  const TournamentDetailView({super.key});

  static const _joinOrange = Color(0xFFF8A241);
  static const _joinOrangeDark = Color(0xFFC06701);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CT.bg,
      appBar: AppBar(
        backgroundColor: CT.bg,
        elevation: 0,
        iconTheme: const IconThemeData(color: CT.onSurface),
        title: Text('Tournament', style: CT.headline(18)),
        actions: [
          Obx(() {
            final tournament = controller.tournament.value;
            return IconButton(
              tooltip: 'Share publicity poster',
              onPressed: tournament == null
                  ? null
                  : () => Get.to(
                      () => TournamentSharePosterView(tournament: tournament),
                    ),
              icon: const Icon(Icons.ios_share_rounded, size: 20),
            );
          }),
        ],
      ),
      body: Obx(() {
        final t = controller.tournament.value;
        if (controller.loading.value && t == null) {
          return const AppLinearLoader.screen();
        }
        if (t == null) {
          return Center(
            child: Text(
              controller.error.value ?? 'Not found',
              style: CT.body(15),
            ),
          );
        }
        return _body(t);
      }),
      bottomNavigationBar: Obx(() {
        final t = controller.tournament.value;
        if (t == null) return const SizedBox.shrink();
        return _cta(t);
      }),
    );
  }

  Widget _body(Tournament t) {
    final sym = ctCurrency(t.currency);
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        AspectRatio(aspectRatio: 16 / 8.5, child: _banner(t)),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.title, style: CT.display(26)),
              const SizedBox(height: 10),
              Row(
                children: [
                  _chip(t.game, _joinOrange),
                  const SizedBox(width: 8),
                  if (t.tournamentType != null)
                    _chip(
                      t.tournamentType!.replaceAll('_', ' '),
                      CT.onSurfaceVariant,
                    ),
                ],
              ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.only(bottom: 18),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: CT.hairline)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _stat(
                      'ENTRY',
                      t.isFree ? 'FREE' : '$sym${ctAmount(t.entryFee)}',
                    ),
                    _stat('PRIZE POOL', '$sym${ctAmount(t.prizePool)}'),
                    _stat(
                      'PLAYERS',
                      '${t.registeredPlayersCount}/${t.maxPlayers}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              if (t.description != null && t.description!.isNotEmpty) ...[
                _section('About'),
                Text(t.description!, style: CT.body(14)),
                const SizedBox(height: 22),
              ],
              _section('Schedule'),
              _row('Registration ends', _fmt(t.registrationEndAt)),
              _row('Starts', _fmt(t.tournamentStartAt)),
              const SizedBox(height: 22),
              if (controller.matches.isNotEmpty ||
                  {'registration_closed', 'live', 'completed'}.contains(
                    controller.lifecycleStatus.value?.status ?? t.status,
                  )) ...[
                _liveArena(t),
                const SizedBox(height: 20),
              ],
              if (controller.hasJoined.value &&
                  controller.announcements.isNotEmpty) ...[
                _section('Tournament updates'),
                ...controller.announcements
                    .take(3)
                    .map(
                      (item) => Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: CT.card(),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.campaign_outlined,
                              size: 19,
                              color: _joinOrange,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                (item['message'] ?? item['title'] ?? '')
                                    .toString(),
                                style: CT.body(12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                const SizedBox(height: 12),
              ],
              if (t.rules != null && t.rules!.isNotEmpty) ...[
                _section('Rules'),
                Text(t.rules!, style: CT.body(14)),
                const SizedBox(height: 16),
              ],
              if (t.prizeDistribution.isNotEmpty) ...[
                _section('Prize split'),
                for (final p in t.prizeDistribution)
                  _row('Rank ${p.rank}', '${p.percent}%'),
                const SizedBox(height: 16),
              ],
              if ((t.roomDetails?.isNotEmpty ?? false) ||
                  t.roomDetailsData != null) ...[
                _section('Room details'),
                _roomDetailsCard(t),
                const SizedBox(height: 16),
              ],
              Row(
                children: [
                  if (t.discordLink != null && t.discordLink!.isNotEmpty)
                    _linkBtn('Discord', Icons.discord, t.discordLink!),
                  if (t.whatsappLink != null && t.whatsappLink!.isNotEmpty) ...[
                    const SizedBox(width: 10),
                    _linkBtn('WhatsApp', Icons.chat_rounded, t.whatsappLink!),
                  ],
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ],
    );
  }

  Widget _cta(Tournament t) {
    final st = ctStatus(t.status);
    final canRegister = t.canRegister;
    return Container(
      color: CT.surfaceLow,
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + Get.mediaQuery.padding.bottom,
      ),
      child: Obx(() {
        final active =
            controller.canManage.value ||
            controller.hasJoined.value ||
            canRegister;
        return Container(
          height: 54,
          decoration: BoxDecoration(
            gradient: active
                ? const LinearGradient(colors: [_joinOrange, _joinOrangeDark])
                : null,
            color: active ? null : CT.surfaceHigh,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ElevatedButton(
            onPressed: controller.canManage.value
                ? () => Get.toNamed(
                    AppRoutes.MANAGE_TOURNAMENT,
                    arguments: {'id': t.id},
                  )
                : controller.hasJoined.value
                ? () => Get.to(() => const ChatInboxView())
                : controller.acting.value || !canRegister
                ? null
                : () => _openRegistration(t),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              disabledBackgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              disabledForegroundColor: CT.muted,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: controller.acting.value
                ? const AppLinearLoader.button()
                : Text(
                    controller.canManage.value
                        ? 'Manage tournament'
                        : controller.hasJoined.value
                        ? 'Open Hash Hub · Tournament chat'
                        : canRegister
                        ? (t.isFree
                              ? 'Register — Free'
                              : 'Register — ${ctCurrency(t.currency)}${ctAmount(t.entryFee)}')
                        : st.label,
                    style: CT.headline(
                      15,
                      color: active ? Colors.white : CT.muted,
                    ),
                  ),
          ),
        );
      }),
    );
  }

  Widget _liveArena(Tournament tournament) {
    final liveStatus =
        controller.lifecycleStatus.value?.status ?? tournament.status;
    final live = liveStatus == 'live';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _section('Live tournament arena')),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: _joinOrange.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _joinOrange.withValues(alpha: .6)),
              ),
              child: Text(
                live ? '● LIVE' : liveStatus.replaceAll('_', ' ').toUpperCase(),
                style: CT.mono(8, color: _joinOrange),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (controller.hasJoined.value)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: CT.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: CT.outline),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.notifications_active_rounded,
                  color: _joinOrange,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    'You’re registered. Match assignments, starts and host announcements will alert you here.',
                    style: CT.body(12, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        if (controller.currentTeamId.value != null &&
            _currentPlayerMatch() != null) ...[
          _playerMatchCard(_currentPlayerMatch()!),
          const SizedBox(height: 12),
        ],
        TournamentBracket(
          matches: controller.matches,
          currentTeamId: controller.currentTeamId.value,
        ),
        const SizedBox(height: 12),
        if (controller.hasJoined.value &&
            controller.participantTeams.isNotEmpty) ...[
          _playerComms(),
          const SizedBox(height: 12),
        ],
        OutlinedButton.icon(
          onPressed: () => Get.to(() => const ChatInboxView()),
          icon: const Icon(Icons.forum_outlined),
          label: const Text('OPEN HASH HUB'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            foregroundColor: _joinOrange,
            side: BorderSide(color: _joinOrange.withValues(alpha: .5)),
          ),
        ),
      ],
    );
  }

  CommunityMatch? _currentPlayerMatch() {
    final teamId = controller.currentTeamId.value;
    if (teamId == null) return null;
    final relevant = controller.matches
        .where(
          (match) => match.teamA?.id == teamId || match.teamB?.id == teamId,
        )
        .toList();
    relevant.sort((a, b) {
      const priority = {
        'in_progress': 0,
        'ready': 1,
        'scheduled': 2,
        'completed': 3,
      };
      return (priority[a.status] ?? 9).compareTo(priority[b.status] ?? 9);
    });
    return relevant.firstOrNull;
  }

  Widget _playerMatchCard(CommunityMatch match) {
    final mine = controller.currentTeamId.value;
    final opponent = match.teamA?.id == mine ? match.teamB : match.teamA;
    final live = {'live', 'in_progress'}.contains(match.status);
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: CT.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _joinOrange.withValues(alpha: live ? .9 : .55),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: _joinOrange.withValues(alpha: live ? .18 : .1),
            blurRadius: 18,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _joinOrange.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  live ? Icons.sensors_rounded : Icons.sports_esports_rounded,
                  color: _joinOrange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      live ? 'YOUR MATCH IS LIVE' : 'YOUR NEXT MATCH',
                      style: CT.mono(9, color: _joinOrange),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'vs ${opponent?.name ?? 'TBD'}',
                      style: CT.headline(17),
                    ),
                    Text(
                      match.scheduledAt == null
                          ? match.status.replaceAll('_', ' ')
                          : '${match.status.replaceAll('_', ' ')} · ${_fmt(match.scheduledAt)}',
                      style: CT.body(10.5),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'View teams',
                onPressed: () => _showMatchDetails(match),
                icon: const Icon(Icons.groups_2_outlined, color: _joinOrange),
              ),
            ],
          ),
          if (live || {'completed', 'disputed'}.contains(match.status)) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (controller.isCurrentUserCaptain &&
                    !{'completed', 'cancelled'}.contains(match.status))
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: controller.acting.value
                          ? null
                          : () => _openResultSubmission(match),
                      icon: const Icon(Icons.upload_file_rounded, size: 18),
                      label: const Text('UPLOAD RESULT'),
                    ),
                  ),
                if (controller.isCurrentUserCaptain &&
                    !{'completed', 'cancelled'}.contains(match.status))
                  const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: controller.acting.value
                        ? null
                        : () => _openDispute(match),
                    icon: const Icon(Icons.gavel_rounded, size: 17),
                    label: const Text('DISPUTE'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFFC857),
                    ),
                  ),
                ),
              ],
            ),
            if (!controller.isCurrentUserCaptain)
              Padding(
                padding: const EdgeInsets.only(top: 7),
                child: Text(
                  'Your captain submits the score. Any player in this match can open a dispute.',
                  style: CT.body(9.5),
                ),
              ),
          ],
        ],
      ),
    );
  }

  void _showMatchDetails(CommunityMatch match) {
    Get.bottomSheet(
      SafeArea(
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: const BoxDecoration(
            color: Color(0xFF111526),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('MATCH ROSTERS', style: CT.mono(11, color: _joinOrange)),
                const SizedBox(height: 14),
                _teamRoster(match.teamA, match.teamAScore),
                const SizedBox(height: 12),
                _teamRoster(match.teamB, match.teamBScore),
                if (match.lobbyId != null || match.accessCode != null) ...[
                  const SizedBox(height: 16),
                  Text('PRIVATE LOBBY', style: CT.mono(9)),
                  Text(
                    [
                      if (match.lobbyId != null) 'ID ${match.lobbyId}',
                      if (match.accessCode != null) 'Code ${match.accessCode}',
                    ].join(' · '),
                    style: CT.body(13, color: Colors.white),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _teamRoster(CommunityTeam? team, int? score) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(13),
    decoration: CT.card(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                team?.name ?? 'Awaiting winner',
                style: CT.headline(15),
              ),
            ),
            Text(score?.toString() ?? '—', style: CT.display(22)),
          ],
        ),
        if (team != null && team.members.isNotEmpty) ...[
          const SizedBox(height: 8),
          for (final member in team.members)
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Row(
                children: [
                  const Icon(Icons.person_outline, size: 16, color: CT.muted),
                  const SizedBox(width: 7),
                  Expanded(child: Text(member.displayName, style: CT.body(12))),
                  if (member.role == 'captain')
                    Text('CAPTAIN', style: CT.mono(7, color: _joinOrange)),
                ],
              ),
            ),
        ],
      ],
    ),
  );

  Future<void> _openResultSubmission(CommunityMatch match) async {
    final aScore = TextEditingController();
    final bScore = TextEditingController();
    final notes = TextEditingController();
    final evidence = <String>[];
    String? winner = match.teamA?.id;
    await Get.dialog<void>(
      StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF15192A),
          title: const Text('Submit match result'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: winner,
                  decoration: const InputDecoration(labelText: 'Winner'),
                  items: [match.teamA, match.teamB]
                      .whereType<CommunityTeam>()
                      .where((team) => team.id.isNotEmpty)
                      .map(
                        (team) => DropdownMenuItem(
                          value: team.id,
                          child: Text(team.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => winner = value,
                ),
                TextField(
                  controller: aScore,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: '${match.teamA?.name ?? 'Team A'} score',
                  ),
                ),
                TextField(
                  controller: bScore,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: '${match.teamB?.name ?? 'Team B'} score',
                  ),
                ),
                TextField(
                  controller: notes,
                  decoration: const InputDecoration(labelText: 'Notes'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      final id = await controller.pickAndUploadEvidence(
                        match.id,
                      );
                      if (id != null) setState(() => evidence.add(id));
                    } catch (error) {
                      Get.snackbar(
                        'Could not read screenshot',
                        error.toString(),
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    }
                  },
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: Text(
                    evidence.isEmpty
                        ? 'ADD RESULT SCREENSHOT'
                        : '${evidence.length} SCREENSHOT ADDED',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: Get.back, child: const Text('CANCEL')),
            ElevatedButton(
              onPressed: () async {
                final scoreA = int.tryParse(aScore.text);
                final scoreB = int.tryParse(bScore.text);
                if (winner == null || scoreA == null || scoreB == null) {
                  Get.snackbar(
                    'Missing result',
                    'Choose a winner and enter both scores.',
                  );
                  return;
                }
                Get.back();
                await controller.submitMatchResult(
                  match: match,
                  winnerTeamId: winner!,
                  teamAScore: scoreA,
                  teamBScore: scoreB,
                  evidenceAssetIds: const [],
                  notes: notes.text,
                );
              },
              child: const Text('SUBMIT'),
            ),
          ],
        ),
      ),
    );
    aScore.dispose();
    bScore.dispose();
    notes.dispose();
  }

  Future<void> _openDispute(CommunityMatch match) async {
    final reason = TextEditingController();
    final description = TextEditingController();
    final evidence = <String>[];
    await Get.dialog<void>(
      StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF15192A),
          title: const Text('Open a dispute'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: reason,
                  decoration: const InputDecoration(labelText: 'Reason'),
                ),
                TextField(
                  controller: description,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Explain what happened',
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      final id = await controller.pickAndUploadEvidence(
                        match.id,
                      );
                      if (id != null) setState(() => evidence.add(id));
                    } catch (error) {
                      Get.snackbar(
                        'Could not read screenshot',
                        error.toString(),
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    }
                  },
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: Text(
                    evidence.isEmpty
                        ? 'ADD EVIDENCE'
                        : '${evidence.length} EVIDENCE FILE ADDED',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: Get.back, child: const Text('CANCEL')),
            ElevatedButton(
              onPressed: () async {
                if (reason.text.trim().isEmpty ||
                    description.text.trim().isEmpty) {
                  Get.snackbar(
                    'Missing details',
                    'Add a reason and description.',
                  );
                  return;
                }
                Get.back();
                await controller.openMatchDispute(
                  match: match,
                  reason: reason.text,
                  description: description.text,
                  evidenceAssetIds: evidence,
                );
              },
              child: const Text('OPEN DISPUTE'),
            ),
          ],
        ),
      ),
    );
    reason.dispose();
    description.dispose();
  }

  Widget _playerComms() {
    final myTeamId = controller.currentTeamId.value;
    final myTeam = controller.participantTeams
        .where((team) => team.id == myTeamId)
        .firstOrNull;
    final activeMatch = _currentPlayerMatch();
    final opponentTeamId = activeMatch?.teamA?.id == myTeamId
        ? activeMatch?.teamB?.id
        : activeMatch?.teamA?.id;
    final opponents = controller.participantTeams
        .where((team) => team.id == opponentTeamId)
        .expand((team) => team.members)
        .where((member) => member.userId != null)
        .toList();
    final teammates = myTeam?.members ?? const [];
    final players = [...teammates, ...opponents];
    final unique = <int, CommunityTeamMember>{};
    for (final player in players) {
      if (player.userId != null &&
          player.userId != controller.currentUserId.value) {
        unique[player.userId!] = player;
      }
    }
    if (unique.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2A1A0D), Color(0xFF0D0B09)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF53351B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.forum_rounded, size: 19, color: _joinOrange),
              const SizedBox(width: 8),
              Expanded(child: Text('PLAYER COMMS', style: CT.mono(10))),
              Text('HASH HUB', style: CT.mono(8, color: _joinOrange)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Your match channel: teammates and your assigned opponent only.',
            style: CT.body(11),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: unique.values.take(12).map((member) {
              final teammate =
                  myTeam?.members.any((item) => item.userId == member.userId) ==
                  true;
              return ActionChip(
                avatar: CircleAvatar(
                  backgroundColor: teammate
                      ? const Color(0xFF315F66)
                      : const Color(0xFF4B316D),
                  child: Text(
                    member.displayName.characters.first.toUpperCase(),
                    style: CT.headline(9),
                  ),
                ),
                label: Text(
                  '${member.displayName}${teammate ? ' · TEAM' : ''}',
                ),
                labelStyle: CT.body(10.5, color: Colors.white),
                backgroundColor: const Color(0xFF202640),
                side: BorderSide(
                  color: teammate
                      ? const Color(0xFF387B78)
                      : const Color(0xFF503B77),
                ),
                onPressed: () => _messagePlayer(member),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Future<void> _messagePlayer(CommunityTeamMember member) async {
    final chat = Get.isRegistered<ChatService>()
        ? Get.find<ChatService>()
        : Get.put(ChatService(), permanent: true);
    final candidates = await chat.searchUsers(member.displayName, limit: 20);
    final user = candidates
        .where((item) => item.backendUserId == member.userId)
        .firstOrNull;
    if (user == null) {
      Get.snackbar(
        'Player chat unavailable',
        '${member.displayName} has not activated Hash Hub chat yet.',
      );
      return;
    }
    try {
      final roomId = await chat.getOrCreateDirectRoom(otherUser: user);
      Get.to(() => ChatRoomView(roomId: roomId));
    } catch (error) {
      Get.snackbar('Could not open chat', error.toString());
    }
  }

  Future<void> _openRegistration(Tournament tournament) async {
    final appTournament = TournamentModel.fromJson({
      'id': tournament.id,
      'source': 'community',
      'title': tournament.title,
      'game': tournament.game,
      'team_mode': tournament.teamMode ?? 'solo',
      'entry_fee': tournament.entryFee,
      'currency': tournament.currency,
      'banner_url': tournament.bannerUrl ?? '',
      'image_url': tournament.bannerUrl ?? '',
      'start_date': tournament.tournamentStartAt?.toIso8601String(),
      'end_date': tournament.tournamentEndAt?.toIso8601String(),
      'status': tournament.status,
      'max_players': tournament.maxPlayers,
      'players_count': tournament.registeredPlayersCount,
      'prize_pool': tournament.prizePool,
      'description': tournament.description ?? '',
      'rules': tournament.rules ?? '',
      'host_user_id': tournament.hostUserId,
      'can_manage': tournament.canManage,
    });
    await Get.to(() => TournamentsRegisterView(tournament: appTournament));
    await controller.refreshDetail();
  }

  Widget _banner(Tournament t) {
    if (t.bannerUrl != null && t.bannerUrl!.isNotEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            t.bannerUrl!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _fallback(),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xB3000000)],
                stops: [.55, 1],
              ),
            ),
          ),
        ],
      );
    }
    return _fallback();
  }

  Widget _fallback() => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF2A1708), Color(0xFF090909)],
      ),
    ),
    child: Center(
      child: Icon(
        Icons.sports_esports_rounded,
        color: _joinOrange.withValues(alpha: 0.55),
        size: 48,
      ),
    ),
  );

  Widget _section(String s) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(s.toUpperCase(), style: CT.mono(10, color: _joinOrange)),
  );

  Widget _roomDetailsCard(Tournament tournament) {
    final rows = tournament.roomDetailsData == null
        ? const <MapEntry<String, String>>[]
        : _roomRows(tournament.roomDetailsData!);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CT.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _joinOrange.withValues(alpha: .4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (tournament.roomDetails?.isNotEmpty ?? false) ...[
            SelectableText(
              tournament.roomDetails!,
              style: CT.body(14, color: CT.onSurface),
            ),
            if (rows.isNotEmpty) const Divider(color: CT.outline, height: 24),
          ],
          for (var index = 0; index < rows.length; index++) ...[
            Text(
              rows[index].key,
              style: CT.mono(9, color: CT.onSurfaceVariant),
            ),
            const SizedBox(height: 3),
            SelectableText(
              rows[index].value,
              style: CT.body(13, color: CT.onSurface, w: FontWeight.w600),
            ),
            if (index != rows.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  List<MapEntry<String, String>> _roomRows(RoomDetailsData details) {
    final rows = <MapEntry<String, String>>[];
    for (final entry in details.join.entries) {
      _appendRoomValue(rows, 'Join · ${_roomLabel(entry.key)}', entry.value);
    }
    for (final entry in details.schedule.entries) {
      _appendRoomValue(
        rows,
        'Schedule · ${_roomLabel(entry.key)}',
        entry.value,
      );
    }
    for (final contact in details.contacts) {
      final channel = contact['channel']?.toString().trim();
      final value = contact['value'];
      _appendRoomValue(
        rows,
        'Contact · ${channel?.isNotEmpty == true ? channel! : 'Contact'}',
        value,
      );
      for (final entry in contact.entries) {
        if (entry.key == 'channel' || entry.key == 'value') continue;
        _appendRoomValue(
          rows,
          'Contact · ${_roomLabel(entry.key)}',
          entry.value,
        );
      }
    }
    for (final field in details.customFields) {
      final label = field['label']?.toString().trim();
      _appendRoomValue(
        rows,
        label?.isNotEmpty == true ? label! : 'Custom field',
        field['value'],
      );
      for (final entry in field.entries) {
        if (entry.key == 'label' || entry.key == 'value') continue;
        _appendRoomValue(
          rows,
          '${label?.isNotEmpty == true ? label! : 'Custom'} · ${_roomLabel(entry.key)}',
          entry.value,
        );
      }
    }
    for (final entry in details.additionalFields.entries) {
      _appendRoomValue(rows, _roomLabel(entry.key), entry.value);
    }
    return rows;
  }

  void _appendRoomValue(
    List<MapEntry<String, String>> rows,
    String label,
    dynamic value,
  ) {
    if (value == null) return;
    if (value is Map) {
      for (final entry in value.entries) {
        _appendRoomValue(
          rows,
          '$label · ${_roomLabel(entry.key.toString())}',
          entry.value,
        );
      }
      return;
    }
    if (value is List) {
      for (var index = 0; index < value.length; index++) {
        _appendRoomValue(rows, '$label ${index + 1}', value[index]);
      }
      return;
    }
    final text = value.toString().trim();
    if (text.isEmpty) return;
    final parsedDate = DateTime.tryParse(text);
    rows.add(MapEntry(label, parsedDate == null ? text : _fmt(parsedDate)));
  }

  String _roomLabel(String key) {
    final words = key.replaceAll('_', ' ').trim();
    if (words.isEmpty) return 'Detail';
    return '${words[0].toUpperCase()}${words.substring(1)}';
  }

  Widget _row(String k, String v) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(k, style: CT.body(13, color: CT.onSurfaceVariant)),
        Text(
          v,
          style: CT.body(13, color: CT.onSurface, w: FontWeight.w600),
        ),
      ],
    ),
  );

  Widget _stat(String label, String value) => Column(
    children: [
      Text(label, style: CT.mono(9)),
      const SizedBox(height: 3),
      Text(value, style: CT.headline(15)),
    ],
  );

  Widget _chip(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: color.withValues(alpha: 0.4)),
    ),
    child: Text(
      text,
      style: CT.body(12, color: color, w: FontWeight.w600),
    ),
  );

  Widget _linkBtn(String label, IconData icon, String url) => Expanded(
    child: OutlinedButton.icon(
      onPressed: () =>
          launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: _joinOrange,
        side: BorderSide(color: _joinOrange.withValues(alpha: 0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
  );

  String _fmt(DateTime? d) {
    if (d == null) return '—';
    final l = d.toLocal();
    const m = [
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
    final h = l.hour % 12 == 0 ? 12 : l.hour % 12;
    final ap = l.hour < 12 ? 'AM' : 'PM';
    final min = l.minute.toString().padLeft(2, '0');
    return '${m[l.month - 1]} ${l.day}, $h:$min $ap';
  }
}
