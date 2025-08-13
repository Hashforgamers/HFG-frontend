import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/core/service/global_bottom_sheet_service.dart';
import 'package:hash/utils/widgets/glow_neon_loader.dart';
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
          onTap: () => _onRedeemPressed(context),
          child: _buildPill(
            icon:
                "https://res.cloudinary.com/dxjjigepf/image/upload/v1755075084/union_wguvvy.png",
            amount: "$hashCoin",
          ),
        ),
        GestureDetector(
          onTap: () => Get.to(WalletScreen()),
          child: Obx(() {
            final isLoading = walletController.isLoading.value;
            final walletBalance = walletController.balance.value;
            return Stack(
              children: [
                _buildPill(
                  icon:
                      "https://res.cloudinary.com/dxjjigepf/image/upload/v1755075079/coin_xqqpx0.png",
                  amount: isLoading ? "..." : "₹$walletBalance",
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: CachedNetworkImage(
                    imageUrl:
                        'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075085/vector_gq1qzh.png',
                    height: 10,
                    width: 10,
                    placeholder: (_, _) =>
                        const Center(child: RainbowGlowingLoader(size: 4)),
                    errorWidget: (_, _, _) =>
                        const Icon(Icons.error, color: Colors.red),
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }

  void _onRedeemPressed(BuildContext context) {
    GlobalBottomSheetService().showHashCoinRedemptionBottomSheet(
      context,
      hashCoin: hashCoin,
      onSuccess: (message) => Get.snackbar("Success", message),
      onError: (message) => Get.snackbar("Error", message),
      onLoading: () => Get.snackbar("Loading", "Please wait..."),
    );
  }

  Widget _buildPill({required String icon, required String amount}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
          constraints: const BoxConstraints(minWidth: 80),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.15),
                Colors.white.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CachedNetworkImage(
                imageUrl: icon,
                height: 18,
                width: 18,
                placeholder: (_, _) =>
                    const Center(child: RainbowGlowingLoader(size: 10)),
                errorWidget: (_, _, _) =>
                    const Icon(Icons.error, color: Colors.red),
              ),
              const SizedBox(width: 8),
              Text(
                amount,
                style: GoogleFonts.bigShouldersDisplay(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
