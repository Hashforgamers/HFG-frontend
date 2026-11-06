import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../routes/app_routes.dart';
import '../data/tournament_api.dart';
import '../data/tournament_models.dart';
import '../data/tournament_payment.dart';
import '../ui/tournament_theme.dart';
import '../ui/tournament_widgets.dart';
import 'match_room_view.dart';
import 'team_view.dart';

/// Arguments: `{'id': String, 'invite_code': String?}` or a [Tournament].
class TournamentDetailView extends StatefulWidget {
  const TournamentDetailView({super.key});

  @override
  State<TournamentDetailView> createState() => _TournamentDetailViewState();
}

class _TournamentDetailViewState extends State<TournamentDetailView> {
  final _api = TournamentApi();
  late final String _id;
  String? _inviteCode;

  Tournament? _t;
  MyTournamentState? _me;
  bool _signedIn = false;
  List<Team> _teams = const [];
  List<MatchRow> _matches = const [];
  List<LeaderboardRow> _board = const [];
  List<Announcement> _news = const [];
  HostProfile? _host;
  bool _loading = true;
  Object? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final a = Get.arguments;
    if (a is Tournament) {
      _id = a.id;
      _t = a;
    } else {
      final m = jsonMap(a);
      _id = (m['id'] ?? Get.parameters['id'] ?? '').toString();
      _inviteCode = jsonStr(m['invite_code']);
    }
    _load();
  }

  Future<void> _load({bool quiet = false}) async {
    if (!quiet) {
      setState(() {
        _loading = _t == null;
        _error = null;
      });
    }
    try {
      _signedIn = await _api.isSignedIn;
      Tournament t;
      try {
        t = await _api.tournament(_id, inviteCode: _inviteCode);
      } on TournamentApiException catch (e) {
        // Private tournaments answer 400/403 until the invite code is given.
        if (_inviteCode == null && (e.status == 403 || e.status == 400)) {
          final code = await promptText(
            'Private tournament',
            hint: 'Enter the invite code',
            confirm: 'Open',
          );
          if (code == null) rethrow;
          _inviteCode = code;
          t = await _api.tournament(_id, inviteCode: code);
        } else {
          rethrow;
        }
      }
      MyTournamentState? me;
      if (_signedIn) {
        try {
          me = await _api.me(_id, inviteCode: _inviteCode);
        } catch (_) {}
      }
      final participant =
          me?.registration?.isConfirmed == true || me?.team != null;
      final results = await Future.wait<dynamic>([
        _api
            .publicTeams(_id, inviteCode: _inviteCode)
            .catchError((_) => <Team>[]),
        _api
            .matches(_id, inviteCode: _inviteCode)
            .catchError((_) => <MatchRow>[]),
        _api
            .leaderboard(_id, inviteCode: _inviteCode)
            .catchError((_) => <LeaderboardRow>[]),
        participant
            ? _api.announcements(_id).catchError((_) => <Announcement>[])
            : Future.value(<Announcement>[]),
        t.hostUserId == null
            ? Future.value(null)
            : _api
                  .hostProfile(t.hostUserId!)
                  .then<HostProfile?>((h) => h)
                  .catchError((_) => null),
      ]);
      if (!mounted) return;
      setState(() {
        _t = t;
        _me = me;
        _teams = results[0] as List<Team>;
        _matches = results[1] as List<MatchRow>;
        _board = results[2] as List<LeaderboardRow>;
        _news = results[3] as List<Announcement>;
        _host = results[4] as HostProfile?;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      toastError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
      await _load(quiet: true);
    }
  }

  Map<String, String> get _teamNames => {
    for (final t in _teams) t.id: t.name,
    if (_me?.team != null) _me!.team!.id: _me!.team!.name,
  };

  // ------------------------------------------------------------------ actions

  Future<void> _join() => _run(() async {
    final t = _t!;
    if (!_signedIn) {
      throw const TournamentApiException('Please sign in to join tournaments.');
    }
    if (t.requiresInviteCode && _inviteCode == null) {
      _inviteCode = await promptText(
        'Invite code',
        hint: 'Code from the host',
        confirm: 'Join',
      );
      if (_inviteCode == null) return;
    }
    if (!t.isFree &&
        !await confirmAction(
          'Join ${t.title}',
          'Entry fee is ${fee(t)}. Your spot is confirmed after payment.',
          confirm: 'Pay ${fee(t)}',
        )) {
      return;
    }
    final reg = await _api.register(t.id, inviteCode: _inviteCode);
    if (reg.isPendingPayment) {
      await _payFor(reg);
    } else {
      toast('You are in! ${t.isSolo ? '' : 'Now create your team.'}');
      if (!t.isSolo) await _load(quiet: true).then((_) => _openTeam());
    }
  });

  Future<void> _continuePayment() => _run(() async {
    final reg = _me?.registration;
    if (reg == null) return;
    await _payFor(reg);
  });

  Future<void> _payFor(Registration reg) async {
    final outcome = await TournamentPayment().pay(_t!, reg);
    switch (outcome) {
      case PaymentOutcome.confirmed:
        toast('Payment received. Your entry is confirmed.');
      case PaymentOutcome.processing:
        toast('Payment is being confirmed. This can take a minute.');
      case PaymentOutcome.rejected:
        toast(
          "We couldn't confirm this payment. If you were charged, it will be refunded.",
          error: true,
        );
      case PaymentOutcome.cancelled:
        toast(
          'Payment not completed. You can finish it from this page.',
          error: true,
        );
    }
  }

  Future<void> _checkIn() => _run(() async {
    await _api.checkIn(_id);
    toast('Checked in. Good luck!');
  });

  Future<void> _cancelEntry() async {
    final paid = _me?.registration?.paymentStatus == 'paid';
    if (!await confirmAction(
      'Leave tournament?',
      paid
          ? 'Your entry is cancelled and the fee is refunded. Refunds can take a few days.'
          : 'Your entry will be cancelled.',
      confirm: 'Leave',
      destructive: true,
    )) {
      return;
    }
    await _run(() async {
      await _api.cancelMyRegistration(_id);
      toast(
        paid ? 'Entry cancelled. Refund is processing.' : 'Entry cancelled.',
      );
    });
  }

  Future<void> _respond(TeamInvitation inv, bool accept) => _run(() async {
    await _api.respondInvitation(inv.tournamentId, inv.teamId, accept: accept);
    toast(accept ? 'You joined ${inv.teamName}.' : 'Invitation declined.');
  });

  Future<void> _openTeam() async {
    await Get.to(() => TeamView(tournament: _t!, me: _me));
    await _load(quiet: true);
  }

  Future<void> _openMatch(MatchRow m) async {
    await Get.to(
      () => MatchRoomView(tournament: _t!, match: m, teamNames: _teamNames),
    );
    await _load(quiet: true);
  }

  Future<void> _review() async {
    final ratings = await Get.dialog<Map<String, int>>(const _ReviewDialog());
    if (ratings == null) return;
    final comment = ratings.remove('_comment_present') == 1
        ? await promptText(
            'Add a comment',
            multiline: true,
            required: false,
            confirm: 'Submit',
          )
        : null;
    await _run(() async {
      await _api.review(
        _id,
        ratings,
        comment: (comment ?? '').isEmpty ? null : comment,
      );
      toast('Thanks for rating the organizer.');
    });
  }

  void _share() => shareTournament(_t!, context);

  // ----------------------------------------------------------------------- UI

  @override
  Widget build(BuildContext context) {
    final t = _t;
    if (t == null) {
      return Scaffold(
        backgroundColor: CT.bg,
        appBar: tAppBar('Tournament'),
        body: Center(
          child: _loading
              ? const TLoading()
              : TMessage.error(_error ?? 'Not found', _load),
        ),
      );
    }
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: CT.bg,
        bottomNavigationBar: _bottomBar(t),
        body: NestedScrollView(
          headerSliverBuilder: (_, _) => [
            SliverAppBar(
              pinned: true,
              expandedHeight: 210,
              backgroundColor: CT.bg,
              foregroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              actions: [
                IconButton(
                  onPressed: _share,
                  icon: const Icon(Icons.ios_share_rounded),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    TBanner(t.bannerUrl),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.black38, Colors.transparent, CT.bg],
                          stops: [0, 0.45, 1],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(child: _hero(t)),
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabsHeader(
                tTabs(const ['Overview', 'Matches', 'Standings', 'Teams']),
              ),
            ),
          ],
          body: RefreshIndicator(
            color: CT.primary,
            onRefresh: () => _load(quiet: true),
            child: TabBarView(
              children: [
                _overviewTab(t),
                _matchesTab(),
                _standingsTab(),
                _teamsTab(t),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _hero(Tournament t) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            TPill(t.status.label, color: statusColor(t.status)),
            if (t.isPrivate)
              const TPill(
                'Private',
                color: CT.verifiedBlue,
                icon: Icons.lock_rounded,
              ),
            if (_host?.verified == true)
              const TPill(
                'Verified host',
                color: CT.verifiedBlue,
                icon: Icons.verified_rounded,
              ),
          ],
        ),
        const SizedBox(height: 10),
        Text(t.title, style: CT.display(24)),
        const SizedBox(height: 4),
        Text(
          [
            t.game,
            t.modeLabel,
            t.formatLabel,
            if (t.platform != null) t.platform!,
          ].where((e) => e.isNotEmpty).join(' · '),
          style: CT.body(13),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            _metric(
              'Prize pool',
              t.prizePool > 0 ? money(t.prizePool, t.currency) : '—',
            ),
            _metric('Entry', fee(t)),
            _metric('Slots', '${t.registeredCount}/${t.maxPlayers}'),
            _metric('Starts', fmtDate(t.startAt)),
          ],
        ),
        _entryPanel(t),
      ],
    ),
  );

  Widget _metric(String label, String value) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: CT.headline(15),
        ),
        const SizedBox(height: 2),
        Text(label, style: CT.body(11.5, color: CT.muted)),
      ],
    ),
  );

  /// The participant's current state: registration, team, check-in, match.
  Widget _entryPanel(Tournament t) {
    final me = _me;
    final invites =
        me?.invitations.where((i) => i.canRespond).toList() ?? const [];
    final reg = me?.registration;
    final team = me?.team;
    if (me == null || (reg == null && team == null && invites.isEmpty)) {
      return const SizedBox(height: 4);
    }
    final rows = <Widget>[];
    if (reg != null) {
      rows.add(
        _stepRow(
          Icons.confirmation_number_rounded,
          'Entry',
          reg.statusLabel,
          stateColor(reg.status),
        ),
      );
    }
    if (!t.isSolo) {
      rows.add(
        team == null
            ? _stepRow(
                Icons.groups_rounded,
                'Team',
                'Not created yet',
                CT.primary,
                action: reg?.isActive == true ? ('Create', _openTeam) : null,
              )
            : _stepRow(
                Icons.groups_rounded,
                team.name,
                '${humanize(team.status)} · ${team.members.where((m) => m.accepted).length}/${t.teamSize} players',
                stateColor(team.status),
                action: ('View', _openTeam),
              ),
      );
    }
    final checkedIn = (team?.checkedInAt ?? reg?.checkedInAt) != null;
    if (reg?.isConfirmed == true || team != null) {
      rows.add(
        _stepRow(
          Icons.how_to_reg_rounded,
          'Check-in',
          checkedIn
              ? 'Checked in'
              : me.canCheckIn
              ? 'Open now'
              : t.checkInStartAt != null
              ? 'Opens ${fmtDateTime(t.checkInStartAt)}'
              : 'Opens after registration closes',
          checkedIn ? CT.success : CT.onSurfaceVariant,
        ),
      );
    }
    final match =
        me.currentMatch ?? (me.matches.isEmpty ? null : me.matches.first);
    if (match != null) {
      rows.add(
        _stepRow(
          Icons.sports_esports_rounded,
          'Your match',
          '${match.title} · ${match.statusLabel}',
          stateColor(match.status),
          action: ('Open', () => _openMatch(match)),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        children: [
          for (final inv in invites) _inviteCard(inv),
          if (rows.isNotEmpty)
            TPanel(
              border: CT.primary.withValues(alpha: 0.4),
              padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
              child: Column(
                children: [
                  ...rows,
                  if (me.canCancel)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: _busy ? null : _cancelEntry,
                        child: Text(
                          'Leave tournament',
                          style: CT.body(13, color: CT.error),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _stepRow(
    IconData icon,
    String title,
    String value,
    Color color, {
    (String, VoidCallback)? action,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: CT.headline(14)),
              Text(value, style: CT.body(12.5, color: color)),
            ],
          ),
        ),
        if (action != null)
          TextButton(
            onPressed: _busy ? null : action.$2,
            child: Text(action.$1, style: CT.headline(13.5, color: CT.primary)),
          ),
      ],
    ),
  );

  Widget _inviteCard(TeamInvitation inv) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TPanel(
      border: CT.verifiedBlue.withValues(alpha: 0.6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Invited to ${inv.teamName}', style: CT.headline(15)),
          const SizedBox(height: 4),
          Text(
            'Join as ${inv.role}. Accepting adds you to the roster.',
            style: CT.body(13),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TButton.secondary(
                  'Decline',
                  onTap: () => _respond(inv, false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TButton(
                  'Accept',
                  busy: _busy,
                  onTap: () => _respond(inv, true),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget? _bottomBar(Tournament t) {
    final me = _me;
    String? label;
    VoidCallback? onTap;
    IconData? icon;
    if (me?.canManage == true || t.canManage) {
      label = 'Manage tournament';
      icon = Icons.tune_rounded;
      onTap = () async {
        await Get.toNamed(AppRoutes.MANAGE_TOURNAMENT, arguments: {'id': t.id});
        _load(quiet: true);
      };
    } else if (me != null && me.canPlay && me.currentMatch != null) {
      label = 'Open match room';
      icon = Icons.sports_esports_rounded;
      onTap = () => _openMatch(me.currentMatch!);
    } else if (me?.canCheckIn == true) {
      label = 'Check in now';
      icon = Icons.how_to_reg_rounded;
      onTap = _checkIn;
    } else if (me?.canContinuePayment == true) {
      label = 'Complete payment · ${fee(t)}';
      icon = Icons.payments_rounded;
      onTap = _continuePayment;
    } else if (me?.canJoin == true ||
        (me == null && t.status == TStatus.registrationOpen && !t.isFull)) {
      label = t.isFree ? 'Join for free' : 'Join · ${fee(t)}';
      icon = Icons.bolt_rounded;
      onTap = _join;
    } else if (!t.isSolo &&
        me?.registration?.isActive == true &&
        me?.team == null) {
      label = 'Create your team';
      icon = Icons.group_add_rounded;
      onTap = _openTeam;
    } else if (me != null && me.canViewMatch && me.matches.isNotEmpty) {
      label = 'View my match';
      icon = Icons.sports_esports_rounded;
      onTap = () => _openMatch(me.currentMatch ?? me.matches.first);
    } else if (t.status == TStatus.completed &&
        (me?.registration?.isConfirmed == true || me?.team != null)) {
      label = 'Rate the organizer';
      icon = Icons.star_rounded;
      onTap = _review;
    }
    final hint = label != null
        ? null
        : switch (t.status) {
            TStatus.registrationOpen when t.isFull => 'This tournament is full',
            TStatus.published =>
              'Registration opens ${fmtDateTime(t.registrationStartAt)}',
            TStatus.registrationOpen
                when me?.registration?.isConfirmed == true =>
              "You're in. See you on game day",
            TStatus.registrationClosed => 'Registration closed',
            TStatus.live => 'Tournament is live',
            TStatus.completed => 'Tournament completed',
            TStatus.cancelled => 'Tournament cancelled',
            _ => null,
          };
    if (label == null && hint == null) return null;
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        decoration: const BoxDecoration(
          color: CT.surfaceLow,
          border: Border(top: BorderSide(color: CT.hairline)),
        ),
        child: label != null
            ? TButton(label, icon: icon, busy: _busy, onTap: onTap)
            : SizedBox(
                height: 50,
                child: Center(
                  child: Text(
                    hint!,
                    style: CT.headline(14, color: CT.onSurfaceVariant),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _tabList(List<Widget> children) => ListView(
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
    children: children,
  );

  Widget _overviewTab(Tournament t) {
    final room = t.roomDetailsData;
    final join = jsonMap(room['join']);
    return _tabList([
      if (_news.isNotEmpty) ...[
        const TSectionTitle('Announcements'),
        for (final a in _news.take(3))
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(a.title, style: CT.headline(14))),
                      Text(
                        fmtDateTime(a.publishedAt),
                        style: CT.body(11, color: CT.muted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(a.message, style: CT.body(13)),
                ],
              ),
            ),
          ),
      ],
      if (t.roomDetails != null || join.isNotEmpty) ...[
        const TSectionTitle('Room details'),
        TPanel(
          border: CT.success.withValues(alpha: 0.5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final e in {
                'Lobby ID': join['lobby_id'],
                'Password': join['access_code'],
                'Server': join['server_region'],
                for (final f in jsonList(room['custom_fields']))
                  '${f['label']}': f['value'],
              }.entries.where((e) => jsonStr(e.value) != null))
                _copyRow(e.key, e.value.toString()),
              if (t.roomDetails != null)
                Text(t.roomDetails!, style: CT.body(13, color: CT.onSurface)),
            ],
          ),
        ),
      ],
      if (t.description != null) ...[
        const TSectionTitle('About'),
        Text(t.description!, style: CT.body(14)),
      ],
      const TSectionTitle('Prizes'),
      TPanel(
        child: Column(
          children: [
            TFact(
              Icons.emoji_events_rounded,
              'Prize pool',
              t.prizePool > 0
                  ? money(t.prizePool, t.currency)
                  : 'No cash prize',
            ),
            for (final p in t.prizeDistribution) ...[
              const SizedBox(height: 10),
              TFact(
                Icons.military_tech_rounded,
                _rankLabel(p.rank),
                t.prizePool > 0
                    ? money(
                        p.amount ?? t.prizePool * p.percent / 100,
                        t.currency,
                      )
                    : '${p.percent}%',
              ),
            ],
            if (!t.isSolo) ...[
              const SizedBox(height: 10),
              Text(
                'Team prizes go to the captain\'s Hash wallet.',
                style: CT.body(12, color: CT.muted),
              ),
            ],
          ],
        ),
      ),
      const TSectionTitle('Schedule'),
      TPanel(
        child: Column(
          children: [
            for (final row in [
              ('Registration opens', t.registrationStartAt),
              ('Registration closes', t.registrationEndAt),
              ('Roster lock', t.rosterLockAt),
              ('Check-in opens', t.checkInStartAt),
              ('Check-in closes', t.checkInEndAt),
              ('Tournament starts', t.startAt),
              ('Tournament ends', t.endAt),
            ].where((r) => r.$2 != null))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: TFact(
                  Icons.schedule_rounded,
                  row.$1,
                  fmtDateTime(row.$2),
                ),
              ),
          ],
        ),
      ),
      const TSectionTitle('Format'),
      TPanel(
        child: Column(
          children: [
            for (final row in [
              (Icons.videogame_asset_rounded, 'Game', t.game),
              (Icons.account_tree_rounded, 'Format', t.formatLabel),
              (
                Icons.groups_rounded,
                'Team',
                t.isSolo
                    ? 'Solo'
                    : '${t.teamSize} players${t.substituteLimit > 0 ? ' + ${t.substituteLimit} subs' : ''}',
              ),
              if (t.gameMode != null) (Icons.tune_rounded, 'Mode', t.gameMode!),
              if (t.region != null) (Icons.public_rounded, 'Region', t.region!),
              if (t.minimumAge != null)
                (Icons.cake_rounded, 'Minimum age', '${t.minimumAge}+'),
              if (t.matchDurationMinutes != null)
                (
                  Icons.timer_rounded,
                  'Match length',
                  '${t.matchDurationMinutes} min',
                ),
            ])
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: TFact(row.$1, row.$2, row.$3),
              ),
          ],
        ),
      ),
      if (t.rules != null) ...[
        const TSectionTitle('Rules'),
        Text(t.rules!, style: CT.body(13.5)),
      ],
      if (t.discordLink != null || t.whatsappLink != null) ...[
        const TSectionTitle('Community'),
        Row(
          children: [
            if (t.discordLink != null)
              Expanded(
                child: TButton.secondary(
                  'Discord',
                  icon: Icons.forum_rounded,
                  onTap: () => openLink(t.discordLink!),
                ),
              ),
            if (t.discordLink != null && t.whatsappLink != null)
              const SizedBox(width: 10),
            if (t.whatsappLink != null)
              Expanded(
                child: TButton.secondary(
                  'WhatsApp',
                  icon: Icons.chat_rounded,
                  onTap: () => openLink(t.whatsappLink!),
                ),
              ),
          ],
        ),
      ],
      if (_host != null) ...[
        const TSectionTitle('Organizer'),
        TPanel(
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: CT.surfaceHigh,
                child: Icon(Icons.shield_rounded, color: CT.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.organizationName ?? _host!.name ?? 'Community host',
                      style: CT.headline(14),
                    ),
                    Text(
                      '${_host!.completed}/${_host!.hosted} completed'
                      '${_host!.reviews > 0 ? ' · ★ ${_host!.rating.toStringAsFixed(1)} (${_host!.reviews})' : ''}',
                      style: CT.body(12.5),
                    ),
                  ],
                ),
              ),
              if (_host!.verified)
                const Icon(Icons.verified_rounded, color: CT.verifiedBlue),
            ],
          ),
        ),
      ],
    ]);
  }

  Widget _copyRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Expanded(child: Text(label, style: CT.body(13))),
        Text(value, style: CT.headline(14)),
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.copy_rounded, size: 16, color: CT.primary),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: value));
            toast('$label copied');
          },
        ),
      ],
    ),
  );

  Widget _matchesTab() {
    if (_matches.isEmpty) {
      return _tabList(const [
        TMessage(
          icon: Icons.account_tree_outlined,
          title: 'No matches yet',
          subtitle: 'The bracket appears once the host generates it.',
        ),
      ]);
    }
    final mine = {for (final m in _me?.matches ?? const <MatchRow>[]) m.id: m};
    final byRound = <String, List<MatchRow>>{};
    for (final m in _matches) {
      byRound
          .putIfAbsent(
            m.round == null ? (m.stage ?? 'Matches') : 'Round ${m.round}',
            () => [],
          )
          .add(m);
    }
    return _tabList([
      for (final e in byRound.entries) ...[
        TSectionTitle(humanize(e.key)),
        for (final m in e.value)
          MatchTile(
            match: mine[m.id] ?? m,
            names: _teamNames,
            highlight: mine.containsKey(m.id),
            onTap: mine.containsKey(m.id)
                ? () => _openMatch(mine[m.id]!)
                : null,
          ),
      ],
    ]);
  }

  Widget _standingsTab() {
    if (_board.isEmpty) {
      return _tabList(const [
        TMessage(
          icon: Icons.leaderboard_outlined,
          title: 'Standings not available yet',
          subtitle: 'Results appear here as matches finish.',
        ),
      ]);
    }
    return _tabList([
      const SizedBox(height: 8),
      for (final (i, r) in _board.indexed)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: CT.card(),
          child: Row(
            children: [
              SizedBox(
                width: 34,
                child: Text(
                  '#${r.rank ?? i + 1}',
                  style: CT.headline(
                    14,
                    color: (r.rank ?? i + 1) <= 3
                        ? CT.primary
                        : CT.onSurfaceVariant,
                  ),
                ),
              ),
              Expanded(child: Text(r.name, style: CT.headline(14))),
              if (r.wins != null)
                Text('${r.wins}W ${r.losses ?? 0}L  ', style: CT.body(12.5)),
              if (r.kills != null) Text('${r.kills} K  ', style: CT.body(12.5)),
              Text('${r.points} pts', style: CT.headline(13.5)),
            ],
          ),
        ),
    ]);
  }

  Widget _teamsTab(Tournament t) {
    if (_teams.isEmpty) {
      return _tabList([
        TMessage(
          icon: Icons.groups_outlined,
          title: t.isSolo
              ? '${t.registeredCount} players registered'
              : 'No approved teams yet',
          subtitle: t.isSolo
              ? null
              : 'Teams appear once the host approves them.',
        ),
      ]);
    }
    return _tabList([
      const SizedBox(height: 8),
      for (final team in _teams)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: CT.card(),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: CT.surfaceHigh,
                child: Text(
                  team.name.characters.first.toUpperCase(),
                  style: CT.headline(14, color: CT.primary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(team.name, style: CT.headline(14))),
              if (team.seed != null)
                TPill('Seed ${team.seed}', color: CT.onSurfaceVariant),
              if (team.checkedInAt != null) ...[
                const SizedBox(width: 6),
                const Icon(
                  Icons.how_to_reg_rounded,
                  size: 18,
                  color: CT.success,
                ),
              ],
            ],
          ),
        ),
    ]);
  }
}

String _rankLabel(int r) => switch (r) {
  1 => '1st place',
  2 => '2nd place',
  3 => '3rd place',
  _ => '${r}th place',
};

/// One match row: teams, score and status.
class MatchTile extends StatelessWidget {
  final MatchRow match;
  final Map<String, String> names;
  final bool highlight;
  final VoidCallback? onTap;
  const MatchTile({
    super.key,
    required this.match,
    required this.names,
    this.highlight = false,
    this.onTap,
  });

  String _name(String? id, String side) =>
      match.inlineName(side) ?? (id == null ? 'TBD' : names[id] ?? 'Team');

  @override
  Widget build(BuildContext context) {
    final m = match;
    Widget side(String? id, int? score, String s) {
      final won = id != null && id == m.winnerTeamId;
      return Row(
        children: [
          Expanded(
            child: Text(
              _name(id, s),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CT.headline(14, color: won ? CT.primary : CT.onSurface),
            ),
          ),
          if (score != null)
            Text(
              '$score',
              style: CT.headline(15, color: won ? CT.primary : CT.onSurface),
            ),
        ],
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: CT.card(
          borderColor: highlight
              ? CT.primary.withValues(alpha: 0.6)
              : CT.outline,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(m.title, style: CT.body(12, color: CT.muted)),
                ),
                TPill(m.statusLabel, color: stateColor(m.status)),
              ],
            ),
            const SizedBox(height: 10),
            if (m.isMultiTeam)
              Text(
                '${m.participantIds.length} teams · ${fmtDateTime(m.scheduledAt)}',
                style: CT.headline(14),
              )
            else ...[
              side(m.teamAId, m.scoreA, 'a'),
              const SizedBox(height: 6),
              side(m.teamBId, m.scoreB, 'b'),
            ],
            if (!m.isFinished && m.scheduledAt != null && !m.isMultiTeam) ...[
              const SizedBox(height: 8),
              Text(
                fmtDateTime(m.scheduledAt),
                style: CT.body(12, color: CT.muted),
              ),
            ],
            if (highlight) ...[
              const SizedBox(height: 8),
              Text(
                'Your match · tap to open',
                style: CT.body(12, color: CT.primary, w: FontWeight.w600),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TabsHeader extends SliverPersistentHeaderDelegate {
  final TabBar tabs;
  _TabsHeader(this.tabs);
  @override
  double get minExtent => tabs.preferredSize.height;
  @override
  double get maxExtent => tabs.preferredSize.height;
  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => Container(color: CT.bg, child: tabs);
  @override
  bool shouldRebuild(covariant _TabsHeader old) => false;
}

/// Five 1–5 ratings, as the review endpoint requires.
class _ReviewDialog extends StatefulWidget {
  const _ReviewDialog();
  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  final _r = {
    'management_rating': 5,
    'communication_rating': 5,
    'fairness_rating': 5,
    'scheduling_rating': 5,
    'dispute_handling_rating': 5,
  };
  bool _comment = false;

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: CT.surfaceHigh,
    title: Text('Rate the organizer', style: CT.headline(17)),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final k in _r.keys)
          Row(
            children: [
              Expanded(
                child: Text(
                  humanize(k.replaceAll('_rating', '')),
                  style: CT.body(13),
                ),
              ),
              for (var i = 1; i <= 5; i++)
                GestureDetector(
                  onTap: () => setState(() => _r[k] = i),
                  child: Icon(
                    i <= _r[k]!
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: CT.primary,
                    size: 22,
                  ),
                ),
            ],
          ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: _comment,
          activeColor: CT.primary,
          onChanged: (v) => setState(() => _comment = v ?? false),
          title: Text('Add a comment', style: CT.body(13)),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Get.back(),
        child: Text('Cancel', style: CT.body(14)),
      ),
      TextButton(
        onPressed: () =>
            Get.back(result: {..._r, if (_comment) '_comment_present': 1}),
        child: Text('Submit', style: CT.headline(14, color: CT.primary)),
      ),
    ],
  );
}
