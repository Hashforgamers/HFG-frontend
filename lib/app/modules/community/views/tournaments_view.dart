import 'package:flutter/material.dart';
import 'package:hash/utils/widgets/loader.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:hash/utils/widgets/bounce_tap_widget.dart';

import '../../../routes/app_routes.dart';
import '../controllers/tournaments_controller.dart';
import '../models/tournament.dart';
import 'community_theme.dart';

/// Community tournament discovery — GET /tournaments.
class TournamentsView extends GetView<TournamentsController> {
  const TournamentsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CT.bg,
      appBar: AppBar(
        backgroundColor: CT.bg,
        elevation: 0,
        iconTheme: const IconThemeData(color: CT.onSurface),
        title: Text('Community Tournaments', style: CT.headline(18)),
        actions: [
          IconButton(
            tooltip: 'My tournaments',
            onPressed: () => Get.toNamed(AppRoutes.MY_TOURNAMENTS),
            icon: const Icon(
              Icons.emoji_events_rounded,
              color: CT.onSurface,
              size: 20,
            ),
          ),
          TextButton.icon(
            onPressed: () => Get.toNamed(AppRoutes.HOST_ONBOARDING),
            icon: SvgPicture.asset(
              'assets/verified_badge.svg',
              width: 18,
              height: 18,
            ),
            label: Text(
              'Host',
              style: CT.body(13, color: CT.primary, w: FontWeight.w700),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _searchBar(),
          _tabs(),
          Expanded(
            child: Obx(() {
              if (controller.loading.value) {
                return const AppLinearLoader.screen();
              }
              if (controller.error.value != null && controller.items.isEmpty) {
                return _empty(controller.error.value!, retry: true);
              }
              if (controller.items.isEmpty) {
                return _empty('No tournaments here yet.');
              }
              return RefreshIndicator(
                color: CT.primary,
                backgroundColor: CT.surface,
                onRefresh: controller.load,
                child: NotificationListener<ScrollNotification>(
                  onNotification: (n) {
                    if (n.metrics.pixels >= n.metrics.maxScrollExtent - 300) {
                      controller.loadMore();
                    }
                    return false;
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: controller.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _TournamentCard(
                      t: controller.items[i],
                      onTap: () => controller.openDetail(controller.items[i]),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: TextField(
        style: CT.body(15, color: CT.onSurface),
        cursorColor: CT.primary,
        textInputAction: TextInputAction.search,
        onSubmitted: controller.setSearch,
        decoration: InputDecoration(
          hintText: 'Search games, titles…',
          hintStyle: CT.body(15, color: CT.muted),
          prefixIcon: const Icon(Icons.search_rounded, color: CT.muted),
          filled: true,
          fillColor: CT.surface,
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _tabs() {
    return SizedBox(
      height: 40,
      child: Obx(
        () => ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          children: [
            for (final t in TournamentsController.tabs)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(t[0].toUpperCase() + t.substring(1)),
                  selected: controller.view.value == t,
                  onSelected: (_) => controller.setView(t),
                  labelStyle: CT.body(
                    13,
                    color: controller.view.value == t
                        ? Colors.white
                        : CT.onSurfaceVariant,
                    w: FontWeight.w600,
                  ),
                  backgroundColor: CT.surface,
                  selectedColor: CT.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: controller.view.value == t
                          ? CT.primary
                          : CT.outline,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _empty(String message, {bool retry = false}) {
    return ListView(
      children: [
        const SizedBox(height: 120),
        Icon(Icons.emoji_events_outlined, size: 44, color: CT.muted),
        const SizedBox(height: 14),
        Center(child: Text(message, style: CT.body(15))),
        if (retry) ...[
          const SizedBox(height: 16),
          Center(
            child: OutlinedButton(
              onPressed: controller.load,
              style: OutlinedButton.styleFrom(
                foregroundColor: CT.primary,
                side: const BorderSide(color: CT.primary),
              ),
              child: const Text('Retry'),
            ),
          ),
        ],
      ],
    );
  }
}

String ctCurrency(String code) {
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

String ctAmount(double a) =>
    a == a.roundToDouble() ? a.toStringAsFixed(0) : a.toStringAsFixed(2);

({String label, Color color}) ctStatus(String status) {
  switch (status) {
    case 'registration_open':
      return (label: 'Register', color: CT.success);
    case 'registration_closed':
      return (label: 'Closed', color: CT.muted);
    case 'live':
      return (label: 'Live', color: CT.primary);
    case 'completed':
      return (label: 'Completed', color: CT.secondary);
    case 'cancelled':
      return (label: 'Cancelled', color: CT.error);
    default:
      return (label: status, color: CT.muted);
  }
}

class _TournamentCard extends StatelessWidget {
  final Tournament t;
  final VoidCallback onTap;
  const _TournamentCard({required this.t, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final st = ctStatus(t.status);
    final sym = ctCurrency(t.currency);
    return BounceTap(
      onTap: onTap,
      child: Container(
        decoration: CT.card(),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 120, width: double.infinity, child: _banner()),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          t.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: CT.headline(16),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: st.color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: st.color.withOpacity(0.5)),
                        ),
                        child: Text(
                          st.label,
                          style: CT.mono(9, color: st.color),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(t.game, style: CT.body(12, color: CT.onSurfaceVariant)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _stat(
                        'ENTRY',
                        t.isFree ? 'FREE' : '$sym${ctAmount(t.entryFee)}',
                        t.isFree ? CT.successBright : CT.onSurface,
                      ),
                      const SizedBox(width: 20),
                      _stat(
                        'PRIZE POOL',
                        '$sym${ctAmount(t.prizePool)}',
                        CT.secondary,
                      ),
                      const Spacer(),
                      _stat(
                        'PLAYERS',
                        '${t.registeredPlayersCount}/${t.maxPlayers}',
                        CT.onSurface,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _banner() {
    if (t.bannerUrl != null && t.bannerUrl!.isNotEmpty) {
      return Image.network(
        t.bannerUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _bannerFallback(),
      );
    }
    return _bannerFallback();
  }

  Widget _bannerFallback() => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0B2410), Color(0xFF090909)],
      ),
    ),
    child: Center(
      child: Icon(
        Icons.sports_esports_rounded,
        color: CT.primary.withOpacity(0.5),
        size: 40,
      ),
    ),
  );

  Widget _stat(String label, String value, Color color) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: CT.mono(9)),
      const SizedBox(height: 2),
      Text(value, style: CT.headline(14, color: color)),
    ],
  );
}
