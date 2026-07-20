import 'package:flutter/material.dart';
import 'package:hash/utils/widgets/loader.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:hash/utils/widgets/bounce_tap_widget.dart';

import '../controllers/host_dashboard_controller.dart';
import '../models/tournament.dart';
import '../models/host_verification.dart';
import 'community_theme.dart';
import 'tournaments_view.dart' show ctAmount, ctCurrency, ctStatus;

class HostDashboardView extends GetView<HostDashboardController> {
  const HostDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CT.bg,
      appBar: AppBar(
        backgroundColor: CT.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: CT.onSurface),
        title: Text('Host HQ', style: CT.headline(18)),
        actions: [
          IconButton(
            onPressed: controller.load,
            tooltip: 'Refresh dashboard',
            icon: const Icon(Icons.refresh_rounded, size: 21),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.loading.value) return const _DashboardLoader();
        if (controller.error.value != null) return _errorState();
        return RefreshIndicator(
          color: CT.primary,
          backgroundColor: CT.surface,
          onRefresh: controller.load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 36),
            children: [
              _hostIdentity(),
              const SizedBox(height: 28),
              _earningsHero(),
              const SizedBox(height: 20),
              _createButton(),
              const SizedBox(height: 28),
              _activityOverview(),
              const SizedBox(height: 32),
              _sectionHeader(
                title: 'Your tournaments',
                action: controller.hosted.isEmpty ? null : 'View all',
                onTap: controller.openAllTournaments,
              ),
              const SizedBox(height: 8),
              if (controller.hosted.isEmpty)
                _emptyTournaments()
              else
                ...controller.hosted
                    .take(3)
                    .map((item) => _tournamentRow(item.tournament)),
              const SizedBox(height: 32),
              _sectionHeader(title: 'Host performance'),
              const SizedBox(height: 12),
              _performance(),
            ],
          ),
        );
      }),
    );
  }

  Widget _hostIdentity() {
    final host = controller.verification.value!;
    final name = host.name?.trim();
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(
            color: CT.surface,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.workspace_premium_rounded,
            color: CT.primaryBright,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name?.isNotEmpty == true ? name! : 'Verified Host',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CT.headline(16),
              ),
              const SizedBox(height: 2),
              Text(
                host.status == HostVerificationStatus.verified
                    ? '${host.hostTier.toUpperCase()} HOST'
                    : '${host.status.name.toUpperCase()} · FREE TOURNAMENTS ONLY',
                style: CT.mono(9, color: CT.successBright),
              ),
            ],
          ),
        ),
        if (host.status == HostVerificationStatus.verified)
          SvgPicture.asset('assets/verified_badge.svg', width: 20, height: 20),
      ],
    );
  }

  Widget _earningsHero() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('TOTAL HOST EARNINGS', style: CT.mono(10)),
      const SizedBox(height: 6),
      Text(
        '₹${ctAmount(controller.totalCommission)}',
        style: CT.display(38, color: CT.successBright),
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          const Icon(
            Icons.account_balance_wallet_outlined,
            size: 15,
            color: CT.muted,
          ),
          const SizedBox(width: 6),
          Text(
            'From ₹${ctAmount(controller.totalCollection)} collected',
            style: CT.body(12),
          ),
        ],
      ),
    ],
  );

  Widget _createButton() => BounceTap(
    onTap: controller.createTournament,
    child: Container(
      height: 52,
      color: CT.primary,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.add_rounded, color: Colors.black, size: 21),
          const SizedBox(width: 8),
          Text(
            'Create a tournament',
            style: CT.headline(14, color: Colors.black),
          ),
        ],
      ),
    ),
  );

  Widget _activityOverview() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('AT A GLANCE', style: CT.mono(10)),
      const SizedBox(height: 14),
      Row(
        children: [
          _metric('${controller.activeTournaments}', 'ACTIVE'),
          _metricDivider(),
          _metric('${controller.totalPlayers}', 'PLAYERS'),
          _metricDivider(),
          _metric('${controller.hosted.length}', 'HOSTED'),
        ],
      ),
      const SizedBox(height: 18),
      Container(height: 1, color: CT.outline),
    ],
  );

  Widget _metric(String value, String label) => Expanded(
    child: Column(
      children: [
        Text(value, style: CT.headline(21)),
        const SizedBox(height: 3),
        Text(label, style: CT.mono(8)),
      ],
    ),
  );

  Widget _metricDivider() => Container(width: 1, height: 34, color: CT.outline);

  Widget _sectionHeader({
    required String title,
    String? action,
    VoidCallback? onTap,
  }) => Row(
    children: [
      Expanded(child: Text(title, style: CT.headline(18))),
      if (action != null)
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(foregroundColor: CT.primaryBright),
          child: Text(action),
        ),
    ],
  );

  Widget _tournamentRow(Tournament tournament) {
    final status = ctStatus(tournament.status);
    final currency = ctCurrency(tournament.currency);
    final capacity = tournament.maxPlayers <= 0
        ? 0.0
        : (tournament.registeredPlayersCount / tournament.maxPlayers).clamp(
            0.0,
            1.0,
          );
    return BounceTap(
      onTap: () => controller.openTournament(tournament),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: CT.outline)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 3, height: 38, color: status.color),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tournament.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CT.headline(15),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${tournament.game}  ·  ${_dateLabel(tournament.tournamentStartAt)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CT.body(11.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(status.label, style: CT.mono(8, color: status.color)),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ClipRect(
                    child: LinearProgressIndicator(
                      value: capacity,
                      minHeight: 3,
                      backgroundColor: CT.outline,
                      valueColor: const AlwaysStoppedAnimation(CT.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${tournament.registeredPlayersCount}/${tournament.maxPlayers} players',
                  style: CT.mono(8),
                ),
              ],
            ),
            const SizedBox(height: 11),
            Row(
              children: [
                Text(
                  '$currency${ctAmount(tournament.totalCollection)} collected',
                  style: CT.body(11.5, color: CT.onSurface),
                ),
                const Spacer(),
                Text(
                  '$currency${ctAmount(tournament.organizerCommissionAmount)} earned',
                  style: CT.body(11.5, color: CT.successBright),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: CT.muted,
                  size: 18,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _dateLabel(DateTime? date) {
    if (date == null) return 'Date pending';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final local = date.toLocal();
    return '${local.day} ${months[local.month - 1]}';
  }

  Widget _emptyTournaments() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 26),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.emoji_events_outlined, color: CT.muted, size: 28),
        const SizedBox(height: 10),
        Text('No tournaments yet', style: CT.headline(15)),
        const SizedBox(height: 4),
        Text(
          'Create your first tournament and start building your community.',
          style: CT.body(12),
        ),
      ],
    ),
  );

  Widget _performance() {
    final host = controller.verification.value!;
    return Column(
      children: [
        _performanceMetric(
          label: 'Average rating',
          value: host.averageRating.toStringAsFixed(1),
          progress: (host.averageRating / 5).clamp(0.0, 1.0),
        ),
        _performanceMetric(
          label: 'Completion rate',
          value: _percent(host.completionRate),
          progress: _ratio(host.completionRate),
        ),
        _performanceMetric(
          label: 'On-time payouts',
          value: _percent(host.onTimePayoutRate),
          progress: _ratio(host.onTimePayoutRate),
        ),
        _performanceMetric(
          label: 'Dispute rate',
          value: _percent(host.disputeRate),
          progress: _ratio(host.disputeRate),
          positive: false,
          last: true,
        ),
      ],
    );
  }

  Widget _performanceMetric({
    required String label,
    required String value,
    required double progress,
    bool positive = true,
    bool last = false,
  }) => Padding(
    padding: EdgeInsets.only(bottom: last ? 0 : 18),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: CT.body(13))),
            Text(value, style: CT.headline(13)),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          minHeight: 3,
          backgroundColor: CT.outline,
          valueColor: AlwaysStoppedAnimation(
            positive ? CT.primary : CT.secondary,
          ),
        ),
      ],
    ),
  );

  double _ratio(double value) =>
      (value <= 1 ? value : value / 100).clamp(0.0, 1.0);

  String _percent(double value) {
    final normalized = value <= 1 ? value * 100 : value;
    return '${normalized.toStringAsFixed(0)}%';
  }

  Widget _errorState() => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_outline_rounded, size: 38, color: CT.muted),
          const SizedBox(height: 14),
          Text(
            controller.error.value!,
            textAlign: TextAlign.center,
            style: CT.body(14),
          ),
          const SizedBox(height: 18),
          TextButton(
            onPressed: controller.verification.value == null
                ? controller.load
                : controller.openOnboarding,
            child: Text(
              controller.verification.value == null
                  ? 'Try again'
                  : 'View verification',
            ),
          ),
        ],
      ),
    ),
  );
}

class _DashboardLoader extends StatelessWidget {
  const _DashboardLoader();

  @override
  Widget build(BuildContext context) {
    return const AppLinearLoader.screen();
  }
}
