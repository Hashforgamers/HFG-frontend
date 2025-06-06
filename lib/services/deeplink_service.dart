import 'package:get/get.dart';
import 'package:uni_links/uni_links.dart';
import 'dart:async';

class DeepLinkController extends GetxController {
  StreamSubscription? _sub;

  @override
  void onInit() {
    super.onInit();
    _handleInitialLink();
    _handleIncomingLinks();
  }

  Future<void> _handleInitialLink() async {
    try {
      final initialLink = await getInitialLink();
      if (initialLink != null) {
        _navigateToDeepLink(initialLink);
      }
    } catch (e) {
      print('Failed to get initial link: $e');
    }
  }

  void _handleIncomingLinks() {
    _sub = uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        _navigateToDeepLink(uri.toString());
      }
    }, onError: (err) {
      print('Error in deep link stream: $err');
    });
  }

  void _navigateToDeepLink(String link) {
    print('Deep Link: $link');
    // Parse the link and navigate
    Uri uri = Uri.parse(link);
    if (uri.pathSegments.contains('contest')) {
      Get.toNamed('/contestPage', arguments: {'id': uri.queryParameters['id']});
    } else if (uri.pathSegments.contains('offer')) {
      Get.toNamed('/offerPage');
    } else {
      Get.toNamed('/home');
    }
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }
}
