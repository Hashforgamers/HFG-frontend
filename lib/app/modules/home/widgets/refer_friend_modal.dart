import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
  static const _kAccent = Color(0xFF6DFB60);
  static const _kPrimaryFill = Color(0xff00DC00);
  static const _kBgUrl =
      'https://res.cloudinary.com/dxjjigepf/image/upload/v1754671561/pop_ui_ohybpb.png';

  double _cardHeight(BuildContext context) =>
      MediaQuery.of(context).size.height * 0.30;

  ButtonStyle _primaryBtnStyle(bool dialog) => OutlinedButton.styleFrom(
    backgroundColor: _kPrimaryFill.withOpacity(0.8),
    foregroundColor: Colors.white,
    side: const BorderSide(color: Colors.white, width: 2),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(dialog ? 25 : 22),
    ),
    padding: EdgeInsets.zero,
    splashFactory: InkRipple.splashFactory,
  );

  ButtonStyle _outlineBtnStyle(bool dialog) => OutlinedButton.styleFrom(
    backgroundColor: Colors.transparent,
    foregroundColor: Colors.white,
    side: const BorderSide(color: Colors.white, width: 1.5),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(dialog ? 25 : 22),
    ),
    padding: EdgeInsets.zero,
    splashFactory: InkRipple.splashFactory,
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
        border: Border.all(color: _kAccent.withOpacity(0.5), width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_kInnerRadius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildBackgroundImage(),
            // optional subtle overlay for text legibility
            Container(color: Colors.black.withOpacity(0.08)),
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
      placeholder: (_, __) => Container(
        color: const Color(0xFF1A1A1A),
        alignment: Alignment.center,
        child: const CircularProgressIndicator(color: _kAccent),
      ),
      errorWidget: (_, __, ___) => Container(
        color: const Color(0xFF1A1A1A),
        alignment: Alignment.center,
        child: const Icon(Icons.error, color: Colors.white, size: 50),
      ),
    );
  }

  Widget _buildContent() {
    final titleSize = isDialog ? 24.0 : 20.0;
    final coinsSize = isDialog ? 28.0 : 24.0;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isDialog) const Spacer(),
          Text(
            'Refer to a Friend',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: titleSize,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(children: [
              TextSpan(
                text: 'Earn ',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: coinsSize,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextSpan(
                text: 'Hash',
                style: GoogleFonts.inter(
                  color: _kAccent,
                  fontSize: coinsSize,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextSpan(
                text: ' Coins',
                style: GoogleFonts.inter(
                  color: _kAccent,
                  fontSize: coinsSize,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ]),
            textAlign: TextAlign.center,
          ),
          if (!isDialog) ...[
            const SizedBox(height: 16),
            Text(
              'Share your referral code with friends and earn rewards together!',
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (isDialog) const Spacer() else const SizedBox(height: 12),
          _buildButtonsRow(),
          if (isDialog) const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildButtonsRow() {
    final btnHeight = isDialog ? 50.0 : 45.0;

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
          child: Text(
            'Refer Now',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: isDialog ? 16 : 15,
              fontWeight: FontWeight.w600,
            ),
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
                  fontWeight: FontWeight.w600,
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
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Helpers
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
