import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui';

import '../../../../utils/widgets/loader.dart';

class ReferFriendModal extends StatelessWidget {
  final VoidCallback? onReferNow;
  final VoidCallback? onNoThanks;
  final bool isDialog;

  const ReferFriendModal({
    super.key,
    this.onReferNow,
    this.onNoThanks,
    this.isDialog = true,
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
    final card = _buildCard(context);

    if (!isDialog) return card;

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
        border: Border.all(color: _kAccent.withValues(alpha: 0.55), width: 1.6),
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
          Text(
            'Invite Friends, Earn Faster',
            style: GoogleFonts.orbitron(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
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
