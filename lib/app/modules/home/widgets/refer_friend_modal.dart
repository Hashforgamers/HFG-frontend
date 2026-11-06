import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/home/widgets/home_design.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui';

import '../../../../utils/widgets/loader.dart';

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

/// Compact home "Refer a friend" card: one headline row with the player's
/// stats, then their code (tap to copy) beside the Refer Now button.
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

  static const _yellow = Color(0xFFFFD60A);
  static const _secondary = Color(0x99EBEBF5);
  static const _fill = Color(0x29787880);

  static TextStyle _text(double size, Color color, {FontWeight? weight}) =>
      GoogleFonts.inter(
        color: color,
        fontSize: size,
        fontWeight: weight ?? FontWeight.w400,
        letterSpacing: size >= 15 ? -0.3 : -0.1,
        height: 1.25,
      );

  @override
  Widget build(BuildContext context) {
    final trimmed = code?.trim() ?? '';
    // brand-gradient rim, as on the other home cards
    return Container(
      padding: const EdgeInsets.all(HomeFrostCard.rim),
      decoration: ShapeDecoration(
        shape: const ContinuousRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(44)),
        ),
        gradient: HomeTokens.brandRim(0.7),
      ),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: const ShapeDecoration(
          shape: ContinuousRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(42)),
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF26241A), Color(0xFF161618)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -70,
              right: -50,
              child: IgnorePointer(
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _yellow.withValues(alpha: 0.16),
                        _yellow.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        padding: const EdgeInsets.all(8),
                        decoration: ShapeDecoration(
                          shape: const ContinuousRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(22)),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              _yellow.withValues(alpha: 0.34),
                              _yellow.withValues(alpha: 0.10),
                            ],
                          ),
                        ),
                        child: Image.asset(
                          'assets/hash_coin.png',
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.monetization_on_rounded,
                            color: _yellow,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Invite your squad',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _text(
                                17,
                                Colors.white,
                                weight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'You both earn Hash Coins when they join',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _text(12.5, _secondary),
                            ),
                          ],
                        ),
                      ),
                      if (friends > 0 || coins > 0) ...[
                        const SizedBox(width: 8),
                        _statChip(),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (trimmed.isNotEmpty) ...[
                        _CodeChip(code: trimmed),
                        const SizedBox(width: 8),
                      ],
                      Expanded(child: _referButton()),
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

  /// Friends joined and coins earned, stacked small so the headline keeps
  /// its width.
  Widget _statChip() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: const ShapeDecoration(
      shape: ContinuousRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(22)),
      ),
      color: _fill,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text('+$coins', style: _text(15, _yellow, weight: FontWeight.w800)),
        Text(
          friends == 1 ? '1 friend' : '$friends friends',
          style: _text(10.5, _secondary, weight: FontWeight.w500),
        ),
      ],
    ),
  );

  Widget _referButton() => Semantics(
    button: true,
    label: 'Refer now',
    excludeSemantics: true,
    child: GestureDetector(
      onTap: onReferNow == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              onReferNow!();
            },
      child: Container(
        height: 44,
        decoration: ShapeDecoration(
          shape: const StadiumBorder(),
          gradient: HomeTokens.brandGradient,
          shadows: [
            BoxShadow(
              color: HomeTokens.pink.withValues(alpha: 0.35),
              blurRadius: 14,
              spreadRadius: -4,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.ios_share_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 6),
            Text(
              'Refer Now',
              style: _text(15, Colors.white, weight: FontWeight.w700),
            ),
          ],
        ),
      ),
    ),
  );
}

/// The player's code as a tappable chip; tapping copies it.
class _CodeChip extends StatelessWidget {
  const _CodeChip({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Copy referral code $code',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () async {
          await Clipboard.setData(ClipboardData(text: code));
          HapticFeedback.selectionClick();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Referral code copied')),
            );
          }
        },
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: ShapeDecoration(
            shape: StadiumBorder(
              side: BorderSide(
                color: Colors.white.withValues(alpha: 0.22),
                style: BorderStyle.solid,
              ),
            ),
            color: _ReferGameCard._fill,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                code,
                style: _ReferGameCard._text(
                  15,
                  Colors.white,
                  weight: FontWeight.w700,
                ).copyWith(letterSpacing: 1.5),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.copy_rounded, size: 15, color: HomeTokens.coral),
            ],
          ),
        ),
      ),
    );
  }
}
