import 'package:get/get.dart';
import 'package:hash/utils/constants.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class CheckoutController extends GetxController {
  var isLoading = false.obs;
  var responseMessage = ''.obs;
  var shortUrl = ''.obs;
  var paymentLinkId = ''.obs;
  var paymentMethod = ''.obs; // Add this observable
  Dio dio = Dio();

  Future<String> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
  }

  Future<void> checkout() async {
    final token = await _getToken(); // Retrieve the token from storage or any other source

    isLoading(true);
    try {
      const url = '$hostName/checkout/other'; // Replace {{base_uri}} with your actual base URI
      final response = await dio.get(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            "Authorization": "Bearer $token",
          },
          followRedirects: true,
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        shortUrl.value = data['short_url'];
        paymentLinkId.value = data['id'];
        responseMessage.value = 'Checkout successful';
        openUrl(); // Open the URL immediately after it's obtained
      } else {
        responseMessage.value = 'Checkout failed: ${response.statusCode}';
      }
    } catch (e) {
      responseMessage.value = 'Error: $e';
    } finally {
      isLoading(false);
    }
  }

  void openUrl() async {
    if (await canLaunch(shortUrl.value)) {
      await launch(
        shortUrl.value,
        forceSafariVC: true,
        forceWebView: true,
        enableJavaScript: true,
      ).then((_) {
        validateTransaction();
      }).catchError((err) {
        responseMessage.value = 'Could not launch URL: $err';
      });
    } else {
      throw 'Could not launch ${shortUrl.value}';
    }
  }

  Future<void> validateTransaction() async {
    isLoading(true);
    final token = await _getToken(); // Retrieve the token from storage or any other source

    try {
      const url = '$hostName/checkout/pay/validate'; // Replace {{base_uri}} with your actual base URI
      final response = await dio.post(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            "Authorization": "Bearer $token",
            "Accept": "*/*",
            "Accept-Encoding": "gzip, deflate, br",
            "Connection": "keep-alive"
          },
          followRedirects: true,
          validateStatus: (status) {
            return status! < 500;
          },
        ),
        data: {
          "payment_link_ids": [paymentLinkId.value],
        },
      );

      if (response.statusCode == 200) {
        responseMessage.value = 'Transaction validated successfully';
      } else {
        responseMessage.value = 'Transaction validation failed: ${response.statusCode}';
      }
    } catch (e) {
      responseMessage.value = 'Error: $e';
    } finally {
      isLoading(false);
    }
  }
}
