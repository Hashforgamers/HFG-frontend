import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/core/service/global_bottom_sheet_service.dart';

import '../wallet/controllers/wallet_controller.dart';
import '../wallet/views/wallet_view.dart';

class RewardsSection extends StatelessWidget {
  final int hashCoin;
  const RewardsSection({super.key, required this.hashCoin});

  @override
  Widget build(BuildContext context) {
    final WalletController walletController = Get.find<WalletController>();

    return Wrap(
      spacing: 8,
      children: [
        GestureDetector(
          onTap: () async {
            await GlobalBottomSheetService().showHashCoinRedemptionBottomSheet(
              context,
              hashCoin: hashCoin,
              onSuccess: (message) {
                Get.snackbar("Success", message);
              },
              onError: (message) {
                Get.snackbar("Error", message);
              },
              onLoading: () {
                Get.snackbar("Loading", "Please wait...");
              },
            );
          },
          child: Center(
            child: _buildPillContainer(
              icon: "assets/icons/union.png",
              amount: "$hashCoin",
            ),
          ),
        ),
        GestureDetector(
          onTap: () async {
            Get.to(WalletScreen());
          },
          child: Center(
            child: Stack(
              children: [
                Obx(() {
                  final walletBalance = walletController.balance.value;
                  final isLoading = walletController.isLoading.value;
                  return _buildPillContainer(
                    icon: "assets/icons/coin.png",
                    amount: isLoading ? "..." : "₹$walletBalance",
                  );
                }),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Image.asset(
                    "assets/icons/vector.png",
                    height: 10,
                    width: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPillContainer({required String icon, required String amount}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          constraints: BoxConstraints(minWidth: 75),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(icon, height: 18, width: 18),
              const SizedBox(width: 6),
              Text(
                amount,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
