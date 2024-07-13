import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/wallet_controller.dart';

class WalletDetailView extends StatelessWidget {
  final WalletController walletController = Get.find<WalletController>();
  final TextEditingController _amountController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Wallet Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Wallet Balance',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Obx(() => Text(
              '\₹${walletController.balance.value.toStringAsFixed(2)}',
              style: TextStyle(
                fontFamily: 'Pricedown',
                fontSize: 26,
                color: Color(0xff00D701),
              ),
            )),
            SizedBox(height: 20),
            ElevatedButton(
              style: ButtonStyle(
              backgroundColor: MaterialStateColor.resolveWith((states) => Color(0xff00D701),)
            ),
              onPressed: () {
                showWithdrawDialog(context);
              },
              child: Text('Withdraw Money'),
            ),
            SizedBox(height: 20),
            Text(
              'Transactions',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Expanded(
              child: Obx(() => ListView.builder(
                itemCount: walletController.transactions.length,
                itemBuilder: (context, index) {
                  final transaction = walletController.transactions[index];

                  return ListTile(
                    leading: Icon(Icons.arrow_downward_sharp),
                    title: Text(
                      transaction['description'],
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      transaction['timestamp'],
                      style: const TextStyle(color: Colors.grey),
                    ),
                    trailing: Text(
                      '\$${transaction['amount'].toString()}',
                      style: const TextStyle(color: Colors.green,fontSize: 18,fontWeight: FontWeight.bold),
                    ),
                  );
                },
              )),
            ),
          ],
        ),
      ),
    );
  }

  void showWithdrawDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Material(
          type: MaterialType.transparency,
          child: CupertinoAlertDialog(
            title: Text("Withdraw Money"),
            content: Column(
              children: [
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: "Amount"),
                ),
              ],
            ),
            actions: [
              CupertinoDialogAction(
                child: Text("Cancel",style: TextStyle(color: Colors.red),),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              CupertinoDialogAction(
                child: Text("Proceed",style: TextStyle(color: Colors.green,),),
                onPressed: () {
                  double amount = double.tryParse(_amountController.text) ?? 0.0;
                  if (amount > 0 && amount <= walletController.balance.value) {
                    walletController.withdrawFunds(amount);
                    Navigator.of(context).pop();
                  } else {
                    // Show error message or handle invalid amount
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
