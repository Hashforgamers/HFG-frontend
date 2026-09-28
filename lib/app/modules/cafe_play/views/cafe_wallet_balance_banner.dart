import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/cafe_play/views/cafe_checkout_sheet.dart';
import 'package:hash/app/modules/home/widgets/home_design.dart';

/// TODO(cafe-wallet): replace with the gamer cafe-balance API once its
/// contract is shared. Placeholder paise value for UI review only.
const int kDummyCafeWalletBalancePaise = 25000;

/// Balance at this cafe only (not Hash Wallet), shown near the top of the
/// cafe detail screen for PC cafes. Gold marks it as money, matching home;
/// the green action opens the PC QR scanner.
class CafeWalletBalanceBanner extends StatelessWidget {
  const CafeWalletBalanceBanner({
    super.key,
    required this.balancePaise,
    required this.onScan,
  });

  final int balancePaise;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    return HomeCard(
      accent: HomeTokens.gold,
      padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
      onTap: onScan,
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
                  cafeMoney(balancePaise),
                  style: HomeTokens.title(
                    22,
                  ).copyWith(color: HomeTokens.goldLight),
                ),
                const SizedBox(height: 2),
                Text(
                  'Only usable at this cafe',
                  style: HomeTokens.body(HomeTokens.textTertiary, size: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _ScanPill(onTap: onScan),
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
