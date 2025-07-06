import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hash/core/service/global_bottom_sheet_service.dart';

import '../wallet/controllers/wallet_controller.dart';
import '../wallet/views/wallet_bottomsheet.dart';
import '../wallet/views/wallet_view.dart';

class RewardsSection extends StatelessWidget {
  final int hashCoin;
  const RewardsSection({super.key, required this.hashCoin});

  @override
  Widget build(BuildContext context) {
    final WalletController walletController = Get.put(WalletController());

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
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
          child: _buildRewardItem(
            CupertinoIcons.hexagon,
            "$hashCoin",
            "Hash Coins",
            const Color(0xff338125),
          ),
        ),
        GestureDetector(
          onTap: () {
            Get.to(WalletScreen());
          },
          child: Obx(() {
            final walletBalance = walletController.balance.value;
            return _buildRewardItem(
              CupertinoIcons.circle_bottomthird_split,
              "₹$walletBalance",
              "Wallet",
              Colors.yellow,
            );
          }),
        ),
      ],
    );
  }

  Widget _buildRewardItem(
      IconData icon, String amount, String label, Color color) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 3.0),
              child: Text(
                label[0],
                style: TextStyle(color: color, fontSize: 20),
              ),
            ),
            Icon(icon, color: color, size: 30),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          amount,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.white)),
      ],
    );
  }
}
