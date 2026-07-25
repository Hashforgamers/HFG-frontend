import 'package:flutter/material.dart';
import 'package:hash/utils/widgets/loader.dart';
import 'package:get/get.dart';

import '../controllers/manage_tournament_controller.dart';
import '../models/community_entities.dart';
import '../models/tournament.dart';
import '../models/tournament_operations.dart';
import '../widgets/tournament_bracket.dart';
import 'community_theme.dart';
import 'tournaments_view.dart' show ctAmount, ctCurrency, ctStatus;
import '../../../routes/app_routes.dart';

class ManageTournamentView extends GetView<ManageTournamentController> {
  const ManageTournamentView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 7,
      child: Scaffold(
        backgroundColor: CT.bg,
        appBar: AppBar(
          backgroundColor: CT.bg,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text('Manage tournament', style: CT.headline(18)),
          actions: [
            IconButton(
              onPressed: controller.load,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: CT.primary,
            labelColor: Colors.white,
            unselectedLabelColor: CT.muted,
            tabs: const [
              Tab(text: 'OVERVIEW'),
              Tab(text: 'ROSTER'),
              Tab(text: 'TEAMS'),
              Tab(text: 'MATCHES'),
              Tab(text: 'RESULTS'),
              Tab(text: 'PAYOUTS'),
              Tab(text: 'CONTROL'),
            ],
          ),
        ),
        body: Obx(() {
          if (controller.loading.value && controller.tournament.value == null) {
            return const AppLinearLoader.screen();
          }
          final tournament = controller.tournament.value;
          if (tournament == null) return _error(controller.error.value);
          return TabBarView(
            children: [
              _overview(context, tournament),
              _roster(context),
              _teams(),
              _matches(context),
              _results(context, tournament),
              _payouts(),
              _controlRoom(context),
            ],
          );
        }),
      ),
    );
  }

  Widget _overview(BuildContext context, Tournament t) {
    final status = ctStatus(t.status);
    final isTerminal = t.status == 'completed' || t.status == 'cancelled';
    return RefreshIndicator(
      onRefresh: controller.load,
      color: CT.primary,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _overviewHero(t, status),
          const SizedBox(height: 14),
          _lifecycleProgress(t.status),
          const SizedBox(height: 22),
          if (!isTerminal)
            _overviewSectionTitle(
              'NEXT ACTIONS',
              'Move the tournament forward',
            ),
          if (t.status == 'draft')
            _action(
              icon: Icons.publish_rounded,
              title: 'Publish tournament',
              subtitle:
                  'Make the tournament discoverable and open its lifecycle.',
              onTap: controller.publish,
            ),
          if (t.status == 'draft' && controller.readiness.value != null) ...[
            const SizedBox(height: 8),
            _readiness(controller.readiness.value!),
          ],
          if (t.status == 'registration_open')
            _action(
              icon: Icons.lock_clock_outlined,
              title: 'Close registration',
              subtitle:
                  'Stop new entries now. This cannot be reopened by the scheduler.',
              onTap: () => _confirmLifecycle(
                context,
                title: 'Close registration?',
                message:
                    'New players will no longer be able to enter this tournament.',
                confirmLabel: 'Close registration',
                action: controller.closeRegistration,
              ),
            ),
          if (t.status == 'registration_closed' && controller.matches.isEmpty)
            _action(
              icon: Icons.account_tree_outlined,
              title: 'Generate bracket',
              subtitle:
                  'Create matches from confirmed entries before going live.',
              onTap: controller.generateMatches,
              loading: controller.generatingMatches.value,
            ),
          if (t.status == 'registration_closed' &&
              controller.matches.isNotEmpty)
            _action(
              icon: Icons.play_circle_outline_rounded,
              title: 'Start tournament',
              subtitle:
                  'Move the tournament to live now and begin operating matches.',
              onTap: () => _confirmLifecycle(
                context,
                title: 'Start tournament now?',
                message:
                    'The start time will be updated to now and the tournament will become live.',
                confirmLabel: 'Start tournament',
                action: controller.startTournament,
              ),
            ),
          if (!isTerminal) ...[
            const SizedBox(height: 14),
            _overviewSectionTitle(
              'ADMINISTRATION',
              'Configuration and safety controls',
            ),
          ],
          if (!isTerminal)
            _action(
              icon: Icons.edit_outlined,
              title: 'Edit tournament',
              subtitle: 'Schedule, format, capacity, prizes and rules.',
              onTap: () async {
                final result = await Get.toNamed(
                  AppRoutes.CREATE_TOURNAMENT,
                  arguments: t,
                );
                if (result is Tournament) controller.load();
              },
            ),
          if (!isTerminal)
            _action(
              icon: Icons.meeting_room_outlined,
              title: 'Room and lobby',
              subtitle: 'Publish secure join details for confirmed players.',
              onTap: () => _roomDialog(context, t),
            ),
          if (!isTerminal)
            _action(
              icon: Icons.cancel_outlined,
              title: 'Cancel tournament',
              subtitle: 'Confirmed paid registrations will be refunded.',
              destructive: true,
              onTap: () => _cancelDialog(context),
            ),
          if (controller.error.value != null) _error(controller.error.value),
        ],
      ),
    );
  }

  Widget _roster(BuildContext context) => Column(
    children: [
      _tabHeader(
        icon: Icons.groups_2_outlined,
        title: 'Participant roster',
        subtitle:
            '${controller.registrations.where((item) => item.status == 'confirmed').length} confirmed · '
            '${controller.registrations.where((item) => item.checkedInAt != null).length} checked in',
      ),
      Expanded(
        child: RefreshIndicator(
          onRefresh: controller.load,
          color: CT.primary,
          child: controller.registrations.isEmpty
              ? _empty('No registrations yet')
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: controller.registrations.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 9),
                  itemBuilder: (_, index) => _registrationRow(
                    context,
                    controller.registrations[index],
                  ),
                ),
        ),
      ),
    ],
  );

  Widget _overviewHero(Tournament t, dynamic status) {
    final capacity = t.maxPlayers <= 0
        ? 0.0
        : (t.registeredPlayersCount / t.maxPlayers).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF251746), Color(0xFF10172C), Color(0xFF0D1820)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF4B3979)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x44000000),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.game.toUpperCase(), style: CT.mono(9)),
                    const SizedBox(height: 5),
                    Text(
                      t.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: CT.display(23),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: status.color.withValues(alpha: .13),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: status.color.withValues(alpha: .7)),
                ),
                child: Text(
                  status.label.toString().toUpperCase(),
                  style: CT.mono(8, color: status.color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _metric(
                '${t.registeredPlayersCount}/${t.maxPlayers}',
                'PLAYERS',
                Icons.groups_2_outlined,
              ),
              const SizedBox(width: 8),
              _metric(
                '${ctCurrency(t.currency)}${ctAmount(t.prizePool)}',
                'PRIZE POOL',
                Icons.emoji_events_outlined,
              ),
              const SizedBox(width: 8),
              _metric(
                '${ctCurrency(t.currency)}${ctAmount(t.organizerCommissionAmount)}',
                'EARNINGS',
                Icons.account_balance_wallet_outlined,
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: capacity,
                    minHeight: 6,
                    backgroundColor: const Color(0xFF272D45),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF00F5D4)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text('${(capacity * 100).round()}% FULL', style: CT.mono(8)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _lifecycleProgress(String status) {
    const stages = [
      ('draft', 'SETUP'),
      ('registration_open', 'REGISTER'),
      ('registration_closed', 'LOCKED'),
      ('live', 'LIVE'),
      ('completed', 'DONE'),
    ];
    final aliases = {'published': 1, 'cancelled': 4};
    final active =
        aliases[status] ??
        stages.indexWhere((stage) => stage.$1 == status).clamp(0, 4);
    return Row(
      children: List.generate(stages.length, (index) {
        final reached = index <= active;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 25,
                      height: 25,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: reached ? CT.primary : CT.surfaceHigh,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: reached ? CT.primaryBright : CT.outline,
                        ),
                      ),
                      child: reached && index < active
                          ? const Icon(
                              Icons.check_rounded,
                              size: 14,
                              color: Colors.white,
                            )
                          : Text('${index + 1}', style: CT.mono(8)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      stages[index].$2,
                      maxLines: 1,
                      style: CT.mono(
                        7,
                        color: reached ? Colors.white : CT.muted,
                      ),
                    ),
                  ],
                ),
              ),
              if (index < stages.length - 1)
                Container(
                  width: 10,
                  height: 1,
                  color: index < active ? CT.primary : CT.outline,
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _overviewSectionTitle(String title, String subtitle) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Row(
      children: [
        Container(
          width: 3,
          height: 28,
          decoration: BoxDecoration(
            color: CT.primary,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 9),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: CT.mono(10, color: Colors.white)),
            Text(subtitle, style: CT.body(10.5)),
          ],
        ),
      ],
    ),
  );

  Widget _registrationRow(BuildContext context, ManagedRegistration item) {
    final checkedIn = item.checkedInAt != null;
    return Container(
      decoration: _dataCardDecoration(
        accent: checkedIn ? const Color(0xFF00C9A7) : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF292447),
          backgroundImage: item.gamer.avatarUrl?.isNotEmpty == true
              ? NetworkImage(item.gamer.avatarUrl!)
              : null,
          child: item.gamer.avatarUrl?.isNotEmpty == true
              ? null
              : const Icon(Icons.person_outline, color: Colors.white),
        ),
        title: Text(item.gamer.displayName, style: CT.headline(14)),
        subtitle: Text(
          item.gamer.gameUsername.isEmpty
              ? item.status.replaceAll('_', ' ')
              : '@${item.gamer.gameUsername}',
          style: CT.body(10.5),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _statusPill(
              checkedIn ? 'CHECKED IN' : item.status,
              checkedIn ? const Color(0xFF00C9A7) : CT.primaryBright,
            ),
            PopupMenuButton<String>(
              color: CT.surfaceHigh,
              iconColor: Colors.white,
              onSelected: (action) =>
                  controller.registrationAction(item, action),
              itemBuilder: (_) => [
                if (item.status == 'confirmed')
                  PopupMenuItem(
                    value: checkedIn ? 'undo_check_in' : 'check_in',
                    child: Text(checkedIn ? 'Undo check-in' : 'Check in'),
                  ),
                const PopupMenuItem(
                  value: 'remove_participant',
                  child: Text('Remove participant'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _teams() => Column(
    children: [
      _tabHeader(
        icon: Icons.shield_outlined,
        title: 'Teams',
        subtitle:
            '${controller.teams.length} total · ${controller.teams.where((team) => team.checkedIn).length} checked in',
      ),
      Expanded(
        child: RefreshIndicator(
          onRefresh: controller.load,
          color: CT.primary,
          child: controller.teams.isEmpty
              ? _empty('No teams have been created yet')
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: controller.teams.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 9),
                  itemBuilder: (_, index) {
                    final team = controller.teams[index];
                    return Container(
                      decoration: _dataCardDecoration(
                        accent: team.checkedIn ? const Color(0xFF00C9A7) : null,
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 7,
                        ),
                        leading: Container(
                          width: 42,
                          height: 42,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6540BA), Color(0xFF292050)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            team.seed?.toString() ??
                                team.name.characters.first.toUpperCase(),
                            style: CT.headline(13),
                          ),
                        ),
                        title: Text(team.name, style: CT.headline(14)),
                        subtitle: Text(
                          '${team.acceptedMembers}/${team.members.length} accepted · '
                          '${team.status.replaceAll('_', ' ')}'
                          '${team.checkedIn ? ' · checked in' : ''}',
                          style: CT.body(11),
                        ),
                        trailing: PopupMenuButton<String>(
                          color: CT.surfaceHigh,
                          iconColor: Colors.white,
                          onSelected: (action) =>
                              controller.teamAction(team, action),
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'approve',
                              child: Text('Approve'),
                            ),
                            PopupMenuItem(
                              value: 'request_information',
                              child: Text('Request information'),
                            ),
                            PopupMenuItem(
                              value: 'lock_roster',
                              child: Text('Lock roster'),
                            ),
                            PopupMenuItem(
                              value: 'check_in',
                              child: Text('Check in'),
                            ),
                            PopupMenuItem(
                              value: 'reject',
                              child: Text('Reject'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    ],
  );

  Widget _matches(BuildContext context) => DefaultTabController(
    length: 3,
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 10, 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tournament operations', style: CT.headline(18)),
                    const SizedBox(height: 2),
                    Text(
                      '${controller.matches.length} matches · '
                      '${controller.leaderboard.length} ranked teams',
                      style: CT.body(11),
                    ),
                  ],
                ),
              ),
              if (controller.tournament.value?.status ==
                      'registration_closed' &&
                  controller.matches.isEmpty)
                FilledButton.icon(
                  onPressed: controller.generatingMatches.value
                      ? null
                      : controller.generateMatches,
                  icon: controller.generatingMatches.value
                      ? const SizedBox(
                          width: 24,
                          child: AppLinearLoader(width: 24, height: 3),
                        )
                      : const Icon(Icons.account_tree_outlined, size: 18),
                  label: Text(
                    controller.generatingMatches.value
                        ? 'Generating'
                        : 'Generate',
                  ),
                ),
              if (controller.teams.length >= 2)
                IconButton.filledTonal(
                  tooltip: 'Create match manually',
                  onPressed: controller.acting.value
                      ? null
                      : () => _manualMatchDialog(context),
                  icon: const Icon(Icons.add_rounded),
                ),
            ],
          ),
        ),
        if (controller.error.value != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: _inlineError(controller.error.value!),
          ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: CT.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: CT.outline),
          ),
          child: TabBar(
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            indicator: BoxDecoration(
              color: CT.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            labelColor: Colors.white,
            unselectedLabelColor: CT.muted,
            labelStyle: CT.headline(11),
            tabs: const [
              Tab(icon: Icon(Icons.account_tree_outlined), text: 'BRACKET'),
              Tab(icon: Icon(Icons.sports_esports_outlined), text: 'MATCHES'),
              Tab(icon: Icon(Icons.leaderboard_outlined), text: 'RANKING'),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: TabBarView(
            children: [
              _bracketTab(),
              _matchListTab(context),
              _leaderboardTab(),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _bracketTab() => RefreshIndicator(
    onRefresh: controller.load,
    color: CT.primary,
    child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [TournamentBracket(matches: controller.matches)],
    ),
  );

  Widget _matchListTab(BuildContext context) => RefreshIndicator(
    onRefresh: controller.load,
    color: CT.primary,
    child: controller.matches.isEmpty
        ? _empty('No matches scheduled yet')
        : ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: controller.matches.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (_, index) =>
                _matchRow(context, controller.matches[index]),
          ),
  );

  Widget _leaderboardTab() => RefreshIndicator(
    onRefresh: controller.load,
    color: CT.primary,
    child: controller.leaderboard.isEmpty
        ? _empty('Standings will appear after results')
        : ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: controller.leaderboard.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (_, index) {
              final entry = controller.leaderboard[index];
              final podium = index < 3;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: podium ? const Color(0xFF201A38) : CT.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: podium ? const Color(0xFF57418B) : CT.outline,
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 38,
                      child: Text(
                        '#${entry.rank ?? index + 1}',
                        style: CT.headline(
                          15,
                          color: podium ? CT.primaryBright : Colors.white,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(entry.name, style: CT.headline(14)),
                          Text(
                            '${entry.kills} kills · ${entry.penalties} penalty',
                            style: CT.body(10.5),
                          ),
                        ],
                      ),
                    ),
                    Text('${entry.points} pts', style: CT.headline(13)),
                  ],
                ),
              );
            },
          ),
  );

  Widget _matchRow(BuildContext context, CommunityMatch match) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: CT.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: CT.outline),
    ),
    child: Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFF242044),
            borderRadius: BorderRadius.circular(11),
          ),
          child: const Icon(
            Icons.sports_esports_outlined,
            color: CT.primaryBright,
            size: 20,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${match.teamA?.name ?? 'TBD'} vs ${match.teamB?.name ?? 'TBD'}',
                style: CT.headline(14),
              ),
              const SizedBox(height: 3),
              Text(
                '${match.roundName ?? 'Round ${match.round ?? '—'}'} · '
                '${match.status.replaceAll('_', ' ')}'
                '${match.scheduledAt == null ? '' : ' · ${match.scheduledAt!.toLocal()}'}',
                style: CT.body(10.5),
              ),
            ],
          ),
        ),
        if (controller.tournament.value?.status == 'live' &&
            {'scheduled', 'ready'}.contains(match.status))
          TextButton(
            onPressed: controller.acting.value
                ? null
                : () => _confirmLifecycle(
                    context,
                    title: 'Start this match?',
                    message:
                        '${match.teamA?.name ?? 'Team A'} vs ${match.teamB?.name ?? 'Team B'} will move to in progress.',
                    confirmLabel: 'Start match',
                    action: () => controller.startMatch(match),
                  ),
            child: const Text('START'),
          ),
      ],
    ),
  );

  Widget _controlRoom(BuildContext context) => RefreshIndicator(
    onRefresh: controller.load,
    color: CT.primary,
    child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _tabHeader(
          icon: Icons.dashboard_customize_outlined,
          title: 'Control room',
          subtitle: 'Live operations, communications and audit history',
          action: FilledButton.icon(
            onPressed: controller.acting.value
                ? null
                : () => _announcementDialog(context),
            icon: const Icon(Icons.campaign_outlined, size: 18),
            label: const Text('ANNOUNCE'),
          ),
        ),
        if (controller.controlRoom.isEmpty)
          _emptyInline('Control-room summary is unavailable')
        else
          ...controller.controlRoom.entries
              .where((entry) => entry.value is num || entry.value is String)
              .map(
                (entry) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: _dataCardDecoration(),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 13),
                    title: Text(
                      entry.key.replaceAll('_', ' '),
                      style: CT.body(12),
                    ),
                    trailing: Text(
                      entry.value.toString(),
                      style: CT.headline(13),
                    ),
                  ),
                ),
              ),
        const SizedBox(height: 20),
        _overviewSectionTitle('ANNOUNCEMENTS', 'Participant communication'),
        const SizedBox(height: 8),
        if (controller.announcements.isEmpty)
          _emptyInline('No announcements yet')
        else
          ...controller.announcements.map(
            (item) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: _dataCardDecoration(accent: CT.primaryBright),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 13),
                leading: const Icon(Icons.campaign_outlined, color: CT.primary),
                title: Text(
                  (item['message'] ?? item['title'] ?? 'Announcement')
                      .toString(),
                  style: CT.headline(13),
                ),
                subtitle: Text(
                  (item['audience'] ?? 'all_participants')
                      .toString()
                      .replaceAll('_', ' '),
                  style: CT.body(11),
                ),
              ),
            ),
          ),
        const SizedBox(height: 20),
        _overviewSectionTitle('AUDIT TRAIL', 'Recent operational activity'),
        const SizedBox(height: 8),
        if (controller.auditLog.isEmpty)
          _emptyInline('No audit activity yet')
        else
          ...controller.auditLog.map(
            (item) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: _dataCardDecoration(),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 13),
                leading: const Icon(Icons.history_rounded, color: CT.muted),
                title: Text(
                  (item['action'] ?? item['event'] ?? 'Tournament updated')
                      .toString()
                      .replaceAll('_', ' '),
                  style: CT.headline(13),
                ),
                subtitle: Text(
                  (item['created_at'] ?? item['timestamp'] ?? '').toString(),
                  style: CT.body(11),
                ),
              ),
            ),
          ),
      ],
    ),
  );

  Future<void> _announcementDialog(BuildContext context) async {
    final message = TextEditingController();
    var audience = 'all_participants';
    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: CT.surfaceHigh,
          title: Text('Publish announcement', style: CT.headline(18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: message,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  hintText: 'Share an update with participants',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: audience,
                dropdownColor: CT.surfaceHigh,
                decoration: const InputDecoration(labelText: 'Audience'),
                items:
                    const {
                          'all_participants': 'All participants',
                          'captains': 'Captains',
                          'unchecked_in': 'Not checked in',
                        }.entries
                        .map(
                          (item) => DropdownMenuItem(
                            value: item.key,
                            child: Text(item.value),
                          ),
                        )
                        .toList(),
                onChanged: (value) =>
                    setState(() => audience = value ?? audience),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('CANCEL'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, message.text.trim().isNotEmpty),
              child: const Text('PUBLISH'),
            ),
          ],
        ),
      ),
    );
    final text = message.text.trim();
    message.dispose();
    if (submitted == true && text.isNotEmpty) {
      await controller.publishAnnouncement(message: text, audience: audience);
    }
  }

  Future<void> _manualMatchDialog(BuildContext context) async {
    String? teamAId;
    String? teamBId;
    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: CT.surfaceHigh,
          title: Text('Create manual match', style: CT.headline(18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: teamAId,
                dropdownColor: CT.surfaceHigh,
                decoration: const InputDecoration(labelText: 'Team A'),
                items: controller.teams
                    .map(
                      (team) => DropdownMenuItem(
                        value: team.id,
                        child: Text(team.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => teamAId = value),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: teamBId,
                dropdownColor: CT.surfaceHigh,
                decoration: const InputDecoration(labelText: 'Team B'),
                items: controller.teams
                    .map(
                      (team) => DropdownMenuItem(
                        value: team.id,
                        child: Text(team.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => teamBId = value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('CANCEL'),
            ),
            FilledButton(
              onPressed:
                  teamAId != null && teamBId != null && teamAId != teamBId
                  ? () => Navigator.pop(dialogContext, true)
                  : null,
              child: const Text('CREATE'),
            ),
          ],
        ),
      ),
    );
    if (submitted == true && teamAId != null && teamBId != null) {
      await controller.createManualMatch(teamAId: teamAId!, teamBId: teamBId!);
    }
  }

  Future<void> _confirmLifecycle(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    required Future<void> Function() action,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: CT.surfaceHigh,
        title: Text(title, style: CT.headline(17)),
        content: Text(message, style: CT.body(13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    if (confirmed == true) await action();
  }

  Widget _readiness(TournamentReadiness state) => Container(
    padding: const EdgeInsets.all(12),
    decoration: CT.card(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          state.readyToPublish ? 'Ready to publish' : 'Publish blockers',
          style: CT.headline(
            13,
            color: state.readyToPublish ? CT.successBright : CT.error,
          ),
        ),
        for (final blocker in state.blockers)
          Text('• $blocker', style: CT.body(11, color: CT.error)),
        for (final warning in state.warnings)
          Text('• $warning', style: CT.body(11, color: CT.muted)),
      ],
    ),
  );

  Widget _results(
    BuildContext context,
    Tournament tournament,
  ) => DefaultTabController(
    length: 2,
    child: Column(
      children: [
        _tabHeader(
          icon: Icons.fact_check_outlined,
          title: 'Results center',
          subtitle:
              '${controller.results.length} submissions · ${controller.disputes.length} disputes',
          action: tournament.status != 'completed'
              ? FilledButton.tonal(
                  onPressed: controller.acting.value
                      ? null
                      : controller.submitVerifiedWinners,
                  child: const Text('SUBMIT WINNERS'),
                )
              : null,
        ),
        _compactTabBar(const [Tab(text: 'SUBMISSIONS'), Tab(text: 'DISPUTES')]),
        const SizedBox(height: 8),
        Expanded(
          child: TabBarView(
            children: [
              RefreshIndicator(
                onRefresh: controller.load,
                child: controller.results.isEmpty
                    ? _empty('No submitted results')
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: controller.results.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 9),
                        itemBuilder: (_, index) =>
                            _resultRow(controller.results[index]),
                      ),
              ),
              RefreshIndicator(
                onRefresh: controller.load,
                child: controller.disputes.isEmpty
                    ? _empty('No open disputes')
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: controller.disputes.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 9),
                        itemBuilder: (_, index) {
                          final item = controller.disputes[index];
                          return Container(
                            padding: const EdgeInsets.all(13),
                            decoration: _dataCardDecoration(accent: CT.error),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.gavel_outlined,
                                  color: CT.error,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(item.reason, style: CT.headline(14)),
                                      const SizedBox(height: 3),
                                      Text(
                                        item.description,
                                        style: CT.body(11),
                                      ),
                                    ],
                                  ),
                                ),
                                _statusPill(item.status, CT.error),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _resultRow(MatchResult item) => Container(
    decoration: _dataCardDecoration(
      accent: item.status == 'verified' ? CT.successBright : null,
    ),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
      leading: Container(
        width: 39,
        height: 39,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF292447),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Text('#${item.rank ?? '—'}', style: CT.headline(12)),
      ),
      title: Text(
        item.winner?.displayName ?? 'Player ${item.winnerUserId ?? ''}',
        style: CT.headline(14),
      ),
      subtitle: Text(item.score ?? 'No score supplied', style: CT.body(10.5)),
      trailing: item.status == 'submitted'
          ? PopupMenuButton<String>(
              color: CT.surfaceHigh,
              iconColor: Colors.white,
              onSelected: (status) => controller.resultAction(item, status),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'verified', child: Text('Verify')),
                PopupMenuItem(value: 'rejected', child: Text('Reject')),
              ],
            )
          : _statusPill(
              item.status,
              item.status == 'verified' ? CT.successBright : CT.muted,
            ),
    ),
  );

  Widget _payouts() => Column(
    children: [
      _tabHeader(
        icon: Icons.payments_outlined,
        title: 'Payout tracker',
        subtitle:
            '${controller.payouts.length} payouts · '
            '${controller.payouts.where((item) => item.status == 'paid').length} settled',
      ),
      Expanded(
        child: RefreshIndicator(
          onRefresh: controller.load,
          color: CT.primary,
          child: controller.payouts.isEmpty
              ? _empty('Payouts appear after winners are submitted')
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: controller.payouts.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 9),
                  itemBuilder: (_, index) {
                    final item = controller.payouts[index];
                    final paid = item.status == 'paid';
                    return Container(
                      decoration: _dataCardDecoration(
                        accent: paid ? CT.successBright : null,
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 7,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF292447),
                          child: Text(
                            '#${item.rank ?? '—'}',
                            style: CT.headline(11),
                          ),
                        ),
                        title: Text(
                          item.gamer?.displayName ?? 'Winner',
                          style: CT.headline(14),
                        ),
                        subtitle: Text(
                          'Rank ${item.rank ?? '—'} · ${item.status.replaceAll('_', ' ')}',
                          style: CT.body(11),
                        ),
                        trailing: Text(
                          '${ctCurrency(item.currency)}${ctAmount(item.amount)}',
                          style: CT.headline(14, color: CT.successBright),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    ],
  );

  Widget _tabHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? action,
  }) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
    child: Row(
      children: [
        Container(
          width: 43,
          height: 43,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6040B3), Color(0xFF292050)],
            ),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: Colors.white, size: 21),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: CT.headline(18)),
              const SizedBox(height: 2),
              Text(subtitle, style: CT.body(10.5)),
            ],
          ),
        ),
        if (action != null) ...[const SizedBox(width: 8), action],
      ],
    ),
  );

  Widget _compactTabBar(List<Tab> tabs) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      color: CT.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: CT.outline),
    ),
    child: TabBar(
      tabs: tabs,
      indicatorSize: TabBarIndicatorSize.tab,
      dividerColor: Colors.transparent,
      indicator: BoxDecoration(
        color: CT.primary,
        borderRadius: BorderRadius.circular(9),
      ),
      labelColor: Colors.white,
      unselectedLabelColor: CT.muted,
      labelStyle: CT.mono(9),
    ),
  );

  BoxDecoration _dataCardDecoration({Color? accent}) => BoxDecoration(
    color: CT.surface,
    borderRadius: BorderRadius.circular(15),
    border: Border.all(color: accent?.withValues(alpha: .55) ?? CT.outline),
    boxShadow: const [
      BoxShadow(color: Color(0x22000000), blurRadius: 10, offset: Offset(0, 5)),
    ],
  );

  Widget _statusPill(String text, Color color) => Container(
    constraints: const BoxConstraints(maxWidth: 92),
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: .45)),
    ),
    child: Text(
      text.replaceAll('_', ' ').toUpperCase(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: CT.mono(7, color: color),
    ),
  );

  Widget _metric(String value, String label, IconData icon) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0x88151A2A),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFF303750)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 17, color: CT.primaryBright),
          const SizedBox(height: 6),
          FittedBox(child: Text(value, style: CT.headline(14))),
          const SizedBox(height: 4),
          Text(label, maxLines: 1, style: CT.mono(7)),
        ],
      ),
    ),
  );

  Widget _action({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool destructive = false,
    bool loading = false,
  }) => Container(
    margin: const EdgeInsets.only(bottom: 9),
    decoration: BoxDecoration(
      color: destructive ? CT.error.withValues(alpha: .06) : CT.surface,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(
        color: destructive ? CT.error.withValues(alpha: .35) : CT.outline,
      ),
    ),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
      onTap: controller.acting.value ? null : onTap,
      leading: Container(
        width: 39,
        height: 39,
        decoration: BoxDecoration(
          color: destructive
              ? CT.error.withValues(alpha: .12)
              : CT.primary.withValues(alpha: .14),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(
          icon,
          size: 20,
          color: destructive ? CT.error : CT.primaryBright,
        ),
      ),
      title: Text(
        title,
        style: CT.headline(13.5, color: destructive ? CT.error : Colors.white),
      ),
      subtitle: Text(subtitle, style: CT.body(10.5)),
      trailing: loading
          ? const SizedBox(
              width: 34,
              child: AppLinearLoader(width: 34, height: 3),
            )
          : const Icon(Icons.chevron_right_rounded, color: CT.muted),
    ),
  );

  Widget _empty(String text) => ListView(
    children: [
      SizedBox(
        height: 220,
        child: Center(child: Text(text, style: CT.body(13))),
      ),
    ],
  );
  Widget _emptyInline(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: Text(text, style: CT.body(12)),
  );
  Widget _inlineError(String text) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: CT.card().copyWith(
      border: Border.all(color: CT.error.withValues(alpha: .6)),
    ),
    child: Text(text, style: CT.body(12, color: CT.error)),
  );
  Widget _error(String? text) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        text ?? 'Something went wrong.',
        style: CT.body(13, color: CT.error),
      ),
    ),
  );

  Future<void> _roomDialog(BuildContext context, Tournament tournament) async {
    final value = await showDialog<_RoomDetailsResult>(
      context: context,
      builder: (_) => _RoomDetailsDialog(
        summary: tournament.roomDetails ?? '',
        details: tournament.roomDetailsData,
      ),
    );
    if (value != null) {
      controller.saveRoomDetails(summary: value.summary, data: value.details);
    }
  }

  Future<void> _cancelDialog(BuildContext context) async {
    final value = await _textDialog(
      context,
      'Cancel tournament',
      'Reason for cancellation',
    );
    if (value != null && value.trim().isNotEmpty) controller.cancel(value);
  }

  Future<String?> _textDialog(
    BuildContext context,
    String title,
    String hint, {
    String initialValue = '',
  }) => showDialog<String>(
    context: context,
    builder: (_) => _ManagedTournamentTextDialog(
      title: title,
      hint: hint,
      initialValue: initialValue,
    ),
  );
}

class _RoomDetailsResult {
  const _RoomDetailsResult({required this.summary, required this.details});

  final String summary;
  final RoomDetailsData details;
}

class _RoomDetailsDialog extends StatefulWidget {
  const _RoomDetailsDialog({required this.summary, required this.details});

  final String summary;
  final RoomDetailsData? details;

  @override
  State<_RoomDetailsDialog> createState() => _RoomDetailsDialogState();
}

class _RoomDetailsDialogState extends State<_RoomDetailsDialog> {
  late final TextEditingController _summary;
  late final TextEditingController _lobbyId;
  late final TextEditingController _accessCode;
  late final TextEditingController _joinUrl;
  late final TextEditingController _serverRegion;
  late final TextEditingController _instructions;
  late final TextEditingController _opensAt;
  late final TextEditingController _checkInAt;
  late final TextEditingController _contacts;
  late final TextEditingController _customFields;
  late String _method;

  RoomDetailsData get _existing => widget.details ?? const RoomDetailsData();

  @override
  void initState() {
    super.initState();
    final join = _existing.join;
    final schedule = _existing.schedule;
    _summary = TextEditingController(text: widget.summary);
    _lobbyId = TextEditingController(text: _text(join['lobby_id']));
    _accessCode = TextEditingController(text: _text(join['access_code']));
    _joinUrl = TextEditingController(text: _text(join['join_url']));
    _serverRegion = TextEditingController(text: _text(join['server_region']));
    _instructions = TextEditingController(text: _text(join['instructions']));
    _opensAt = TextEditingController(text: _text(schedule['opens_at']));
    _checkInAt = TextEditingController(text: _text(schedule['check_in_at']));
    _contacts = TextEditingController(
      text: _existing.contacts
          .map((item) => '${_text(item['channel'])}: ${_text(item['value'])}')
          .join('\n'),
    );
    _customFields = TextEditingController(
      text: _existing.customFields
          .map((item) => '${_text(item['label'])}: ${_text(item['value'])}')
          .join('\n'),
    );
    _method = _text(join['method']);
    if (_method.isEmpty) _method = 'in_game';
  }

  static String _text(dynamic value) => value?.toString().trim() ?? '';

  @override
  void dispose() {
    for (final controller in [
      _summary,
      _lobbyId,
      _accessCode,
      _joinUrl,
      _serverRegion,
      _instructions,
      _opensAt,
      _checkInAt,
      _contacts,
      _customFields,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _save() {
    final join = Map<String, dynamic>.from(_existing.join);
    final schedule = Map<String, dynamic>.from(_existing.schedule);
    _setText(join, 'method', _method);
    _setText(join, 'lobby_id', _lobbyId.text);
    _setText(join, 'access_code', _accessCode.text);
    _setText(join, 'join_url', _joinUrl.text);
    _setText(join, 'server_region', _serverRegion.text);
    _setText(join, 'instructions', _instructions.text);
    _setText(schedule, 'opens_at', _opensAt.text);
    _setText(schedule, 'check_in_at', _checkInAt.text);

    Navigator.pop(
      context,
      _RoomDetailsResult(
        summary: _summary.text.trim(),
        details: RoomDetailsData(
          schemaVersion: _existing.schemaVersion,
          join: join,
          schedule: schedule,
          contacts: _parsePairs(_contacts.text, 'channel', _existing.contacts),
          customFields: _parsePairs(
            _customFields.text,
            'label',
            _existing.customFields,
          ),
          additionalFields: _existing.additionalFields,
        ),
      ),
    );
  }

  void _setText(Map<String, dynamic> target, String key, String raw) {
    final value = raw.trim();
    if (value.isEmpty) {
      target.remove(key);
    } else {
      target[key] = value;
    }
  }

  List<Map<String, dynamic>> _parsePairs(
    String raw,
    String labelKey,
    List<Map<String, dynamic>> existing,
  ) {
    final result = <Map<String, dynamic>>[];
    for (final line in raw.split('\n')) {
      final separator = line.indexOf(':');
      if (separator <= 0) continue;
      final label = line.substring(0, separator).trim();
      final value = line.substring(separator + 1).trim();
      if (label.isEmpty || value.isEmpty) continue;
      final item = result.length < existing.length
          ? Map<String, dynamic>.from(existing[result.length])
          : <String, dynamic>{};
      item[labelKey] = label;
      item['value'] = value;
      result.add(item);
    }
    return result;
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    String? hint,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(
      controller: controller,
      maxLines: maxLines,
      style: CT.body(13, color: Colors.white),
      decoration: InputDecoration(labelText: label, hintText: hint),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final methods = <String>{
      'in_game',
      'join_url',
      'dedicated_server',
      'custom',
      _method,
    }.toList();
    return AlertDialog(
      backgroundColor: CT.surface,
      title: Text('Publish room details', style: CT.headline(17)),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(
                'Player-facing summary',
                _summary,
                maxLines: 2,
                hint: 'Room ID, password and essential instructions',
              ),
              DropdownButtonFormField<String>(
                initialValue: _method,
                dropdownColor: CT.surfaceHigh,
                decoration: const InputDecoration(labelText: 'Join method'),
                items: methods
                    .map(
                      (method) => DropdownMenuItem(
                        value: method,
                        child: Text(method.replaceAll('_', ' ')),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _method = value);
                },
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _field('Lobby / room ID', _lobbyId)),
                  const SizedBox(width: 10),
                  Expanded(child: _field('Access code', _accessCode)),
                ],
              ),
              _field('Join URL', _joinUrl, hint: 'https://…'),
              _field('Server region', _serverRegion),
              _field('Instructions', _instructions, maxLines: 3),
              Row(
                children: [
                  Expanded(child: _field('Opens at (ISO 8601)', _opensAt)),
                  const SizedBox(width: 10),
                  Expanded(child: _field('Check-in at (ISO 8601)', _checkInAt)),
                ],
              ),
              _field(
                'Contacts — one per line',
                _contacts,
                maxLines: 3,
                hint: 'Discord: https://discord.gg/example',
              ),
              _field(
                'Game-specific fields — one per line',
                _customFields,
                maxLines: 4,
                hint: 'Map: Erangel\nTournament code: ABCD',
              ),
              Text(
                'Unknown backend fields are preserved when you save.',
                style: CT.body(11, color: CT.muted),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Publish')),
      ],
    );
  }
}

class _ManagedTournamentTextDialog extends StatefulWidget {
  const _ManagedTournamentTextDialog({
    required this.title,
    required this.hint,
    required this.initialValue,
  });

  final String title;
  final String hint;
  final String initialValue;

  @override
  State<_ManagedTournamentTextDialog> createState() =>
      _ManagedTournamentTextDialogState();
}

class _ManagedTournamentTextDialogState
    extends State<_ManagedTournamentTextDialog> {
  late final TextEditingController _field;

  @override
  void initState() {
    super.initState();
    _field = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: CT.surface,
    title: Text(widget.title, style: CT.headline(17)),
    content: TextField(
      controller: _field,
      autofocus: true,
      maxLines: 3,
      style: CT.body(14, color: Colors.white),
      decoration: InputDecoration(hintText: widget.hint),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, _field.text),
        child: const Text('Save'),
      ),
    ],
  );
}
