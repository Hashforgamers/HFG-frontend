import 'package:get/get.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter/material.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service_locator.dart';

class WalletController extends GetxController {
  var balance = 0.0.obs;
  var transactions = <Map<String, dynamic>>[].obs;
  final _remoteRepo = locator<RemoteRepoInterface>();

  @override
  void onInit() {
    super.onInit();
    fetchWallet();
  }

  Future<void> withdrawFunds(double amount) async {
    // Call your withdraw funds API here
    // Example:
    // var response = await api.withdrawFunds(amount);
    // Handle response and update balance
    balance.value -= amount;
    fetchWallet(); // Refresh wallet details
  }

  Future<void> fetchWallet() async {
    try {
      final data = await _remoteRepo.fetchWallet();
      balance.value = data['balance'];
      transactions.value = List<Map<String, dynamic>>.from(data['transactions']);
      print('this ${transactions.value}');
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch wallet data');
    }
  }

  Future<void> addFunds(double amount, String description, String name, String contact, String emailId, BuildContext context) async {
    try {
      final data = await _remoteRepo.addFunds(
        amount: amount,
        description: description,
        name: name,
        contact: contact,
        emailId: emailId,
      );
      String paymentLink = data['short_url'];
      openPaymentLink(paymentLink, data['id'], context);
    } catch (e) {
      Get.snackbar('Error', 'Failed to add funds');
    }
  }

  void openPaymentLink(String url, String paymentId, BuildContext context) {
    Get.to(() => PaymentWebView(url: url, paymentId: paymentId));
  }

  Future<void> validateFunds(String paymentLinkId) async {
    try {
      await _remoteRepo.validateFunds(paymentLinkId);
      fetchWallet();
      Get.snackbar('Success', 'Funds Added successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to validate funds');
    }
  }
}

class PaymentWebView extends StatefulWidget {
  final String url;
  final String paymentId;

  PaymentWebView({required this.url, required this.paymentId});

  @override
  _PaymentWebViewState createState() => _PaymentWebViewState();
}

class _PaymentWebViewState extends State<PaymentWebView> {
  InAppWebViewController? webViewController;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await Get.find<WalletController>().validateFunds(widget.paymentId);
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Complete Payment'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              await Get.find<WalletController>().validateFunds(widget.paymentId);
              Navigator.pop(context);
            },
          ),
        ),
        body: InAppWebView(
          initialUrlRequest: URLRequest(url: Uri.parse(widget.url)),
          onWebViewCreated: (controller) {
            webViewController = controller;
          },
        ),
      ),
    );
  }
}
