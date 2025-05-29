import 'package:get/get.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service_locator.dart';
import 'package:url_launcher/url_launcher.dart';

class CheckoutController extends GetxController {
  var isLoading = false.obs;
  var responseMessage = ''.obs;
  var shortUrl = ''.obs;
  var paymentLinkId = ''.obs;
  var paymentMethod = ''.obs;
  final _remoteRepo = locator<RemoteRepoInterface>();

  Future<void> checkout() async {
    isLoading(true);
    try {
      final response = await _remoteRepo.initiateCheckout();
      shortUrl.value = response['short_url'];
      paymentLinkId.value = response['id'];
      responseMessage.value = 'Checkout successful';
      openUrl(); // Open the URL immediately after it's obtained
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
    try {
      final response = await _remoteRepo.validateTransaction(paymentLinkId.value);
      responseMessage.value = 'Transaction validated successfully';
    } catch (e) {
      responseMessage.value = 'Error: $e';
    } finally {
      isLoading(false);
    }
  }
}
