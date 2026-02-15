import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/core/repositories/model/get_pass_model.dart';
import 'package:hash/utils/widgets/loader.dart';

class BookingSummaryGamePassDialog extends StatelessWidget {
  final RxBool isLoading;
  final RxString errorMessage;
  final RxList<GetPassModel> userGamePasses;
  final Rx<GetPassModel?> selectedGamePass;
  final VoidCallback onRefresh;
  final VoidCallback onProceed;

  const BookingSummaryGamePassDialog({
    super.key,
    required this.isLoading,
    required this.errorMessage,
    required this.userGamePasses,
    required this.selectedGamePass,
    required this.onRefresh,
    required this.onProceed,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 500, minHeight: 200),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Hash Game Pass',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Row(
                  children: [
                    Obx(
                      () => isLoading.value
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CupertinoActivityIndicator(
                                color: const Color(0xff00DC00),
                              ),
                            )
                          : IconButton(
                              onPressed: onRefresh,
                              icon: const Icon(
                                Icons.refresh,
                                color: const Color(0xff00DC00),
                              ),
                            ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Obx(() {
              if (isLoading.value) {
                return const Center(child: RainbowLoadingBar());
              }

              if (errorMessage.value.isNotEmpty) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          errorMessage.value,
                          style: GoogleFonts.inter(
                            color: Colors.red,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (userGamePasses.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.gamepad_outlined,
                        color: Colors.grey.shade400,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No Compatible Game Passes',
                        style: GoogleFonts.inter(
                          color: Colors.grey.shade400,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "You don't have any active game passes that can be used at this cafe.",
                        style: GoogleFonts.inter(
                          color: Colors.grey.shade500,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'HASH Passes can be used at any cafe. Cafe-specific passes can only be used at their respective cafes.',
                        style: GoogleFonts.inter(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return SizedBox(
                height: 300,
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: userGamePasses.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final pass = userGamePasses[index];
                    final isSelected = selectedGamePass.value?.id == pass.id;
                    final isExpired = pass.progressValue >= 1.0;

                    return GestureDetector(
                      onTap: isExpired
                          ? null
                          : () {
                              selectedGamePass.value = pass;
                            },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xff00DC00).withValues(alpha: 0.2)
                              : const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xff00DC00)
                                : isExpired
                                    ? Colors.red.withValues(alpha: 0.3)
                                    : Colors.grey.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        pass.name,
                                        style: GoogleFonts.inter(
                                          color: isExpired
                                              ? Colors.grey.shade500
                                              : Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        pass.vendorName,
                                        style: GoogleFonts.inter(
                                          color: Colors.grey.shade400,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    Icons.check_circle,
                                    color: Color(0xff00DC00),
                                    size: 24,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        pass.expiryText,
                                        style: GoogleFonts.inter(
                                          color: isExpired
                                              ? Colors.red
                                              : Colors.grey.shade300,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      if (pass.description.isNotEmpty)
                                        Text(
                                          pass.description,
                                          style: GoogleFonts.inter(
                                            color: Colors.grey.shade400,
                                            fontSize: 12,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                ),
                                Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isExpired
                                            ? Colors.red.withValues(alpha: 0.2)
                                            : const Color(0xff00DC00)
                                                .withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        isExpired ? 'EXPIRED' : 'ACTIVE',
                                        style: GoogleFonts.inter(
                                          color: isExpired
                                              ? Colors.red
                                              : const Color(0xff00DC00),
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: pass.vendorId == null
                                            ? Colors.blue.withValues(alpha: 0.2)
                                            : Colors.orange.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        pass.vendorId == null ? 'HASH' : 'CAFE',
                                        style: GoogleFonts.inter(
                                          color: pass.vendorId == null
                                              ? Colors.blue
                                              : Colors.orange,
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (!isExpired) ...[
                              const SizedBox(height: 12),
                              LinearProgressIndicator(
                                value: pass.progressValue,
                                backgroundColor: Colors.grey.withValues(alpha: 0.3),
                                valueColor:
                                    const AlwaysStoppedAnimation<Color>(
                                  Color(0xff00DC00),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: Colors.grey.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.inter(
                        color: Colors.grey.shade300,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Obx(
                    () => ElevatedButton(
                      onPressed: selectedGamePass.value != null
                          ? () {
                              Navigator.of(context).pop();
                              onProceed();
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff00DC00),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Proceed',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
