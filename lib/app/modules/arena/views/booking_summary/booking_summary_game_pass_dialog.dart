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
  final VoidCallback onPurchasePasses;

  const BookingSummaryGamePassDialog({
    super.key,
    required this.isLoading,
    required this.errorMessage,
    required this.userGamePasses,
    required this.selectedGamePass,
    required this.onRefresh,
    required this.onProceed,
    required this.onPurchasePasses,
  });

  @override
  Widget build(BuildContext context) {
    final viewHeight = MediaQuery.of(context).size.height;
    return SafeArea(
      top: false,
      child: Container(
        height: viewHeight * 0.82,
        decoration: const BoxDecoration(
          color: Color(0xFF111111),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 46,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Select Hash Game Pass',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Obx(
                    () => isLoading.value
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CupertinoActivityIndicator(
                              color: Color(0xff00DC00),
                            ),
                          )
                        : IconButton(
                            onPressed: onRefresh,
                            icon: const Icon(
                              Icons.refresh_rounded,
                              color: Color(0xff00DC00),
                            ),
                          ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Obx(() {
                  if (isLoading.value) {
                    return const Center(child: AppLinearLoader());
                  }

                  if (errorMessage.value.isNotEmpty) {
                    return _ErrorState(
                      message: errorMessage.value,
                      onRetry: onRefresh,
                    );
                  }

                  if (userGamePasses.isEmpty) {
                    return _EmptyState(onPurchasePasses: onPurchasePasses);
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.only(top: 8, bottom: 8),
                    itemCount: userGamePasses.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (_, index) {
                      final pass = userGamePasses[index];
                      final isSelected = selectedGamePass.value?.id == pass.id;
                      final isExpired = pass.progressValue >= 1.0;
                      return _PassTile(
                        pass: pass,
                        isExpired: isExpired,
                        isSelected: isSelected,
                        onTap: isExpired
                            ? null
                            : () => selectedGamePass.value = pass,
                      );
                    },
                  );
                }),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              decoration: const BoxDecoration(
                color: Color(0xFF111111),
                border: Border(top: BorderSide(color: Colors.white10)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(color: Colors.white70),
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
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          'Proceed',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 10),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onPurchasePasses;

  const _EmptyState({required this.onPurchasePasses});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.gamepad_outlined, color: Colors.grey.shade400, size: 42),
            const SizedBox(height: 10),
            Text(
              'No Compatible Game Passes',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "You don't have active passes for this cafe.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.white60, fontSize: 12),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onPurchasePasses();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff00DC00),
                  foregroundColor: Colors.black,
                ),
                child: Text(
                  'View Passes to Purchase',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PassTile extends StatelessWidget {
  final GetPassModel pass;
  final bool isExpired;
  final bool isSelected;
  final VoidCallback? onTap;

  const _PassTile({
    required this.pass,
    required this.isExpired,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected
        ? const Color(0xff00DC00)
        : isExpired
        ? Colors.red.withValues(alpha: 0.35)
        : Colors.white24;
    final bgColor = isSelected
        ? const Color(0xff00DC00).withValues(alpha: 0.12)
        : const Color(0xFF1E1E1E);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pass.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: isExpired ? Colors.white54 : Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        pass.vendorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xff00DC00),
                    size: 22,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    pass.expiryText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: isExpired ? Colors.redAccent : Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _statusChip(
                  isExpired ? 'EXPIRED' : 'ACTIVE',
                  isExpired ? Colors.redAccent : const Color(0xff00DC00),
                ),
                const SizedBox(width: 6),
                _statusChip(
                  pass.vendorId == null ? 'HASH' : 'CAFE',
                  pass.vendorId == null ? Colors.blue : Colors.orange,
                ),
              ],
            ),
            if (!isExpired) ...[
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: pass.progressValue,
                minHeight: 6,
                borderRadius: BorderRadius.circular(8),
                backgroundColor: Colors.white12,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xff00DC00),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
