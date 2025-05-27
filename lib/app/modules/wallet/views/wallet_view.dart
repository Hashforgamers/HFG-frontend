import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/services/service_locator.dart';
import '../../../../core/services/amplitude_service.dart';
import '../controllers/wallet_controller.dart';

class WalletDetailView extends StatelessWidget {
  final WalletController walletController = Get.find<WalletController>();
  final TextEditingController _amountController = TextEditingController();
  final _amplitudeService = serviceLocator<AmplitudeService>();

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
            Obx(() {
              // Track wallet balance view
              _amplitudeService.trackWalletAction(
                action: 'view_balance',
                amount: walletController.balance.value,
              );
              return Text(
                '\₹${walletController.balance.value.toStringAsFixed(2)}',
                style: TextStyle(
                  fontFamily: 'Pricedown',
                  fontSize: 26,
                  color: Color(0xffDE3A3A),
                ),
              );
            }),
            SizedBox(height: 20),
            ElevatedButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateColor.resolveWith((states) => Color(0xffDE3A3A),)
              ),
              onPressed: () async {
                await _amplitudeService.trackWalletAction(
                  action: 'withdraw_initiated',
                );
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
              child: Obx(() {
                // Track transaction list view
                _amplitudeService.trackWalletAction(
                  action: 'view_transactions',
                  status: 'success',
                );
                return ListView.builder(
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
                      onTap: () async {
                        await _amplitudeService.trackWalletAction(
                          action: 'view_transaction_details',
                          transactionId: transaction['id'],
                          amount: transaction['amount'],
                        );
                      },
                    );
                  },
                );
              }),
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
                  onChanged: (value) async {
                    await _amplitudeService.trackWalletAction(
                      action: 'withdraw_amount_entered',
                      amount: double.tryParse(value) ?? 0.0,
                    );
                  },
                ),
              ],
            ),
            actions: [
              CupertinoDialogAction(
                child: Text("Cancel",style: TextStyle(color: Colors.red),),
                onPressed: () async {
                  await _amplitudeService.trackWalletAction(
                    action: 'withdraw_cancelled',
                  );
                  Navigator.of(context).pop();
                },
              ),
              CupertinoDialogAction(
                child: Text("Proceed",style: TextStyle(color: Colors.green,),),
                onPressed: () async {
                  double amount = double.tryParse(_amountController.text) ?? 0.0;
                  if (amount > 0 && amount <= walletController.balance.value) {
                    await _amplitudeService.trackWalletAction(
                      action: 'withdraw_completed',
                      amount: amount,
                    );
                    walletController.withdrawFunds(amount);
                    Navigator.of(context).pop();
                  } else {
                    await _amplitudeService.trackWalletAction(
                      action: 'withdrawal_failed',
                      status: 'invalid_amount',
                    );
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
