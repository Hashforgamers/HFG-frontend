import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hash/app/modules/hash_coin/cubit/hash_coin_cubit.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service_locator.dart';
import 'package:hash/core/utils/app_logger.dart';
import 'package:hash/core/utils/haptics.dart';
import 'package:hash/utils/widgets/game_button.dart';
import 'package:hash/utils/widgets/game_panel.dart';

import 'cosmetics.dart';

/// One tab of a [CosmeticShopScreen]: a slot, its catalog, and how to draw a
/// preview of an item.
class CosmeticTab {
  const CosmeticTab({
    required this.label,
    required this.slot,
    required this.items,
    required this.preview,
  });

  final String label;
  final String slot;
  final List<Cosmetic<Object?>> items;
  final Widget Function(Cosmetic<Object?> item) preview;
}

/// A mini game's theme shop: buy cosmetics with HashCoins and pick which to
/// use, grouped by rarity.
class CosmeticShopScreen extends StatefulWidget {
  const CosmeticShopScreen({
    super.key,
    required this.title,
    required this.tabs,
    this.store,
    this.balance,
  });

  final String title;
  final List<CosmeticTab> tabs;

  /// Defaults to the shared store.
  final CosmeticStore? store;

  /// Fixed HashCoin balance for tests; otherwise fetched.
  @visibleForTesting
  final int? balance;

  @override
  State<CosmeticShopScreen> createState() => _CosmeticShopScreenState();
}

class _CosmeticShopScreenState extends State<CosmeticShopScreen> {
  late final CosmeticStore _store = widget.store ?? CosmeticStore.instance;
  int? _balance;
  String? _buying;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _balance = widget.balance;
    _store.load();
    if (widget.balance == null) _loadBalance();
  }

  Future<void> _loadBalance() async {
    try {
      final coins = await locator<RemoteRepoInterface>().getHashCoin();
      if (mounted) setState(() => _balance = coins);
    } catch (e) {
      if (kDebugMode) AppLogger.d('Cosmetic shop balance load failed: $e');
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _buy(CosmeticTab tab, Cosmetic<Object?> item) async {
    if (_buying != null) return;
    final balance = _balance;
    if (balance != null && balance < item.price) {
      _snack(
        'You need ${item.price - balance} more HashCoins for ${item.name}.',
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: GamePanel(
            headerColors: GameColors.yellow,
            header: Center(
              child: FittedBox(child: GameText('BUY ${item.name}?', size: 24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GameTray(
                  child: Column(
                    children: [
                      tab.preview(item),
                      const SizedBox(height: 10),
                      Text(
                        '${item.price} HashCoins',
                        style: gameFont(20, GameColors.yellow.$1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: GameButton(
                        label: 'Cancel',
                        tone: GameButtonTone.grey,
                        height: 48,
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GameButton(
                        label: 'Buy',
                        height: 48,
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _buying = item.id);
    try {
      final left = await _store.buy(tab.slot, item);
      Haptics.medium();
      if (!mounted) return;
      setState(() => _balance = left);
      try {
        BlocProvider.of<HashCoinCubit>(context).getHashCoin();
      } catch (_) {
        // ignore if cubit context is unavailable
      }
      _snack('${item.name} unlocked and equipped!');
    } catch (e) {
      if (kDebugMode) AppLogger.d('Cosmetic purchase failed: $e');
      if (mounted) _snack('Couldn’t buy ${item.name}. No coins were spent.');
    } finally {
      if (mounted) setState(() => _buying = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tab = widget.tabs[_tab];
    return Scaffold(
      backgroundColor: GameColors.bgBottom,
      body: Stack(
        children: [
          const GameBackground(),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
                  child: Row(
                    children: [
                      GameIconButton(
                        icon: Icons.arrow_back_rounded,
                        tooltip: 'Back',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: GameText(widget.title, size: 26),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GameBadge(label: '🪙 ${_balance ?? '…'}'),
                    ],
                  ),
                ),
                if (widget.tabs.length > 1)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
                    child: Row(
                      children: [
                        for (final (i, t) in widget.tabs.indexed) ...[
                          if (i > 0) const SizedBox(width: 8),
                          Expanded(
                            child: GameButton(
                              label: t.label,
                              tone: _tab == i
                                  ? GameButtonTone.purple
                                  : GameButtonTone.grey,
                              height: 44,
                              onPressed: () => setState(() => _tab = i),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                Expanded(
                  child: ListenableBuilder(
                    listenable: _store,
                    builder: (context, _) {
                      final rows = <Widget>[
                        for (final rarity in CosmeticRarity.values)
                          if (tab.items.any((i) => i.rarity == rarity)) ...[
                            _heading(rarity),
                            for (final item in tab.items)
                              if (item.rarity == rarity) _card(tab, item),
                          ],
                      ];
                      return ListView.separated(
                        key: ValueKey(_tab),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: rows.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, i) => rows[i],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heading(CosmeticRarity rarity) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Row(
      children: [
        GameText(rarity.label, size: 22, color: rarity.color),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 3,
            decoration: BoxDecoration(
              color: rarity.color.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _card(CosmeticTab tab, Cosmetic<Object?> item) {
    final owned = _store.owns(item.id);
    final equipped = _store.selected(tab.slot) == item.id;
    final busy = _buying == item.id;
    return GamePanel(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GameText(item.name, size: 20),
                    Text(item.tagline, style: gameFont(13, GameColors.soft)),
                  ],
                ),
              ),
              if (equipped)
                GameBadge(label: 'EQUIPPED', dot: GameColors.green.$1)
              else if (owned)
                const GameBadge(label: 'OWNED'),
            ],
          ),
          const SizedBox(height: 10),
          GameTray(child: Center(child: tab.preview(item))),
          const SizedBox(height: 10),
          if (equipped)
            const GameButton(
              label: 'Equipped',
              icon: Icons.check_rounded,
              tone: GameButtonTone.grey,
              height: 46,
            )
          else if (owned)
            GameButton(
              label: 'Equip',
              height: 46,
              onPressed: () {
                Haptics.selection();
                _store.equip(tab.slot, item.id);
              },
            )
          else
            GameButton(
              label: busy ? 'Buying…' : 'Buy · ${item.price}',
              icon: Icons.shopping_bag_rounded,
              tone: busy ? GameButtonTone.grey : GameButtonTone.yellow,
              height: 46,
              onPressed: busy ? null : () => _buy(tab, item),
            ),
        ],
      ),
    );
  }
}
