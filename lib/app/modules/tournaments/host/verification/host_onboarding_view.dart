import 'package:flutter/material.dart';
import 'package:hash/utils/widgets/loader.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:hash/utils/widgets/hash_wordmark.dart';

import 'host_onboarding_controller.dart';
import '../models/host_program.dart';
import '../models/host_verification.dart';
import '../../ui/tournament_theme.dart';
import '../../ui/tournament_widgets.dart';
import 'package:hash/core/localization/app_region.dart';

/// Host Onboarding — value proposition screen.
/// Wired to GET /hosts/program (fee + tiers) and GET /hosts/me/verification
/// (CTA state). Styled to the "Neon Velocity" design system.
class HostOnboardingView extends GetView<HostOnboardingController> {
  const HostOnboardingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CT.bg,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Obx(() {
              if (controller.isLoading.value) {
                return const _CenteredLoader();
              }
              if (controller.program.value == null) {
                return _ErrorRetry(
                  message: controller.error.value ?? 'Something went wrong.',
                  onRetry: controller.load,
                );
              }
              return _Content(controller: controller);
            }),
          ],
        ),
      ),
      bottomNavigationBar: Obx(
        () => controller.isLoading.value || controller.program.value == null
            ? const SizedBox.shrink()
            : _BottomCta(controller: controller),
      ),
    );
  }
}

class _CenteredLoader extends StatelessWidget {
  const _CenteredLoader();
  @override
  Widget build(BuildContext context) {
    return const Center(child: AppLinearLoader.screen());
  }
}

class _ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorRetry({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, color: CT.muted, size: 40),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center, style: CT.body(15)),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                foregroundColor: CT.secondary,
                side: const BorderSide(color: CT.secondary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  final HostOnboardingController controller;
  const _Content({required this.controller});

  @override
  Widget build(BuildContext context) {
    final program = controller.program.value!;
    return RefreshIndicator(
      color: CT.primary,
      backgroundColor: CT.surface,
      onRefresh: controller.load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          const _Hero(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _StatsRow(),
                const SizedBox(height: 20),
                _Estimator(program: program),
                if (program.performanceLevels.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _TierStrip(tiers: program.performanceLevels),
                ],
                const SizedBox(height: 24),
                const _FeatureGrid(),
                const SizedBox(height: 24),
                const _HowItWorks(),
                const SizedBox(height: 24),
                _VerificationCard(program: program),
                const SizedBox(height: 18),
                const _TrustBadges(),
                if (controller.status == HostVerificationStatus.rejected)
                  _StatusNote(
                    color: CT.error,
                    icon: Icons.error_outline_rounded,
                    text:
                        'Your previous application was rejected. You can '
                        're-apply below.',
                  ),
                if (controller.status == HostVerificationStatus.pending)
                  const _StatusNote(
                    color: CT.secondary,
                    icon: Icons.hourglass_top_rounded,
                    text:
                        'Your verification is under review. We will notify you '
                        'once it is approved.',
                  ),
                if (controller.status == HostVerificationStatus.suspended)
                  const _StatusNote(
                    color: CT.error,
                    icon: Icons.block_rounded,
                    text: 'Your host account is suspended. Contact support.',
                  ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();
  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: CT.bg,
      child: SafeArea(
        top: false,
        bottom: false,
        child: AspectRatio(
          aspectRatio: 1672 / 941,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/community_host_banner.png',
                width: double.infinity,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                filterQuality: FilterQuality.high,
              ),
              Positioned(
                right: 10,
                top: 10,
                child: Material(
                  color: Colors.black54,
                  shape: const CircleBorder(),
                  child: IconButton(
                    tooltip: 'Close',
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                    onPressed: Get.back,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow();
  @override
  Widget build(BuildContext context) {
    Widget stat(String value, String label, Color color) => Expanded(
      child: Column(
        children: [
          Text(value, style: CT.headline(20, color: color, w: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(label, style: CT.mono(10)),
        ],
      ),
    );
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: CT.card(borderColor: CT.outline),
      child: Row(
        children: [
          stat('2,800+', 'HOSTS', CT.onSurface),
          Container(width: 1, height: 34, color: CT.outline),
          stat('65,000+', 'PLAYERS', CT.onSurface),
          Container(width: 1, height: 34, color: CT.outline),
          stat('500+', 'EVENTS', CT.onSurface),
        ],
      ),
    );
  }
}

/// Interactive earnings estimate: players x entry fee x tier commission.
/// Indicative only; real figures are computed by the server per tournament.
class _Estimator extends StatefulWidget {
  final HostProgram program;
  const _Estimator({required this.program});
  @override
  State<_Estimator> createState() => _EstimatorState();
}

class _EstimatorState extends State<_Estimator> {
  double _players = 32;
  double _fee = 100;
  int _tier = 0;

  @override
  Widget build(BuildContext context) {
    final tiers = widget.program.performanceLevels;
    double rateOf(HostTierLevel t) =>
        t.organizerCommissionRate <= 1 ? t.organizerCommissionRate : t.organizerCommissionRate / 100;
    final rate = tiers.isEmpty ? 0.08 : rateOf(tiers[_tier.clamp(0, tiers.length - 1)]);
    final collected = _players * _fee;
    final earn = collected * rate;
    String inr(num v) => Money.format(v.round());
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: CT.card(borderColor: CT.outline),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ESTIMATE YOUR EARNINGS', style: CT.mono(10, color: CT.muted)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: Text(inr(earn), style: CT.display(34))),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('per tournament', style: CT.body(12.5, color: CT.muted)),
              ),
            ],
          ),
          Text(
            '${inr(collected)} collected · ${(rate * 100).toStringAsFixed(0)}% host commission',
            style: CT.body(12.5),
          ),
          const SizedBox(height: 14),
          _slider('Players', '${_players.round()}', _players, 8, 128, 15, (v) => setState(() => _players = v)),
          _slider('Entry fee', inr(_fee), _fee, 10, 500, 49, (v) => setState(() => _fee = v)),
          if (tiers.length > 1) ...[
            const SizedBox(height: 6),
            TSegments(
              options: {for (final (i, t) in tiers.indexed) '$i': t.label.replaceAll(' Host', '')},
              value: '$_tier',
              onChanged: (v) => setState(() => _tier = int.parse(v)),
            ),
          ],
          const SizedBox(height: 10),
          Text('Indicative only. Paid tournaments need verification.', style: CT.body(11, color: CT.muted)),
        ],
      ),
    );
  }

  Widget _slider(String label, String value, double v, double min, double max, int divisions, ValueChanged<double> onChanged) =>
      Column(
        children: [
          Row(children: [
            Expanded(child: Text(label, style: CT.body(13))),
            Text(value, style: CT.headline(13.5, w: FontWeight.w700)),
          ]),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              activeTrackColor: CT.primary,
              inactiveTrackColor: Colors.white.withValues(alpha: 0.08),
              thumbColor: Colors.white,
              overlayColor: Colors.white12,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              tickMarkShape: SliderTickMarkShape.noTickMark,
            ),
            child: Slider(value: v, min: min, max: max, divisions: divisions, onChanged: onChanged),
          ),
        ],
      );
}

class _HowItWorks extends StatefulWidget {
  const _HowItWorks();

  @override
  State<_HowItWorks> createState() => _HowItWorksState();
}

class _HowItWorksState extends State<_HowItWorks> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    const steps = [
      (
        Icons.add_circle_outline_rounded,
        'Create your tournament',
        'Set the game, format, schedule, and rules.',
      ),
      (
        Icons.share_rounded,
        'Share with players',
        'Send one tournament link to your gaming community.',
      ),
      (
        Icons.group_add_rounded,
        'Players register',
        'Track confirmed entries as your available slots fill up.',
      ),
      (
        Icons.sports_esports_rounded,
        'Run the event',
        'Publish room details, manage matches, and verify results.',
      ),
      (
        Icons.emoji_events_rounded,
        'Celebrate results',
        'Complete the tournament and publish final standings.',
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Expanded(child: Text('How it works', style: CT.headline(18, w: FontWeight.w800))),
                AnimatedRotation(
                  turns: _isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 220),
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: CT.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          child: _isExpanded
              ? Column(
                  children: [
                    for (var index = 0; index < steps.length; index++)
                      _TimelineStep(
                        index: index,
                        icon: steps[index].$1,
                        title: steps[index].$2,
                        description: steps[index].$3,
                        isLast: index == steps.length - 1,
                      ),
                  ],
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

class _TimelineStep extends StatelessWidget {
  final int index;
  final IconData icon;
  final String title;
  final String description;
  final bool isLast;

  const _TimelineStep({
    required this.index,
    required this.icon,
    required this.title,
    required this.description,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isLast ? CT.successBright : CT.primaryBright;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 28,
                child: Text(
                  '${index + 1}'.padLeft(2, '0'),
                  style: CT.mono(10, color: accent),
                ),
              ),
              Icon(icon, size: 18, color: accent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: CT.body(
                        14,
                        color: CT.onSurface,
                        w: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: CT.body(12.5, color: CT.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast) Container(height: 1, color: CT.outline),
      ],
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid();
  @override
  Widget build(BuildContext context) {
    const features = [
      (Icons.verified_rounded, 'Official Host Badge', CT.verifiedBlue),
      (Icons.emoji_events_rounded, 'Community spotlight', CT.onSurfaceVariant),
      (Icons.sports_esports_rounded, 'Unlimited tournaments', CT.onSurfaceVariant),
      (Icons.trending_up_rounded, 'Live registrations', CT.onSurfaceVariant),
      (Icons.groups_rounded, 'Player management', CT.onSurfaceVariant),
      (Icons.insights_rounded, 'Event insights', CT.onSurfaceVariant),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Host benefits', style: CT.headline(18, w: FontWeight.w800)),
        const SizedBox(height: 12),
        GridView.count(
          padding: EdgeInsets.zero,
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.5,
          children: [
            for (final f in features)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: CT.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: CT.outline),
                ),
                child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  f.$2 == 'Official Host Badge'
                      ? SvgPicture.asset(
                          'assets/verified_badge.svg',
                          width: 20,
                          height: 20,
                        )
                      : Icon(f.$1, color: f.$3, size: 19),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      f.$2,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: CT.body(
                        12.5,
                        color: CT.onSurface,
                        w: FontWeight.w600,
                      ).copyWith(height: 1.25),
                    ),
                  ),
                ],
              ),
              ),
          ],
        ),
      ],
    );
  }
}

String _currencySymbol(String code) {
  switch (code.toUpperCase()) {
    case 'INR':
      return '${Money.symbol}';
    case 'USD':
      return '\$';
    case 'EUR':
      return '€';
    default:
      return '$code ';
  }
}

class _VerificationCard extends StatelessWidget {
  final HostProgram program;
  const _VerificationCard({required this.program});
  @override
  Widget build(BuildContext context) {
    final fee = program.verificationFee;
    final symbol = _currencySymbol(fee.currency);
    final amount = fee.amount == fee.amount.roundToDouble()
        ? fee.amount.toStringAsFixed(0)
        : fee.amount.toStringAsFixed(2);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: CT.card(borderColor: CT.verifiedBlue.withValues(alpha: 0.35)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  SvgPicture.asset(
                    'assets/verified_badge.svg',
                    width: 26,
                    height: 26,
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('BECOME AN OFFICIAL', style: CT.mono(10)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const HashWordmark(fontSize: 9, letterSpacing: 1.5),
                          const SizedBox(width: 6),
                          Text('HOST', style: CT.mono(10)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    fee.periodLabel.toUpperCase(),
                    style: CT.mono(10, color: CT.muted),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$symbol$amount',
                    style: CT.display(26, color: CT.onSurface),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _check('Verified Badge'),
          _check('Unlimited Tournaments'),
          _check('Host Tools Enabled'),
          if (fee.includedTournamentsPerWeek > 0)
            _check(
              '${fee.includedTournamentsPerWeek} tournaments/week included',
            ),
        ],
      ),
    );
  }

  Widget _check(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        const Icon(Icons.check_circle_rounded, color: CT.verifiedBlue, size: 18),
        const SizedBox(width: 10),
        Text(label, style: CT.body(14, color: CT.onSurface)),
      ],
    ),
  );
}

class _TierStrip extends StatelessWidget {
  final List<HostTierLevel> tiers;
  const _TierStrip({required this.tiers});
  @override
  Widget build(BuildContext context) {
    if (tiers.isEmpty) return const SizedBox.shrink();
    Color colorFor(String key) {
      switch (key) {
        case 'silver':
          return const Color(0xFFC0C0C0);
        case 'gold':
          return const Color(0xFFFFD24C);
        case 'platinum':
          return CT.secondary;
        default:
          return const Color(0xFFCD7F32); // bronze
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 8),
          child: Text('HOST TIERS & COMMISSION', style: CT.mono(10)),
        ),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 2.9,
          children: [
            for (final t in tiers)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: CT.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: CT.outline),
                ),
                child: Row(
                  children: [
                    Container(width: 3, height: 28, decoration: BoxDecoration(color: colorFor(t.key), borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(t.label, maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: CT.body(13, color: CT.onSurface, w: FontWeight.w700)),
                          Text(
                            t.organizerCommissionRate > 0
                                ? '${(t.organizerCommissionRate <= 1 ? t.organizerCommissionRate * 100 : t.organizerCommissionRate).toStringAsFixed(0)}% commission'
                                : 'Host tier',
                            style: CT.body(11, color: CT.muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _TrustBadges extends StatelessWidget {
  const _TrustBadges();
  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.verified_rounded, 'VERIFIED HOSTS'),
      (Icons.lock_rounded, 'SECURE PAYMENTS'),
      (Icons.bolt_rounded, 'INSTANT PAYOUTS'),
      (Icons.shield_rounded, 'ESCROW PROTECTED'),
    ];
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 14,
      runSpacing: 8,
      children: [
        for (final i in items)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              i.$2 == 'VERIFIED HOSTS'
                  ? SvgPicture.asset(
                      'assets/verified_badge.svg',
                      width: 12,
                      height: 12,
                    )
                  : Icon(i.$1, size: 12, color: CT.muted),
              const SizedBox(width: 4),
              Text(i.$2, style: CT.mono(9)),
            ],
          ),
      ],
    );
  }
}

class _StatusNote extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String text;
  const _StatusNote({
    required this.color,
    required this.icon,
    required this.text,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: CT.body(13, color: CT.onSurface)),
          ),
        ],
      ),
    );
  }
}

class _BottomCta extends StatelessWidget {
  final HostOnboardingController controller;
  const _BottomCta({required this.controller});
  @override
  Widget build(BuildContext context) {
    final enabled = controller.ctaEnabled;
    return Container(
      color: CT.surfaceLow,
      padding: EdgeInsets.fromLTRB(
        16,
        14,
        16,
        14 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TButton(
            controller.ctaLabel,
            icon: enabled && controller.status != HostVerificationStatus.verified
                ? Icons.rocket_launch_rounded
                : null,
            onTap: enabled ? controller.onPrimaryCta : null,
          ),
        ],
      ),
    );
  }
}
