import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:get/get.dart';

import '../../../routes/app_routes.dart';
import '../data/tournament_api.dart';
import '../data/tournament_models.dart';
import '../data/tournament_uploads.dart';
import '../ui/tournament_theme.dart';
import '../ui/tournament_widgets.dart';
import 'models/host_verification.dart';

/// Create or edit a tournament. Saves a draft, shows readiness blockers, then
/// publishes. Arguments: `{'id': String?, 'verified': bool?}`.
class TournamentEditorView extends StatefulWidget {
  const TournamentEditorView({super.key});
  @override
  State<TournamentEditorView> createState() => _TournamentEditorViewState();
}

class _TournamentEditorViewState extends State<TournamentEditorView> {
  static const _formats = [
    'single_elimination',
    'round_robin',
    'league',
    'double_elimination',
    'group_knockout',
    'battle_royale',
  ];
  static const _autoFormats = {'single_elimination', 'round_robin', 'league'};
  static const _modes = {'solo': 1, 'duo': 2, 'squad': 4, 'team': 5};

  final _api = TournamentApi();
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _game = TextEditingController();
  final _description = TextEditingController();
  final _maxPlayers = TextEditingController(text: '16');
  final _minEntries = TextEditingController();
  final _teamSize = TextEditingController(text: '1');
  final _subs = TextEditingController(text: '0');
  final _fee = TextEditingController(text: '0');
  final _rules = TextEditingController();
  final _inviteCode = TextEditingController();
  final _discord = TextEditingController();
  final _whatsapp = TextEditingController();
  final _platform = TextEditingController();
  final _region = TextEditingController(text: 'India');
  final _matchMinutes = TextEditingController(text: '30');

  String? _id;
  bool _verified = false;
  String _format = 'single_elimination';
  String _mode = 'solo';
  bool _private = false;
  bool _evidenceRequired = true;
  DateTime? _regStart, _regEnd, _start, _end, _checkInStart, _checkInEnd;
  List<PrizeSplit> _prizes = const [
    PrizeSplit(rank: 1, percent: 60),
    PrizeSplit(rank: 2, percent: 30),
    PrizeSplit(rank: 3, percent: 10),
  ];
  FileAsset? _banner;
  String? _bannerUrl;
  Tournament? _saved;
  Readiness? _readiness;
  bool _loading = false;
  bool _busy = false;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    final a = jsonMap(Get.arguments);
    _verified = a['verified'] == true;
    _id = jsonStr(a['id']);
    final now = DateTime.now();
    _regStart = DateTime(now.year, now.month, now.day, now.hour + 1);
    _regEnd = _regStart!.add(const Duration(days: 3));
    _start = _regEnd!.add(const Duration(hours: 2));
    _end = _start!.add(const Duration(hours: 4));
    // Default check-in: the hour before start, closing 10 minutes before.
    _checkInStart = _start!.subtract(const Duration(hours: 1));
    _checkInEnd = _start!.subtract(const Duration(minutes: 10));
    final tpl = jsonMap(a['template']);
    if (tpl.isNotEmpty) {
      _title.text = jsonStr(tpl['title']) ?? '';
      _game.text = jsonStr(tpl['game']) ?? '';
      if (_modes.containsKey(tpl['mode'])) _mode = tpl['mode'] as String;
      _teamSize.text = '${_modes[_mode]}';
      if (_formats.contains(tpl['format'])) _format = tpl['format'] as String;
      _maxPlayers.text = '${jsonInt(tpl['max']) ?? 16}';
    }
    if (_id != null) _loadExisting();
    if (!_verified) {
      _api
          .myHostVerification()
          .then((v) {
            if (mounted && v?.status == HostVerificationStatus.verified)
              setState(() => _verified = true);
          })
          .catchError((_) {});
    }
  }

  Future<void> _loadExisting() async {
    setState(() => _loading = true);
    try {
      final t = await _api.tournament(_id!);
      _fill(t);
      _readiness = await _api
          .readiness(_id!)
          .catchError((_) => const Readiness(false, [], []));
    } catch (e) {
      toastError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _fill(Tournament t) {
    _saved = t;
    _title.text = t.title;
    _game.text = t.game;
    _description.text = t.description ?? '';
    _maxPlayers.text = '${t.maxPlayers}';
    _minEntries.text = t.minEntries?.toString() ?? '';
    _teamSize.text = '${t.teamSize}';
    _subs.text = '${t.substituteLimit}';
    _fee.text = t.entryFee.toStringAsFixed(t.entryFee % 1 == 0 ? 0 : 2);
    _rules.text = t.rules ?? '';
    _inviteCode.text = t.inviteCode ?? '';
    _discord.text = t.discordLink ?? '';
    _whatsapp.text = t.whatsappLink ?? '';
    _platform.text = t.platform ?? '';
    _region.text = t.region ?? '';
    _matchMinutes.text = t.matchDurationMinutes?.toString() ?? '';
    _format = _formats.contains(t.format) ? t.format : _format;
    _mode = _modes.containsKey(t.teamMode)
        ? t.teamMode
        : (t.isSolo ? 'solo' : 'team');
    _private = t.isPrivate;
    _evidenceRequired = t.rulesConfig['evidence_required'] != false;
    _regStart = t.registrationStartAt;
    _regEnd = t.registrationEndAt;
    _start = t.startAt;
    _end = t.endAt;
    _checkInStart = t.checkInStartAt;
    _checkInEnd = t.checkInEndAt;
    if (t.prizeDistribution.isNotEmpty) _prizes = t.prizeDistribution;
    _bannerUrl = t.bannerUrl;
  }

  bool get _isDraft => _saved == null || _saved!.status == TStatus.draft;

  String? _validate() {
    if (_title.text.trim().length < 3)
      return 'Title needs at least 3 characters.';
    if (_game.text.trim().isEmpty) return 'Enter the game.';
    final max = int.tryParse(_maxPlayers.text) ?? 0;
    if (max < 2 || max > 10000) return 'Slots must be between 2 and 10000.';
    final size = int.tryParse(_teamSize.text) ?? 0;
    if (size < 1 || size > 100) return 'Team size must be between 1 and 100.';
    final subs = int.tryParse(_subs.text) ?? -1;
    if (subs < 0 || subs > 20) return 'Substitutes must be between 0 and 20.';
    final fee = double.tryParse(_fee.text) ?? -1;
    if (fee < 0) return 'Entry fee cannot be negative.';
    if (fee > 0 && !_verified)
      return 'Paid tournaments need a verified host. Set the fee to 0 or get verified.';
    if (_regStart == null || _regEnd == null || _start == null)
      return 'Set the registration and start dates.';
    if (!_regEnd!.isAfter(_regStart!))
      return 'Registration must close after it opens.';
    if (_start!.isBefore(_regEnd!))
      return 'The tournament must start after registration closes.';
    if (_end != null && !_end!.isAfter(_start!))
      return 'The end must be after the start.';
    if (_checkInStart != null &&
        _checkInEnd != null &&
        !_checkInEnd!.isAfter(_checkInStart!)) {
      return 'Check-in must close after it opens.';
    }
    if (_private && _inviteCode.text.trim().isEmpty)
      return 'Private tournaments need an invite code.';
    final total = _prizes.fold<num>(0, (a, p) => a + p.percent);
    if (fee > 0 && total != 100)
      return 'Prize split must add up to 100% (now $total%).';
    return null;
  }

  String _iso(DateTime d) => d.toUtc().toIso8601String();

  Map<String, dynamic> _body() {
    final fee = double.tryParse(_fee.text) ?? 0;
    String? opt(TextEditingController c) =>
        c.text.trim().isEmpty ? null : c.text.trim();
    final body = <String, dynamic>{
      'title': _title.text.trim(),
      'game': _game.text.trim(),
      'description': opt(_description),
      'tournament_type': _format,
      'team_mode': _mode,
      'team_size': _mode == 'solo' ? 1 : int.parse(_teamSize.text),
      'substitute_limit': _mode == 'solo' ? 0 : int.parse(_subs.text),
      'max_players': int.parse(_maxPlayers.text),
      'min_entries': int.tryParse(_minEntries.text),
      'entry_fee': fee,
      'currency': 'INR',
      'registration_start_at': _iso(_regStart!),
      'registration_end_at': _iso(_regEnd!),
      'tournament_start_at': _iso(_start!),
      'tournament_end_at': _end == null ? null : _iso(_end!),
      'check_in_start_at': _checkInStart == null ? null : _iso(_checkInStart!),
      'check_in_end_at': _checkInEnd == null ? null : _iso(_checkInEnd!),
      'match_duration_minutes': int.tryParse(_matchMinutes.text),
      'rules': opt(_rules),
      'rules_config': {'evidence_required': _evidenceRequired},
      'prize_distribution': _prizes.map((p) => p.toJson()).toList(),
      'is_private': _private,
      'invite_code': _private ? opt(_inviteCode) : null,
      'visibility': !_private,
      'discord_link': opt(_discord),
      'whatsapp_link': opt(_whatsapp),
      'platform': opt(_platform),
      'region': opt(_region),
      'banner_asset_id': _banner?.id,
    }..removeWhere((_, v) => v == null);
    return body;
  }

  /// PATCH accepts a narrower set of fields; send only those it documents.
  Map<String, dynamic> _patchBody() {
    const editable = {
      'title',
      'description',
      'banner_asset_id',
      'game',
      'tournament_type',
      'team_mode',
      'entry_fee',
      'currency',
      'max_players',
      'visibility',
      'registration_start_at',
      'registration_end_at',
      'tournament_start_at',
      'tournament_end_at',
      'rules',
      'prize_distribution',
      'discord_link',
      'whatsapp_link',
      'is_private',
      'invite_code',
    };
    return Map.of(_body())..removeWhere((k, _) => !editable.contains(k));
  }

  Future<void> _save({bool publish = false}) async {
    final err = _validate();
    if (err != null) return toast(err, error: true);
    setState(() => _busy = true);
    try {
      var t = _saved == null
          ? await _api.createTournament({..._body(), 'status': 'draft'})
          : await _api.updateTournament(_saved!.id, _patchBody());
      final r = await _api
          .readiness(t.id)
          .catchError((_) => const Readiness(false, [], []));
      if (publish) {
        if (r.blockers.isNotEmpty) {
          setState(() => _readiness = r);
          throw TournamentApiException(
            'Fix ${r.blockers.length} issue(s) before publishing.',
          );
        }
        t = await _api.updateTournament(t.id, {'status': 'published'});
        toast('Published! Players can now find it.');
        Get.offNamed(AppRoutes.MANAGE_TOURNAMENT, arguments: {'id': t.id});
        return;
      }
      setState(() {
        _saved = t;
        _readiness = r;
      });
      toast(
        r.blockers.isEmpty ? 'Draft saved. Ready to publish.' : 'Draft saved.',
      );
    } catch (e) {
      toastError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _loadTemplate() async {
    if (_game.text.trim().isEmpty)
      return toast('Enter the game first.', error: true);
    try {
      final t = await _api.ruleTemplate(_game.text.trim());
      final rules =
          jsonStr(t['rules'] ?? t['template'] ?? t['text']) ??
          [
            ...jsonStrings(t['default_rules']),
            ...jsonStrings(t['mandatory_rules']),
            ...jsonStrings(t['safety_rules']),
          ].join('\n');
      if (rules.isEmpty)
        return toast('No template for this game yet.', error: true);
      setState(() => _rules.text = rules);
    } catch (e) {
      toastError(e);
    }
  }

  Future<void> _pickBanner() async {
    setState(() => _uploading = true);
    try {
      final a = await pickAndUploadBanner();
      if (a != null) {
        setState(() {
          _banner = a;
          _bannerUrl = a.url;
        });
      }
    } catch (e) {
      toastError(e);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<DateTime?> _pickDate(DateTime? current) async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (d == null || !mounted) return null;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current ?? now),
    );
    if (t == null) return null;
    return DateTime(d.year, d.month, d.day, t.hour, t.minute);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: CT.bg,
    appBar: tAppBar(_saved == null ? 'New tournament' : 'Edit tournament'),
    bottomNavigationBar: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
        child: Row(
          children: [
            Expanded(
              child: TButton.secondary(
                _isDraft ? 'Save draft' : 'Save changes',
                busy: _busy,
                onTap: () => _save(),
              ),
            ),
            if (_isDraft) ...[
              const SizedBox(width: 10),
              Expanded(
                child: TButton(
                  'Publish',
                  busy: _busy,
                  onTap: () => _save(publish: true),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
    body: _loading
        ? const TLoading()
        : Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              children: [
                if (_readiness != null &&
                    (_readiness!.blockers.isNotEmpty ||
                        _readiness!.warnings.isNotEmpty))
                  _readinessPanel(),
                _bannerPicker(),
                const TSectionTitle('Basics'),
                _field(_title, 'Title', hint: 'Friday Night Cup'),
                _field(_game, 'Game', hint: 'BGMI, Valorant, FIFA...'),
                _field(_description, 'Description', lines: 3),
                Row(
                  children: [
                    Expanded(
                      child: _field(_platform, 'Platform', hint: 'Mobile, PC'),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: _field(_region, 'Region')),
                  ],
                ),
                const TSectionTitle('Format'),
                _chips<String>(
                  _formats,
                  _format,
                  formatLabelOf,
                  (v) => setState(() => _format = v),
                ),
                if (!_autoFormats.contains(_format))
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'You will create matches yourself for this format.',
                      style: CT.body(12, color: CT.primary),
                    ),
                  ),
                const SizedBox(height: 12),
                _chips<String>(
                  _modes.keys.toList(),
                  _mode,
                  humanize,
                  (v) => setState(() {
                    _mode = v;
                    _teamSize.text = '${_modes[v]}';
                  }),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _field(
                        _maxPlayers,
                        _mode == 'solo' ? 'Max players' : 'Max teams',
                        number: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _field(_minEntries, 'Min entries', number: true),
                    ),
                  ],
                ),
                if (_mode != 'solo')
                  Row(
                    children: [
                      Expanded(
                        child: _field(
                          _teamSize,
                          'Players per team',
                          number: true,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _field(_subs, 'Substitutes', number: true),
                      ),
                    ],
                  ),
                _field(_matchMinutes, 'Match length (minutes)', number: true),
                const TSectionTitle('Schedule'),
                _dateRow('Registration opens', _regStart, (d) => _regStart = d),
                _dateRow('Registration closes', _regEnd, (d) => _regEnd = d),
                _dateRow(
                  'Check-in opens (optional)',
                  _checkInStart,
                  (d) => _checkInStart = d,
                  clearable: true,
                ),
                _dateRow(
                  'Check-in closes (optional)',
                  _checkInEnd,
                  (d) => _checkInEnd = d,
                  clearable: true,
                ),
                _dateRow('Tournament starts', _start, (d) => _start = d),
                _dateRow(
                  'Tournament ends (optional)',
                  _end,
                  (d) => _end = d,
                  clearable: true,
                ),
                const TSectionTitle('Entry & prizes'),
                _field(_fee, 'Entry fee (₹)', number: true, hint: '0 for free'),
                if (!_verified)
                  Text(
                    'Only verified hosts can charge an entry fee.',
                    style: CT.body(12, color: CT.muted),
                  ),
                const SizedBox(height: 8),
                Text(
                  'Prize split of the pool (after Hash fees)',
                  style: CT.body(13),
                ),
                for (final (i, p) in _prizes.indexed)
                  Row(
                    children: [
                      SizedBox(
                        width: 70,
                        child: Text('Rank ${p.rank}', style: CT.headline(13.5)),
                      ),
                      Expanded(
                        child: Slider(
                          value: p.percent.toDouble().clamp(0, 100),
                          max: 100,
                          divisions: 20,
                          activeColor: CT.primary,
                          label: '${p.percent}%',
                          onChanged: (v) => setState(() {
                            _prizes = [..._prizes]
                              ..[i] = PrizeSplit(
                                rank: p.rank,
                                percent: v.round(),
                              );
                          }),
                        ),
                      ),
                      SizedBox(
                        width: 44,
                        child: Text(
                          '${p.percent}%',
                          style: CT.body(13, color: CT.onSurface),
                        ),
                      ),
                    ],
                  ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => setState(
                        () => _prizes = [
                          ..._prizes,
                          PrizeSplit(rank: _prizes.length + 1, percent: 0),
                        ],
                      ),
                      child: Text(
                        '+ Add rank',
                        style: CT.body(13, color: CT.primary),
                      ),
                    ),
                    if (_prizes.length > 1)
                      TextButton(
                        onPressed: () => setState(
                          () =>
                              _prizes = _prizes.sublist(0, _prizes.length - 1),
                        ),
                        child: Text('Remove last', style: CT.body(13)),
                      ),
                    const Spacer(),
                    Text(
                      'Total ${_prizes.fold<num>(0, (a, p) => a + p.percent)}%',
                      style: CT.headline(13),
                    ),
                  ],
                ),
                const TSectionTitle('Rules'),
                _field(_rules, 'Rules', lines: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _loadTemplate,
                    icon: const Icon(
                      PhosphorIconsBold.magicWand,
                      color: CT.primary,
                      size: 18,
                    ),
                    label: Text(
                      'Use Hash template for this game',
                      style: CT.body(13, color: CT.primary),
                    ),
                  ),
                ),
                _switch(
                  'Screenshot required for results',
                  _evidenceRequired,
                  (v) => setState(() => _evidenceRequired = v),
                ),
                const TSectionTitle('Privacy & links'),
                _switch(
                  'Private (invite code only)',
                  _private,
                  (v) => setState(() => _private = v),
                ),
                if (_private)
                  _field(_inviteCode, 'Invite code', hint: 'FRIDAY24'),
                _field(_discord, 'Discord link (optional)'),
                _field(_whatsapp, 'WhatsApp group link (optional)'),
              ],
            ),
          ),
  );

  Widget _readinessPanel() => TPanel(
    border: (_readiness!.blockers.isEmpty ? CT.success : CT.error).withValues(
      alpha: 0.6,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _readiness!.blockers.isEmpty
              ? 'Ready to publish'
              : 'Before you publish',
          style: CT.headline(15),
        ),
        for (final b in _readiness!.blockers)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text('• $b', style: CT.body(13, color: CT.error)),
          ),
        for (final w in _readiness!.warnings)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text('• $w', style: CT.body(13, color: CT.gold)),
          ),
      ],
    ),
  );

  Widget _bannerPicker() => GestureDetector(
    onTap: _uploading ? null : _pickBanner,
    child: Stack(
      alignment: Alignment.center,
      children: [
        TBanner(_bannerUrl, height: 150, radius: BorderRadius.circular(16)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            _uploading
                ? 'Uploading…'
                : (_bannerUrl == null ? 'Add banner' : 'Change banner'),
            style: CT.headline(13),
          ),
        ),
      ],
    ),
  );

  Widget _field(
    TextEditingController c,
    String label, {
    String? hint,
    int lines = 1,
    bool number = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(
      controller: c,
      maxLines: lines,
      keyboardType: number ? TextInputType.number : null,
      style: CT.body(14.5, color: CT.onSurface),
      decoration: tInput(hint ?? '', label: label),
    ),
  );

  Widget _chips<T>(
    List<T> values,
    T selected,
    String Function(T) label,
    ValueChanged<T> onTap,
  ) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final v in values)
        ChoiceChip(
          label: Text(label(v)),
          selected: v == selected,
          onSelected: (_) => onTap(v),
          showCheckmark: false,
          selectedColor: CT.primary,
          backgroundColor: CT.surface,
          labelStyle: CT.body(12.5, color: v == selected ? Colors.white : CT.onSurface, w: FontWeight.w700),
          shape: const StadiumBorder(side: BorderSide(color: CT.outline)),
          side: BorderSide(color: v == selected ? CT.primary : CT.outline),
        ),
    ],
  );

  Widget _dateRow(
    String label,
    DateTime? value,
    void Function(DateTime?) set, {
    bool clearable = false,
  }) => Container(
    decoration: CT.card(),
    child: ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: CT.body(13.5)),
      subtitle: Text(
        value == null ? 'Not set' : fmtDateTime(value),
        style: CT.headline(14),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (clearable && value != null)
            IconButton(
              onPressed: () => setState(() => set(null)),
              icon: const Icon(PhosphorIconsBold.x, color: CT.muted),
            ),
          const Icon(PhosphorIconsBold.calendarBlank, color: CT.primary),
        ],
      ),
      onTap: () async {
        final d = await _pickDate(value);
        if (d != null) setState(() => set(d));
      },
    ),
  );

  Widget _switch(String label, bool v, ValueChanged<bool> f) => SwitchListTile(
    contentPadding: EdgeInsets.zero,
    value: v,
    onChanged: f,
    activeThumbColor: CT.primary,
    title: Text(label, style: CT.body(14, color: CT.onSurface)),
  );
}
