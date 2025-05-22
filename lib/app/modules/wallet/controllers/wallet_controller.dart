import 'dart:convert';
import 'package:get/get.dart';
import 'package:hash/utils/constants.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WalletController extends GetxController {
  var balance = 0.0.obs;
  var transactions = <Map<String, dynamic>>[].obs;
  final String baseUri = hostName; // Replace with your base URI

  @override
  void onInit() {
    super.onInit();
    fetchWallet();
  }
  Future<String> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
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
    final token = await _getToken(); // Retrieve the token from storage or any other source

    final response = await http.get(Uri.parse('$baseUri/wallet'),  headers: {
      'Content-Type': 'application/json',
      "Authorization": "Bearer $token",
    },);
    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      balance.value = data['balance'];
      transactions.value = List<Map<String, dynamic>>.from(data['transactions']);
      print('this ${transactions.value}');

    } else {
      Get.snackbar('Error', 'Failed to fetch wallet data');
    }
  }

  Future<void> addFunds(double amount, String description, String name, String contact, String emailId, BuildContext context) async {
    final token = await _getToken(); // Retrieve the token from storage or any other source

    final response = await http.post(
      Uri.parse('$baseUri/wallet/add-funds'),
      headers: {
        'Content-Type': 'application/json',
        "Authorization": "Bearer $token",
      },
      body: json.encode({
        'amount': amount,
        'description': description,
        'name': name,
        'contact': contact,
        'email_id': emailId,
      }),
    );
    print(response.body);

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      String paymentLink = data['short_url'];
      openPaymentLink(paymentLink, data['id'], context);
    } else {
      Get.snackbar('Error', 'Failed to add funds');
    }
  }

  void openPaymentLink(String url, String paymentId, BuildContext context) {
    Get.to(() => PaymentWebView(url: url, paymentId: paymentId));
  }

  Future<void> validateFunds(String paymentLinkId) async {
    final token = await _getToken(); // Retrieve the token from storage or any other source
    print('validate funds${paymentLinkId}');

    final response = await http.post(
      Uri.parse('$baseUri/wallet/validate-funds'),
      headers: {
        'Content-Type': 'application/json',
        "Authorization": "Bearer $token",
      },      body: json.encode({
        'payment_link_ids': [paymentLinkId],
      }),
    );
    print('validate funds${response.body}');
    print('validate funds${response.statusCode}');

    if (response.statusCode == 200) {
      fetchWallet();
      Get.snackbar('Success', 'Funds Added successfully');
    } else {
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
          title: Text('Complete Payment'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
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
