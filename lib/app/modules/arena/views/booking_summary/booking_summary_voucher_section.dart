import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/core/repositories/model/get_voucher_model.dart';
import 'package:hash/utils/widgets/loader.dart';

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
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF191919),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Have a Voucher?',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              SizedBox(
                height: 20,
                child: Obx(
                  () => isLoadingVouchers.value
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CupertinoActivityIndicator(),
                        )
                      : GestureDetector(
                          onTap: onReload,
                          child: const Icon(
                            CupertinoIcons.refresh,
                            color: Colors.green,
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
                  color: Colors.green.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
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
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${applied.discountPercentage}% discount active',
                            style: GoogleFonts.inter(
                              color: Colors.green.withValues(alpha: 0.8),
                              fontSize: 12,
                            ),
                          ),
                          if (applied.discountPercentage == 100) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.orange.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                '⚠️ Limited to 1 slot only',
                                style: GoogleFonts.inter(
                                  color: Colors.orange,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: onRemove,
                      icon: const Icon(
                        Icons.close,
                        size: 18,
                        color: Colors.green,
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
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Your Available Vouchers (${availableVouchers.length})',
                  style: GoogleFonts.inter(
                    color: Colors.grey.shade300,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: TextField(
                    controller: voucherController,
                    style: GoogleFonts.inter(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Enter voucher code',
                      hintStyle: GoogleFonts.inter(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: Colors.black.withValues(alpha: 0.3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(
                          color: Color(0xFF505050),
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(
                          color: Color(0xFF505050),
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(
                          color: Color(0xFF338125),
                          width: 1,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
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
                    height: 44,
                    width: 100,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      border: Border.all(
                        color: const Color(0xFF338125),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Center(
                      child: isApplyingVoucher.value
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: RainbowLoadingBar(),
                            )
                          : Text(
                              'Apply',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
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
                    color: Colors.red.shade300,
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
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: availableVouchers.length,
                      itemBuilder: (context, index) {
                        final voucher = availableVouchers[index];
                        final isActive = voucher.isActive;
                        final canApply = isActive && canApplyVoucher(voucher);
                        return GestureDetector(
                          onTap: canApply
                              ? () => onSelectVoucher(voucher)
                              : null,
                          child: Container(
                            width: 140,
                            margin: const EdgeInsets.only(right: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: canApply
                                  ? Colors.deepOrange.withValues(alpha: 0.08)
                                  : isActive
                                      ? Colors.grey.shade700
                                      : Colors.grey.shade800,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: canApply
                                    ? Colors.deepOrange.withValues(alpha: 0.3)
                                    : isActive
                                        ? Colors.orange.withValues(alpha: 0.3)
                                        : Colors.grey.withValues(alpha: 0.2),
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
                                        ? Colors.deepOrange
                                        : isActive
                                            ? Colors.grey.shade400
                                            : Colors.grey.shade500,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${voucher.discountPercentage}% OFF',
                                  style: GoogleFonts.inter(
                                    color: canApply
                                        ? Colors.white
                                        : isActive
                                            ? Colors.grey.shade400
                                            : Colors.grey,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  canApply
                                      ? 'Available'
                                      : isActive
                                          ? 'Limited'
                                          : 'Inactive',
                                  style: GoogleFonts.inter(
                                    color: canApply
                                        ? Colors.green
                                        : isActive
                                            ? Colors.orange
                                            : Colors.red,
                                    fontSize: 10,
                                  ),
                                ),
                                if (isActive &&
                                    voucher.discountPercentage == 100) ...[
                                  const SizedBox(height: 2),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: canApply
                                          ? Colors.orange.withValues(alpha: 0.2)
                                          : Colors.red.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      canApply ? '1 slot only' : 'Too many slots',
                                      style: GoogleFonts.inter(
                                        color: canApply
                                            ? Colors.orange
                                            : Colors.red,
                                        fontSize: 8,
                                        fontWeight: FontWeight.w500,
                                      ),
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
