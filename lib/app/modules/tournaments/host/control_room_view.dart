import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../routes/app_routes.dart';
import '../data/tournament_api.dart';
import '../data/tournament_models.dart';
import '../player/match_room_view.dart' show ResultInput, ResultSheet;
import '../player/tournament_detail_view.dart' show MatchTile;
import '../ui/tournament_theme.dart';
import '../ui/tournament_widgets.dart';

/// Host control room. Arguments: `{'id': String}`.
class ControlRoomView extends StatefulWidget {
  const ControlRoomView({super.key});
  @override
  State<ControlRoomView> createState() => _ControlRoomViewState();
}

class _ControlRoomViewState extends State<ControlRoomView> {
  final _api = TournamentApi();
  late final String _id = (jsonMap(Get.arguments)['id'] ?? '').toString();

  Tournament? _t;
  Map<String, dynamic> _room = const {};
  Readiness? _readiness;
  List<Registration> _regs = const [];
  List<Team> _teams = const [];
  List<MatchRow> _matches = const [];
  List<Dispute> _disputes = const [];
  List<Announcement> _news = const [];
  Map<String, dynamic> _results = const {};
  FinalizationPreview? _preview;
  List<Payout> _payouts = const [];
  bool _loading = true;
  Object? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final t = await _api.tournament(_id);
      T? soft<T>(Object? _) => null;
      final r = await Future.wait<dynamic>([
        _api.controlRoom(_id).catchError((_) => <String, dynamic>{}),
        t.status == TStatus.draft
            ? _api
                  .readiness(_id)
                  .then<Readiness?>((x) => x)
                  .catchError(soft<Readiness>)
            : Future.value(null),
        _api.registrations(_id).catchError((_) => <Registration>[]),
        t.isSolo
            ? Future.value(<Team>[])
            : _api.teams(_id).catchError((_) => <Team>[]),
        _api.privateMatches(_id).catchError((_) => <MatchRow>[]),
        _api.tournamentDisputes(_id).catchError((_) => <Dispute>[]),
        _api.announcements(_id).catchError((_) => <Announcement>[]),
        _api.resultsOverview(_id).catchError((_) => <String, dynamic>{}),
        const {
              TStatus.live,
              TStatus.registrationClosed,
              TStatus.completed,
            }.contains(t.status)
            ? _api
                  .finalizationPreview(_id)
                  .then<FinalizationPreview?>((x) => x)
                  .catchError(soft<FinalizationPreview>)
            : Future.value(null),
        _api.tournamentPayouts(_id).catchError((_) => <Payout>[]),
      ]);
      if (!mounted) return;
      setState(() {
        _t = t;
        _room = r[0] as Map<String, dynamic>;
        _readiness = r[1] as Readiness?;
        _regs = r[2] as List<Registration>;
        _teams = r[3] as List<Team>;
        _matches = r[4] as List<MatchRow>;
        _disputes = r[5] as List<Dispute>;
        _news = r[6] as List<Announcement>;
        _results = r[7] as Map<String, dynamic>;
        _preview = r[8] as FinalizationPreview?;
        _payouts = r[9] as List<Payout>;
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _run(Future<void> Function() f, String done) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await f();
      toast(done);
    } catch (e) {
      toastError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
      await _load();
    }
  }

  Map<String, String> get _names => {for (final t in _teams) t.id: t.name};

  // ----------------------------------------------------------- lifecycle ops

  Future<void> _publish() => _run(() async {
    final r = await _api.readiness(_id);
    if (r.blockers.isNotEmpty) {
      throw TournamentApiException('Fix first: ${r.blockers.first}');
    }
    await _api.updateTournament(_id, {'status': 'published'});
  }, 'Published.');

  Future<void> _closeRegistration() async {
    if (!await confirmAction(
      'Close registration?',
      'No new players can join after this.',
      confirm: 'Close',
    ))
      return;
    await _run(() => _api.closeRegistration(_id), 'Registration closed.');
  }

  Future<void> _generate() async {
    if (!await confirmAction(
      'Generate the bracket?',
      'Uses approved entries. This can only be done once.',
      confirm: 'Generate',
    )) {
      return;
    }
    await _run(() => _api.generateMatches(_id), 'Matches generated.');
  }

  Future<void> _start() async {
    if (!await confirmAction(
      'Start the tournament now?',
      'The tournament goes live immediately.',
      confirm: 'Start',
    ))
      return;
    await _run(() => _api.startTournament(_id), 'Tournament is live.');
  }

  Future<void> _cancel() async {
    final reason = await promptText(
      'Cancel tournament',
      hint: 'Reason shown to players',
      multiline: true,
      confirm: 'Cancel tournament',
    );
    if (reason == null) return;
    await _run(
      () => _api.cancelTournament(_id, reason),
      'Tournament cancelled. Refunds are processing.',
    );
  }

  Future<void> _announce() async {
    final title = await promptText(
      'Announcement title',
      hint: 'Room ID is out',
    );
    if (title == null) return;
    final message = await promptText(
      'Message',
      multiline: true,
      confirm: 'Next',
    );
    if (message == null) return;
    const audiences = {
      'all_participants': 'Everyone',
      'captains': 'Captains only',
      'unchecked_in': 'Not checked in yet',
    };
    final audience = await Get.bottomSheet<String>(
      SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final e in audiences.entries)
              ListTile(
                title: Text(e.value, style: CT.headline(14)),
                onTap: () => Get.back(result: e.key),
              ),
          ],
        ),
      ),
      backgroundColor: CT.surfaceLow,
    );
    if (audience == null) return;
    await _run(
      () => _api.announce(
        _id,
        title: title,
        message: message,
        audience: audience,
      ),
      'Announcement sent.',
    );
  }

  // ---------------------------------------------------------------------- UI

  @override
  Widget build(BuildContext context) {
    final t = _t;
    if (t == null) {
      return Scaffold(
        backgroundColor: CT.bg,
        appBar: tAppBar('Control room'),
        body: _loading
            ? const TLoading()
            : TMessage.error(_error ?? 'Not found', _load),
      );
    }
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: CT.bg,
        appBar: tAppBar(
          t.title,
          bottom: tTabs(const [
            'Overview',
            'Entrants',
            'Matches',
            'Results',
            'Finish',
          ], scrollable: true),
        ),
        body: TabBarView(
          children: [
            _list(_overview(t)),
            _list(_entrants(t)),
            _list(_matchesTab(t)),
            _list(_resultsTab()),
            _list(_finishTab(t)),
          ],
        ),
      ),
    );
  }

  Widget _list(List<Widget> children) => RefreshIndicator(
    color: CT.primary,
    onRefresh: _load,
    child: ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 60),
      physics: const AlwaysScrollableScrollPhysics(),
      children: children,
    ),
  );

  List<Widget> _overview(Tournament t) {
    final s = t.status;
    final confirmed = _regs.where((r) => r.isConfirmed).length;
    final approved = _teams.where((x) => x.isApproved).length;
    final checkedIn = t.isSolo
        ? _regs.where((r) => r.checkedInAt != null).length
        : _teams.where((x) => x.checkedInAt != null).length;
    final openDisputes = _disputes.where((d) => d.isOpen).length;
    final roomTasks = jsonStrings(
      _room['next_actions'] ?? _room['attention_items'] ?? _room['tasks'],
    );

    // The single next step for the host, following the lifecycle.
    final (String, String, VoidCallback?)? next = switch (s) {
      TStatus.draft => ('Publish', 'Players cannot see a draft.', _publish),
      TStatus.published => null,
      TStatus.registrationOpen => (
        'Close registration',
        '$confirmed confirmed so far. Close early or wait for the deadline.',
        _closeRegistration,
      ),
      TStatus.registrationClosed when _matches.isEmpty => (
        'Generate matches',
        t.isSolo
            ? '$confirmed confirmed players.'
            : '$approved approved teams. Approve teams in Entrants first.',
        _generate,
      ),
      TStatus.registrationClosed => (
        'Start tournament',
        '${_matches.length} matches ready.',
        _start,
      ),
      TStatus.live when openDisputes > 0 => null,
      _ => null,
    };

    final nextCard = switch (s) {
      TStatus.published => (
        'Registration opens ${fmtDateTime(t.registrationStartAt)}',
        'Share the link now so players are ready to join.',
        'Share tournament',
        Icons.ios_share_rounded,
        _share as VoidCallback?,
      ),
      TStatus.live when openDisputes > 0 => (
        '$openDisputes open dispute${openDisputes == 1 ? '' : 's'}',
        'A Hash referee decides disputes. Follow them in Results.',
        null,
        null,
        null,
      ),
      TStatus.live => (
        'Tournament is live',
        'Share lobby details from Matches and post results as games end.',
        null,
        null,
        null,
      ),
      TStatus.completed => (
        'Tournament completed',
        'Track prize payouts in Finish.',
        null,
        null,
        null,
      ),
      TStatus.cancelled => ('Tournament cancelled', 'Refunds are processed automatically.', null, null, null),
      _ when next != null => (next.$1, next.$2, next.$1, Icons.arrow_forward_rounded, next.$3),
      _ => null,
    };

    return [
      _hero(t),
      const SizedBox(height: 14),
      _lifecycle(s),
      if (_readiness != null && _readiness!.blockers.isNotEmpty) ...[
        const TSectionTitle('Before you publish'),
        for (final b in _readiness!.blockers)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text('• $b', style: CT.body(13, color: CT.error)),
          ),
      ],
      if (nextCard != null) ...[
        const TSectionTitle('Next step'),
        TPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(nextCard.$1, style: CT.headline(16, w: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(nextCard.$2, style: CT.body(13)),
              if (nextCard.$3 != null) ...[
                const SizedBox(height: 14),
                TButton(nextCard.$3!, icon: nextCard.$4, busy: _busy, onTap: nextCard.$5, height: 48),
              ],
            ],
          ),
        ),
      ],
      const TSectionTitle('At a glance'),
      GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.15,
        children: [
          _tile(Icons.groups_rounded, '${t.registeredCount}/${t.maxPlayers}', t.isSolo ? 'Players' : 'Entries'),
          if (!t.isSolo) _tile(Icons.verified_rounded, '$approved', 'Approved'),
          _tile(Icons.how_to_reg_rounded, '$checkedIn', 'Checked in'),
          _tile(Icons.account_tree_rounded, '${_matches.length}', 'Matches'),
          _tile(Icons.gavel_rounded, '$openDisputes', 'Disputes'),
          _tile(Icons.payments_rounded, money(t.totalCollection, t.currency), 'Collected'),
          if (t.isSolo) _tile(Icons.emoji_events_rounded, money(t.prizePool, t.currency), 'Prize pool'),
        ],
      ),
      if (roomTasks.isNotEmpty) ...[
        const TSectionTitle('Needs attention'),
        for (final x in roomTasks)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text('• $x', style: CT.body(13, color: CT.onSurface)),
          ),
      ],
      const TSectionTitle('Manage'),
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.4,
        children: [
          if (!s.isTerminal)
            _action(Icons.edit_rounded, 'Edit details', () async {
              await Get.toNamed(AppRoutes.CREATE_TOURNAMENT, arguments: {'id': _id});
              _load();
            }),
          if (s != TStatus.draft) _action(Icons.ios_share_rounded, 'Share', _share),
          if (!s.isTerminal && s != TStatus.draft) _action(Icons.campaign_rounded, 'Announce', _announce),
          _action(Icons.visibility_rounded, 'Player view', () => Get.toNamed(
                AppRoutes.TOURNAMENT_DETAIL,
                arguments: {'id': _id},
                preventDuplicates: false,
              )),
          if (s == TStatus.registrationClosed && _matches.isNotEmpty && next?.$1 != 'Start tournament')
            _action(Icons.play_arrow_rounded, 'Start now', _start),
          if (!s.isTerminal) _action(Icons.cancel_rounded, 'Cancel', _cancel, danger: true),
        ],
      ),
      if (_news.isNotEmpty) ...[
        const TSectionTitle('Announcements'),
        for (final a in _news)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TPanel(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.title, style: CT.headline(14)),
                  Text(a.message, style: CT.body(13)),
                  Text('${humanize(a.audience)} · ${fmtDateTime(a.publishedAt)}', style: CT.body(11.5, color: CT.muted)),
                ],
              ),
            ),
          ),
      ],
    ];
  }

  void _share() => shareTournament(_t!, context);

  Widget _hero(Tournament t) => Container(
    height: 150,
    decoration: CT.card(borderColor: CT.outline),
    clipBehavior: Clip.antiAlias,
    child: Stack(
      fit: StackFit.expand,
      children: [
        TBanner(t.bannerUrl),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x33000000), Color(0xEE0B0D12)],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TPill(t.status.label, color: statusColor(t.status)),
              const Spacer(),
              Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: CT.display(20)),
              const SizedBox(height: 2),
              Text(
                [t.game, t.modeLabel, fee(t), 'Starts ${fmtDateTime(t.startAt)}']
                    .where((e) => e.isNotEmpty)
                    .join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CT.body(12.5),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  /// Where the tournament is in its lifecycle.
  Widget _lifecycle(TStatus s) {
    const steps = ['Draft', 'Published', 'Open', 'Live', 'Done'];
    final at = switch (s) {
      TStatus.draft => 0,
      TStatus.published => 1,
      TStatus.registrationOpen || TStatus.registrationClosed => 2,
      TStatus.live => 3,
      TStatus.completed || TStatus.cancelled => 4,
      TStatus.unknown => 0,
    };
    return Row(
      children: [
        for (var i = 0; i < steps.length; i++)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 4,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: i <= at ? CT.success : Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  steps[i],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CT.body(10.5,
                      color: i == at ? CT.onSurface : CT.muted,
                      w: i == at ? FontWeight.w700 : FontWeight.w500),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _tile(IconData icon, String value, String label) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: CT.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: CT.outline),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Icon(icon, size: 18, color: CT.onSurfaceVariant),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value, style: CT.headline(17, w: FontWeight.w800)),
        ),
        Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: CT.body(11, color: CT.muted)),
      ],
    ),
  );

  Widget _action(IconData icon, String label, VoidCallback onTap, {bool danger = false}) => Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: _busy ? null : onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: CT.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: danger ? CT.error.withValues(alpha: 0.35) : CT.outline),
        ),
        child: Row(
          children: [
            Icon(icon, size: 19, color: danger ? CT.error : CT.onSurface),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CT.headline(13.5, color: danger ? CT.error : CT.onSurface, w: FontWeight.w700)),
            ),
          ],
        ),
      ),
    ),
  );

  // -------------------------------------------------------------- entrants

  List<Widget> _entrants(Tournament t) {
    final teamByReg = {for (final x in _teams) x.registrationId: x};
    return [
      if (!t.isSolo) ...[
        TSectionTitle('Teams (${_teams.length})'),
        if (_teams.isEmpty) Text('Teams appear here as players create them.', style: CT.body(13)),
        for (final team in _teams) _teamTile(team, t),
      ],
      TSectionTitle(
        t.isSolo
            ? 'Players (${_regs.length})'
            : 'Registrations (${_regs.length})',
      ),
      if (_regs.isEmpty)
        TMessage(
          icon: Icons.group_add_rounded,
          title: 'No one has joined yet',
          subtitle: t.status == TStatus.published
              ? 'Registration opens ${fmtDateTime(t.registrationStartAt)}. Share the link to get players ready.'
              : 'Share the tournament to fill your slots.',
          actionLabel: 'Share tournament',
          onAction: _share,
        ),
      for (final r in _regs)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: CT.card(),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.gamerName, style: CT.headline(14)),
                    Text(
                      [
                        r.statusLabel,
                        if (r.paymentStatus != 'not_required')
                          humanize(r.paymentStatus),
                        if (teamByReg[r.id] != null) teamByReg[r.id]!.name,
                        if (r.checkedInAt != null) 'Checked in',
                      ].join(' · '),
                      style: CT.body(12, color: stateColor(r.status)),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                color: CT.surfaceHigh,
                icon: const Icon(Icons.more_vert_rounded, color: CT.muted),
                onSelected: (a) async {
                  if (a == 'remove_participant' &&
                      !await confirmAction(
                        'Remove ${r.gamerName}?',
                        'Paid entries are refunded.',
                        confirm: 'Remove',
                        destructive: true,
                      )) {
                    return;
                  }
                  await _run(
                    () => _api.manageRegistration(_id, r.id, a),
                    'Updated.',
                  );
                },
                itemBuilder: (_) => [
                  if (r.isConfirmed && r.checkedInAt == null)
                    _menu('check_in', 'Check in'),
                  if (r.checkedInAt != null)
                    _menu('undo_check_in', 'Undo check-in'),
                  if (r.isActive) _menu('remove_participant', 'Remove'),
                ],
              ),
            ],
          ),
        ),
    ];
  }

  PopupMenuItem<String> _menu(String v, String label) => PopupMenuItem(
    value: v,
    child: Text(label, style: CT.body(14, color: CT.onSurface)),
  );

  Widget _teamTile(Team team, Tournament t) {
    final accepted = team.members
        .where((m) => m.accepted && m.role != 'substitute')
        .length;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: CT.card(),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(child: Text(team.name, style: CT.headline(14))),
                    const SizedBox(width: 8),
                    TPill(
                      humanize(team.status),
                      color: stateColor(team.status),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    '$accepted/${t.teamSize} accepted',
                    if (team.seed != null) 'Seed ${team.seed}',
                    if (team.checkedInAt != null) 'Checked in',
                    if (team.rosterLockedAt != null) 'Locked',
                    if (team.warnings > 0) '${team.warnings} warning(s)',
                  ].join(' · '),
                  style: CT.body(12),
                ),
                if (team.reason != null)
                  Text(team.reason!, style: CT.body(12, color: CT.error)),
              ],
            ),
          ),
          PopupMenuButton<String>(
            color: CT.surfaceHigh,
            icon: const Icon(Icons.more_vert_rounded, color: CT.muted),
            onSelected: (a) => _teamAction(team, a),
            itemBuilder: (_) => [
              if (!team.isApproved) _menu('approve', 'Approve'),
              if (team.status == 'pending')
                _menu('request_information', 'Request info'),
              if (team.status != 'rejected' && !team.isApproved)
                _menu('reject', 'Reject'),
              if (team.checkedInAt == null)
                _menu('check_in', 'Check in')
              else
                _menu('undo_check_in', 'Undo check-in'),
              _menu('seed', 'Set seed'),
              if (team.rosterLockedAt == null)
                _menu('lock_roster', 'Lock roster'),
              _menu('warn', 'Warn'),
              if (team.status != 'disqualified')
                _menu('disqualify', 'Disqualify'),
              _menu('refund', 'Refund'),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _teamAction(Team team, String action) async {
    String? reason;
    int? seed;
    if (const {
      'reject',
      'request_information',
      'warn',
      'disqualify',
      'refund',
    }.contains(action)) {
      reason = await promptText(
        '${humanize(action)} ${team.name}',
        hint: 'Reason the team will see',
        multiline: true,
        confirm: humanize(action),
      );
      if (reason == null) return;
    }
    if (action == 'seed') {
      final s = await promptText(
        'Seed for ${team.name}',
        keyboard: TextInputType.number,
        initial: team.seed?.toString(),
      );
      seed = int.tryParse(s ?? '');
      if (seed == null) return;
    }
    await _run(
      () => _api.manageTeam(_id, team.id, action, reason: reason, seed: seed),
      '${team.name}: ${humanize(action)} done.',
    );
  }

  // ---------------------------------------------------------------- matches

  List<Widget> _matchesTab(Tournament t) {
    final canGenerate =
        t.status == TStatus.registrationClosed && _matches.isEmpty;
    final auto = const {
      'single_elimination',
      'round_robin',
      'league',
    }.contains(t.format);
    return [
      if (canGenerate && auto)
        TButton(
          'Generate matches',
          icon: Icons.account_tree_rounded,
          busy: _busy,
          onTap: _generate,
        ),
      if (!t.status.isTerminal &&
          t.status != TStatus.draft &&
          (!auto || _matches.isNotEmpty)) ...[
        const SizedBox(height: 10),
        TButton.secondary(
          'Create match',
          icon: Icons.add_rounded,
          onTap: () => _createMatch(t),
        ),
      ],
      if (_matches.isEmpty)
        const TMessage(
          icon: Icons.account_tree_outlined,
          title: 'No matches yet',
          subtitle: 'Close registration and approve entries first.',
        ),
      const SizedBox(height: 12),
      for (final m in _matches)
        MatchTile(
          match: m,
          names: _names,
          onTap: m.isFinished ? null : () => _matchActions(m),
        ),
    ];
  }

  Future<void> _createMatch(Tournament t) async {
    final approved = _teams.where((x) => x.isApproved).toList();
    if (approved.length < 2)
      return toast('Approve at least two teams first.', error: true);
    final picked = <String>{};
    final ok = await Get.bottomSheet<bool>(
      StatefulBuilder(
        builder: (_, set) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pick teams', style: CT.display(18)),
                Text(
                  'Two teams for head-to-head, more for a multi-team round.',
                  style: CT.body(12.5),
                ),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final team in approved)
                        CheckboxListTile(
                          value: picked.contains(team.id),
                          activeColor: CT.primary,
                          title: Text(
                            team.name,
                            style: CT.body(14, color: CT.onSurface),
                          ),
                          onChanged: (v) => set(
                            () => v == true
                                ? picked.add(team.id)
                                : picked.remove(team.id),
                          ),
                        ),
                    ],
                  ),
                ),
                TButton(
                  'Create',
                  onTap: () => Get.back(result: picked.length >= 2),
                ),
              ],
            ),
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: CT.surfaceLow,
    );
    if (ok != true) return;
    final ids = picked.toList();
    final round =
        (_matches.map((m) => m.round ?? 0).fold(0, (a, b) => a > b ? a : b))
            .clamp(1, 999);
    await _run(
      () => _api.createMatch(_id, {
        'round_number': round,
        'match_number': _matches.length + 1,
        'scheduled_at': DateTime.now()
            .add(const Duration(minutes: 15))
            .toUtc()
            .toIso8601String(),
        if (ids.length == 2) ...{
          'team_a_id': ids[0],
          'team_b_id': ids[1],
        } else
          'participant_team_ids': ids,
      }),
      'Match created.',
    );
  }

  Future<void> _matchActions(MatchRow m) async {
    final actions = <String, String>{
      'set_lobby': 'Set lobby / room details',
      if (const {'scheduled', 'ready'}.contains(m.status))
        'start': 'Start match',
      if (!m.isMultiTeam &&
          const {'in_progress', 'awaiting_results'}.contains(m.status))
        'propose': 'Post result for captains',
      if (m.isMultiTeam && m.status == 'in_progress')
        'record_standings': 'Record standings',
      'reschedule': 'Reschedule',
      'restart': 'Restart',
      'cancel': 'Cancel match',
    };
    final a = await Get.bottomSheet<String>(
      SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(m.title, style: CT.headline(16)),
            ),
            for (final e in actions.entries)
              ListTile(
                title: Text(
                  e.value,
                  style: CT.body(
                    14.5,
                    color: e.key == 'cancel' ? CT.error : CT.onSurface,
                  ),
                ),
                onTap: () => Get.back(result: e.key),
              ),
          ],
        ),
      ),
      backgroundColor: CT.surfaceLow,
    );
    if (a == null) return;
    switch (a) {
      case 'set_lobby':
        final lobby = await _lobbyDialog(m.lobby);
        if (lobby == null) return;
        await _run(
          () => _api.manageMatch(_id, m.id, {
            'action': 'set_lobby',
            'lobby_details': lobby,
          }),
          'Lobby shared with both teams.',
        );
      case 'start':
        if (!m.hasLobby &&
            !await confirmAction(
              'No lobby set',
              'Players will not see room details. Start anyway?',
              confirm: 'Start',
            ))
          return;
        await _run(
          () => _api.manageMatch(_id, m.id, {'action': 'start'}),
          'Match started.',
        );
      case 'propose':
        final r = await Get.bottomSheet<ResultInput>(
          ResultSheet(
            title: 'Post result',
            tournamentId: _id,
            teamA: (m.teamAId ?? '', _names[m.teamAId] ?? 'Team A'),
            teamB: (m.teamBId ?? '', _names[m.teamBId] ?? 'Team B'),
            requireEvidence: true,
            withNotes: false,
          ),
          isScrollControlled: true,
          backgroundColor: CT.surfaceLow,
        );
        if (r == null) return;
        await _run(
          () => _api.proposeResult(
            _id,
            m.id,
            winnerTeamId: r.winner,
            scoreA: r.a,
            scoreB: r.b,
            evidenceAssetIds: r.evidence,
          ),
          'Result posted. Captains have 15 minutes to accept or dispute.',
        );
      case 'record_standings':
        final rows = await _standingsDialog(m);
        if (rows == null) return;
        await _run(
          () => _api.manageMatch(_id, m.id, {
            'action': 'record_standings',
            'standings': rows,
          }),
          'Standings recorded.',
        );
      case 'reschedule':
        if (!mounted) return;
        final d = await showDatePicker(
          context: context,
          initialDate: m.scheduledAt ?? DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 60)),
        );
        if (d == null || !mounted) return;
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(m.scheduledAt ?? DateTime.now()),
        );
        if (time == null) return;
        final at = DateTime(d.year, d.month, d.day, time.hour, time.minute);
        await _run(
          () => _api.manageMatch(_id, m.id, {
            'action': 'reschedule',
            'scheduled_at': at.toUtc().toIso8601String(),
          }),
          'Rescheduled.',
        );
      case 'restart' || 'cancel':
        final reason = await promptText(
          '${humanize(a)} match',
          hint: 'Reason',
          multiline: true,
          confirm: humanize(a),
        );
        if (reason == null) return;
        await _run(
          () => _api.manageMatch(_id, m.id, {'action': a, 'reason': reason}),
          'Done.',
        );
    }
  }

  Future<Map<String, dynamic>?> _lobbyDialog(
    Map<String, dynamic> current,
  ) async {
    final id = TextEditingController(
      text: jsonStr(current['lobby_id'] ?? current['room_id']),
    );
    final code = TextEditingController(
      text: jsonStr(current['access_code'] ?? current['password']),
    );
    final server = TextEditingController(
      text: jsonStr(current['server_region']),
    );
    final notes = TextEditingController(text: jsonStr(current['notes']));
    return Get.dialog<Map<String, dynamic>>(
      AlertDialog(
        backgroundColor: CT.surfaceHigh,
        title: Text('Lobby details', style: CT.headline(17)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (c, l) in [
                (id, 'Room / lobby ID'),
                (code, 'Password'),
                (server, 'Server'),
                (notes, 'Notes'),
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TextField(
                    controller: c,
                    style: CT.body(14, color: CT.onSurface),
                    decoration: tInput('', label: l),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel', style: CT.body(14)),
          ),
          TextButton(
            onPressed: () => Get.back(
              result: {
                'lobby_id': ?jsonStr(id.text),
                'access_code': ?jsonStr(code.text),
                'server_region': ?jsonStr(server.text),
                'notes': ?jsonStr(notes.text),
              },
            ),
            child: Text('Share', style: CT.headline(14, color: CT.primary)),
          ),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>?> _standingsDialog(MatchRow m) async {
    final ids = m.participantIds;
    final place = {for (final id in ids) id: TextEditingController()};
    final kills = {for (final id in ids) id: TextEditingController(text: '0')};
    return Get.bottomSheet<List<Map<String, dynamic>>>(
      SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            16 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Record standings', style: CT.display(18)),
              Text(
                'Every team needs a unique placement.',
                style: CT.body(12.5),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final id in ids)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                _names[id] ?? 'Team',
                                style: CT.body(13.5, color: CT.onSurface),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: place[id],
                                keyboardType: TextInputType.number,
                                style: CT.body(14, color: CT.onSurface),
                                decoration: tInput('', label: 'Place'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: kills[id],
                                keyboardType: TextInputType.number,
                                style: CT.body(14, color: CT.onSurface),
                                decoration: tInput('', label: 'Kills'),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TButton(
                'Save standings',
                onTap: () {
                  final rows = [
                    for (final id in ids)
                      {
                        'team_id': id,
                        'placement': int.tryParse(place[id]!.text),
                        'kills': int.tryParse(kills[id]!.text) ?? 0,
                        'penalty_points': 0,
                      },
                  ];
                  final places = rows.map((r) => r['placement']).toList();
                  if (places.any((p) => p == null || (p as int) < 1) ||
                      places.toSet().length != places.length) {
                    return toast(
                      'Give every team a unique placement.',
                      error: true,
                    );
                  }
                  Get.back(result: rows);
                },
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: CT.surfaceLow,
    );
  }

  // ---------------------------------------------------------------- results

  List<Widget> _resultsTab() {
    final summary = {
      ...jsonMap(_results['summary']),
      ...jsonMap(_results['counters']),
    }.entries.where((e) => e.value is num).toList();
    final pendingMatches = _matches
        .where(
          (m) => const {
            'awaiting_results',
            'result_pending',
            'disputed',
          }.contains(m.status),
        )
        .toList();
    return [
      if (summary.isNotEmpty)
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final e in summary)
              TPill(
                '${humanize(e.key)}: ${e.value}',
                color: CT.onSurfaceVariant,
              ),
          ],
        ),
      TSectionTitle('Waiting on results (${pendingMatches.length})'),
      if (pendingMatches.isEmpty) Text('Nothing pending.', style: CT.body(13)),
      for (final m in pendingMatches)
        MatchTile(match: m, names: _names, onTap: () => _matchActions(m)),
      TSectionTitle('Disputes (${_disputes.length})'),
      Text(
        'A Hash referee decides match disputes. You can add context in the dispute chat.',
        style: CT.body(12.5, color: CT.muted),
      ),
      const SizedBox(height: 8),
      for (final d in _disputes)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: CT.card(),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d.reason, style: CT.headline(14)),
                    if (d.description != null)
                      Text(
                        d.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: CT.body(12.5),
                      ),
                    if (d.deadline != null)
                      Text(
                        'Due ${fmtDateTime(d.deadline)}',
                        style: CT.body(11.5, color: CT.muted),
                      ),
                  ],
                ),
              ),
              TPill(
                humanize(d.status),
                color: d.isOpen ? CT.error : CT.success,
              ),
            ],
          ),
        ),
    ];
  }

  // ----------------------------------------------------------------- finish

  List<Widget> _finishTab(Tournament t) {
    final p = _preview;
    final out = <Widget>[];
    if (_payouts.isNotEmpty) {
      out.add(const TSectionTitle('Payouts'));
      out.add(
        Text(
          'Hash approves and pays prizes into winners\' wallets.',
          style: CT.body(12.5, color: CT.muted),
        ),
      );
      for (final x in _payouts) {
        out.add(
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: CT.card(),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        x.type == 'organizer_commission'
                            ? 'Your commission'
                            : '#${x.rank ?? '-'} ${x.gamerName}',
                        style: CT.headline(14),
                      ),
                      Text(
                        x.statusLabel,
                        style: CT.body(12, color: stateColor(x.status)),
                      ),
                    ],
                  ),
                ),
                Text(money(x.amount, x.currency), style: CT.headline(14)),
              ],
            ),
          ),
        );
      }
      return out;
    }
    if (p == null) {
      return [
        const TMessage(
          icon: Icons.emoji_events_outlined,
          title: 'Finish comes later',
          subtitle: 'Once every match is done you pick the winners here.',
        ),
      ];
    }
    out.addAll([
      TPanel(
        border: (p.ready ? CT.success : CT.primary).withValues(alpha: 0.6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              p.ready ? 'Ready to finish' : 'Not ready yet',
              style: CT.headline(15),
            ),
            for (final b in p.blockers)
              Text('• $b', style: CT.body(13, color: CT.error)),
            const SizedBox(height: 6),
            Text(
              'Prize pool ${money(p.prizePool > 0 ? p.prizePool : t.prizePool, p.currency)}',
              style: CT.body(13),
            ),
            if (!t.isSolo)
              Text(
                'Team prizes go to the captain\'s Hash wallet.',
                style: CT.body(12, color: CT.muted),
              ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      TButton(
        'Pick winners',
        icon: Icons.emoji_events_rounded,
        busy: _busy,
        onTap: p.ready ? () => _pickWinners(t, p) : null,
      ),
    ]);
    return out;
  }

  Future<void> _pickWinners(Tournament t, FinalizationPreview p) async {
    // Eligible payees from the preview; fall back to approved teams / confirmed players.
    final payees = <(String label, Map<String, dynamic> ref)>[
      for (final x in p.payees)
        (
          jsonStr(x['team_name'] ?? x['display_name'] ?? x['name']) ?? 'Entry',
          {
            'team_id': ?jsonStr(x['team_id']),
            'user_id': ?jsonInt(x['user_id']),
          },
        ),
    ];
    if (payees.isEmpty) {
      payees.addAll(
        t.isSolo
            ? _regs
                  .where((r) => r.isConfirmed)
                  .map(
                    (r) =>
                        (r.gamerName, <String, dynamic>{'user_id': r.userId}),
                  )
            : _teams
                  .where((x) => x.isApproved)
                  .map((x) => (x.name, <String, dynamic>{'team_id': x.id})),
      );
    }
    final ranks = t.prizeDistribution.isEmpty ? 1 : t.prizeDistribution.length;
    final chosen = List<int?>.filled(ranks, null);
    final winners = await Get.bottomSheet<List<Map<String, dynamic>>>(
      StatefulBuilder(
        builder: (_, set) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pick winners', style: CT.display(19)),
                Text(
                  'Prize amounts follow your prize split. This cannot be undone.',
                  style: CT.body(12.5),
                ),
                const SizedBox(height: 10),
                for (var r = 0; r < ranks; r++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: DropdownButtonFormField<int>(
                      initialValue: chosen[r],
                      dropdownColor: CT.surfaceHigh,
                      decoration: tInput('', label: 'Rank ${r + 1}'),
                      style: CT.body(14, color: CT.onSurface),
                      items: [
                        for (final (i, x) in payees.indexed)
                          DropdownMenuItem(value: i, child: Text(x.$1)),
                      ],
                      onChanged: (v) => set(() => chosen[r] = v),
                    ),
                  ),
                const SizedBox(height: 8),
                TButton(
                  'Submit winners',
                  onTap: () {
                    final picked = chosen.whereType<int>().toList();
                    if (picked.isEmpty ||
                        picked.toSet().length != picked.length) {
                      return toast(
                        'Pick different entries for each rank.',
                        error: true,
                      );
                    }
                    Get.back(
                      result: [
                        for (var r = 0; r < ranks; r++)
                          if (chosen[r] != null)
                            {
                              ...payees[chosen[r]!].$2,
                              'rank': r + 1,
                              'amount': 0,
                            },
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: CT.surfaceLow,
    );
    if (winners == null) return;
    await _run(
      () => _api.submitWinners(_id, winners),
      'Winners recorded. Hash will approve the payouts.',
    );
  }
}
