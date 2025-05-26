import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hash/app/modules/wallet/views/wallet_view.dart';
import '../controllers/wallet_controller.dart';

class WalletBottomSheet extends StatelessWidget {
  final WalletController walletController = Get.put(WalletController());

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        BackdropFilter(
          filter: ImageFilter.blur(sigmaY: 8, sigmaX: 8),
          child: SizedBox(
            height: 250,
            width: Get.width,
          ),
        ),
        Container(
          height: 250,
          padding: EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Color(0xff121212),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Wallet Balance',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: Icon(
                      Icons.close,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Obx(() => Text(
                '\₹${walletController.balance.value.toStringAsFixed(2)}',
                style: TextStyle(
                  fontFamily: 'Pricedown',
                  fontSize: 26,
                  color: Color(0xffDE3A3A),
                ),
              )),
              SizedBox(height: 20),
              TextField(
                keyboardType: TextInputType.number,
                
                decoration: InputDecoration(
                  hintText: 'Add Amount',
                  hintStyle: TextStyle(
                    color: Colors.grey,

                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  fillColor: Colors.black,
                  focusColor: Colors.black,
                ),
                onSubmitted: (value) async {
                  if (value.isNotEmpty) {
                    await walletController.addFunds(
                      double.parse(value),
                      'Add fund #${DateTime.now().millisecondsSinceEpoch}',
                      'Gaurav Kumar',
                      '+919000090000',
                      'gaurav.kumar@example.com',
                      context,
                    );
                  }
                },
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [10, 25, 50, 100].map((amount) {
                  return GestureDetector(
                    onTap: () async {
                      await walletController.addFunds(
                        amount.toDouble(),
                        'Add fund #${DateTime.now().millisecondsSinceEpoch}',
                        'Gaurav Kumar',
                        '+919000090000',
                        'gaurav.kumar@example.com',
                        context,
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                      decoration: BoxDecoration(
                        color: Color(0xffDE3A3A),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          'Add ₹$amount',
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 10),

              GestureDetector(
                onTap: (){
                  Get.to(() => WalletDetailView());
                },
                child: Row(crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('Open Wallet'),
                    SizedBox(width: 5,),
                    Icon(Icons.arrow_forward_ios_rounded,size: 12,)
                  ],
                ),
              )
            ],
          ),
        ),
      ],
    );
  }
}
