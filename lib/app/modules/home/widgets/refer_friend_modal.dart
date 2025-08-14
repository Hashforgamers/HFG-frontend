import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ReferFriendModal extends StatefulWidget {
  final VoidCallback? onReferNow;
  final VoidCallback? onNoThanks;
  final bool isDialog;

  const ReferFriendModal({
    super.key,
    this.onReferNow,
    this.onNoThanks,
    this.isDialog = true,
  });

  @override
  State<ReferFriendModal> createState() => _ReferFriendModalState();
}

class _ReferFriendModalState extends State<ReferFriendModal> {
  @override
  Widget build(BuildContext context) {
    if (widget.isDialog) {
      // Render as dialog
      return Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height * 0.3,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF6DFB60).withValues(alpha: 0.5),
              width: 2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              children: [
                // Background image
                _buildBackgroundImage(),
                // Content
                _buildContent(),
              ],
            ),
          ),
        ),
      );
    } else {
      // Render as widget for home screen
      return Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.3,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF6DFB60).withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              // Background image
              _buildBackgroundImage(),
              // Content
              _buildContent(),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildBackgroundImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: CachedNetworkImage(
        imageUrl:
            'https://res.cloudinary.com/dxjjigepf/image/upload/v1754671561/pop_ui_ohybpb.png',
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        placeholder: (context, url) => Container(
          color: const Color(0xFF1A1A1A),
          child: const Center(
            child: CircularProgressIndicator(color: Color(0xFF6DFB60)),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: const Color(0xFF1A1A1A),
          child: const Center(
            child: Icon(Icons.error, color: Colors.white, size: 50),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: widget.isDialog
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                Column(
                  children: [
                    Text(
                      'Refer to a Friend',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Earn ',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: 'Hash',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF6DFB60),
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: ' Coins',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF6DFB60),
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(child: _buildReferNowButton()),
                    const SizedBox(width: 16),
                    Expanded(child: _buildNoThanksButton()),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    Text(
                      'Refer to a Friend',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Earn ',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: 'Hash',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF6DFB60),
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: ' Coins',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF6DFB60),
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
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
                ),
                const SizedBox(height: 20),
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: _buildReferNowButton(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
    );
  }

  Widget _buildReferNowButton() {
    return Container(
      height: widget.isDialog ? 50 : 45,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.isDialog ? 25 : 22),
        border: Border.all(color: Colors.white, width: 2),
        color: Color(0xff00DC00).withValues(alpha: 0.8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(widget.isDialog ? 25 : 22),
          onTap: () {
            widget.onReferNow?.call();
          },
          child: Center(
            child: Text(
              'Refer Now',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: widget.isDialog ? 16 : 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoThanksButton() {
    return Container(
      height: widget.isDialog ? 50 : 45,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(widget.isDialog ? 25 : 22),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(widget.isDialog ? 25 : 22),
          onTap: () {
            widget.onNoThanks?.call();
          },
          child: Center(
            child: Text(
              'No, thanks',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: widget.isDialog ? 16 : 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Helper function to show the modal
void showReferFriendModal(
  BuildContext context, {
  VoidCallback? onReferNow,
  VoidCallback? onNoThanks,
}) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) => ReferFriendModal(
      onReferNow: onReferNow,
      onNoThanks: onNoThanks,
      isDialog: true,
    ),
  );
}

// Helper function to get the refer friend widget for home screen
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
