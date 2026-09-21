import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/arena/views/booking_design.dart';
import 'package:hash/core/repositories/model/get_voucher_model.dart';

class BookingSummaryVoucherSection extends StatelessWidget {
  final TextEditingController voucherController;
  final RxBool isLoadingVouchers;
  final RxList<Voucher> availableVouchers;
  final Rx<Voucher?> appliedVoucher;
  final RxBool isApplyingVoucher;
  final RxString voucherError;
  final VoidCallback onReload;
  final VoidCallback onApply;
  final VoidCallback onRemove;
  final void Function(Voucher voucher) onSelectVoucher;
  final bool Function(Voucher voucher) canApplyVoucher;

  const BookingSummaryVoucherSection({
    super.key,
    required this.voucherController,
    required this.isLoadingVouchers,
    required this.availableVouchers,
    required this.appliedVoucher,
    required this.isApplyingVoucher,
    required this.voucherError,
    required this.onReload,
    required this.onApply,
    required this.onRemove,
    required this.onSelectVoucher,
    required this.canApplyVoucher,
  });

  @override
  Widget build(BuildContext context) {
    return BookingCard(
      margin: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.local_offer_rounded,
                    size: 17,
                    color: BookingColors.textSecondary,
                  ),
                  const SizedBox(width: 10),
                  Text('Voucher', style: BookingText.title(context)),
                ],
              ),
              SizedBox(
                height: 22,
                child: Obx(
                  () => isLoadingVouchers.value
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CupertinoActivityIndicator(
                            color: BookingColors.textSecondary,
                          ),
                        )
                      : GestureDetector(
                          onTap: onReload,
                          child: const Icon(
                            CupertinoIcons.refresh,
                            color: BookingColors.accentBright,
                            size: 20,
                          ),
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Obx(() {
            final applied = appliedVoucher.value;
            if (applied != null) {
              return Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: BookingColors.success.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
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
                            'Applied: ${applied.code}',
                            style: GoogleFonts.inter(
                              color: BookingColors.success,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${applied.discountPercentage}% discount active',
                            style: GoogleFonts.inter(
                              color: BookingColors.success.withValues(
                                alpha: 0.85,
                              ),
                              fontSize: 12,
                            ),
                          ),
                          if (applied.discountPercentage == 100) ...[
                            const SizedBox(height: 6),
                            const BookingStatusPill(
                              label: 'Limited to 1 slot only',
                              tone: BookingPillTone.warning,
                              icon: Icons.info_outline_rounded,
                              dense: true,
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: onRemove,
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: BookingColors.success,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Remove Voucher',
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          }),
          Obx(() {
            if (availableVouchers.isNotEmpty) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  'Your available vouchers (${availableVouchers.length})',
                  style: BookingText.secondary(context),
                ),
              );
            }
            return const SizedBox.shrink();
          }),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: TextField(
                    controller: voucherController,
                    style: GoogleFonts.inter(
                      color: BookingColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter voucher code',
                      hintStyle: GoogleFonts.inter(
                        color: BookingColors.textMuted,
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: BookingColors.surfaceAlt,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          BookingRadius.button,
                        ),
                        borderSide: const BorderSide(
                          color: BookingColors.border,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          BookingRadius.button,
                        ),
                        borderSide: const BorderSide(
                          color: BookingColors.border,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          BookingRadius.button,
                        ),
                        borderSide: const BorderSide(
                          color: BookingColors.accent,
                          width: 1.4,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Obx(() {
                return GestureDetector(
                  onTap: isApplyingVoucher.value ? null : onApply,
                  child: Container(
                    height: 48,
                    width: 100,
                    decoration: BoxDecoration(
                      color: BookingColors.accent.withValues(alpha: 0.12),
                      border: Border.all(color: BookingColors.accentBright),
                      borderRadius: BorderRadius.circular(BookingRadius.button),
                    ),
                    child: Center(
                      child: isApplyingVoucher.value
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: BookingColors.accentBright,
                              ),
                            )
                          : Text(
                              'Apply',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: BookingColors.accentBright,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                );
              }),
            ],
          ),
          Obx(() {
            if (voucherError.value.isNotEmpty) {
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  voucherError.value,
                  style: GoogleFonts.inter(
                    color: BookingColors.danger,
                    fontSize: 12,
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }),
          Obx(() {
            if (availableVouchers.isNotEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 122,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: availableVouchers.length,
                      itemBuilder: (context, index) {
                        final voucher = availableVouchers[index];
                        final isActive = voucher.isActive;
                        final canApply = isActive && canApplyVoucher(voucher);
                        final Color tone = canApply
                            ? BookingColors.accent
                            : isActive
                            ? BookingColors.warning
                            : BookingColors.textMuted;
                        return GestureDetector(
                          onTap: canApply
                              ? () => onSelectVoucher(voucher)
                              : null,
                          child: Container(
                            width: 146,
                            margin: const EdgeInsets.only(right: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: tone.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: tone.withValues(alpha: 0.32),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  voucher.code,
                                  style: GoogleFonts.inter(
                                    color: canApply
                                        ? BookingColors.accentBright
                                        : tone,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${voucher.discountPercentage}% OFF',
                                  style: GoogleFonts.inter(
                                    color: canApply
                                        ? BookingColors.textPrimary
                                        : BookingColors.textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  canApply
                                      ? 'Available'
                                      : isActive
                                      ? 'Limited'
                                      : 'Inactive',
                                  style: GoogleFonts.inter(
                                    color: canApply
                                        ? BookingColors.success
                                        : isActive
                                        ? BookingColors.warning
                                        : BookingColors.danger,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (isActive &&
                                    voucher.discountPercentage == 100) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    canApply ? '1 slot only' : 'Too many slots',
                                    style: GoogleFonts.inter(
                                      color: canApply
                                          ? BookingColors.warning
                                          : BookingColors.danger,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }
}
