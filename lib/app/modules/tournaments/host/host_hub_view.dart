import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
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
      TournamentApi.isHost.value =
          _verification?.status == HostVerificationStatus.verified || _hosted.isNotEmpty;
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
    ('BGMI Squads', 'Squads · Battle royale', PhosphorIconsBold.gameController,
        {'game': 'BGMI', 'mode': 'squad', 'format': 'battle_royale', 'max': 25, 'title': 'BGMI Squad Showdown'}),
    ('Valorant 5v5', '5v5 · Knockout', PhosphorIconsBold.crosshair,
        {'game': 'Valorant', 'mode': 'team', 'format': 'single_elimination', 'max': 16, 'title': 'Valorant 5v5 Cup'}),
    ('FIFA 1v1', 'Solo · Knockout', PhosphorIconsBold.soccerBall,
        {'game': 'EA FC', 'mode': 'solo', 'format': 'single_elimination', 'max': 32, 'title': 'FIFA 1v1 Knockout'}),
    ('Free Fire Duo', 'Duos · League', PhosphorIconsBold.fire,
        {'game': 'Free Fire', 'mode': 'duo', 'format': 'league', 'max': 16, 'title': 'Free Fire Duo League'}),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: CT.bg,
    bottomNavigationBar: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
        child: TButton('Create a tournament', icon: PhosphorIconsBold.plus, onTap: _create),
      ),
    ),
    body: RefreshIndicator(
      color: CT.primary,
      onRefresh: _load,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 16, 4),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: Get.back,
                      icon: const Icon(PhosphorIconsBold.arrowLeft, color: Colors.white),
                    ),
                    Text('Host', style: CT.screenTitle(20)),
                  ],
                ),
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
                        const TSectionTitle('Needs attention'),
                        for (final a in _attention)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(children: [
                              const Icon(PhosphorIconsBold.warningCircle, color: CT.primary, size: 18),
                              const SizedBox(width: 8),
                              Expanded(child: Text(a, style: CT.body(13.5, color: CT.onSurface))),
                            ]),
                          ),
                      ],
                      if (_hasActivity && _stats.isNotEmpty) ...[
                        const TSectionTitle('Your numbers'),
                        _statsGrid(),
                      ],
                      if (_hosted.isNotEmpty) ...[
                        const TSectionTitle('Your tournaments'),
                        for (final t in _hosted)
                          TournamentCard(t, onTap: () async {
                            await Get.toNamed(AppRoutes.MANAGE_TOURNAMENT, arguments: {'id': t.id});
                            _load();
                          }),
                      ] else ...[
                        const TSectionTitle('Start from a template'),
                        Text('You can change everything before publishing.', style: CT.body(13, color: CT.muted)),
                        const SizedBox(height: 12),
                        _templateGrid(),
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

  Widget _templateGrid() => Container(
    decoration: CT.card(borderColor: CT.outline),
    child: Column(
      children: [
        for (final (i, (name, detail, icon, template)) in _templates.indexed) ...[
          if (i > 0) const Divider(height: 1, color: CT.hairline),
          ListTile(
            onTap: () => _create(template),
            leading: Icon(icon, color: Colors.white),
            title: Text(name, style: CT.headline(14.5, w: FontWeight.w700)),
            subtitle: Text(detail, style: CT.body(12, color: CT.muted)),
            trailing: const Icon(PhosphorIconsBold.caretRight, color: CT.muted),
          ),
        ],
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
                  s == HostVerificationStatus.verified ? PhosphorIconsBold.sealCheck : PhosphorIconsBold.shield,
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
              icon: PhosphorIconsBold.shieldCheck,
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
