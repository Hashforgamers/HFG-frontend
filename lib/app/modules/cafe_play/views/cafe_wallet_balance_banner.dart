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
      amount = '—';
      caption = 'Balance unavailable. Tap to retry';
    } else {
      amount = '…';
      caption = 'Only usable at this cafe';
    }

    return HomeCard(
      accent: HomeTokens.gold,
      padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
      onTap: wallet == null && _failed ? _load : _openWallet,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: HomeTokens.gold.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: HomeTokens.gold.withValues(alpha: 0.3)),
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: HomeTokens.gold,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const HomeEyebrow('Cafe wallet', color: HomeTokens.gold),
                const SizedBox(height: 4),
                Text(
                  amount,
                  style: HomeTokens.title(
                    22,
                  ).copyWith(color: HomeTokens.goldLight),
                ),
                const SizedBox(height: 2),
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
          gradient: const LinearGradient(
            colors: [HomeTokens.greenBright, HomeTokens.green],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          boxShadow: [
            BoxShadow(
              color: HomeTokens.green.withValues(alpha: 0.3),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: Colors.black,
                    size: 17,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Scan PC',
                    style: GoogleFonts.inter(
                      color: Colors.black,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
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
