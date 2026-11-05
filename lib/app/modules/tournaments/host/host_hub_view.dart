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

  Future<void> _create() async {
    await Get.toNamed(
      AppRoutes.CREATE_TOURNAMENT,
      arguments: {
        'verified': _verification?.status == HostVerificationStatus.verified,
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
        .where(
          (e) =>
              e.value is num &&
              !e.key.endsWith('_id') &&
              e.key != 'host_user_id',
        )
        .map((e) => MapEntry(e.key, e.value as num))
        .take(6)
        .toList();
  }

  List<String> get _attention => jsonStrings(
    _dash['attention_items'] ?? _dash['attention'] ?? _dash['action_items'],
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: CT.bg,
    appBar: tAppBar('Host tournaments'),
    floatingActionButton: FloatingActionButton.extended(
      backgroundColor: CT.primary,
      foregroundColor: Colors.black,
      onPressed: _create,
      icon: const Icon(Icons.add_rounded),
      label: Text(
        'New tournament',
        style: CT.headline(14, color: Colors.black),
      ),
    ),
    body: RefreshIndicator(
      color: CT.primary,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: _loading
            ? const [TLoading()]
            : _error != null
            ? [TMessage.error(_error!, _load)]
            : [
                _verificationCard(),
                if (_stats.isNotEmpty) ...[
                  const TSectionTitle('Overview'),
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.25,
                    children: [
                      for (final s in _stats)
                        TPanel(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${s.value is double ? (s.value as double).toStringAsFixed(1) : s.value}',
                                style: CT.display(20),
                              ),
                              Text(
                                humanize(s.key),
                                maxLines: 2,
                                style: CT.body(11.5),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
                if (_attention.isNotEmpty) ...[
                  const TSectionTitle('Needs attention'),
                  for (final a in _attention)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.priority_high_rounded,
                            color: CT.primary,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              a,
                              style: CT.body(13.5, color: CT.onSurface),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
                const TSectionTitle('Your tournaments'),
                if (_hosted.isEmpty)
                  const TMessage(
                    icon: Icons.emoji_events_outlined,
                    title: 'Host your first tournament',
                    subtitle:
                        'Free tournaments need no verification. Create a draft, check it, publish.',
                  ),
                for (final t in _hosted)
                  TournamentCard(
                    t,
                    onTap: () async {
                      await Get.toNamed(
                        AppRoutes.MANAGE_TOURNAMENT,
                        arguments: {'id': t.id},
                      );
                      _load();
                    },
                  ),
              ],
      ),
    ),
  );

  Widget _verificationCard() {
    final v = _verification;
    final s = v?.status ?? HostVerificationStatus.none;
    final (title, body, color) = switch (s) {
      HostVerificationStatus.verified => (
        'Verified host',
        'You can host free and paid tournaments.',
        CT.verifiedBlue,
      ),
      HostVerificationStatus.pending ||
      HostVerificationStatus.submitted ||
      HostVerificationStatus.underReview => (
        'Verification in review',
        'You can host free tournaments meanwhile.',
        CT.primary,
      ),
      HostVerificationStatus.suspended => (
        'Hosting suspended',
        'Contact support to restore hosting.',
        CT.error,
      ),
      HostVerificationStatus.rejected => (
        'Verification rejected',
        v?.rejectionReason ?? 'Update your details and apply again.',
        CT.error,
      ),
      _ => (
        'Host free tournaments now',
        'Get verified to charge entry fees and earn commission.',
        CT.primary,
      ),
    };
    final canApply = const {
      HostVerificationStatus.none,
      HostVerificationStatus.rejected,
      HostVerificationStatus.draft,
      HostVerificationStatus.paymentPending,
      HostVerificationStatus.unknown,
    }.contains(s);
    return TPanel(
      border: color.withValues(alpha: 0.6),
      child: Row(
        children: [
          Icon(
            s == HostVerificationStatus.verified
                ? Icons.verified_rounded
                : Icons.shield_outlined,
            color: color,
            size: 30,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: CT.headline(15)),
                Text(body, style: CT.body(12.5)),
              ],
            ),
          ),
          if (canApply)
            TextButton(
              onPressed: () async {
                await Get.toNamed(AppRoutes.HOST_ONBOARDING);
                _load();
              },
              child: Text(
                'Get verified',
                style: CT.headline(13, color: CT.primary),
              ),
            ),
        ],
      ),
    );
  }
}
