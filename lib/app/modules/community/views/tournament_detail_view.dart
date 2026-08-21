import 'package:flutter/material.dart';
import 'package:hash/utils/widgets/loader.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controllers/tournament_detail_controller.dart';
import '../../chat/views/chat_inbox_view.dart';
import '../../chat/views/chat_room_view.dart';
import '../../chat/services/chat_service.dart';
import '../../chat/models/chat_user_model.dart';
import '../../../routes/app_routes.dart';
import '../models/tournament.dart';
import '../models/tournament_operations.dart';
import '../widgets/tournament_bracket.dart';
import '../../tournaments_section/models/tournament_model.dart';
import '../../tournaments_section/pages/tournaments_register_view.dart';
import 'community_theme.dart';
import 'community_team_invite_view.dart';
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
        return _body(context, t);
      }),
      bottomNavigationBar: Obx(() {
        final t = controller.tournament.value;
        if (t == null) return const SizedBox.shrink();
        return _cta(t);
      }),
    );
  }

  Widget _body(BuildContext context, Tournament t) {
    final sym = ctCurrency(t.currency);
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 600;
        final pagePadding = wide ? 32.0 : 20.0;
        return RefreshIndicator(
          color: _joinOrange,
          backgroundColor: CT.surface,
          onRefresh: controller.refreshDetail,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(
                    children: [
                      _hero(t, wide: wide),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          pagePadding,
                          20,
                          pagePadding,
                          28,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _summaryStats(
                              entry: t.isFree
                                  ? 'FREE'
                                  : '$sym${ctAmount(t.entryFee)}',
                              prize: '$sym${ctAmount(t.prizePool)}',
                              players:
                                  '${t.registeredPlayersCount}/${t.maxPlayers}',
                            ),
                            const SizedBox(height: 18),
                            if (controller.matches.isNotEmpty ||
                                {
                                  'registration_closed',
                                  'live',
                                  'completed',
                                }.contains(
                                  controller.lifecycleStatus.value?.status ??
                                      t.status,
                                )) ...[
                              _liveArena(t),
                              const SizedBox(height: 20),
                            ],
                            if (t.description != null &&
                                t.description!.isNotEmpty) ...[
                              _section('About'),
                              Text(t.description!, style: CT.body(14)),
                              const SizedBox(height: 22),
                            ],
                            _section('Schedule'),
                            _row(
                              'Registration ends',
                              _fmt(t.registrationEndAt),
                            ),
                            _row('Starts', _fmt(t.tournamentStartAt)),
                            const SizedBox(height: 18),
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Icon(
                                            Icons.campaign_outlined,
                                            size: 19,
                                            color: _joinOrange,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              (item['message'] ??
                                                      item['title'] ??
                                                      '')
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
                            if (controller.hasJoined.value) ...[
                              _participantHub(t),
                              const SizedBox(height: 22),
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
                                if (t.discordLink != null &&
                                    t.discordLink!.isNotEmpty)
                                  _linkBtn(
                                    'Discord',
                                    Icons.discord,
                                    t.discordLink!,
                                  ),
                                if (t.whatsappLink != null &&
                                    t.whatsappLink!.isNotEmpty) ...[
                                  const SizedBox(width: 10),
                                  _linkBtn(
                                    'WhatsApp',
                                    Icons.chat_rounded,
                                    t.whatsappLink!,
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _cta(Tournament t) {
    final st = ctStatus(t.status);
    final canRegister = t.canRegister;
    return Container(
      color: CT.surfaceLow,
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        8 + Get.mediaQuery.padding.bottom,
      ),
      child: Obx(() {
        final active =
            controller.canManage.value ||
            controller.hasJoined.value ||
            (controller.membershipResolved.value && canRegister);
        final team = controller.currentTeam;
        final canInvite =
            controller.hasJoined.value &&
            controller.isCurrentUserCaptain &&
            t.teamMode?.toLowerCase() != 'solo' &&
            team != null;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canInvite) ...[
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => Get.to(
                    () => CommunityTeamInviteView(
                      tournamentId: t.id,
                      teamId: team.id,
                      teamName: team.name,
                    ),
                  ),
                  icon: const Icon(Icons.person_add_alt_1_rounded),
                  label: Text('Invite teammates', style: CT.headline(14)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xff00DC00),
                    side: const BorderSide(color: Color(0xff00DC00)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            Container(
              constraints: const BoxConstraints(maxWidth: 720),
              height: 48,
              decoration: BoxDecoration(
                gradient: active
                    ? const LinearGradient(
                        colors: [_joinOrange, _joinOrangeDark],
                      )
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
                    : !controller.membershipResolved.value ||
                          controller.acting.value ||
                          !canRegister
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
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (controller.hasJoined.value) ...[
                            const Icon(Icons.forum_rounded, size: 18),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Text(
                              controller.canManage.value
                                  ? 'Manage tournament'
                                  : controller.hasJoined.value
                                  ? 'Tournament chat'
                                  : !controller.membershipResolved.value
                                  ? 'Checking registration…'
                                  : canRegister
                                  ? (t.isFree
                                        ? 'Register — Free'
                                        : 'Register — ${ctCurrency(t.currency)}${ctAmount(t.entryFee)}')
                                  : st.label,
                              overflow: TextOverflow.ellipsis,
                              style: CT.headline(
                                14,
                                color: active ? Colors.white : CT.muted,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _participantHub(Tournament tournament) {
    final players = controller.participantTeams
        .expand((team) => team.members)
        .where(
          (member) =>
              member.role == 'captain' ||
              {'accepted', 'active'}.contains(member.invitationStatus),
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _section('Participant hub'),
        if (controller.participantDataLoading.value) ...[
          const AppLinearLoader(),
          const SizedBox(height: 14),
        ],
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: controller.messageHost,
                icon: const Icon(Icons.support_agent_rounded, size: 18),
                label: const Text('Chat with host'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Get.to(() => const ChatInboxView()),
                icon: const Icon(Icons.forum_rounded, size: 18),
                label: const Text('Tournament chat'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: CT.card(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('LEADERBOARD', style: CT.mono(10, color: _joinOrange)),
              const SizedBox(height: 10),
              if (controller.leaderboard.isEmpty)
                Text('Standings will appear after results.', style: CT.body(12))
              else
                ...controller.leaderboard
                    .take(5)
                    .map(
                      (entry) => _row(
                        '#${entry.rank ?? '-'}  ${entry.name}',
                        '${entry.points} pts',
                      ),
                    ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: CT.card(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'JOINED PLAYERS  ${players.length}',
                style: CT.mono(10, color: _joinOrange),
              ),
              const SizedBox(height: 10),
              if (players.isEmpty)
                Text('Player roster is not available yet.', style: CT.body(12))
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: players
                      .map(
                        (member) => Chip(
                          label: Text(member.displayName),
                          avatar: const Icon(Icons.person_rounded, size: 16),
                          backgroundColor: CT.surfaceHigh,
                          side: const BorderSide(color: CT.outline),
                          labelStyle: CT.body(11, color: Colors.white),
                        ),
                      )
                      .toList(),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _liveArena(Tournament tournament) {
    final liveStatus =
        controller.lifecycleStatus.value?.status ?? tournament.status;
    final live = liveStatus == 'live';
    final playerMatch = _currentPlayerMatch();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _section(
                playerMatch != null ? 'Your match' : 'Tournament arena',
              ),
            ),
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
        if (controller.hasJoined.value && playerMatch == null)
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
        if (controller.currentTeamId.value != null && playerMatch != null) ...[
          _playerMatchCard(playerMatch),
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
        'live': 0,
        'awaiting_results': 1,
        'result_pending': 1,
        'disputed': 1,
        'ready': 2,
        'scheduled': 3,
        'completed': 4,
      };
      return (priority[a.status] ?? 9).compareTo(priority[b.status] ?? 9);
    });
    return relevant.firstOrNull;
  }

  Widget _playerMatchCard(CommunityMatch match) {
    final mine = controller.currentTeamId.value;
    final opponent = match.teamA?.id == mine ? match.teamB : match.teamA;
    final live = {'active', 'in_progress'}.contains(match.status);
    final awaitingResults = {
      'awaiting_results',
      'result_pending',
    }.contains(match.status);
    final disputed = match.status == 'disputed';
    // The backend lifecycle is authoritative. A host can intentionally start
    // a match before its planned time, so a future scheduled_at must not block
    // captains from submitting an early result.
    final canSubmitResult = live || awaitingResults;
    final startedEarly =
        live &&
        match.scheduledAt != null &&
        DateTime.now().isBefore(match.scheduledAt!);
    final proposal = controller.proposalFor(match);
    final proposalPending =
        proposal != null && {'pending', 'submitted'}.contains(proposal.status);
    final canApproveProposal =
        proposalPending && controller.resultPermission(match, 'can_accept');
    final canDisputeProposal =
        proposalPending && controller.resultPermission(match, 'can_dispute');
    final evidenceUrls = controller.resultEvidenceUrls(match);
    final remaining = controller.resultTimeRemaining(match);
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: CT.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _joinOrange.withValues(alpha: canSubmitResult ? .9 : .55),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: _joinOrange.withValues(alpha: canSubmitResult ? .18 : .1),
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
                  live
                      ? Icons.sensors_rounded
                      : awaitingResults
                      ? Icons.upload_file_rounded
                      : disputed
                      ? Icons.gavel_rounded
                      : Icons.sports_esports_rounded,
                  color: _joinOrange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      live
                          ? 'YOUR MATCH IS LIVE'
                          : awaitingResults
                          ? 'SUBMIT MATCH RESULT'
                          : disputed
                          ? 'RESULT DISPUTED'
                          : 'YOUR NEXT MATCH',
                      style: CT.mono(9, color: _joinOrange),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'vs ${opponent?.name ?? 'TBD'}',
                      style: CT.headline(17),
                    ),
                    Text(
                      startedEarly
                          ? '${match.status.replaceAll('_', ' ')} · started early'
                          : match.scheduledAt == null
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
          if (canSubmitResult ||
              {'completed', 'disputed'}.contains(match.status)) ...[
            const SizedBox(height: 12),
            if (proposalPending) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: CT.card(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('HOST RESULT PROPOSAL', style: CT.mono(9)),
                    const SizedBox(height: 5),
                    Text(
                      '${match.teamA?.name ?? 'Team A'} ${proposal.teamAScore ?? 0} · '
                      '${proposal.teamBScore ?? 0} ${match.teamB?.name ?? 'Team B'}',
                      style: CT.headline(14),
                    ),
                    if (proposal.reviewDeadline != null)
                      Text(
                        'Review by ${_fmt(proposal.reviewDeadline!)}',
                        style: CT.body(9.5, color: CT.muted),
                      ),
                    if (remaining != null)
                      Text(
                        remaining == Duration.zero
                            ? 'Review window ended'
                            : 'Auto-finalizes in ${remaining.inMinutes}:${remaining.inSeconds.remainder(60).toString().padLeft(2, '0')}',
                        style: CT.body(9.5, color: CT.muted),
                      ),
                    if (evidenceUrls.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 92,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: evidenceUrls.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (_, index) => ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              evidenceUrls[index],
                              width: 150,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                width: 150,
                                color: CT.surfaceHigh,
                                alignment: Alignment.center,
                                child: const Icon(Icons.broken_image_outlined),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (disputed)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFC857).withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFFFC857).withValues(alpha: .35),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.policy_outlined,
                      color: Color(0xFFFFC857),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DISPUTE UNDER REVIEW',
                            style: CT.mono(9, color: const Color(0xFFFFC857)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Uploads are locked while the platform admin reviews the submitted results.',
                            style: CT.body(10.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              Row(
                children: [
                  if (controller.isCurrentUserCaptain && proposalPending)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed:
                            controller.acting.value || !canApproveProposal
                            ? null
                            : () => controller.respondToHostResultProposal(
                                match: match,
                                action: 'accept',
                              ),
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: const Text('ACCEPT'),
                      ),
                    )
                  else if (controller.isCurrentUserCaptain &&
                      !{'completed', 'cancelled'}.contains(match.status))
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: !canSubmitResult || controller.acting.value
                            ? null
                            : () => _openResultSubmission(match),
                        icon: const Icon(Icons.upload_file_rounded, size: 18),
                        label: Text(
                          canSubmitResult
                              ? 'UPLOAD RESULT'
                              : 'MATCH NOT STARTED',
                        ),
                      ),
                    ),
                  if (controller.isCurrentUserCaptain && proposalPending)
                    const SizedBox(width: 8),
                  if (controller.isCurrentUserCaptain && proposalPending)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed:
                            controller.acting.value || !canDisputeProposal
                            ? null
                            : () => _openHostProposalDispute(match),
                        icon: const Icon(Icons.gavel_rounded, size: 17),
                        label: const Text('DISPUTE'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFFFC857),
                        ),
                      ),
                    ),
                ],
              ),
            if (!disputed && !controller.isCurrentUserCaptain)
              Padding(
                padding: const EdgeInsets.only(top: 7),
                child: Text(
                  'Your captain submits the score and reviews host result proposals.',
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

  Future<void> _openHostProposalDispute(CommunityMatch match) async {
    final description = TextEditingController();
    final evidence = <String>[];
    var uploading = false;
    var submitting = false;
    String? dialogError;
    await Get.dialog<void>(
      StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: CT.surface,
          title: const Text('Dispute host result'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Upload your scoreboard first, then explain what is incorrect.',
                  style: CT.body(11, color: CT.muted),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: description,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Dispute description',
                    hintText: 'My scoreboard shows 2-1 for Team B.',
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: uploading || submitting
                      ? null
                      : () async {
                          setState(() {
                            uploading = true;
                            dialogError = null;
                          });
                          try {
                            final assetId = await controller
                                .pickAndUploadEvidence(
                                  match.id,
                                  purpose: 'dispute_evidence',
                                );
                            if (assetId != null && assetId.isNotEmpty) {
                              evidence.add(assetId);
                            }
                          } catch (error) {
                            dialogError = error.toString();
                          } finally {
                            if (context.mounted) {
                              setState(() => uploading = false);
                            }
                          }
                        },
                  icon: uploading
                      ? const SizedBox.square(
                          dimension: 17,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_photo_alternate_outlined),
                  label: Text(
                    uploading
                        ? 'UPLOADING...'
                        : evidence.isEmpty
                        ? 'UPLOAD SCOREBOARD'
                        : '${evidence.length} SCREENSHOT ADDED',
                  ),
                ),
                if (dialogError != null) ...[
                  const SizedBox(height: 8),
                  Text(dialogError!, style: CT.body(10.5, color: CT.error)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: uploading || submitting ? null : Get.back,
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: uploading || submitting
                  ? null
                  : () async {
                      final reason = description.text.trim();
                      if (reason.isEmpty || evidence.isEmpty) {
                        setState(() {
                          dialogError =
                              'Add a description and scoreboard screenshot.';
                        });
                        return;
                      }
                      setState(() {
                        submitting = true;
                        dialogError = null;
                      });
                      final submitted = await controller
                          .respondToHostResultProposal(
                            match: match,
                            action: 'dispute',
                            description: reason,
                            evidenceAssetIds: evidence,
                          );
                      if (context.mounted && submitted) Get.back<void>();
                      if (context.mounted && !submitted) {
                        setState(() => submitting = false);
                      }
                    },
              child: Text(submitting ? 'SUBMITTING...' : 'OPEN DISPUTE'),
            ),
          ],
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 350));
    description.dispose();
  }

  Future<void> _openResultSubmission(CommunityMatch match) async {
    final aScore = TextEditingController();
    final bScore = TextEditingController();
    final notes = TextEditingController();
    final evidence = <String>[];
    String? winner = match.teamA?.id;
    String? submissionError;
    var submitting = false;
    var uploadingEvidence = false;
    var evidenceUploadProgress = 0.0;
    var evidenceUploadStatus = 'Preparing screenshot…';
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
                  onPressed: submitting || uploadingEvidence
                      ? null
                      : () async {
                          setState(() {
                            uploadingEvidence = true;
                            evidenceUploadProgress = 0;
                            evidenceUploadStatus = 'Choose a screenshot…';
                            submissionError = null;
                          });
                          try {
                            final id = await controller.pickAndUploadEvidence(
                              match.id,
                              onProgress: (progress, status) {
                                if (!context.mounted) return;
                                setState(() {
                                  evidenceUploadProgress = progress;
                                  evidenceUploadStatus = status;
                                });
                              },
                            );
                            if (!context.mounted) return;
                            if (id != null) {
                              setState(() {
                                evidence.add(id);
                                evidenceUploadProgress = 1;
                                evidenceUploadStatus = 'Screenshot added';
                              });
                            }
                          } catch (error) {
                            if (context.mounted) {
                              setState(
                                () => submissionError =
                                    'Could not upload screenshot: $error',
                              );
                            }
                          } finally {
                            if (context.mounted) {
                              setState(() => uploadingEvidence = false);
                            }
                          }
                        },
                  icon: uploadingEvidence
                      ? const SizedBox(
                          width: 17,
                          height: 17,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_photo_alternate_outlined),
                  label: Text(
                    uploadingEvidence
                        ? 'UPLOADING ${(evidenceUploadProgress * 100).round()}%'
                        : evidence.isEmpty
                        ? 'ADD RESULT SCREENSHOT'
                        : '${evidence.length} SCREENSHOT ADDED',
                  ),
                ),
                if (uploadingEvidence) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: evidenceUploadProgress,
                      minHeight: 6,
                      backgroundColor: CT.surfaceHigh,
                      color: _joinOrange,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      evidenceUploadStatus,
                      style: CT.body(10.5, color: CT.muted),
                    ),
                  ),
                ],
                if (submissionError != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    submissionError!,
                    style: CT.body(11, color: const Color(0xFFFF7B7B)),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: submitting || uploadingEvidence ? null : Get.back,
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: submitting || uploadingEvidence
                  ? null
                  : () async {
                      final scoreA = int.tryParse(aScore.text);
                      final scoreB = int.tryParse(bScore.text);
                      if (winner == null || scoreA == null || scoreB == null) {
                        setState(
                          () => submissionError =
                              'Choose a winner and enter both scores.',
                        );
                        return;
                      }
                      setState(() {
                        submitting = true;
                        submissionError = null;
                      });
                      final submitted = await controller.submitMatchResult(
                        match: match,
                        winnerTeamId: winner!,
                        teamAScore: scoreA,
                        teamBScore: scoreB,
                        evidenceAssetIds: evidence,
                        notes: notes.text,
                      );
                      if (!context.mounted) return;
                      if (submitted) {
                        Get.back<void>();
                      } else {
                        setState(() {
                          submitting = false;
                          submissionError =
                              controller.resultSubmissionError.value ??
                              'Result was not submitted. Please try again.';
                        });
                      }
                    },
              child: Text(submitting ? 'SUBMITTING...' : 'SUBMIT'),
            ),
          ],
        ),
      ),
    );
    // Let the dialog route and its text fields finish unmounting before their
    // controllers are disposed. Disposing immediately after Get.back caused
    // iOS to rebuild a field with an already-disposed controller.
    await Future<void>.delayed(const Duration(milliseconds: 350));
    aScore.dispose();
    bScore.dispose();
    notes.dispose();
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
    final fid = member.firebaseUid?.trim() ?? '';
    if (fid.isNotEmpty) {
      try {
        final roomId = await chat.getOrCreateDirectRoom(
          otherUser: ChatUserModel(
            uid: fid,
            displayName: member.displayName,
            username: member.gameId,
            email: '',
            phoneNumber: '',
            photoUrl: '',
            backendUserId: member.userId,
            isOnline: false,
            updatedAt: DateTime.now(),
            lastSeenAt: null,
          ),
        );
        Get.to(() => ChatRoomView(roomId: roomId));
        return;
      } catch (_) {}
    }
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

  Widget _hero(Tournament tournament, {required bool wide}) {
    final status = ctStatus(tournament.status);
    return AspectRatio(
      aspectRatio: wide ? 16 / 6 : 16 / 7.2,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _banner(tournament),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x08000000), Color(0xF2000000)],
                stops: [.25, 1],
              ),
            ),
          ),
          Positioned(
            top: 14,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: .58),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: _joinOrange.withValues(alpha: .5)),
              ),
              child: Text(
                status.label.toUpperCase(),
                style: CT.mono(8, color: _joinOrange),
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tournament.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: CT.display(wide ? 28 : 23),
                ),
                const SizedBox(height: 9),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _chip(tournament.game, _joinOrange),
                    if (tournament.tournamentType != null)
                      _chip(
                        tournament.tournamentType!.replaceAll('_', ' '),
                        CT.onSurfaceVariant,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryStats({
    required String entry,
    required String prize,
    required String players,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
      decoration: BoxDecoration(
        color: CT.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CT.outline),
      ),
      child: Row(
        children: [
          Expanded(child: _stat('ENTRY', entry)),
          const SizedBox(height: 36, child: VerticalDivider(color: CT.outline)),
          Expanded(child: _stat('PRIZE', prize)),
          const SizedBox(height: 36, child: VerticalDivider(color: CT.outline)),
          Expanded(child: _stat('PLAYERS', players)),
        ],
      ),
    );
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
