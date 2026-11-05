import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hash/app/data/services/user_controller.dart';
import 'package:hash/app/modules/chat/models/chat_user_model.dart';
import 'package:hash/app/modules/chat/services/chat_service.dart';

import '../data/tournament_api.dart';
import '../data/tournament_models.dart';
import '../ui/tournament_theme.dart';
import '../ui/tournament_widgets.dart';

/// Create a team, invite players, manage the roster before lock.
class TeamView extends StatefulWidget {
  final Tournament tournament;
  final MyTournamentState? me;
  const TeamView({super.key, required this.tournament, this.me});

  @override
  State<TeamView> createState() => _TeamViewState();
}

class _TeamViewState extends State<TeamView> {
  final _api = TournamentApi();
  late MyTournamentState? _me = widget.me;
  int? _myId;
  bool _busy = false;
  final _name = TextEditingController();
  final _gameId = TextEditingController();

  Tournament get t => widget.tournament;
  Team? get _team => _me?.team;
  bool get _isCaptain =>
      _team != null &&
      (_team!.captainUserId == _myId ||
          _team!.members.any((m) => m.isCaptain && m.userId == _myId));
  bool get _locked => _team?.rosterLockedAt != null;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<UserController>()) {
      _gameId.text = Get.find<UserController>().user.value.gameUserName ?? '';
    }
    _resolveMe();
  }

  @override
  void dispose() {
    _name.dispose();
    _gameId.dispose();
    super.dispose();
  }

  Future<void> _resolveMe() async {
    _myId = _me?.registration?.userId;
    if (_myId == null && Get.isRegistered<ChatService>()) {
      _myId = await Get.find<ChatService>().resolveCurrentBackendUserId();
    }
    if (mounted) setState(() {});
  }

  Future<void> _reload() async {
    try {
      final me = await _api.me(t.id);
      if (mounted) setState(() => _me = me);
    } catch (e) {
      toastError(e);
    }
  }

  Future<void> _run(Future<void> Function() f) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await f();
    } catch (e) {
      toastError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
      await _reload();
    }
  }

  Future<void> _create() => _run(() async {
    final name = _name.text.trim();
    final gameId = _gameId.text.trim();
    if (name.length < 2)
      throw const TournamentApiException('Give your team a name.');
    if (gameId.isEmpty)
      throw const TournamentApiException('Enter your in-game ID.');
    if (_myId == null)
      throw const TournamentApiException('Please sign in again.');
    await _api.createTeam(
      t.id,
      name: name,
      members: [
        {'user_id': _myId, 'game_id': gameId, 'role': 'captain'},
      ],
    );
    toast('Team created. Invite your players next.');
  });

  Future<void> _invite({required bool substitute}) async {
    final user = await Get.to<ChatUserModel>(() => const _PlayerPicker());
    if (user == null) return;
    if (user.backendUserId == null) {
      toast(
        '${user.displayName} does not have a Hash player account yet.',
        error: true,
      );
      return;
    }
    final gameId = await promptText(
      '${user.displayName}\'s in-game ID',
      hint: 'Their ${t.game} username or ID',
      initial: user.username,
      confirm: 'Invite',
    );
    if (gameId == null) return;
    await _run(() async {
      await _api.inviteMember(
        t.id,
        _team!.id,
        userId: user.backendUserId!,
        gameId: gameId,
        role: substitute ? 'substitute' : 'player',
      );
      toast('Invite sent to ${user.displayName}. They need to accept it.');
    });
  }

  Future<void> _remove(TeamMember m) async {
    if (!await confirmAction(
      'Remove ${m.name}?',
      'Changing the roster sends the team back to pending until everyone accepts again.',
      confirm: 'Remove',
      destructive: true,
    )) {
      return;
    }
    await _run(() async {
      await _api.replaceRoster(
        t.id,
        _team!.id,
        members: _team!.members
            .where((x) => x.userId != m.userId)
            .map((x) => x.toRosterJson())
            .toList(),
      );
      toast('${m.name} removed.');
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: CT.bg,
    appBar: tAppBar(_team?.name ?? 'Your team'),
    body: RefreshIndicator(
      color: CT.primary,
      onRefresh: _reload,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: _team == null ? _createForm() : _roster(_team!),
      ),
    ),
  );

  List<Widget> _createForm() {
    final reg = _me?.registration;
    return [
      Text('Create your team', style: CT.display(22)),
      const SizedBox(height: 6),
      Text(
        '${t.title} needs ${t.teamSize} players per team'
        '${t.substituteLimit > 0 ? ' plus up to ${t.substituteLimit} substitutes' : ''}. '
        'You will be the captain.',
        style: CT.body(14),
      ),
      if (reg == null || !reg.isActive) ...[
        const SizedBox(height: 16),
        TPanel(
          border: CT.primary,
          child: Text(
            'Join the tournament first, then create your team.',
            style: CT.body(13.5),
          ),
        ),
      ] else ...[
        const SizedBox(height: 22),
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.words,
          style: CT.body(15, color: CT.onSurface),
          decoration: tInput('Team Phoenix', label: 'Team name'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _gameId,
          style: CT.body(15, color: CT.onSurface),
          decoration: tInput('Your ${t.game} ID', label: 'Your in-game ID'),
        ),
        const SizedBox(height: 22),
        TButton(
          'Create team',
          icon: Icons.group_add_rounded,
          busy: _busy,
          onTap: _create,
        ),
      ],
    ];
  }

  List<Widget> _roster(Team team) {
    final players = team.members.where((m) => m.role != 'substitute').toList();
    final subs = team.members.where((m) => m.role == 'substitute').toList();
    final openPlayers = (t.teamSize - players.length).clamp(0, 99);
    final openSubs = (t.substituteLimit - subs.length).clamp(0, 99);
    final editable =
        _isCaptain &&
        !_locked &&
        !t.status.isTerminal &&
        t.status != TStatus.live;
    return [
      TPanel(
        border: stateColor(team.status).withValues(alpha: 0.6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(team.name, style: CT.display(20))),
                TPill(humanize(team.status), color: stateColor(team.status)),
              ],
            ),
            const SizedBox(height: 8),
            Text(_statusHint(team, players), style: CT.body(13)),
            if (team.reason != null) ...[
              const SizedBox(height: 8),
              Text(
                'Host note: ${team.reason}',
                style: CT.body(13, color: CT.error),
              ),
            ],
            if (_locked) ...[
              const SizedBox(height: 8),
              const TPill(
                'Roster locked',
                color: CT.muted,
                icon: Icons.lock_rounded,
              ),
            ],
          ],
        ),
      ),
      TSectionTitle('Players ${players.length}/${t.teamSize}'),
      for (final m in players) _memberTile(m, editable),
      if (editable && openPlayers > 0)
        _addTile(
          'Invite a player ($openPlayers open)',
          () => _invite(substitute: false),
        ),
      if (t.substituteLimit > 0) ...[
        TSectionTitle('Substitutes ${subs.length}/${t.substituteLimit}'),
        for (final m in subs) _memberTile(m, editable),
        if (editable && openSubs > 0)
          _addTile('Add a substitute', () => _invite(substitute: true)),
      ],
    ];
  }

  String _statusHint(Team team, List<TeamMember> players) {
    if (team.isApproved)
      return 'Approved. You are in the bracket once it is generated.';
    final pending = team.members.where((m) => !m.accepted).length;
    if (players.length < t.teamSize) {
      return 'Invite ${t.teamSize - players.length} more player(s). The host approves full teams.';
    }
    if (pending > 0)
      return 'Waiting for $pending player(s) to accept their invite.';
    if (_me?.registration?.isPendingPayment == true)
      return 'Complete the entry payment to get approved.';
    return 'Roster complete. Waiting for host approval.';
  }

  Widget _memberTile(TeamMember m, bool editable) => Container(
    padding: const EdgeInsets.symmetric(vertical: 10),
    decoration: CT.card(),
    child: Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: CT.surfaceHigh,
          child: Icon(
            m.isCaptain
                ? Icons.workspace_premium_rounded
                : Icons.person_rounded,
            size: 18,
            color: m.isCaptain ? CT.primary : CT.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                m.name + (m.userId == _myId ? ' (you)' : ''),
                style: CT.headline(14),
              ),
              Text(
                [
                  humanize(m.role),
                  if (m.gameId.isNotEmpty) m.gameId,
                ].join(' · '),
                style: CT.body(12),
              ),
            ],
          ),
        ),
        TPill(
          m.accepted ? 'Accepted' : humanize(m.status),
          color: m.accepted ? CT.success : CT.primary,
        ),
        if (editable && !m.isCaptain)
          IconButton(
            onPressed: _busy ? null : () => _remove(m),
            icon: const Icon(Icons.close_rounded, color: CT.muted, size: 20),
          ),
      ],
    ),
  );

  Widget _addTile(String label, VoidCallback onTap) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: TButton.secondary(
      label,
      icon: Icons.person_add_alt_1_rounded,
      busy: _busy,
      onTap: onTap,
    ),
  );
}

/// Search Hash players by name or username.
class _PlayerPicker extends StatefulWidget {
  const _PlayerPicker();
  @override
  State<_PlayerPicker> createState() => _PlayerPickerState();
}

class _PlayerPickerState extends State<_PlayerPicker> {
  final _q = TextEditingController();
  Timer? _debounce;
  List<ChatUserModel> _users = const [];
  bool _loading = false;
  int _req = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _q.dispose();
    super.dispose();
  }

  void _search(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      final req = ++_req;
      if (q.trim().length < 2) return setState(() => _users = const []);
      setState(() => _loading = true);
      try {
        final users = await Get.find<ChatService>().searchUsers(q);
        if (req == _req && mounted) setState(() => _users = users);
      } catch (_) {
        if (req == _req && mounted) setState(() => _users = const []);
      } finally {
        if (req == _req && mounted) setState(() => _loading = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: CT.bg,
    appBar: tAppBar('Invite a player'),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _q,
            autofocus: true,
            onChanged: _search,
            style: CT.body(15, color: CT.onSurface),
            decoration: tInput('Search by name or username').copyWith(
              prefixIcon: const Icon(Icons.search_rounded, color: CT.muted),
            ),
          ),
        ),
        if (_loading) const TLoading(),
        Expanded(
          child: ListView.builder(
            itemCount: _users.length,
            itemBuilder: (_, i) {
              final u = _users[i];
              return ListTile(
                onTap: () => Get.back(result: u),
                leading: CircleAvatar(
                  backgroundColor: CT.surfaceHigh,
                  backgroundImage: u.photoUrl.startsWith('http')
                      ? NetworkImage(u.photoUrl)
                      : null,
                  child: u.photoUrl.startsWith('http')
                      ? null
                      : const Icon(Icons.person, color: CT.muted),
                ),
                title: Text(u.displayName, style: CT.headline(14)),
                subtitle: Text(
                  u.username.isEmpty ? '' : '@${u.username}',
                  style: CT.body(12),
                ),
                trailing: const Icon(
                  Icons.add_circle_outline_rounded,
                  color: CT.primary,
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}
