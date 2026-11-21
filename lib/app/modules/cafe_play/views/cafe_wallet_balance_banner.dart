import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/cafe_play/data/cafe_play_api.dart';
import 'package:hash/app/modules/cafe_play/models/cafe_play_models.dart';
import 'package:hash/app/modules/cafe_play/views/cafe_checkout_sheet.dart';
import 'package:hash/app/modules/cafe_play/views/cafe_wallet_view.dart';
import 'package:hash/app/modules/home/widgets/home_design.dart';

/// Balance at this cafe only (not Hash Wallet), shown near the top of the
/// cafe detail screen for PC cafes. Gold marks it as money, matching home;
/// the card opens the cafe wallet history, the green action the PC scanner.
class CafeWalletBalanceBanner extends StatefulWidget {
  const CafeWalletBalanceBanner({
    super.key,
    required this.vendorId,
    required this.cafeName,
  });

  final int vendorId;
  final String cafeName;

  @override
  State<CafeWalletBalanceBanner> createState() =>
      _CafeWalletBalanceBannerState();
}

class _CafeWalletBalanceBannerState extends State<CafeWalletBalanceBanner>
    with WidgetsBindingObserver {
  CafeWallet? _wallet;
  bool _failed = false;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  Future<void> _load() async {
    final gen = ++_generation;
    try {
      final wallet = await CafePlayApi.instance.getWallet(widget.vendorId);
      if (!mounted || gen != _generation) return;
      setState(() {
        _wallet = wallet;
        _failed = false;
      });
    } on CafePlayException {
      if (!mounted || gen != _generation) return;
      setState(() => _failed = true);
    }
  }

  Future<void> _scan() async {
    await startCafeScanFlow(context);
    if (mounted) _load();
  }

  Future<void> _openWallet() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CafeWalletView(
          vendorId: widget.vendorId,
          cafeName: widget.cafeName,
        ),
      ),
    );
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final wallet = _wallet;
    final String amount;
    final String caption;
    if (wallet != null) {
      amount = cafeMoney(wallet.availableBalance);
      caption = wallet.reserved != 0
          ? 'Pending reservation ${cafeMoney(wallet.reserved)}'
          : 'Top up at this cafe\'s reception';
    } else if (_failed) {
      // A failed read reads as a quiet status, not a giant dash.
      amount = 'Couldn\'t load balance';
      caption = 'Tap to retry';
    } else {
      amount = '…';
      caption = 'Only usable at this cafe';
    }

    return HomeCard(
      accent: HomeTokens.gold,
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      onTap: wallet == null && _failed ? _load : _openWallet,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: HomeTokens.gold.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: HomeTokens.gold.withValues(alpha: 0.3)),
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: HomeTokens.gold,
              size: 19,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    const HomeEyebrow('Cafe wallet', color: HomeTokens.gold),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        amount,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: wallet == null && _failed
                            ? HomeTokens.title(
                                13,
                              ).copyWith(color: Colors.white70)
                            : HomeTokens.title(
                                17,
                              ).copyWith(color: HomeTokens.goldLight),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  caption,
                  style: HomeTokens.body(HomeTokens.textTertiary, size: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _ScanPill(onTap: _scan),
        ],
      ),
    );
  }
}

class _ScanPill extends StatelessWidget {
  const _ScanPill({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Scan PC QR to play',
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: HomeTokens.green.withValues(alpha: 0.12),
          border: Border.all(color: HomeTokens.green.withValues(alpha: 0.45)),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: HomeTokens.green,
                    size: 17,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Scan PC',
                    style: GoogleFonts.inter(
                      color: HomeTokens.green,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
