import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/utils/widgets/loader.dart';

import '../controllers/verification_checkout_controller.dart';
import 'community_theme.dart';

/// Official Host Verification — checkout screen (Neon Velocity).
class VerificationCheckoutView extends GetView<VerificationCheckoutController> {
  const VerificationCheckoutView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CT.bg,
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            Expanded(
              child: Obx(() {
                if (controller.loading.value) {
                  return const AppLinearLoader.screen();
                }
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  children: [
                    _summaryCard(),
                    const SizedBox(height: 24),
                    Text(
                      'INCLUDED BENEFITS',
                      style: CT.mono(11, color: CT.secondary),
                    ),
                    const SizedBox(height: 12),
                    _benefit(Icons.verified_rounded, 'Verified Host Badge'),
                    const SizedBox(height: 10),
                    _benefit(
                      Icons.all_inclusive_rounded,
                      'Unlimited Tournaments',
                    ),
                    const SizedBox(height: 10),
                    _benefit(Icons.payments_rounded, 'Earnings Enabled'),
                    const SizedBox(height: 24),
                    Text(
                      'SECURE PAYMENT',
                      style: CT.mono(11, color: CT.secondary),
                    ),
                    const SizedBox(height: 12),
                    _paymentGatewayCard(),
                  ],
                );
              }),
            ),
            _payBar(),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(Icons.close_rounded, color: CT.onSurface),
              onPressed: Get.back,
            ),
          ),
          Text(
            'NEON VELOCITY',
            style: GoogleFonts.sora(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              fontStyle: FontStyle.italic,
              color: CT.primaryBright,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: CT.card(),
      child: Column(
        children: [
          SvgPicture.asset('assets/verified_badge.svg', width: 44, height: 44),
          const SizedBox(height: 16),
          Text(
            'Official Host Verification',
            textAlign: TextAlign.center,
            style: CT.headline(22),
          ),
          const SizedBox(height: 8),
          Text(
            'Unlock premium tournament hosting capabilities.',
            textAlign: TextAlign.center,
            style: CT.body(14),
          ),
          const SizedBox(height: 20),
          Obx(
            () => Text(
              controller.amountText,
              style: GoogleFonts.sora(
                fontSize: 44,
                fontWeight: FontWeight.w800,
                color: CT.primaryBright,
                shadows: [
                  Shadow(
                    color: CT.primary.withValues(alpha: 0.6),
                    blurRadius: 24,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _benefit(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CT.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: icon == Icons.verified_rounded
                ? CT.verifiedBlue
                : CT.primaryBright,
            size: 22,
          ),
          const SizedBox(width: 14),
          Text(
            label,
            style: CT.body(15, color: CT.onSurface, w: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _paymentGatewayCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: CT.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: CT.bg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.security_rounded,
              color: CT.secondary,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Razorpay Checkout',
                  style: CT.headline(16, color: CT.onSurface),
                ),
                const SizedBox(height: 3),
                Text(
                  'Choose UPI, card, net banking, or wallet securely.',
                  style: CT.body(12),
                ),
              ],
            ),
          ),
          const Icon(Icons.lock_rounded, color: CT.primaryBright, size: 18),
        ],
      ),
    );
  }

  Widget _payBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(color: CT.outline, height: 1),
          const SizedBox(height: 14),
          Obx(
            () => DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: CT.glow(CT.primary, blur: 22, opacity: 0.5),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: controller.processing.value
                      ? null
                      : controller.pay,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CT.primary,
                    disabledBackgroundColor: CT.surfaceHigh,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: controller.processing.value
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.lock_rounded, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Pay ${controller.amountText} & Get Verified',
                              style: GoogleFonts.sora(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline_rounded, size: 12, color: CT.muted),
              const SizedBox(width: 4),
              Text('256-BIT SSL', style: CT.mono(9)),
              const SizedBox(width: 10),
              Text('•', style: CT.mono(9)),
              const SizedBox(width: 10),
              Icon(Icons.shield_outlined, size: 12, color: CT.muted),
              const SizedBox(width: 4),
              Text('SECURE CHECKOUT', style: CT.mono(9)),
            ],
          ),
        ],
      ),
    );
  }
}
