import 'package:flutter/material.dart';
import 'package:hash/utils/widgets/loader.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:hash/utils/widgets/hash_wordmark.dart';

import '../controllers/host_onboarding_controller.dart';
import '../models/host_program.dart';
import '../models/host_verification.dart';
import 'community_theme.dart';

/// Host Onboarding — value proposition screen.
/// Wired to GET /hosts/program (fee + tiers) and GET /hosts/me/verification
/// (CTA state). Styled to the "Neon Velocity" design system.
class HostOnboardingView extends GetView<HostOnboardingController> {
  const HostOnboardingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CT.bg,
      body: Obx(() {
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
                const _EarningsCard(),
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
        bottom: false,
        child: AspectRatio(
          aspectRatio: 1672 / 941,
          child: Image.asset(
            'assets/community_host_banner.png',
            width: double.infinity,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            filterQuality: FilterQuality.high,
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
          Text(value, style: CT.headline(18, color: color)),
          const SizedBox(height: 4),
          Text(label, style: CT.mono(10)),
        ],
      ),
    );
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          stat('2,800+', 'HOSTS', CT.primaryBright),
          Container(width: 1, height: 34, color: CT.outline),
          stat('65,000+', 'PLAYERS', CT.secondary),
          Container(width: 1, height: 34, color: CT.outline),
          stat('₹18L+', 'PRIZES', CT.successBright),
        ],
      ),
    );
  }
}

class _EarningsCard extends StatelessWidget {
  const _EarningsCard();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ESTIMATED HOST EARNING', style: CT.mono(10)),
                    const SizedBox(height: 5),
                    Text(
                      '₹1,000',
                      style: CT.headline(30, color: CT.successBright),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '10% host share',
                  style: CT.body(12, color: CT.primaryBright),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: CT.outline),
          const SizedBox(height: 16),
          Row(
            children: [
              _EarningMetric(
                value: '100',
                label: 'PLAYERS',
                alignment: CrossAxisAlignment.start,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  '×',
                  style: TextStyle(color: CT.muted, fontSize: 18),
                ),
              ),
              _EarningMetric(
                value: '₹100',
                label: 'ENTRY FEE',
                alignment: CrossAxisAlignment.center,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  '=',
                  style: TextStyle(color: CT.muted, fontSize: 18),
                ),
              ),
              _EarningMetric(
                value: '₹10,000',
                label: 'TOTAL COLLECTED',
                alignment: CrossAxisAlignment.end,
                valueColor: CT.onSurface,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: Container(height: 4, color: CT.successBright),
              ),
              Expanded(flex: 9, child: Container(height: 4, color: CT.outline)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('₹1,000 · HOST', style: CT.mono(9, color: CT.successBright)),
              Text('₹9,000 · PRIZE POOL', style: CT.mono(9)),
            ],
          ),
        ],
      ),
    );
  }
}

class _EarningMetric extends StatelessWidget {
  final String value;
  final String label;
  final CrossAxisAlignment alignment;
  final Color valueColor;

  const _EarningMetric({
    required this.value,
    required this.label,
    required this.alignment,
    this.valueColor = CT.primaryBright,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Text(value, style: CT.headline(15, color: valueColor)),
          const SizedBox(height: 3),
          Text(label, style: CT.mono(8), maxLines: 1),
        ],
      ),
    );
  }
}

class _HowItWorks extends StatefulWidget {
  const _HowItWorks();

  @override
  State<_HowItWorks> createState() => _HowItWorksState();
}

class _HowItWorksState extends State<_HowItWorks> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    const steps = [
      (
        Icons.add_circle_outline_rounded,
        'Create your tournament',
        'Set the game, format, schedule, entry fee, and prizes.',
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
        Icons.payments_rounded,
        'Earn from hosting',
        'Complete the tournament and receive your host commission.',
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
                Expanded(child: Text('How it works', style: CT.headline(18))),
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
        Container(height: 1, color: CT.outline),
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
      (Icons.savings_rounded, 'Earn from tournaments', CT.successBright),
      (
        Icons.sports_esports_rounded,
        'Create Unlimited Tournaments',
        CT.primaryBright,
      ),
      (Icons.trending_up_rounded, 'Track Registrations Live', CT.successBright),
      (Icons.groups_rounded, 'Player Management', CT.primaryBright),
      (
        Icons.account_balance_rounded,
        'Withdraw Earnings Anytime',
        CT.successBright,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Host benefits', style: CT.headline(18)),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 18,
          crossAxisSpacing: 20,
          childAspectRatio: 3.1,
          children: [
            for (final f in features)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                      style: CT.body(
                        12.5,
                        color: CT.onSurface,
                        w: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
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
      return '₹';
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 1, color: CT.outline),
          const SizedBox(height: 18),
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
                    style: CT.mono(10, color: CT.secondary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$symbol$amount',
                    style: CT.display(26, color: CT.secondary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _check('Verified Badge'),
          _check('Unlimited Tournaments'),
          _check('Earnings Enabled'),
          if (fee.includedTournamentsPerWeek > 0)
            _check(
              '${fee.includedTournamentsPerWeek} tournaments/week included',
            ),
          const SizedBox(height: 8),
          Container(height: 1, color: CT.outline),
        ],
      ),
    );
  }

  Widget _check(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        const Icon(Icons.check_rounded, color: CT.successBright, size: 18),
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
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final t in tiers)
                Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: Row(
                    children: [
                      Container(width: 3, height: 32, color: colorFor(t.key)),
                      const SizedBox(width: 9),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.label,
                            style: CT.body(
                              12,
                              color: colorFor(t.key),
                              w: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${t.organizerCommissionRate.toStringAsFixed(0)}% commission',
                            style: CT.mono(10, color: CT.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
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
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              boxShadow: enabled
                  ? CT.glow(CT.primary, blur: 20, opacity: 0.4)
                  : null,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: enabled ? controller.onPrimaryCta : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: CT.primary,
                  disabledBackgroundColor: CT.surfaceHigh,
                  foregroundColor: Colors.white,
                  disabledForegroundColor: CT.muted,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      controller.ctaLabel,
                      style: CT.headline(
                        15,
                        color: enabled ? Colors.white : CT.muted,
                      ),
                    ),
                    if (enabled &&
                        controller.status !=
                            HostVerificationStatus.verified) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.rocket_launch_rounded, size: 18),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
