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

import '../constants.dart';
import 'ludo_board_theme.dart';
import 'ludo_dice_skin.dart';
import 'ludo_skin.dart';
import 'ludo_skin_store.dart';

/// The Ludo shop: buy pawn skins and board themes with HashCoins and pick
/// which to use.
class LudoSkinsScreen extends StatefulWidget {
  const LudoSkinsScreen({super.key, this.store, this.balance});

  /// Defaults to the shared store.
  final LudoSkinStore? store;

  /// Fixed HashCoin balance for tests; otherwise fetched.
  @visibleForTesting
  final int? balance;

  @override
  State<LudoSkinsScreen> createState() => _LudoSkinsScreenState();
}

class _LudoSkinsScreenState extends State<LudoSkinsScreen> {
  late final LudoSkinStore _store = widget.store ?? LudoSkinStore.instance;
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
      if (kDebugMode) AppLogger.d('Ludo skins balance load failed: $e');
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _buy(LudoShopItem skin) async {
    if (_buying != null) return;
    final balance = _balance;
    if (balance != null && balance < skin.price) {
      _snack(
        'You need ${skin.price - balance} more HashCoins for ${skin.name}.',
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
            header: Center(child: GameText('BUY ${skin.name}?', size: 24)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GameTray(
                  child: Column(
                    children: [
                      _preview(skin, big: true),
                      const SizedBox(height: 10),
                      Text(
                        '${skin.price} HashCoins',
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

    setState(() => _buying = skin.id);
    try {
      final left = await _store.buy(skin);
      Haptics.medium();
      if (!mounted) return;
      setState(() => _balance = left);
      try {
        BlocProvider.of<HashCoinCubit>(context).getHashCoin();
      } catch (_) {
        // ignore if cubit context is unavailable
      }
      _snack('${skin.name} unlocked and equipped!');
    } catch (e) {
      if (kDebugMode) AppLogger.d('Ludo skin purchase failed: $e');
      if (mounted) _snack('Couldn’t buy ${skin.name}. No coins were spent.');
    } finally {
      if (mounted) setState(() => _buying = null);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                      const Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: GameText('LUDO SHOP', size: 26),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GameBadge(label: '🪙 ${_balance ?? '…'}'),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
                  child: Row(
                    children: [
                      for (final (tab, label) in const [
                        (0, 'Tokens'),
                        (1, 'Boards'),
                        (2, 'Dice'),
                      ]) ...[
                        if (tab > 0) const SizedBox(width: 8),
                        Expanded(
                          child: GameButton(
                            label: label,
                            tone: _tab == tab
                                ? GameButtonTone.purple
                                : GameButtonTone.grey,
                            height: 44,
                            onPressed: () => setState(() => _tab = tab),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 2, 18, 4),
                  child: Text(
                    const [
                      '👀 Rivals see your token skin in online matches.',
                      '👀 When you host a match, everyone plays on your board.',
                      '👀 Rivals see your dice whenever you roll.',
                    ][_tab],
                    textAlign: TextAlign.center,
                    style: gameFont(13, GameColors.soft),
                  ),
                ),
                Expanded(
                  child: ListenableBuilder(
                    listenable: _store,
                    builder: (context, _) {
                      final List<LudoShopItem> items = switch (_tab) {
                        1 => LudoBoardTheme.all,
                        2 => LudoDiceSkin.all,
                        _ => LudoSkin.all,
                      };
                      // Grouped under Normal / Premium / Legendary headings.
                      final rows = <Widget>[
                        for (final rarity in LudoRarity.values)
                          if (items.any((i) => i.rarity == rarity)) ...[
                            _heading(rarity),
                            for (final item in items)
                              if (item.rarity == rarity) _card(item),
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

  Widget _preview(LudoShopItem item, {bool big = false}) {
    if (item is LudoSkin) return _pawns(item, big ? 44 : 38);
    if (item is LudoDiceSkin) {
      final side = big ? 56.0 : 50.0;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final value in const [1, 3, 5, 6])
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: SizedBox(
                width: side,
                height: side,
                child: LudoDice(skin: item, value: value),
              ),
            ),
        ],
      );
    }
    final side = big ? 190.0 : 170.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: side,
        height: side,
        child: LudoBoardSurface(theme: item as LudoBoardTheme),
      ),
    );
  }

  /// The skin on one pawn of each seat colour.
  Widget _pawns(LudoSkin skin, double size) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (final color in const [
        LudoColor.green,
        LudoColor.yellow,
        LudoColor.blue,
        LudoColor.red,
      ])
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: SizedBox(
            width: size,
            height: size,
            child: LudoPawn(skin: skin, color: color),
          ),
        ),
    ],
  );

  Widget _heading(LudoRarity rarity) => Padding(
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

  Widget _card(LudoShopItem skin) {
    final owned = _store.owns(skin.id);
    final equipped = _store.isEquipped(skin.id);
    final busy = _buying == skin.id;
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
                    GameText(skin.name, size: 20),
                    Text(skin.tagline, style: gameFont(13, GameColors.soft)),
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
          GameTray(child: Center(child: _preview(skin))),
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
                _store.equip(skin.id);
              },
            )
          else
            GameButton(
              label: busy ? 'Buying…' : 'Buy · ${skin.price}',
              icon: Icons.shopping_bag_rounded,
              tone: busy ? GameButtonTone.grey : GameButtonTone.yellow,
              height: 46,
              loading: busy,
              onPressed: busy ? null : () => _buy(skin),
            ),
        ],
      ),
    );
  }
}
