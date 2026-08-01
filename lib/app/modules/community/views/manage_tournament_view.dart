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
    return LayoutBuilder(
      builder: (context, constraints) => Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 760,
            minHeight: constraints.maxHeight,
            maxHeight: constraints.maxHeight,
          ),
          child: RefreshIndicator(
            onRefresh: controller.load,
            color: CT.primary,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
              children: [
                _overviewHero(t, status),
                const SizedBox(height: 24),
                _lifecycleProgress(t.status),
                const SizedBox(height: 28),
                if (!isTerminal)
                  _overviewSectionTitle(
                    'ACTION CENTER',
                    'Your next move to keep the tournament on track',
                  ),
                if (t.status == 'draft')
                  _action(
                    icon: Icons.publish_rounded,
                    title: 'Publish tournament',
                    subtitle:
                        'Make the tournament discoverable and open its lifecycle.',
                    primary: true,
                    onTap: controller.publish,
                  ),
                if (t.status == 'draft' &&
                    controller.readiness.value != null) ...[
                  const SizedBox(height: 8),
                  _readiness(controller.readiness.value!),
                ],
                if (t.status == 'registration_open')
                  _action(
                    icon: Icons.lock_clock_outlined,
                    title: 'Close registration',
                    subtitle:
                        'Stop new entries now. This cannot be reopened by the scheduler.',
                    primary: true,
                    onTap: () => _confirmLifecycle(
                      context,
                      title: 'Close registration?',
                      message:
                          'New players will no longer be able to enter this tournament.',
                      confirmLabel: 'Close registration',
                      action: controller.closeRegistration,
                    ),
                  ),
                if (t.status == 'registration_closed' &&
                    controller.matches.isEmpty)
                  _action(
                    icon: Icons.account_tree_outlined,
                    title: 'Generate bracket',
                    subtitle:
                        'Create matches from confirmed entries before going live.',
                    primary: true,
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
                    primary: true,
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
                  const SizedBox(height: 24),
                  _overviewSectionTitle(
                    'MANAGE',
                    'Configuration and participant access',
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
                    subtitle:
                        'Publish secure join details for confirmed players.',
                    onTap: () => _roomDialog(context, t),
                  ),
                if (!isTerminal) ...[
                  const SizedBox(height: 22),
                  _overviewSectionTitle(
                    'DANGER ZONE',
                    'Actions that affect every participant',
                  ),
                  _action(
                    icon: Icons.cancel_outlined,
                    title: 'Cancel tournament',
                    subtitle: 'Confirmed paid registrations will be refunded.',
                    destructive: true,
                    onTap: () => _cancelDialog(context),
                  ),
                ],
                if (controller.error.value != null)
                  _error(controller.error.value),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _roster(BuildContext context) {
    final all = controller.registrations.toList();
    final confirmed = all.where((item) => item.status == 'confirmed').toList();
    final checkedIn = all.where((item) => item.checkedInAt != null).toList();
    final pending = all.length - confirmed.length;
    return DefaultTabController(
      length: 3,
      child: LayoutBuilder(
        builder: (context, constraints) => Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 760,
              minHeight: constraints.maxHeight,
              maxHeight: constraints.maxHeight,
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Roster', style: CT.headline(20)),
                                const SizedBox(height: 3),
                                Text(
                                  'Review entries, payments and check-ins',
                                  style: CT.body(11),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Refresh roster',
                            onPressed: controller.load,
                            icon: const Icon(
                              Icons.refresh_rounded,
                              color: CT.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          _rosterMetric('${all.length}', 'TOTAL'),
                          _rosterMetric(
                            '${confirmed.length}',
                            'CONFIRMED',
                            color: CT.primary,
                          ),
                          _rosterMetric(
                            '${checkedIn.length}',
                            'CHECKED IN',
                            color: CT.successBright,
                          ),
                          _rosterMetric(
                            '$pending',
                            'PENDING',
                            color: CT.muted,
                            last: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                TabBar(
                  indicatorColor: CT.primary,
                  indicatorSize: TabBarIndicatorSize.label,
                  dividerColor: CT.hairline,
                  labelColor: CT.onSurface,
                  unselectedLabelColor: CT.muted,
                  labelStyle: CT.mono(9),
                  tabs: [
                    Tab(text: 'ALL  ${all.length}'),
                    Tab(text: 'CONFIRMED  ${confirmed.length}'),
                    Tab(text: 'CHECKED IN  ${checkedIn.length}'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _rosterList(context, all),
                      _rosterList(context, confirmed),
                      _rosterList(context, checkedIn),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _rosterMetric(
    String value,
    String label, {
    Color color = CT.onSurface,
    bool last = false,
  }) => Expanded(
    child: Container(
      padding: EdgeInsets.only(right: last ? 0 : 10),
      decoration: last
          ? null
          : const BoxDecoration(
              border: Border(right: BorderSide(color: CT.hairline)),
            ),
      child: Column(
        children: [
          Text(value, style: CT.headline(18, color: color)),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: CT.mono(7),
          ),
        ],
      ),
    ),
  );

  Widget _rosterList(
    BuildContext context,
    List<ManagedRegistration> registrations,
  ) => RefreshIndicator(
    onRefresh: controller.load,
    color: CT.primary,
    child: registrations.isEmpty
        ? ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(height: MediaQuery.sizeOf(context).height * .18),
              _emptyContent('No players in this view'),
            ],
          )
        : ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: registrations.length,
            separatorBuilder: (_, _) =>
                const Divider(height: 1, color: CT.hairline),
            itemBuilder: (_, index) =>
                _registrationRow(context, registrations[index]),
          ),
  );

  Widget _overviewHero(Tournament t, dynamic status) {
    final capacity = t.maxPlayers <= 0
        ? 0.0
        : (t.registeredPlayersCount / t.maxPlayers).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: status.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 7),
            Text(
              status.label.toString().toUpperCase(),
              style: CT.mono(8, color: status.color),
            ),
            const Spacer(),
            Text(t.game.toUpperCase(), style: CT.mono(8)),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          t.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: CT.display(23),
        ),
        if (t.tournamentStartAt != null) ...[
          const SizedBox(height: 6),
          Text(
            'Starts ${_matchTime(t.tournamentStartAt!)}',
            style: CT.body(10.5, color: CT.muted),
          ),
        ],
        const SizedBox(height: 22),
        Row(
          children: [
            _overviewMetric(
              '${t.registeredPlayersCount}/${t.maxPlayers}',
              'PLAYERS',
            ),
            _overviewMetric(
              '${ctCurrency(t.currency)}${ctAmount(t.prizePool)}',
              'PRIZE POOL',
            ),
            _overviewMetric(
              '${ctCurrency(t.currency)}${ctAmount(t.organizerCommissionAmount)}',
              'EARNINGS',
              last: true,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: capacity,
                  minHeight: 4,
                  backgroundColor: CT.surfaceHigh,
                  valueColor: const AlwaysStoppedAnimation(CT.primary),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text('${(capacity * 100).round()}% FULL', style: CT.mono(8)),
          ],
        ),
      ],
    );
  }

  Widget _overviewMetric(String value, String label, {bool last = false}) =>
      Expanded(
        child: Container(
          decoration: last
              ? null
              : const BoxDecoration(
                  border: Border(right: BorderSide(color: CT.hairline)),
                ),
          child: Column(
            children: [
              FittedBox(child: Text(value, style: CT.headline(16))),
              const SizedBox(height: 4),
              Text(label, style: CT.mono(7)),
            ],
          ),
        ),
      );

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('TOURNAMENT PROGRESS', style: CT.mono(9)),
            const Spacer(),
            Text(stages[active].$2, style: CT.mono(9, color: CT.primary)),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: (active + 1) / stages.length,
            minHeight: 4,
            backgroundColor: CT.surfaceHigh,
            valueColor: const AlwaysStoppedAnimation(CT.primary),
          ),
        ),
        const SizedBox(height: 9),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var index = 0; index < stages.length; index++)
              Text(
                stages[index].$2,
                style: CT.mono(
                  6.5,
                  color: index <= active ? CT.onSurfaceVariant : CT.muted,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _overviewSectionTitle(String title, String subtitle) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: CT.mono(9, color: CT.onSurface)),
        const SizedBox(height: 2),
        Text(subtitle, style: CT.body(10.5, color: CT.muted)),
      ],
    ),
  );

  Widget _registrationRow(BuildContext context, ManagedRegistration item) {
    final checkedIn = item.checkedInAt != null;
    final confirmed = item.status == 'confirmed';
    final paid = {
      'paid',
      'completed',
      'captured',
    }.contains(item.paymentStatus.toLowerCase());
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFF35200D),
            backgroundImage: item.gamer.avatarUrl?.isNotEmpty == true
                ? NetworkImage(item.gamer.avatarUrl!)
                : null,
            child: item.gamer.avatarUrl?.isNotEmpty == true
                ? null
                : const Icon(Icons.person_outline, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        item.gamer.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CT.headline(13.5),
                      ),
                    ),
                    if (checkedIn) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.check_circle_rounded,
                        color: CT.primary,
                        size: 15,
                      ),
                    ],
                  ],
                ),
                if (item.gamer.gameUsername.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    '@${item.gamer.gameUsername}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CT.body(10.5, color: CT.muted),
                  ),
                ],
                const SizedBox(height: 6),
                Wrap(
                  spacing: 10,
                  runSpacing: 4,
                  children: [
                    _rosterMeta(
                      confirmed
                          ? 'Confirmed'
                          : item.status.replaceAll('_', ' '),
                      confirmed ? CT.primary : CT.onSurfaceVariant,
                    ),
                    _rosterMeta(
                      paid ? 'Paid' : item.paymentStatus.replaceAll('_', ' '),
                      paid ? CT.successBright : CT.muted,
                    ),
                    if (checkedIn) _rosterMeta('Checked in', CT.successBright),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          PopupMenuButton<String>(
            tooltip: 'Player actions',
            color: CT.surfaceHigh,
            iconColor: CT.onSurfaceVariant,
            onSelected: (action) => controller.registrationAction(item, action),
            itemBuilder: (_) => [
              if (item.status == 'confirmed')
                PopupMenuItem(
                  value: checkedIn ? 'undo_check_in' : 'check_in',
                  child: Row(
                    children: [
                      Icon(
                        checkedIn
                            ? Icons.undo_rounded
                            : Icons.how_to_reg_outlined,
                        size: 19,
                      ),
                      const SizedBox(width: 10),
                      Text(checkedIn ? 'Undo check-in' : 'Check in'),
                    ],
                  ),
                ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'remove_participant',
                child: Row(
                  children: [
                    Icon(
                      Icons.person_remove_outlined,
                      color: CT.error,
                      size: 19,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Remove participant',
                      style: TextStyle(color: CT.error),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _rosterMeta(String text, Color color) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 5,
        height: 5,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 5),
      Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: CT.body(9.5, color: color),
      ),
    ],
  );

  Widget _teams() {
    final all = controller.teams.toList();
    final approved = all
        .where((team) => {'approved', 'confirmed'}.contains(team.status))
        .toList();
    final checkedIn = all.where((team) => team.checkedIn).toList();
    final locked = all.where((team) => team.rosterLocked).length;
    return DefaultTabController(
      length: 3,
      child: LayoutBuilder(
        builder: (context, constraints) => Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 760,
              minHeight: constraints.maxHeight,
              maxHeight: constraints.maxHeight,
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Teams', style: CT.headline(20)),
                                const SizedBox(height: 3),
                                Text(
                                  'Review rosters and tournament readiness',
                                  style: CT.body(11),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Refresh teams',
                            onPressed: controller.load,
                            icon: const Icon(
                              Icons.refresh_rounded,
                              color: CT.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          _rosterMetric('${all.length}', 'TOTAL'),
                          _rosterMetric(
                            '${approved.length}',
                            'APPROVED',
                            color: CT.primary,
                          ),
                          _rosterMetric(
                            '${checkedIn.length}',
                            'CHECKED IN',
                            color: CT.successBright,
                          ),
                          _rosterMetric(
                            '$locked',
                            'LOCKED',
                            color: CT.onSurfaceVariant,
                            last: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                TabBar(
                  indicatorColor: CT.primary,
                  indicatorSize: TabBarIndicatorSize.label,
                  dividerColor: CT.hairline,
                  labelColor: CT.onSurface,
                  unselectedLabelColor: CT.muted,
                  labelStyle: CT.mono(9),
                  tabs: [
                    Tab(text: 'ALL  ${all.length}'),
                    Tab(text: 'APPROVED  ${approved.length}'),
                    Tab(text: 'CHECKED IN  ${checkedIn.length}'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _teamList(context, all),
                      _teamList(context, approved),
                      _teamList(context, checkedIn),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _teamList(BuildContext context, List<CommunityTeam> teams) =>
      RefreshIndicator(
        onRefresh: controller.load,
        color: CT.primary,
        child: teams.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.sizeOf(context).height * .18),
                  _emptyContent('No teams in this view'),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: teams.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, color: CT.hairline),
                itemBuilder: (_, index) => _teamRow(teams[index]),
              ),
      );

  Widget _teamRow(CommunityTeam team) {
    final approved = {'approved', 'confirmed'}.contains(team.status);
    final initial = team.name.trim().isEmpty
        ? '?'
        : team.name.trim().characters.first.toUpperCase();
    return Theme(
      data: ThemeData.dark().copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(vertical: 5),
        childrenPadding: const EdgeInsets.fromLTRB(56, 0, 8, 12),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: CT.surfaceHigh,
          child: Text(
            team.seed == null ? initial : '#${team.seed}',
            style: CT.headline(12, color: CT.primaryBright),
          ),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                team.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CT.headline(13.5),
              ),
            ),
            if (team.checkedIn) ...[
              const SizedBox(width: 6),
              const Icon(
                Icons.check_circle_rounded,
                color: CT.primary,
                size: 15,
              ),
            ],
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Wrap(
            spacing: 10,
            runSpacing: 4,
            children: [
              _rosterMeta(
                approved ? 'Approved' : team.status.replaceAll('_', ' '),
                approved ? CT.primary : CT.onSurfaceVariant,
              ),
              _rosterMeta(
                '${team.acceptedMembers}/${team.members.length} ready',
                team.acceptedMembers == team.members.length
                    ? CT.successBright
                    : CT.muted,
              ),
              if (team.rosterLocked)
                _rosterMeta('Roster locked', CT.onSurfaceVariant),
            ],
          ),
        ),
        trailing: PopupMenuButton<String>(
          tooltip: 'Team actions',
          color: CT.surfaceHigh,
          iconColor: CT.onSurfaceVariant,
          onSelected: (action) => controller.teamAction(team, action),
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'approve', child: Text('Approve')),
            PopupMenuItem(
              value: 'request_information',
              child: Text('Request information'),
            ),
            PopupMenuItem(value: 'lock_roster', child: Text('Lock roster')),
            PopupMenuItem(value: 'check_in', child: Text('Check in')),
            PopupMenuDivider(),
            PopupMenuItem(
              value: 'reject',
              child: Text('Reject', style: TextStyle(color: CT.error)),
            ),
          ],
        ),
        children: [
          if (team.members.isEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: Text('No members added', style: CT.body(10.5)),
            )
          else
            for (final member in team.members) _teamMemberRow(member),
          if (team.rejectionReason?.trim().isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  team.rejectionReason!,
                  style: CT.body(10.5, color: CT.error),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _teamMemberRow(CommunityTeamMember member) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: CT.surfaceHigh,
            shape: BoxShape.circle,
          ),
          child: Text(
            member.displayName.isEmpty
                ? '?'
                : member.displayName.characters.first.toUpperCase(),
            style: CT.headline(10),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(member.displayName, style: CT.headline(11.5)),
              Text(
                [
                  member.role,
                  if (member.gameId.isNotEmpty) member.gameId,
                ].join(' · '),
                style: CT.body(9.5, color: CT.muted),
              ),
            ],
          ),
        ),
        _rosterMeta(
          member.invitationStatus.replaceAll('_', ' '),
          {'accepted', 'active'}.contains(member.invitationStatus)
              ? CT.successBright
              : CT.muted,
        ),
      ],
    ),
  );

  Widget _matches(BuildContext context) => DefaultTabController(
    length: 3,
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Matches', style: CT.headline(20)),
                        const SizedBox(height: 3),
                        Text(
                          'Bracket, fixtures and live results',
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
                              width: 20,
                              child: AppLinearLoader(width: 20, height: 3),
                            )
                          : const Icon(Icons.account_tree_outlined, size: 18),
                      label: Text(
                        controller.generatingMatches.value
                            ? 'Generating'
                            : 'Generate',
                      ),
                    ),
                  if (controller.teams.length >= 2)
                    IconButton(
                      tooltip: 'Create match manually',
                      onPressed: controller.acting.value
                          ? null
                          : () => _manualMatchDialog(context),
                      icon: const Icon(
                        Icons.add_rounded,
                        color: CT.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  _rosterMetric('${controller.matches.length}', 'TOTAL'),
                  _rosterMetric(
                    '${controller.matches.where((match) => {'live', 'in_progress'}.contains(match.status)).length}',
                    'LIVE',
                    color: CT.primary,
                  ),
                  _rosterMetric(
                    '${controller.matches.where((match) => {'scheduled', 'ready'}.contains(match.status)).length}',
                    'UPCOMING',
                    color: CT.onSurfaceVariant,
                  ),
                  _rosterMetric(
                    '${controller.matches.where((match) => match.status == 'completed').length}',
                    'DONE',
                    color: CT.successBright,
                    last: true,
                  ),
                ],
              ),
            ],
          ),
        ),
        if (controller.error.value != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: _inlineError(controller.error.value!),
          ),
        TabBar(
          indicatorColor: CT.primary,
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: CT.hairline,
          labelColor: CT.onSurface,
          unselectedLabelColor: CT.muted,
          labelStyle: CT.mono(9),
          tabs: const [
            Tab(text: 'BRACKET'),
            Tab(text: 'FIXTURES'),
            Tab(text: 'STANDINGS'),
          ],
        ),
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
            separatorBuilder: (_, _) =>
                const Divider(height: 1, color: CT.hairline),
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
            separatorBuilder: (_, _) =>
                const Divider(height: 1, color: CT.hairline),
            itemBuilder: (_, index) {
              final entry = controller.leaderboard[index];
              final podium = index < 3;
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 13,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 42,
                      child: Text(
                        '#${entry.rank ?? index + 1}',
                        style: CT.headline(
                          15,
                          color: podium ? CT.primary : CT.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(entry.name, style: CT.headline(14)),
                          Text(
                            '${entry.kills} kills${entry.penalties == 0 ? '' : ' · ${entry.penalties} penalty'}',
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

  Widget _matchRow(BuildContext context, CommunityMatch match) {
    final statusColor = switch (match.status) {
      'live' || 'in_progress' => CT.primary,
      'completed' => CT.successBright,
      'disputed' => CT.error,
      _ => CT.muted,
    };
    final hasScore = match.teamAScore != null || match.teamBScore != null;
    final action =
        controller.tournament.value?.status == 'live' &&
            {'scheduled', 'ready'}.contains(match.status)
        ? (
            label: 'START',
            onTap: () => _confirmLifecycle(
              context,
              title: 'Start this match?',
              message:
                  '${match.teamA?.name ?? 'Team A'} vs ${match.teamB?.name ?? 'Team B'} will move to in progress.',
              confirmLabel: 'Start match',
              action: () => controller.startMatch(match),
            ),
          )
        : controller.tournament.value?.status == 'live' &&
              {'live', 'in_progress', 'disputed'}.contains(match.status)
        ? (label: 'RESULT', onTap: () => _hostResultDialog(context, match))
        : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 3,
            height: 64,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      (match.roundName ?? 'Round ${match.round ?? '—'}')
                          .toUpperCase(),
                      style: CT.mono(8, color: CT.onSurfaceVariant),
                    ),
                    const SizedBox(width: 8),
                    _rosterMeta(match.status.replaceAll('_', ' '), statusColor),
                  ],
                ),
                const SizedBox(height: 9),
                _fixtureTeam(
                  match.teamA?.name ?? 'Opponent pending',
                  hasScore ? match.teamAScore : null,
                  winner: match.winnerTeamId == match.teamA?.id,
                ),
                const SizedBox(height: 5),
                _fixtureTeam(
                  match.teamB?.name ?? 'Opponent pending',
                  hasScore ? match.teamBScore : null,
                  winner: match.winnerTeamId == match.teamB?.id,
                ),
                if (match.scheduledAt != null) ...[
                  const SizedBox(height: 7),
                  Text(
                    _matchTime(match.scheduledAt!),
                    style: CT.body(9.5, color: CT.muted),
                  ),
                ],
              ],
            ),
          ),
          if (action != null) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: controller.acting.value ? null : action.onTap,
              child: Text(action.label),
            ),
          ],
        ],
      ),
    );
  }

  Widget _fixtureTeam(String name, int? score, {required bool winner}) => Row(
    children: [
      if (winner) ...[
        const Icon(Icons.arrow_right_rounded, color: CT.primary, size: 17),
        const SizedBox(width: 2),
      ],
      Expanded(
        child: Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: CT.headline(
            13,
            color: name == 'Opponent pending' ? CT.muted : CT.onSurface,
          ),
        ),
      ),
      if (score != null)
        Text(
          '$score',
          style: CT.headline(15, color: winner ? CT.primary : CT.onSurface),
        ),
    ],
  );

  String _matchTime(DateTime value) {
    final local = value.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '${local.day}/${local.month} · $hour:$minute $period';
  }

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

  Future<void> _hostResultDialog(
    BuildContext context,
    CommunityMatch match,
  ) async {
    final scoreA = TextEditingController();
    final scoreB = TextEditingController();
    final reason = TextEditingController(text: 'Host verified screenshot');
    HostMatchEvidence? evidence;
    var scanning = false;
    String? winnerId = match.teamA?.id;
    final game = (controller.tournament.value?.game ?? '').toLowerCase();
    final usesPlacement = [
      'bgmi',
      'pubg',
      'free fire',
      'fortnite',
      'battle royale',
    ].any(game.contains);
    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          final canSubmit =
              evidence != null &&
              winnerId != null &&
              int.tryParse(scoreA.text) != null &&
              int.tryParse(scoreB.text) != null;
          return Dialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 24,
            ),
            backgroundColor: Colors.transparent,
            child: LayoutBuilder(
              builder: (context, constraints) => ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 460,
                  maxHeight: MediaQuery.sizeOf(context).height * .86,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: CT.surface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 16, 8, 14),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Complete match',
                                    style: CT.headline(18),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${match.teamA?.name ?? 'Team A'} vs ${match.teamB?.name ?? 'Team B'}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: CT.body(11, color: CT.muted),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, false),
                              icon: const Icon(
                                Icons.close_rounded,
                                color: CT.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: CT.outline),
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        evidence == null
                                            ? Icons.document_scanner_outlined
                                            : Icons
                                                  .check_circle_outline_rounded,
                                        color: evidence == null
                                            ? CT.onSurfaceVariant
                                            : CT.successBright,
                                      ),
                                      const SizedBox(width: 9),
                                      Expanded(
                                        child: Text(
                                          evidence == null
                                              ? 'RESULT SCREENSHOT'
                                              : 'SCREENSHOT READ · ${(evidence!.analysis.confidence * 100).round()}% CONFIDENCE',
                                          style: CT.mono(
                                            9,
                                            color: evidence == null
                                                ? CT.onSurfaceVariant
                                                : CT.successBright,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 7),
                                  Text(
                                    evidence == null
                                        ? 'Upload a clear scoreboard. HASH stores the evidence asset and extracted result for captain review.'
                                        : 'Check the detected result before submitting.',
                                    style: CT.body(11),
                                  ),
                                  const SizedBox(height: 12),
                                  FilledButton.icon(
                                    onPressed: scanning
                                        ? null
                                        : () async {
                                            setState(() => scanning = true);
                                            try {
                                              final uploaded = await controller
                                                  .uploadMatchEvidence(match);
                                              if (uploaded == null) return;
                                              setState(() {
                                                evidence = uploaded;
                                                final detectedA = uploaded
                                                    .analysis
                                                    .detectedTeamAScore;
                                                final detectedB = uploaded
                                                    .analysis
                                                    .detectedTeamBScore;
                                                final detectedWinner = uploaded
                                                    .analysis
                                                    .detectedWinnerTeamId;
                                                if (detectedA != null) {
                                                  scoreA.text = '$detectedA';
                                                }
                                                if (detectedB != null) {
                                                  scoreB.text = '$detectedB';
                                                }
                                                if (detectedWinner != null) {
                                                  winnerId = detectedWinner;
                                                }
                                              });
                                            } catch (error) {
                                              Get.snackbar(
                                                'Could not read screenshot',
                                                error.toString(),
                                                snackPosition:
                                                    SnackPosition.BOTTOM,
                                              );
                                            } finally {
                                              if (context.mounted) {
                                                setState(
                                                  () => scanning = false,
                                                );
                                              }
                                            }
                                          },
                                    icon: scanning
                                        ? const SizedBox.square(
                                            dimension: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.add_photo_alternate_outlined,
                                            size: 18,
                                          ),
                                    label: Text(
                                      scanning
                                          ? 'READING SCOREBOARD...'
                                          : evidence == null
                                          ? 'UPLOAD SCREENSHOT'
                                          : 'SCAN ANOTHER',
                                    ),
                                    style: FilledButton.styleFrom(
                                      minimumSize: const Size.fromHeight(44),
                                      backgroundColor: CT.surfaceHigh,
                                      foregroundColor: CT.onSurface,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 22),
                              Text('Winner', style: CT.body(11)),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                key: ValueKey(winnerId),
                                initialValue: winnerId,
                                dropdownColor: CT.surfaceHigh,
                                decoration: const InputDecoration(
                                  prefixIcon: Icon(Icons.emoji_events_outlined),
                                  hintText: 'Select winner',
                                ),
                                items: [match.teamA, match.teamB]
                                    .whereType<CommunityTeam>()
                                    .where((team) => team.id.isNotEmpty)
                                    .map(
                                      (team) => DropdownMenuItem(
                                        value: team.id,
                                        child: Text(
                                          team.name,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) =>
                                    setState(() => winnerId = value),
                              ),
                              const SizedBox(height: 22),
                              Text(
                                usesPlacement ? 'FINISH RANKS' : 'SCORES',
                                style: CT.mono(9),
                              ),
                              const SizedBox(height: 4),
                              _resultValueCard(
                                team: match.teamA,
                                controller: scoreA,
                                usesPlacement: usesPlacement,
                                winner: winnerId == match.teamA?.id,
                                onChanged: () => setState(() {}),
                              ),
                              _resultValueCard(
                                team: match.teamB,
                                controller: scoreB,
                                usesPlacement: usesPlacement,
                                winner: winnerId == match.teamB?.id,
                                onChanged: () => setState(() {}),
                              ),
                              const SizedBox(height: 18),
                              TextField(
                                controller: reason,
                                maxLines: 1,
                                decoration: const InputDecoration(
                                  labelText: 'Audit note',
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.timer_outlined,
                                    color: CT.muted,
                                    size: 17,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '15-minute accept or dispute window after submission',
                                      style: CT.body(10.5, color: CT.muted),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
                        decoration: const BoxDecoration(
                          border: Border(top: BorderSide(color: CT.outline)),
                        ),
                        child: Row(
                          children: [
                            OutlinedButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, false),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: CT.outline),
                                foregroundColor: CT.onSurfaceVariant,
                              ),
                              child: const Text('CANCEL'),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton(
                                onPressed: canSubmit
                                    ? () => Navigator.pop(dialogContext, true)
                                    : null,
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(48),
                                  backgroundColor: CT.primary,
                                  foregroundColor: Colors.black,
                                ),
                                child: const Text('SUBMIT RESULT'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
    if (submitted == true && evidence != null && winnerId != null) {
      await controller.completeMatch(
        match: match,
        winnerTeamId: winnerId!,
        teamAScore: int.parse(scoreA.text),
        teamBScore: int.parse(scoreB.text),
        reason: reason.text.trim(),
        evidence: evidence!,
      );
    }
    scoreA.dispose();
    scoreB.dispose();
    reason.dispose();
  }

  Widget _resultValueCard({
    required CommunityTeam? team,
    required TextEditingController controller,
    required bool usesPlacement,
    required bool winner,
    required VoidCallback onChanged,
  }) {
    final name = team?.name.trim();
    final displayName = name == null || name.isEmpty ? 'Unknown team' : name;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: CT.hairline)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CT.headline(13),
                  ),
                ),
                if (winner) ...[
                  const SizedBox(width: 7),
                  const Icon(
                    Icons.check_circle_rounded,
                    color: CT.primary,
                    size: 15,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 14),
          SizedBox(
            width: 88,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              onChanged: (_) => onChanged(),
              style: CT.headline(16, color: Colors.white),
              decoration: InputDecoration(
                hintText: usesPlacement ? '#' : '0',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 11,
                ),
              ),
            ),
          ),
        ],
      ),
    );
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

  Widget _results(BuildContext context, Tournament tournament) {
    final submitted = controller.results
        .where((item) => item.status == 'submitted')
        .length;
    final verified = controller.results
        .where((item) => item.status == 'verified')
        .length;
    final rejected = controller.results
        .where((item) => item.status == 'rejected')
        .length;
    final openDisputes = controller.disputes
        .where((item) => {'open', 'under_review'}.contains(item.status))
        .length;
    return DefaultTabController(
      length: 2,
      child: LayoutBuilder(
        builder: (context, constraints) => Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 760,
              minHeight: constraints.maxHeight,
              maxHeight: constraints.maxHeight,
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Results', style: CT.headline(20)),
                                const SizedBox(height: 3),
                                Text(
                                  'Verify submissions and resolve disputes',
                                  style: CT.body(11),
                                ),
                              ],
                            ),
                          ),
                          if (tournament.status != 'completed')
                            FilledButton(
                              onPressed: controller.acting.value
                                  ? null
                                  : controller.submitVerifiedWinners,
                              child: const Text('SUBMIT WINNERS'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          _rosterMetric(
                            '$submitted',
                            'TO REVIEW',
                            color: CT.onSurfaceVariant,
                          ),
                          _rosterMetric(
                            '$verified',
                            'VERIFIED',
                            color: CT.primary,
                          ),
                          _rosterMetric(
                            '$rejected',
                            'REJECTED',
                            color: rejected > 0 ? CT.error : CT.muted,
                          ),
                          _rosterMetric(
                            '$openDisputes',
                            'DISPUTES',
                            color: openDisputes > 0 ? CT.error : CT.muted,
                            last: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                TabBar(
                  indicatorColor: CT.primary,
                  indicatorSize: TabBarIndicatorSize.label,
                  dividerColor: CT.hairline,
                  labelColor: CT.onSurface,
                  unselectedLabelColor: CT.muted,
                  labelStyle: CT.mono(9),
                  tabs: [
                    Tab(text: 'SUBMISSIONS  ${controller.results.length}'),
                    Tab(text: 'DISPUTES  ${controller.disputes.length}'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [_resultList(context), _disputeList(context)],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _resultList(BuildContext context) => RefreshIndicator(
    onRefresh: controller.load,
    color: CT.primary,
    child: controller.results.isEmpty
        ? ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(height: MediaQuery.sizeOf(context).height * .18),
              _emptyContent('No submitted results'),
            ],
          )
        : ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: controller.results.length,
            separatorBuilder: (_, _) =>
                const Divider(height: 1, color: CT.hairline),
            itemBuilder: (_, index) => _resultRow(controller.results[index]),
          ),
  );

  Widget _disputeList(BuildContext context) => RefreshIndicator(
    onRefresh: controller.load,
    color: CT.primary,
    child: controller.disputes.isEmpty
        ? ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(height: MediaQuery.sizeOf(context).height * .18),
              _emptyContent('No disputes'),
            ],
          )
        : ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: controller.disputes.length,
            separatorBuilder: (_, _) =>
                const Divider(height: 1, color: CT.hairline),
            itemBuilder: (_, index) {
              final item = controller.disputes[index];
              final open = {'open', 'under_review'}.contains(item.status);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 3,
                      height: 54,
                      decoration: BoxDecoration(
                        color: open ? CT.error : CT.muted,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.reason,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: CT.headline(13.5),
                                ),
                              ),
                              _rosterMeta(
                                item.status.replaceAll('_', ' '),
                                open ? CT.error : CT.muted,
                              ),
                            ],
                          ),
                          if (item.reporter != null) ...[
                            const SizedBox(height: 3),
                            Text(
                              'Reported by ${item.reporter!.displayName}',
                              style: CT.body(9.5, color: CT.muted),
                            ),
                          ],
                          const SizedBox(height: 6),
                          Text(
                            item.description,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: CT.body(10.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
  );

  Widget _resultRow(MatchResult item) {
    final verified = item.status == 'verified';
    final rejected = item.status == 'rejected';
    final color = verified
        ? CT.primary
        : rejected
        ? CT.error
        : CT.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              item.rank == null ? '—' : '#${item.rank}',
              style: CT.headline(15, color: color),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.winner?.displayName ??
                      'Player ${item.winnerUserId ?? ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CT.headline(13.5),
                ),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 10,
                  runSpacing: 4,
                  children: [
                    _rosterMeta(item.status.replaceAll('_', ' '), color),
                    _rosterMeta(
                      item.score?.trim().isNotEmpty == true
                          ? item.score!
                          : 'No score',
                      CT.muted,
                    ),
                    if (item.evidenceAssetIds.isNotEmpty)
                      _rosterMeta(
                        '${item.evidenceAssetIds.length} evidence',
                        CT.muted,
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (item.status == 'submitted')
            PopupMenuButton<String>(
              tooltip: 'Review result',
              color: CT.surfaceHigh,
              iconColor: CT.onSurfaceVariant,
              onSelected: (status) => controller.resultAction(item, status),
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'verified',
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: CT.primary,
                        size: 19,
                      ),
                      SizedBox(width: 10),
                      Text('Verify'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'rejected',
                  child: Row(
                    children: [
                      Icon(Icons.cancel_outlined, color: CT.error, size: 19),
                      SizedBox(width: 10),
                      Text('Reject', style: TextStyle(color: CT.error)),
                    ],
                  ),
                ),
              ],
            )
          else
            Icon(
              verified
                  ? Icons.check_circle_rounded
                  : rejected
                  ? Icons.cancel_rounded
                  : Icons.schedule_rounded,
              color: color,
              size: 19,
            ),
        ],
      ),
    );
  }

  Widget _payouts() {
    final all = controller.payouts.toList();
    final paid = all.where((item) => item.status == 'paid').toList();
    final pending = all.where((item) => item.status != 'paid').toList();
    final totalAmount = all.fold<double>(0, (sum, item) => sum + item.amount);
    final paidAmount = paid.fold<double>(0, (sum, item) => sum + item.amount);
    final currency = all.isEmpty ? 'INR' : all.first.currency;
    return DefaultTabController(
      length: 3,
      child: LayoutBuilder(
        builder: (context, constraints) => Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 760,
              minHeight: constraints.maxHeight,
              maxHeight: constraints.maxHeight,
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Payouts', style: CT.headline(20)),
                                const SizedBox(height: 3),
                                Text(
                                  'Track winner settlements',
                                  style: CT.body(11),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Refresh payouts',
                            onPressed: controller.load,
                            icon: const Icon(
                              Icons.refresh_rounded,
                              color: CT.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          _rosterMetric(
                            '${ctCurrency(currency)}${ctAmount(totalAmount)}',
                            'TOTAL',
                          ),
                          _rosterMetric(
                            '${ctCurrency(currency)}${ctAmount(paidAmount)}',
                            'SETTLED',
                            color: CT.successBright,
                          ),
                          _rosterMetric(
                            '${paid.length}/${all.length}',
                            'PAID',
                            color: CT.primary,
                          ),
                          _rosterMetric(
                            '${pending.length}',
                            'PENDING',
                            color: pending.isEmpty
                                ? CT.muted
                                : CT.onSurfaceVariant,
                            last: true,
                          ),
                        ],
                      ),
                      if (all.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: totalAmount <= 0
                                ? 0
                                : (paidAmount / totalAmount).clamp(0, 1),
                            minHeight: 4,
                            backgroundColor: CT.surfaceHigh,
                            valueColor: const AlwaysStoppedAnimation(
                              CT.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                TabBar(
                  indicatorColor: CT.primary,
                  indicatorSize: TabBarIndicatorSize.label,
                  dividerColor: CT.hairline,
                  labelColor: CT.onSurface,
                  unselectedLabelColor: CT.muted,
                  labelStyle: CT.mono(9),
                  tabs: [
                    Tab(text: 'ALL  ${all.length}'),
                    Tab(text: 'PENDING  ${pending.length}'),
                    Tab(text: 'PAID  ${paid.length}'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _payoutList(context, all),
                      _payoutList(context, pending),
                      _payoutList(context, paid),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _payoutList(BuildContext context, List<Payout> payouts) =>
      RefreshIndicator(
        onRefresh: controller.load,
        color: CT.primary,
        child: payouts.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.sizeOf(context).height * .18),
                  _emptyContent('No payouts in this view'),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: payouts.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, color: CT.hairline),
                itemBuilder: (_, index) => _payoutRow(payouts[index]),
              ),
      );

  Widget _payoutRow(Payout item) {
    final paid = item.status == 'paid';
    final failed = {'failed', 'rejected'}.contains(item.status);
    final statusColor = paid
        ? CT.successBright
        : failed
        ? CT.error
        : CT.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 42,
            child: Text(
              item.rank == null ? '—' : '#${item.rank}',
              style: CT.headline(
                15,
                color: item.rank != null ? CT.primary : CT.muted,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.gamer?.displayName ?? 'Winner',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CT.headline(13.5),
                ),
                const SizedBox(height: 5),
                _rosterMeta(item.status.replaceAll('_', ' '), statusColor),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${ctCurrency(item.currency)}${ctAmount(item.amount)}',
                style: CT.headline(14),
              ),
              const SizedBox(height: 4),
              Icon(
                paid
                    ? Icons.check_circle_rounded
                    : failed
                    ? Icons.error_outline_rounded
                    : Icons.schedule_rounded,
                color: statusColor,
                size: 17,
              ),
            ],
          ),
        ],
      ),
    );
  }

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
              colors: [Color(0xFFF8A241), Color(0xFFC06701)],
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

  BoxDecoration _dataCardDecoration({Color? accent}) => BoxDecoration(
    color: CT.surface,
    borderRadius: BorderRadius.circular(15),
    border: Border.all(color: accent?.withValues(alpha: .55) ?? CT.outline),
    boxShadow: const [
      BoxShadow(color: Color(0x22000000), blurRadius: 10, offset: Offset(0, 5)),
    ],
  );

  Widget _action({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool destructive = false,
    bool primary = false,
    bool loading = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: primary
              ? CT.primary.withValues(alpha: .1)
              : destructive
              ? CT.error.withValues(alpha: .05)
              : CT.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: primary
                ? CT.primary.withValues(alpha: .5)
                : destructive
                ? CT.error.withValues(alpha: .3)
                : CT.outline,
          ),
        ),
        child: InkWell(
          onTap: controller.acting.value ? null : onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(13, 13, 11, 13),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: primary
                        ? CT.primary
                        : destructive
                        ? CT.error.withValues(alpha: .12)
                        : CT.surfaceHigh,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: primary
                        ? Colors.black
                        : destructive
                        ? CT.error
                        : CT.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (primary) ...[
                        Text(
                          'RECOMMENDED NEXT STEP',
                          style: CT.mono(7.5, color: CT.primary),
                        ),
                        const SizedBox(height: 3),
                      ],
                      Text(
                        title,
                        style: CT.headline(
                          13.5,
                          color: destructive ? CT.error : CT.onSurface,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: CT.body(10.5, color: CT.muted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (loading)
                  const SizedBox(
                    width: 34,
                    child: AppLinearLoader(width: 34, height: 3),
                  )
                else
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: primary
                          ? CT.primary.withValues(alpha: .16)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      destructive
                          ? Icons.warning_amber_rounded
                          : Icons.arrow_forward_rounded,
                      size: 17,
                      color: destructive
                          ? CT.error
                          : primary
                          ? CT.primary
                          : CT.muted,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
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
  Widget _emptyContent(String text) =>
      Center(child: Text(text, style: CT.body(13)));
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
