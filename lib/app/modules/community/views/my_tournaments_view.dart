import 'package:flutter/material.dart';
import 'package:hash/utils/widgets/loader.dart';
import 'package:get/get.dart';
import 'package:hash/utils/widgets/bounce_tap_widget.dart';

import '../controllers/my_tournaments_controller.dart';
import '../models/tournament.dart';
import 'community_theme.dart';
import 'tournaments_view.dart' show ctCurrency, ctAmount, ctStatus;

/// "My Tournaments" — Joined / Hosted, from GET /me/tournaments.
class MyTournamentsView extends GetView<MyTournamentsController> {
  const MyTournamentsView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: CT.bg,
        appBar: AppBar(
          backgroundColor: CT.bg,
          elevation: 0,
          iconTheme: const IconThemeData(color: CT.onSurface),
          title: Text('My Tournaments', style: CT.headline(18)),
          bottom: TabBar(
            indicatorColor: CT.primary,
            labelColor: CT.primary,
            unselectedLabelColor: CT.muted,
            labelStyle: CT.body(14, w: FontWeight.w700),
            tabs: const [
              Tab(text: 'Joined'),
              Tab(text: 'Hosted'),
            ],
          ),
        ),
        body: Obx(() {
          if (controller.loading.value) {
            return const AppLinearLoader.screen();
          }
          if (controller.error.value != null) {
            return _errorState(controller.error.value!);
          }
          return TabBarView(
            children: [
              _list(
                controller.joined,
                'You haven\'t joined any tournaments yet.',
              ),
              _list(
                controller.hosted,
                'You haven\'t hosted any tournaments yet.',
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _errorState(String msg) {
    return ListView(
      children: [
        const SizedBox(height: 140),
        const Icon(Icons.emoji_events_outlined, size: 44, color: CT.muted),
        const SizedBox(height: 14),
        Center(child: Text(msg, style: CT.body(15))),
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
    );
  }

  Widget _list(RxList<TournamentListItem> source, String emptyMsg) {
    return Obx(() {
      final items = source;
      if (items.isEmpty) {
        return RefreshIndicator(
          color: CT.primary,
          backgroundColor: CT.surface,
          onRefresh: controller.load,
          child: ListView(
            children: [
              const SizedBox(height: 140),
              Center(child: Text(emptyMsg, style: CT.body(15))),
            ],
          ),
        );
      }
      return RefreshIndicator(
        color: CT.primary,
        backgroundColor: CT.surface,
        onRefresh: controller.load,
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) => _row(items[i]),
        ),
      );
    });
  }

  Widget _row(TournamentListItem item) {
    final t = item.tournament;
    final st = ctStatus(t.status);
    final sym = ctCurrency(t.currency);
    final reg = item.registration;
    return BounceTap(
      onTap: () => controller.openDetail(t),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: CT.card(),
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
                  child: Text(st.label, style: CT.mono(9, color: st.color)),
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
                ),
                const SizedBox(width: 20),
                _stat('PRIZE POOL', '$sym${ctAmount(t.prizePool)}'),
                const Spacer(),
                _stat('PLAYERS', '${t.registeredPlayersCount}/${t.maxPlayers}'),
              ],
            ),
            if (reg != null) ...[
              const SizedBox(height: 12),
              _regBadge(reg.status),
            ],
          ],
        ),
      ),
    );
  }

  Widget _regBadge(String status) {
    Color c;
    String label;
    switch (status) {
      case 'confirmed':
        c = CT.success;
        label = 'Confirmed';
        break;
      case 'pending_payment':
        c = const Color(0xFFF5A524);
        label = 'Payment pending';
        break;
      case 'refunded':
        c = CT.secondary;
        label = 'Refunded';
        break;
      case 'cancelled':
        c = CT.muted;
        label = 'Cancelled';
        break;
      default:
        c = CT.muted;
        label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: c.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: c.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.confirmation_number_outlined, size: 13, color: c),
          const SizedBox(width: 6),
          Text(
            'Registration: $label',
            style: CT.body(12, color: c, w: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: CT.mono(9)),
      const SizedBox(height: 2),
      Text(value, style: CT.headline(14)),
    ],
  );
}
