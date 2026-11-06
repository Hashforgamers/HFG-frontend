import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../routes/app_routes.dart';
import '../data/tournament_api.dart';
import '../data/tournament_models.dart';
import '../ui/tournament_theme.dart';
import '../ui/tournament_widgets.dart';
import 'models/host_verification.dart';

/// Host home: verification state, dashboard counts, hosted tournaments.
class HostHubView extends StatefulWidget {
  const HostHubView({super.key});
  @override
  State<HostHubView> createState() => _HostHubViewState();
}

class _HostHubViewState extends State<HostHubView> {
  final _api = TournamentApi();
  HostVerification? _verification;
  Map<String, dynamic> _dash = const {};
  List<Tournament> _hosted = const [];
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final r = await Future.wait<dynamic>([
        _api.myHostVerification(),
        _api.hostDashboard().catchError((_) => <String, dynamic>{}),
        _api.myTournaments('hosted').then((p) => p.items),
      ]);
      if (!mounted) return;
      setState(() {
        _verification = r[0] as HostVerification?;
        _dash = r[1] as Map<String, dynamic>;
        _hosted = r[2] as List<Tournament>;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _create([Map<String, dynamic>? template]) async {
    await Get.toNamed(
      AppRoutes.CREATE_TOURNAMENT,
      arguments: {
        'verified': _verification?.status == HostVerificationStatus.verified,
        'template': ?template,
      },
    );
    _load();
  }

  /// Numeric counters from the dashboard payload, wherever the backend nests them.
  List<MapEntry<String, num>> get _stats {
    final src = {
      ..._dash,
      ...jsonMap(_dash['counts']),
      ...jsonMap(_dash['summary']),
      ...jsonMap(_dash['stats']),
    };
    return src.entries
        .where((e) => e.value is num && !e.key.endsWith('_id') && e.key != 'host_user_id')
        .map((e) => MapEntry(e.key, e.value as num))
        .take(6)
        .toList();
  }

  bool get _hasActivity => _hosted.isNotEmpty || _stats.any((s) => s.value != 0);

  List<String> get _attention => jsonStrings(
    _dash['attention_items'] ?? _dash['attention'] ?? _dash['action_items'],
  );

  static const _templates = <(String, String, IconData, Map<String, dynamic>)>[
    ('BGMI Squads', 'Squads · Battle royale', Icons.sports_esports_rounded,
        {'game': 'BGMI', 'mode': 'squad', 'format': 'battle_royale', 'max': 25, 'title': 'BGMI Squad Showdown'}),
    ('Valorant 5v5', '5v5 · Knockout', Icons.gps_fixed_rounded,
        {'game': 'Valorant', 'mode': 'team', 'format': 'single_elimination', 'max': 16, 'title': 'Valorant 5v5 Cup'}),
    ('FIFA 1v1', 'Solo · Knockout', Icons.sports_soccer_rounded,
        {'game': 'EA FC', 'mode': 'solo', 'format': 'single_elimination', 'max': 32, 'title': 'FIFA 1v1 Knockout'}),
    ('Free Fire Duo', 'Duos · League', Icons.local_fire_department_rounded,
        {'game': 'Free Fire', 'mode': 'duo', 'format': 'league', 'max': 16, 'title': 'Free Fire Duo League'}),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: CT.bg,
    bottomNavigationBar: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
        child: TButton('Create a tournament', icon: Icons.add_rounded, onTap: _create),
      ),
    ),
    body: RefreshIndicator(
      color: CT.primary,
      onRefresh: _load,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 200,
            backgroundColor: CT.bg,
            surfaceTintColor: Colors.transparent,
            foregroundColor: Colors.white,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: Material(
                color: Colors.black54,
                shape: const CircleBorder(),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                  onPressed: Get.back,
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsetsDirectional.only(start: 56, bottom: 14),
              title: Text.rich(TextSpan(children: [
                TextSpan(text: 'Host on ', style: CT.headline(18, w: FontWeight.w800)),
                WidgetSpan(
                  alignment: PlaceholderAlignment.baseline,
                  baseline: TextBaseline.alphabetic,
                  child: GradientText('HASH', style: CT.headline(18, w: FontWeight.w800)),
                ),
              ])),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset('assets/host_program_hero.jpg', fit: BoxFit.cover, alignment: const Alignment(1, 0.1)),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xCC000000), Color(0x55000000), CT.bg],
                        stops: [0, 0.5, 1],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            sliver: SliverList.list(
              children: _loading
                  ? const [TLoading()]
                  : _error != null
                  ? [TMessage.error(_error!, _load)]
                  : [
                      _verificationCard(),
                      if (_attention.isNotEmpty) ...[
                        const TSectionTitle('Needs ', accent: 'attention'),
                        for (final a in _attention)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(children: [
                              const Icon(Icons.priority_high_rounded, color: CT.primary, size: 18),
                              const SizedBox(width: 8),
                              Expanded(child: Text(a, style: CT.body(13.5, color: CT.onSurface))),
                            ]),
                          ),
                      ],
                      if (_hasActivity && _stats.isNotEmpty) ...[
                        const TSectionTitle('Your ', accent: 'numbers'),
                        _statsGrid(),
                      ],
                      if (_hosted.isNotEmpty) ...[
                        const TSectionTitle('Your ', accent: 'tournaments'),
                        for (final t in _hosted)
                          TournamentCard(t, onTap: () async {
                            await Get.toNamed(AppRoutes.MANAGE_TOURNAMENT, arguments: {'id': t.id});
                            _load();
                          }),
                      ] else ...[
                        const TSectionTitle('Quick ', accent: 'start'),
                        Text('Pick a template. You can change everything before publishing.', style: CT.body(13)),
                        const SizedBox(height: 12),
                        _templateGrid(),
                        const TSectionTitle('How ', accent: 'hosting works'),
                        _steps(),
                      ],
                    ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _statsGrid() => GridView.count(
    crossAxisCount: 3,
    shrinkWrap: true,
    padding: EdgeInsets.zero,
    physics: const NeverScrollableScrollPhysics(),
    mainAxisSpacing: 10,
    crossAxisSpacing: 10,
    childAspectRatio: 1.0,
    children: [
      for (final s in _stats)
        TPanel(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  RegExp('fee|prize|amount|collect|earn|commission').hasMatch(s.key)
                      ? money(s.value)
                      : '${s.value is double ? (s.value as double).toStringAsFixed(1) : s.value}',
                  style: CT.display(22),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                humanize(s.key),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: CT.body(11.5, color: CT.muted).copyWith(height: 1.25),
              ),
            ],
          ),
        ),
    ],
  );

  Widget _templateGrid() => GridView.count(
    crossAxisCount: 2,
    shrinkWrap: true,
    padding: EdgeInsets.zero,
    physics: const NeverScrollableScrollPhysics(),
    mainAxisSpacing: 10,
    crossAxisSpacing: 10,
    childAspectRatio: 1.45,
    children: [
      for (final (name, detail, icon, template) in _templates)
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () => _create(template),
            child: Ink(
              padding: const EdgeInsets.all(14),
              decoration: CT.card(borderColor: CT.outline),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
                    child: Icon(icon, color: Colors.white, size: 20),
                  ),
                  const Spacer(),
                  Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: CT.headline(14.5, w: FontWeight.w800)),
                  Text(detail, maxLines: 1, overflow: TextOverflow.ellipsis, style: CT.body(11.5, color: CT.muted)),
                ],
              ),
            ),
          ),
        ),
    ],
  );

  Widget _steps() => TPanel(
    child: Column(
      children: [
        for (final (i, step) in const [
          ('Create a draft', 'Game, format, schedule and prizes. Save anytime.'),
          ('Publish', 'We check it\'s ready, then players can find and join it.'),
          ('Approve & run', 'Approve teams, generate the bracket, share lobby details.'),
          ('Pick winners', 'Hash pays prizes to winners\' wallets.'),
        ].indexed)
          Padding(
            padding: EdgeInsets.only(bottom: i == 3 ? 0 : 14),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: Color(0x1FFFFFFF), shape: BoxShape.circle),
                child: Text('${i + 1}', style: CT.headline(12, color: Colors.white, w: FontWeight.w800)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(step.$1, style: CT.headline(14, w: FontWeight.w700)),
                  Text(step.$2, style: CT.body(12.5)),
                ]),
              ),
            ]),
          ),
      ],
    ),
  );

  Widget _verificationCard() {
    final v = _verification;
    final s = v?.status ?? HostVerificationStatus.none;
    final (title, body, color) = switch (s) {
      HostVerificationStatus.verified => ('Verified host', 'You can host free and paid tournaments.', CT.verifiedBlue),
      HostVerificationStatus.pending || HostVerificationStatus.submitted || HostVerificationStatus.underReview =>
        ('Verification in review', 'Host free tournaments while we review.', CT.primaryBright),
      HostVerificationStatus.suspended => ('Hosting suspended', 'Contact support to restore hosting.', CT.error),
      HostVerificationStatus.rejected =>
        ('Verification rejected', v?.rejectionReason ?? 'Update your details and apply again.', CT.error),
      _ => ('Free hosting is on', 'Get verified to charge entry fees and earn commission.', CT.success),
    };
    final canApply = const {
      HostVerificationStatus.none,
      HostVerificationStatus.rejected,
      HostVerificationStatus.draft,
      HostVerificationStatus.paymentPending,
      HostVerificationStatus.unknown,
    }.contains(s);
    return TPanel(
      border: color.withValues(alpha: 0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.14), shape: BoxShape.circle),
                child: Icon(
                  s == HostVerificationStatus.verified ? Icons.verified_rounded : Icons.shield_rounded,
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: CT.headline(15.5, w: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(body, style: CT.body(12.5)),
                ]),
              ),
            ],
          ),
          if (canApply) ...[
            const SizedBox(height: 14),
            TButton.secondary(
              'Get verified',
              icon: Icons.verified_user_rounded,
              height: 44,
              onTap: () async {
                await Get.toNamed(AppRoutes.HOST_ONBOARDING);
                _load();
              },
            ),
          ],
        ],
      ),
    );
  }
}
