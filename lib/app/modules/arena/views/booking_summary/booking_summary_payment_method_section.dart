import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/arena/views/booking_design.dart';
import 'package:hash/app/modules/arena/views/booking_summary/booking_summary_payment_option_chip.dart';
import 'package:hash/core/repositories/model/get_pass_model.dart';
import 'package:hash/core/localization/app_region.dart';

class BookingSummaryPaymentMethodSection extends StatelessWidget {
  final RxString selectedPayment;
  final Rx<GetPassModel?> selectedGamePass;
  final bool showPayAtCafeOption;
  final double walletBalance;
  final double walletAppliedAmount;
  final double walletTopUpAmount;
  final double remainingAmount;
  final void Function(String value) onSelectPayment;
  final VoidCallback onClearSelectedPass;

  const BookingSummaryPaymentMethodSection({
    super.key,
    required this.selectedPayment,
    required this.selectedGamePass,
    required this.showPayAtCafeOption,
    required this.walletBalance,
    required this.walletAppliedAmount,
    required this.walletTopUpAmount,
    required this.remainingAmount,
    required this.onSelectPayment,
    required this.onClearSelectedPass,
  });

  @override
  Widget build(BuildContext context) {
    return BookingCard(
      margin: const EdgeInsets.only(top: 12),
      child: Obx(
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Payment method', style: BookingText.title(context)),
            const SizedBox(height: 14),
            BookingSummaryPaymentOptionChip(
              label: walletBalance > 0
                  ? 'Wallet • ${Money.symbol}${walletBalance.toStringAsFixed(0)}'
                  : 'Wallet',
              icon: Icons.account_balance_wallet_rounded,
              isSelected: selectedPayment.value == 'wallet',
              onTap: () => onSelectPayment('wallet'),
            ),
            const SizedBox(height: 10),
            BookingSummaryPaymentOptionChip(
              label: 'Hash Game Pass',
              icon: Icons.videogame_asset_rounded,
              isSelected: selectedPayment.value == 'none',
              onTap: () => onSelectPayment('none'),
            ),
            const SizedBox(height: 10),
            BookingSummaryPaymentOptionChip(
              label: 'UPI / Card',
              icon: Icons.credit_card_rounded,
              isSelected: selectedPayment.value == 'gateway',
              onTap: () => onSelectPayment('gateway'),
            ),
            if (showPayAtCafeOption) ...[
              const SizedBox(height: 10),
              BookingSummaryPaymentOptionChip(
                label: 'Pay in Cafe',
                icon: Icons.directions_walk_rounded,
                isSelected: selectedPayment.value == 'pay_at_cafe',
                onTap: () => onSelectPayment('pay_at_cafe'),
              ),
            ],
            if (selectedPayment.value == 'wallet') ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: BookingColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: BookingColors.border),
                ),
                child: Text(
                  walletTopUpAmount > 0
                      ? 'Your wallet currently has ${Money.symbol}${walletBalance.toStringAsFixed(2)}. We will add ${Money.symbol}${walletTopUpAmount.toStringAsFixed(2)} to the wallet first, refresh the balance here, and then complete this booking using wallet payment.'
                      : walletAppliedAmount > 0
                      ? 'Entire booking will be covered by your wallet balance.'
                      : 'Wallet payment is selected. We will complete this booking using your wallet balance.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    height: 1.45,
                    color: BookingColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
            if (selectedPayment.value == 'none' &&
                selectedGamePass.value != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: BookingColors.success.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: BookingColors.success.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: BookingColors.success,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selected: ${selectedGamePass.value!.name}',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: BookingColors.success,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            selectedGamePass.value!.vendorName,
                            style: BookingText.muted(context),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: onClearSelectedPass,
                      style: TextButton.styleFrom(
                        foregroundColor: BookingColors.accentBright,
                      ),
                      child: Text(
                        'Change',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: BookingColors.accentBright,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
