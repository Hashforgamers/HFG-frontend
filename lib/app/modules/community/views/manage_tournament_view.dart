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
      length: 6,
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
              _matches(),
              _results(context, tournament),
              _payouts(),
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
          Text(t.title, style: CT.display(24)),
          const SizedBox(height: 6),
          Text(status.label, style: CT.mono(10, color: status.color)),
          const SizedBox(height: 24),
          Row(
            children: [
              _metric('${t.registeredPlayersCount}/${t.maxPlayers}', 'PLAYERS'),
              _metric(
                '${ctCurrency(t.currency)}${ctAmount(t.prizePool)}',
                'PRIZE POOL',
              ),
              _metric(
                '${ctCurrency(t.currency)}${ctAmount(t.organizerCommissionAmount)}',
                'EARNINGS',
              ),
            ],
          ),
          const SizedBox(height: 28),
          if (!isTerminal) ...[
            _action(
              icon: Icons.edit_outlined,
              title: 'Edit tournament',
              subtitle: 'Update details, schedule, links, capacity and prizes.',
              onTap: () async {
                final result = await Get.toNamed(
                  AppRoutes.CREATE_TOURNAMENT,
                  arguments: t,
                );
                if (result is Tournament) controller.load();
              },
            ),
            _action(
              icon: Icons.meeting_room_outlined,
              title: 'Publish room details',
              subtitle: 'Game-neutral lobby, schedule and custom join fields.',
              onTap: () => _roomDialog(context, t),
            ),
          ],
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

  Widget _roster(BuildContext context) => RefreshIndicator(
    onRefresh: controller.load,
    color: CT.primary,
    child: controller.registrations.isEmpty
        ? _empty('No registrations yet')
        : ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: controller.registrations.length,
            separatorBuilder: (_, __) => const Divider(color: CT.outline),
            itemBuilder: (_, index) =>
                _registrationRow(context, controller.registrations[index]),
          ),
  );

  Widget _registrationRow(BuildContext context, ManagedRegistration item) {
    final checkedIn = item.checkedInAt != null;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: CT.surfaceHigh,
        backgroundImage: item.gamer.avatarUrl?.isNotEmpty == true
            ? NetworkImage(item.gamer.avatarUrl!)
            : null,
        child: item.gamer.avatarUrl?.isNotEmpty == true
            ? null
            : const Icon(Icons.person_outline, color: Colors.white),
      ),
      title: Text(item.gamer.displayName, style: CT.headline(14)),
      subtitle: Text(
        '${item.gamer.gameUsername.isEmpty ? item.status : '@${item.gamer.gameUsername} · ${item.status}'}${checkedIn ? ' · checked in' : ''}',
        style: CT.body(11),
      ),
      trailing: PopupMenuButton<String>(
        color: CT.surfaceHigh,
        iconColor: Colors.white,
        onSelected: (action) => controller.registrationAction(item, action),
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
    );
  }

  Widget _teams() => RefreshIndicator(
    onRefresh: controller.load,
    color: CT.primary,
    child: controller.teams.isEmpty
        ? _empty('No teams have been created yet')
        : ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: controller.teams.length,
            separatorBuilder: (_, _) => const Divider(color: CT.outline),
            itemBuilder: (_, index) {
              final team = controller.teams[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
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
                  onSelected: (action) => controller.teamAction(team, action),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'approve', child: Text('Approve')),
                    PopupMenuItem(
                      value: 'request_information',
                      child: Text('Request information'),
                    ),
                    PopupMenuItem(
                      value: 'lock_roster',
                      child: Text('Lock roster'),
                    ),
                    PopupMenuItem(value: 'check_in', child: Text('Check in')),
                    PopupMenuItem(value: 'reject', child: Text('Reject')),
                  ],
                ),
              );
            },
          ),
  );

  Widget _matches() => RefreshIndicator(
    onRefresh: controller.load,
    color: CT.primary,
    child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(child: Text('Schedule & bracket', style: CT.headline(18))),
            TextButton.icon(
              onPressed: controller.acting.value
                  ? null
                  : controller.generateMatches,
              icon: const Icon(Icons.account_tree_outlined),
              label: const Text('Generate'),
            ),
          ],
        ),
        TournamentBracket(matches: controller.matches),
        const SizedBox(height: 12),
        if (controller.matches.isNotEmpty) ...[
          Text('Match list', style: CT.headline(15)),
          ...controller.matches.map(_matchRow),
        ],
        const SizedBox(height: 24),
        Text('Leaderboard', style: CT.headline(18)),
        const SizedBox(height: 8),
        if (controller.leaderboard.isEmpty)
          _emptyInline('Standings will appear after results')
        else
          ...controller.leaderboard.map(
            (entry) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Text('#${entry.rank ?? '—'}', style: CT.headline(14)),
              title: Text(entry.name, style: CT.headline(14)),
              subtitle: Text(
                '${entry.kills} kills · ${entry.penalties} penalty',
                style: CT.body(11),
              ),
              trailing: Text('${entry.points} pts', style: CT.headline(13)),
            ),
          ),
      ],
    ),
  );

  Widget _matchRow(CommunityMatch match) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: const Icon(Icons.sports_esports_outlined, color: CT.primary),
    title: Text(
      '${match.teamA?.name ?? 'TBD'} vs ${match.teamB?.name ?? 'TBD'}',
      style: CT.headline(14),
    ),
    subtitle: Text(
      '${match.roundName ?? 'Round ${match.round ?? '—'}'} · '
      '${match.status.replaceAll('_', ' ')}'
      '${match.scheduledAt == null ? '' : ' · ${match.scheduledAt!.toLocal()}'}',
      style: CT.body(11),
    ),
  );

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

  Widget _results(BuildContext context, Tournament tournament) =>
      RefreshIndicator(
        onRefresh: controller.load,
        color: CT.primary,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(child: Text('Result inbox', style: CT.headline(18))),
                if (tournament.status != 'completed')
                  TextButton(
                    onPressed: controller.acting.value
                        ? null
                        : controller.submitVerifiedWinners,
                    child: const Text('Submit winners'),
                  ),
              ],
            ),
            if (controller.results.isEmpty)
              _emptyInline('No submitted results')
            else
              ...controller.results.map(_resultRow),
            const SizedBox(height: 28),
            Text('Open disputes', style: CT.headline(18)),
            const SizedBox(height: 8),
            if (controller.disputes.isEmpty)
              _emptyInline('No open disputes')
            else
              ...controller.disputes.map(
                (item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(item.reason, style: CT.headline(14)),
                  subtitle: Text(item.description, style: CT.body(12)),
                  trailing: Text(item.status.toUpperCase(), style: CT.mono(8)),
                ),
              ),
          ],
        ),
      );

  Widget _resultRow(MatchResult item) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(
      item.winner?.displayName ?? 'Player ${item.winnerUserId ?? ''}',
      style: CT.headline(14),
    ),
    subtitle: Text(
      'Rank ${item.rank ?? '—'} · ${item.score ?? 'No score'} · ${item.status}',
      style: CT.body(11),
    ),
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
        : null,
  );

  Widget _payouts() => RefreshIndicator(
    onRefresh: controller.load,
    color: CT.primary,
    child: controller.payouts.isEmpty
        ? _empty('Payouts appear after winners are submitted')
        : ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: controller.payouts.length,
            separatorBuilder: (_, __) => const Divider(color: CT.outline),
            itemBuilder: (_, index) {
              final item = controller.payouts[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
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
              );
            },
          ),
  );

  Widget _metric(String value, String label) => Expanded(
    child: Column(
      children: [
        Text(value, style: CT.headline(16)),
        const SizedBox(height: 4),
        Text(label, style: CT.mono(8)),
      ],
    ),
  );

  Widget _action({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool destructive = false,
  }) => ListTile(
    contentPadding: const EdgeInsets.symmetric(vertical: 4),
    onTap: controller.acting.value ? null : onTap,
    leading: Icon(icon, color: destructive ? CT.error : CT.primaryBright),
    title: Text(
      title,
      style: CT.headline(14, color: destructive ? CT.error : Colors.white),
    ),
    subtitle: Text(subtitle, style: CT.body(11)),
    trailing: const Icon(Icons.chevron_right_rounded, color: CT.muted),
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
