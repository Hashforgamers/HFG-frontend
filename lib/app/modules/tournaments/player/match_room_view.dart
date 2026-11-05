import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hash/app/modules/chat/views/chat_room_view.dart';

import '../data/dispute_chat_auth.dart';
import '../data/tournament_api.dart';
import '../data/tournament_models.dart';
import '../data/tournament_uploads.dart';
import '../ui/tournament_theme.dart';
import '../ui/tournament_widgets.dart';

/// A participant's view of one match: lobby, result agreement, disputes.
class MatchRoomView extends StatefulWidget {
  final Tournament tournament;
  final MatchRow match;
  final Map<String, String> teamNames;
  const MatchRoomView({
    super.key,
    required this.tournament,
    required this.match,
    this.teamNames = const {},
  });

  @override
  State<MatchRoomView> createState() => _MatchRoomViewState();
}

class _MatchRoomViewState extends State<MatchRoomView> {
  final _api = TournamentApi();
  late MatchRow _m = widget.match;
  ResultState? _rs;
  MyTournamentState? _me;
  Object? _error;
  bool _busy = false;
  Timer? _poll;
  Duration _clockSkew = Duration.zero;

  String get _tid => widget.tournament.id;

  @override
  void initState() {
    super.initState();
    _load();
    // Bounded refresh while open: there is no realtime socket.
    _poll = Timer.periodic(const Duration(seconds: 20), (_) => _load());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait<dynamic>([
        _api
            .resultState(_tid, _m.id)
            .then<ResultState?>((r) => r)
            .catchError((_) => null),
        _api.myMatches(_tid).catchError((_) => <MatchRow>[]),
        _api
            .me(_tid)
            .then<MyTournamentState?>((m) => m)
            .catchError((_) => null),
      ]);
      if (!mounted) return;
      final rs = results[0] as ResultState?;
      final mine = (results[1] as List<MatchRow>).where((x) => x.id == _m.id);
      setState(() {
        _rs = rs;
        _me = results[2] as MyTournamentState?;
        _m = rs?.match ?? (mine.isNotEmpty ? mine.first : _m);
        if (mine.isNotEmpty && !_m.hasLobby)
          _m = MatchRow({..._m.raw, 'lobby_details': mine.first.lobby});
        final st = rs?.serverTime;
        if (st != null) _clockSkew = st.difference(DateTime.now());
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
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

  String _name(String? id, String side) =>
      _m.inlineName(side) ??
      (id == null
          ? 'TBD'
          : widget.teamNames[id] ??
                (id == _me?.team?.id ? _me!.team!.name : 'Team'));

  String? get _myTeamId => _me?.team?.id ?? _rs?.viewerTeamId;
  bool get _iAmCaptain {
    final team = _me?.team;
    final myId = _me?.registration?.userId;
    return team != null &&
        myId != null &&
        (team.captainUserId == myId ||
            team.members.any((x) => x.isCaptain && x.userId == myId));
  }

  bool get _canSubmit {
    final rs = _rs;
    if (rs == null || _m.isMultiTeam || _m.isFinished) return false;
    if (rs.pendingProposal != null || rs.activeDispute != null) return false;
    if (rs.flag('can_submit_result') || rs.flag('can_submit')) return true;
    final mineSubmitted = rs.submissions.any((s) => s.teamId == _myTeamId);
    return _iAmCaptain &&
        !mineSubmitted &&
        const {'in_progress', 'awaiting_results'}.contains(_m.status);
  }

  bool get _canDispute =>
      _rs != null &&
      !_m.isFinished &&
      _rs!.activeDispute == null &&
      _myTeamId != null;

  Future<void> _submitResult() async {
    final r = await _resultSheet(
      title: 'Submit result',
      requireEvidence:
          widget.tournament.rulesConfig['evidence_required'] == true,
    );
    if (r == null) return;
    await _run(
      () => _api.submitCaptainResult(
        _tid,
        _m.id,
        winnerTeamId: r.winner,
        scoreA: r.a,
        scoreB: r.b,
        evidenceAssetIds: r.evidence,
        notes: r.notes,
      ),
      'Result submitted. Waiting for the other captain.',
    );
  }

  Future<void> _accept(ResultProposal p) async {
    if (!await confirmAction(
      'Accept this result?',
      '${_name(_m.teamAId, 'a')} ${p.scoreA ?? '-'} : ${p.scoreB ?? '-'} ${_name(_m.teamBId, 'b')}\n'
          'Winner: ${_name(p.winnerTeamId, p.winnerTeamId == _m.teamAId ? 'a' : 'b')}',
      confirm: 'Accept',
    )) {
      return;
    }
    await _run(
      () => _api.acceptProposal(_tid, _m.id, p.id),
      'Result accepted.',
    );
  }

  Future<void> _disputeProposal(ResultProposal p) async {
    final d = await _disputeSheet(askReason: false);
    if (d == null) return;
    await _run(
      () => _api.disputeProposal(
        _tid,
        _m.id,
        p.id,
        description: d.description,
        evidenceAssetIds: d.evidence,
      ),
      'Dispute opened. A referee will review it.',
    );
  }

  Future<void> _openDispute() async {
    final d = await _disputeSheet(askReason: true);
    if (d == null) return;
    await _run(
      () => _api.openDispute(
        _tid,
        matchId: _m.id,
        reason: d.reason,
        description: d.description,
        evidenceAssetIds: d.evidence,
      ),
      'Dispute opened. A referee will review it.',
    );
  }

  Future<void> _openChat(Dispute d) async {
    try {
      final session = await DisputeChatAuth().authenticate();
      await Get.to(
        () => ChatRoomView(
          roomId: d.chatRoomId!,
          roomCollection: 'communityDisputeRooms',
          chatService: session.chatService,
        ),
      );
    } catch (e) {
      toast('Dispute chat is unavailable right now.', error: true);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: CT.bg,
    appBar: tAppBar(_m.title),
    body: RefreshIndicator(
      color: CT.primary,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          _scoreboard(),
          if (_error != null && _rs == null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                TournamentApiException.from(_error!).message,
                style: CT.body(13, color: CT.error),
              ),
            ),
          if (_m.hasLobby) ...[const TSectionTitle('Lobby'), _lobby()],
          ..._resultSection(),
          if (_m.isMultiTeam && _m.standings.isNotEmpty) ...[
            const TSectionTitle('Standings'),
            for (final s in _m.standings)
              _kv(
                '#${s['placement'] ?? '-'} ${widget.teamNames[s['team_id']?.toString()] ?? 'Team'}',
                '${s['points'] ?? '-'} pts · ${s['kills'] ?? 0} K',
              ),
          ],
          const SizedBox(height: 20),
          if (_canSubmit) ...[
            TButton(
              'Submit result',
              icon: Icons.upload_rounded,
              busy: _busy,
              onTap: _submitResult,
            ),
            const SizedBox(height: 10),
          ],
          if (_canDispute)
            TButton.secondary(
              'Report a problem',
              icon: Icons.flag_rounded,
              color: CT.error,
              onTap: _openDispute,
            ),
          if (_m.isMultiTeam && !_m.isFinished)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'The host records standings for multi-team rounds.',
                style: CT.body(12.5, color: CT.muted),
              ),
            ),
        ],
      ),
    ),
  );

  Widget _scoreboard() {
    Widget team(String? id, String side, int? score) {
      final won = id != null && id == _m.winnerTeamId;
      return Expanded(
        child: Column(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: id == _myTeamId
                  ? CT.primary.withValues(alpha: 0.2)
                  : CT.surfaceHigh,
              child: Text(
                _name(id, side).characters.first.toUpperCase(),
                style: CT.display(20, color: won ? CT.primary : CT.onSurface),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _name(id, side),
              textAlign: TextAlign.center,
              maxLines: 2,
              style: CT.headline(14),
            ),
            if (id == _myTeamId)
              Text('Your team', style: CT.body(11.5, color: CT.primary)),
            const SizedBox(height: 6),
            Text(
              score?.toString() ?? '–',
              style: CT.display(30, color: won ? CT.primary : CT.onSurface),
            ),
          ],
        ),
      );
    }

    return TPanel(
      border: stateColor(_m.status).withValues(alpha: 0.5),
      child: Column(
        children: [
          TPill(_m.statusLabel, color: stateColor(_m.status)),
          const SizedBox(height: 14),
          if (_m.isMultiTeam)
            Text(
              '${_m.participantIds.length} teams in this round',
              style: CT.headline(16),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                team(_m.teamAId, 'a', _m.scoreA),
                Padding(
                  padding: const EdgeInsets.only(top: 18),
                  child: Text('VS', style: CT.headline(14, color: CT.muted)),
                ),
                team(_m.teamBId, 'b', _m.scoreB),
              ],
            ),
          const SizedBox(height: 10),
          Text(
            _m.isFinished
                ? 'Finished'
                : _m.resultDueAt != null && _m.status == 'in_progress'
                ? 'Report the result by ${fmtDateTime(_m.resultDueAt)}'
                : 'Starts ${fmtDateTime(_m.scheduledAt)}',
            style: CT.body(12.5),
          ),
        ],
      ),
    );
  }

  Widget _lobby() => TPanel(
    border: CT.success.withValues(alpha: 0.5),
    child: Column(
      children: [
        for (final e in _m.lobby.entries.where(
          (e) =>
              jsonStr(e.value) != null && e.value is! Map && e.value is! List,
        ))
          Row(
            children: [
              Expanded(child: Text(humanize(e.key), style: CT.body(13))),
              Text('${e.value}', style: CT.headline(14)),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(
                  Icons.copy_rounded,
                  size: 16,
                  color: CT.primary,
                ),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: '${e.value}'));
                  toast('${humanize(e.key)} copied');
                },
              ),
            ],
          ),
        const SizedBox(height: 4),
        Text(
          'Keep these private. Play the match in-game, then report the result here.',
          style: CT.body(12, color: CT.muted),
        ),
      ],
    ),
  );

  List<Widget> _resultSection() {
    final rs = _rs;
    if (rs == null) return const [];
    final out = <Widget>[];
    final p = rs.pendingProposal;
    if (p != null) {
      final now = DateTime.now().add(_clockSkew);
      out.addAll([
        const TSectionTitle('Result from the host'),
        TPanel(
          border: CT.primary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_name(_m.teamAId, 'a')} ${p.scoreA ?? '-'} : ${p.scoreB ?? '-'} ${_name(_m.teamBId, 'b')}',
                style: CT.headline(16),
              ),
              const SizedBox(height: 4),
              Text(
                'Winner: ${_name(p.winnerTeamId, p.winnerTeamId == _m.teamAId ? 'a' : 'b')}',
                style: CT.body(13),
              ),
              if (p.expiresAt != null)
                Text(
                  p.expiresAt!.isAfter(now)
                      ? 'Confirms automatically in ${countdown(p.expiresAt, now: now)} unless disputed'
                      : 'Awaiting confirmation',
                  style: CT.body(12.5, color: CT.primary),
                ),
              if (p.evidenceUrls.isNotEmpty) ...[
                const SizedBox(height: 10),
                _evidence(p.evidenceUrls),
              ],
              if (rs.canAccept || rs.canDisputeProposal) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    if (rs.canDisputeProposal)
                      Expanded(
                        child: TButton.secondary(
                          'Dispute',
                          color: CT.error,
                          onTap: () => _disputeProposal(p),
                        ),
                      ),
                    if (rs.canAccept && rs.canDisputeProposal)
                      const SizedBox(width: 10),
                    if (rs.canAccept)
                      Expanded(
                        child: TButton(
                          'Accept',
                          busy: _busy,
                          onTap: () => _accept(p),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ]);
    }
    if (rs.submissions.isNotEmpty) {
      out.add(const TSectionTitle('Captain reports'));
      for (final s in rs.submissions) {
        out.add(
          _kv(
            s.teamId == _myTeamId
                ? 'Your team'
                : _name(s.teamId, s.teamId == _m.teamAId ? 'a' : 'b'),
            '${s.scoreA ?? '-'} : ${s.scoreB ?? '-'} · ${humanize(s.status)}',
          ),
        );
      }
      if (rs.submissions.length == 1 && !_m.isFinished) {
        out.add(
          Text(
            'Waiting for the other captain. Matching reports confirm the result.',
            style: CT.body(12.5, color: CT.muted),
          ),
        );
      }
    }
    final d = rs.activeDispute;
    if (d != null) {
      out.addAll([
        const TSectionTitle('Dispute'),
        TPanel(
          border: CT.error.withValues(alpha: 0.6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(d.reason, style: CT.headline(15))),
                  TPill(humanize(d.status), color: CT.error),
                ],
              ),
              if (d.description != null) ...[
                const SizedBox(height: 6),
                Text(d.description!, style: CT.body(13)),
              ],
              if (d.deadline != null)
                Text(
                  'Response due ${fmtDateTime(d.deadline)}',
                  style: CT.body(12.5, color: CT.muted),
                ),
              if (d.adminComment != null)
                Text(
                  'Referee: ${d.adminComment}',
                  style: CT.body(13, color: CT.onSurface),
                ),
              const SizedBox(height: 6),
              Text(
                'A Hash referee makes the final call. The match is on hold until then.',
                style: CT.body(12, color: CT.muted),
              ),
              if (d.chatReady) ...[
                const SizedBox(height: 12),
                TButton.secondary(
                  'Open dispute chat',
                  icon: Icons.chat_rounded,
                  onTap: () => _openChat(d),
                ),
              ],
            ],
          ),
        ),
      ]);
    }
    return out;
  }

  Widget _evidence(List<String> urls) => SizedBox(
    height: 90,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: urls.length,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (_, i) => GestureDetector(
        onTap: () => Get.dialog(
          Dialog(
            backgroundColor: Colors.black,
            child: InteractiveViewer(
              child: CachedNetworkImage(imageUrl: urls[i]),
            ),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: CachedNetworkImage(
            imageUrl: urls[i],
            width: 120,
            fit: BoxFit.cover,
            errorWidget: (_, _, _) => Container(
              width: 120,
              color: CT.surfaceHigh,
              alignment: Alignment.center,
              child: Text('Unavailable', style: CT.body(11)),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _kv(String k, String v) => Container(
    padding: const EdgeInsets.symmetric(vertical: 10),
    decoration: CT.card(),
    child: Row(
      children: [
        Expanded(
          child: Text(k, style: CT.body(13.5, color: CT.onSurface)),
        ),
        Text(v, style: CT.headline(13.5)),
      ],
    ),
  );

  Future<ResultInput?> _resultSheet({
    required String title,
    required bool requireEvidence,
  }) => Get.bottomSheet<ResultInput>(
    ResultSheet(
      title: title,
      tournamentId: _tid,
      teamA: (_m.teamAId ?? '', _name(_m.teamAId, 'a')),
      teamB: (_m.teamBId ?? '', _name(_m.teamBId, 'b')),
      requireEvidence: requireEvidence,
    ),
    isScrollControlled: true,
    backgroundColor: CT.surfaceLow,
  );

  Future<_DisputeInput?> _disputeSheet({required bool askReason}) =>
      Get.bottomSheet<_DisputeInput>(
        _DisputeSheet(tournamentId: _tid, askReason: askReason),
        isScrollControlled: true,
        backgroundColor: CT.surfaceLow,
      );
}

class ResultInput {
  final String winner;
  final int a;
  final int b;
  final List<String> evidence;
  final String? notes;
  const ResultInput(this.winner, this.a, this.b, this.evidence, this.notes);
}

/// Winner + both scores + screenshot evidence. Shared with the host flow.
class ResultSheet extends StatefulWidget {
  final String title;
  final String tournamentId;
  final (String, String) teamA;
  final (String, String) teamB;
  final bool requireEvidence;
  final bool withNotes;
  const ResultSheet({
    super.key,
    required this.title,
    required this.tournamentId,
    required this.teamA,
    required this.teamB,
    this.requireEvidence = false,
    this.withNotes = true,
  });

  @override
  State<ResultSheet> createState() => _ResultSheetState();
}

class _ResultSheetState extends State<ResultSheet> {
  String? _winner;
  final _a = TextEditingController();
  final _b = TextEditingController();
  final _notes = TextEditingController();
  final List<FileAsset> _evidence = [];
  bool _uploading = false;
  String? _error;

  Future<void> _addEvidence() async {
    setState(() => _uploading = true);
    try {
      final asset = await pickAndUploadEvidence(
        widget.tournamentId,
        'result_evidence',
      );
      if (asset != null) setState(() => _evidence.add(asset));
    } catch (e) {
      setState(() => _error = TournamentApiException.from(e).message);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _submit() {
    final a = int.tryParse(_a.text.trim());
    final b = int.tryParse(_b.text.trim());
    final err = _winner == null
        ? 'Pick the winner.'
        : (a == null || b == null || a < 0 || b < 0)
        ? 'Enter both scores.'
        : (widget.requireEvidence && _evidence.isEmpty)
        ? 'Add a screenshot of the final scoreboard.'
        : null;
    if (err != null) return setState(() => _error = err);
    Get.back(
      result: ResultInput(
        _winner!,
        a!,
        b!,
        _evidence.map((e) => e.id).toList(),
        _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      16,
      18,
      16,
      16 + MediaQuery.of(context).viewInsets.bottom,
    ),
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title, style: CT.display(20)),
          const SizedBox(height: 14),
          Text('Winner', style: CT.body(13)),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final t in [widget.teamA, widget.teamB]) ...[
                Expanded(
                  child: ChoiceChip(
                    label: SizedBox(
                      width: double.infinity,
                      child: Text(
                        t.$2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    selected: _winner == t.$1,
                    onSelected: (_) => setState(() => _winner = t.$1),
                    showCheckmark: false,
                    selectedColor: CT.primary,
                    backgroundColor: CT.surface,
                    labelStyle: CT.headline(
                      13,
                      color: _winner == t.$1 ? Colors.black : CT.onSurface,
                    ),
                  ),
                ),
                if (t == widget.teamA) const SizedBox(width: 10),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _a,
                  keyboardType: TextInputType.number,
                  style: CT.body(15, color: CT.onSurface),
                  decoration: tInput('0', label: '${widget.teamA.$2} score'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _b,
                  keyboardType: TextInputType.number,
                  style: CT.body(15, color: CT.onSurface),
                  decoration: tInput('0', label: '${widget.teamB.$2} score'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final e in _evidence)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: e.url == null
                      ? const Icon(Icons.image, color: CT.success)
                      : CachedNetworkImage(
                          imageUrl: e.url!,
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                        ),
                ),
              SizedBox(
                width: 200,
                child: TButton.secondary(
                  _evidence.isEmpty ? 'Add screenshot' : 'Add another',
                  icon: Icons.add_photo_alternate_rounded,
                  busy: _uploading,
                  onTap: _addEvidence,
                ),
              ),
            ],
          ),
          if (widget.withNotes) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _notes,
              style: CT.body(14, color: CT.onSurface),
              decoration: tInput(
                'Anything the other team should know',
                label: 'Notes (optional)',
              ),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: CT.body(13, color: CT.error)),
          ],
          const SizedBox(height: 16),
          TButton('Submit', onTap: _uploading ? null : _submit),
        ],
      ),
    ),
  );
}

class _DisputeInput {
  final String reason;
  final String description;
  final List<String> evidence;
  const _DisputeInput(this.reason, this.description, this.evidence);
}

class _DisputeSheet extends StatefulWidget {
  final String tournamentId;
  final bool askReason;
  const _DisputeSheet({required this.tournamentId, required this.askReason});
  @override
  State<_DisputeSheet> createState() => _DisputeSheetState();
}

class _DisputeSheetState extends State<_DisputeSheet> {
  static const _reasons = [
    'Incorrect score',
    'Opponent no-show',
    'Cheating or rule break',
    'Lobby problem',
    'Other',
  ];
  String _reason = _reasons.first;
  final _desc = TextEditingController();
  final List<FileAsset> _evidence = [];
  bool _uploading = false;
  String? _error;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      16,
      18,
      16,
      16 + MediaQuery.of(context).viewInsets.bottom,
    ),
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Report a problem', style: CT.display(20)),
          const SizedBox(height: 4),
          Text(
            'A Hash referee reviews disputes. Add proof to speed it up.',
            style: CT.body(13),
          ),
          if (widget.askReason) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final r in _reasons)
                  ChoiceChip(
                    label: Text(r),
                    selected: _reason == r,
                    onSelected: (_) => setState(() => _reason = r),
                    showCheckmark: false,
                    selectedColor: CT.primary,
                    backgroundColor: CT.surface,
                    labelStyle: CT.body(
                      12.5,
                      color: _reason == r ? Colors.black : CT.onSurface,
                      w: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          TextField(
            controller: _desc,
            maxLines: 4,
            style: CT.body(14, color: CT.onSurface),
            decoration: tInput('What happened?', label: 'Details'),
          ),
          const SizedBox(height: 12),
          TButton.secondary(
            _evidence.isEmpty
                ? 'Add screenshot'
                : '${_evidence.length} screenshot(s) added · add more',
            icon: Icons.add_photo_alternate_rounded,
            busy: _uploading,
            onTap: () async {
              setState(() => _uploading = true);
              try {
                final a = await pickAndUploadEvidence(
                  widget.tournamentId,
                  'dispute_evidence',
                );
                if (a != null) setState(() => _evidence.add(a));
              } catch (e) {
                setState(() => _error = TournamentApiException.from(e).message);
              } finally {
                if (mounted) setState(() => _uploading = false);
              }
            },
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: CT.body(13, color: CT.error)),
          ],
          const SizedBox(height: 16),
          TButton(
            'Open dispute',
            color: CT.error,
            onTap: _uploading
                ? null
                : () {
                    if (_desc.text.trim().length < 5) {
                      return setState(() => _error = 'Describe the problem.');
                    }
                    Get.back(
                      result: _DisputeInput(
                        _reason,
                        _desc.text.trim(),
                        _evidence.map((e) => e.id).toList(),
                      ),
                    );
                  },
          ),
        ],
      ),
    ),
  );
}
