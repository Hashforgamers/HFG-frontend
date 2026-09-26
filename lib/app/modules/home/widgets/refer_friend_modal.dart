import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui';

import '../../../../utils/widgets/loader.dart';
import 'package:hash/utils/widgets/game_button.dart';
import 'package:hash/utils/widgets/game_panel.dart';

class ReferFriendModal extends StatelessWidget {
  final VoidCallback? onReferNow;
  final VoidCallback? onNoThanks;
  final bool isDialog;

  /// Shown on the inline (home) card when available.
  final String? referralCode;
  final int? referralCount;
  final int? referralRewards;

  const ReferFriendModal({
    super.key,
    this.onReferNow,
    this.onNoThanks,
    this.isDialog = true,
    this.referralCode,
    this.referralCount,
    this.referralRewards,
  });

  static const _kBorderRadius = 20.0;
  static const _kInnerRadius = 18.0;
  static const _kAccent = Color(0xff00DC00);
  static const _kPrimaryFill = Color(0xff00DC00);
  static const _kDeep = Color(0xFF081108);
  static const _kPanel = Color(0xFF102114);
  static const _kBgUrl =
      'https://res.cloudinary.com/dxjjigepf/image/upload/v1754671561/pop_ui_ohybpb.png';

  double _cardHeight(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    if (isDialog) return screenHeight * 0.38;
    return (screenHeight * 0.31).clamp(220.0, 270.0).toDouble();
  }

  ButtonStyle _primaryBtnStyle(bool dialog) => OutlinedButton.styleFrom(
    backgroundColor: _kPrimaryFill.withValues(alpha: 0.8),
    foregroundColor: Colors.white,
    side: const BorderSide(color: Colors.white, width: 2),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(dialog ? 25 : 22),
    ),
    padding: EdgeInsets.zero,
    elevation: 0,
  );

  ButtonStyle _outlineBtnStyle(bool dialog) => OutlinedButton.styleFrom(
    backgroundColor: _kPanel.withValues(alpha: 0.7),
    foregroundColor: Colors.white,
    side: BorderSide(color: _kAccent.withValues(alpha: 0.55), width: 1.3),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(dialog ? 25 : 22),
    ),
    padding: EdgeInsets.zero,
  );

  @override
  Widget build(BuildContext context) {
    if (!isDialog) {
      return _ReferGameCard(
        code: referralCode,
        friends: referralCount ?? 0,
        coins: referralRewards ?? 0,
        onReferNow: onReferNow,
      );
    }
    final card = _buildCard(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: card,
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    final h = _cardHeight(context);

    return Container(
      width: double.infinity,
      height: h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_kBorderRadius),
        boxShadow: [
          BoxShadow(
            color: _kAccent.withValues(alpha: 0.22),
            blurRadius: 18,
            spreadRadius: 1,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_kInnerRadius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildBackgroundImage(),
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5),
              child: Container(color: Colors.black.withValues(alpha: 0.08)),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _kDeep.withValues(alpha: 0.50),
                    Colors.black.withValues(alpha: 0.62),
                    _kPanel.withValues(alpha: 0.70),
                  ],
                ),
              ),
            ),
            _buildContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundImage() {
    return CachedNetworkImage(
      imageUrl: _kBgUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: const Color(0xFF0E130F),
        alignment: Alignment.center,
        child: const AppLinearLoader(),
      ),
      errorWidget: (context, url, error) => Container(
        color: const Color(0xFF0E130F),
        alignment: Alignment.center,
        child: Icon(
          Icons.image_not_supported_rounded,
          color: _kAccent.withValues(alpha: 0.9),
          size: 34,
        ),
      ),
    );
  }

  Widget _buildContent() {
    return isDialog ? _buildDialogContent() : _buildInlineContent();
  }

  Widget _buildDialogContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Invite Your Squad',
            style: GoogleFonts.orbitron(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Earn ',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(
                  text: 'Hash Coins',
                  style: GoogleFonts.inter(
                    color: _kAccent,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextSpan(
                  text: ' on every signup',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: const [
              _BenefitPill(icon: Icons.verified_user_rounded, label: 'Trusted'),
              _BenefitPill(icon: Icons.bolt_rounded, label: 'Instant Share'),
              _BenefitPill(
                icon: Icons.monetization_on_rounded,
                label: 'Rewards',
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildButtonsRow(),
        ],
      ),
    );
  }

  Widget _buildInlineContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _kAccent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: _kAccent.withValues(alpha: 0.35)),
            ),
            child: Text(
              'REFERRAL BOOST',
              style: GoogleFonts.orbitron(
                color: _kAccent,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Invite Friends, ',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextSpan(
                  text: 'Earn Faster',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF00DC00),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Share your referral code. Both players unlock rewards once they join and start playing.',
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.86),
              fontSize: 12.8,
              height: 1.3,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 28,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              children: const [
                _BenefitPill(icon: Icons.group_add_rounded, label: 'Invite'),
                SizedBox(width: 8),
                _BenefitPill(icon: Icons.login_rounded, label: 'Signup'),
                SizedBox(width: 8),
                _BenefitPill(
                  icon: Icons.wallet_giftcard_rounded,
                  label: 'Earn',
                ),
              ],
            ),
          ),
          const Spacer(),
          _buildButtonsRow(),
        ],
      ),
    );
  }

  Widget _buildButtonsRow() {
    final btnHeight = isDialog ? 45.0 : 44.0;

    if (!isDialog) {
      return SizedBox(
        width: double.infinity,
        height: btnHeight,
        child: OutlinedButton(
          style: _primaryBtnStyle(isDialog),
          onPressed: onReferNow == null
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  onReferNow!();
                },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.ios_share_rounded,
                size: 18,
                color: Colors.black,
              ),
              const SizedBox(width: 8),
              Text(
                'Refer Now',
                style: GoogleFonts.inter(
                  color: Colors.black,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: btnHeight,
            child: OutlinedButton(
              style: _primaryBtnStyle(isDialog),
              onPressed: onReferNow == null
                  ? null
                  : () {
                      HapticFeedback.selectionClick();
                      onReferNow!();
                    },
              child: Text(
                'Refer Now',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: btnHeight,
            child: OutlinedButton(
              style: _outlineBtnStyle(isDialog),
              onPressed: onNoThanks == null
                  ? null
                  : () {
                      HapticFeedback.selectionClick();
                      onNoThanks!();
                    },
              child: Text(
                'No, thanks',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BenefitPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _BenefitPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    const accent = ReferFriendModal._kAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: accent),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// Entry Points
void showReferFriendModal(
  BuildContext context, {
  VoidCallback? onReferNow,
  VoidCallback? onNoThanks,
}) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) => ReferFriendModal(
      onReferNow: onReferNow,
      onNoThanks: onNoThanks,
      isDialog: true,
    ),
  );
}

Widget getReferFriendWidget({
  VoidCallback? onReferNow,
  VoidCallback? onNoThanks,
}) {
  return ReferFriendModal(
    onReferNow: onReferNow,
    onNoThanks: onNoThanks,
    isDialog: false,
  );
}

/// Home "Refer a friend" card in the chunky game style: steps, the player's
/// code with copy, their referral stats and a Refer button.
class _ReferGameCard extends StatelessWidget {
  const _ReferGameCard({
    required this.code,
    required this.friends,
    required this.coins,
    required this.onReferNow,
  });

  final String? code;
  final int friends;
  final int coins;
  final VoidCallback? onReferNow;

  @override
  Widget build(BuildContext context) {
    final hasCode = code != null && code!.trim().isNotEmpty;
    return GamePanel(
      onTap: onReferNow,
      headerColors: GameColors.green,
      headerHeight: 70,
      header: Row(
        children: [
          Image.asset(
            'assets/hash_coin.png',
            width: 40,
            height: 40,
            errorBuilder: (_, _, _) =>
                const Text('🪙', style: TextStyle(fontSize: 30)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const GameText('INVITE YOUR SQUAD', size: 21),
                Text(
                  'You both earn Hash Coins',
                  style: gameFont(
                    12.5,
                    GameColors.outline.withValues(alpha: 0.72),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GameTray(
            padding: const EdgeInsets.fromLTRB(6, 10, 6, 8),
            child: Row(
              children: [
                _step('1', 'Share\nyour code'),
                _arrow(),
                _step('2', 'Friend\nsigns up'),
                _arrow(),
                _step('3', 'Both get\ncoins', last: true),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _stat('$friends', 'Friends joined', Colors.white),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _stat('$coins', 'Coins earned', GameColors.yellow.$1),
              ),
            ],
          ),
          if (hasCode) ...[
            const SizedBox(height: 10),
            _CodeRow(code: code!.trim()),
          ],
          const SizedBox(height: 12),
          GameButton(
            label: 'Refer Now',
            icon: Icons.ios_share_rounded,
            tone: GameButtonTone.green,
            height: 52,
            onPressed: onReferNow == null
                ? null
                : () {
                    HapticFeedback.selectionClick();
                    onReferNow!();
                  },
          ),
        ],
      ),
    );
  }

  Widget _step(String n, String label, {bool last = false}) => Expanded(
    child: Column(
      children: [
        Container(
          width: 34,
          height: 34,
          padding: const EdgeInsets.all(2.5),
          decoration: const BoxDecoration(
            color: GameColors.outline,
            shape: BoxShape.circle,
          ),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: last
                    ? [GameColors.yellow.$1, GameColors.yellow.$2]
                    : [GameColors.green.$1, GameColors.green.$2],
              ),
            ),
            child: GameText(n, size: 16),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          textAlign: TextAlign.center,
          style: gameFont(12, Colors.white),
        ),
      ],
    ),
  );

  Widget _arrow() => const Padding(
    padding: EdgeInsets.only(bottom: 26),
    child: Icon(Icons.chevron_right_rounded, color: GameColors.soft, size: 20),
  );

  Widget _stat(String value, String label, Color color) => GameTray(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Column(
      children: [
        GameText(value, size: 20, color: color),
        Text(label, style: gameFont(11.5, GameColors.soft)),
      ],
    ),
  );
}

class _CodeRow extends StatelessWidget {
  const _CodeRow({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
      decoration: BoxDecoration(
        color: GameColors.socket,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GameColors.trayEdge, width: 2),
      ),
      child: Row(
        children: [
          Text('CODE', style: gameFont(12, GameColors.soft)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              code,
              overflow: TextOverflow.ellipsis,
              style: gameFont(20, Colors.white).copyWith(letterSpacing: 2),
            ),
          ),
          SizedBox(
            width: 88,
            child: GameButton(
              label: 'Copy',
              tone: GameButtonTone.purple,
              height: 38,
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: code));
                HapticFeedback.selectionClick();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Referral code copied')),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
