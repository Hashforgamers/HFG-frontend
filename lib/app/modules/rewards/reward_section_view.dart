import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class RewardsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildRewardItem(CupertinoIcons.gift, "2,559", "Reward", Colors.red),
        _buildRewardItem(CupertinoIcons.money_dollar_circle, "₹20,050", "Wallet", Colors.yellow),
      ],
    );
  }

  Widget _buildRewardItem(IconData icon, String amount, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 30),
        SizedBox(height: 5),
        Text(amount, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.white)),
      ],
    );
  }
}
