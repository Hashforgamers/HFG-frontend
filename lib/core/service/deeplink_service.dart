import 'dart:async';

import 'package:get/get.dart';
import 'package:app_links/app_links.dart';
import 'package:hash/core/utils/app_logger.dart';

class DeepLinkController extends GetxController {
  final AppLinks _appLinks = AppLinks();
  late final StreamSubscription<Uri> _linkSub;

  @override
  void onInit() {
    super.onInit();
    _handleInitialLink();
    _handleIncomingLinks();
  }

  Future<void> _handleInitialLink() async {
    try {
      final Uri? initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _navigateToDeepLink(initialUri);
      }
    } catch (e) {
      AppLogger.d('Failed to get initial app link: $e');
    }
  }

  void _handleIncomingLinks() {
    _linkSub = _appLinks.uriLinkStream.listen(
          (Uri uri) {
        _navigateToDeepLink(uri);
      },
      onError: (err) {
        AppLogger.d('Error in app link stream: $err');
      },
    );
  }

  void _navigateToDeepLink(Uri uri) {
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
    _linkSub.cancel();
    super.onClose();
  }
}
