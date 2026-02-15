import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/arena/views/booking_summary/booking_summary_payment_option_chip.dart';
import 'package:hash/core/repositories/model/get_pass_model.dart';

class BookingSummaryPaymentMethodSection extends StatelessWidget {
  final RxString selectedPayment;
  final Rx<GetPassModel?> selectedGamePass;
  final void Function(String value) onSelectPayment;
  final VoidCallback onClearSelectedPass;

  const BookingSummaryPaymentMethodSection({
    super.key,
    required this.selectedPayment,
    required this.selectedGamePass,
    required this.onSelectPayment,
    required this.onClearSelectedPass,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Obx(
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose Payment Method',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: BookingSummaryPaymentOptionChip(
                    label: 'Wallet',
                    icon: Icons.account_balance_wallet,
                    isSelected: selectedPayment.value == 'wallet',
                    onTap: () => onSelectPayment('wallet'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: BookingSummaryPaymentOptionChip(
                    label: 'Hash Game Pass',
                    icon: Icons.gamepad,
                    isSelected: selectedPayment.value == 'none',
                    onTap: () => onSelectPayment('none'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: BookingSummaryPaymentOptionChip(
                    label: 'UPI / Card',
                    icon: Icons.credit_card,
                    isSelected: selectedPayment.value == 'gateway',
                    onTap: () => onSelectPayment('gateway'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: BookingSummaryPaymentOptionChip(
                    label: 'Pay in Cafe',
                    icon: Icons.directions_walk,
                    isSelected: selectedPayment.value == 'pay_at_cafe',
                    onTap: () => onSelectPayment('pay_at_cafe'),
                  ),
                ),
              ],
            ),
            if (selectedPayment.value == 'none' &&
                selectedGamePass.value != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xff00DC00).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xff00DC00).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xff00DC00),
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
                              color: const Color(0xff00DC00),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            selectedGamePass.value!.vendorName,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: onClearSelectedPass,
                      child: Text(
                        'Change',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xff00DC00),
                          fontWeight: FontWeight.w500,
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
