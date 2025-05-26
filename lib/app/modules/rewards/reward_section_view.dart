import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../wallet/controllers/wallet_controller.dart';
import '../wallet/views/wallet_bottomsheet.dart';

class RewardsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    WalletController walletController=Get.put(WalletController());

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildRewardItem(CupertinoIcons.hexagon, "2,559", "Hash. Coins", Color(0xffDE3A3A),),
        GestureDetector(
            onTap: (){
              Get.bottomSheet(
                WalletBottomSheet(),
                isScrollControlled: true,
              );
            },
            child: _buildRewardItem(CupertinoIcons.circle_bottomthird_split, "\₹${walletController.balance.value}", "Wallet", Colors.yellow)),
      ],
    );
  }

  Widget _buildRewardItem(IconData icon, String amount, String label, Color color) {
    return Column(
      children: [
        Stack(alignment: Alignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 3.0),
              child: Text('${label[0]}',style: TextStyle(color: color,fontSize: 20),),
            ),
            Icon(icon, color: color, size: 30),
          ],
        ),
        SizedBox(height: 5),
        Text(amount, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.white)),
      ],
    );
  }
}
