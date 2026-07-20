import 'dart:async';

import 'package:get/get.dart';
import 'package:app_links/app_links.dart';
import 'package:hash/app/modules/tournaments_section/pages/tournaments_team_invite_join_view.dart';
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
    final segments = uri.pathSegments
        .map((segment) => segment.trim().toLowerCase())
        .where((segment) => segment.isNotEmpty)
        .toList();
    final isCustomSchemeTeamJoin =
        uri.host.toLowerCase() == 'team' && segments.contains('join');
    final isWebTeamJoin =
        segments.length >= 2 && segments[0] == 'team' && segments[1] == 'join';
    final isTeamJoinLink =
        isCustomSchemeTeamJoin ||
        isWebTeamJoin ||
        segments.contains('team-join');
    if (isTeamJoinLink) {
      final eventId = uri.queryParameters['event_id'] ?? '';
      final teamId = uri.queryParameters['team_id'] ?? '';
      final inviteId = uri.queryParameters['invite_id'] ?? '';
      if (eventId.isNotEmpty && teamId.isNotEmpty) {
        Get.to(
          () => TournamentsTeamInviteJoinView(
            eventId: eventId,
            teamId: teamId,
            inviteId: inviteId,
          ),
        );
        return;
      }
    }
    final contestIndex = segments.indexOf('contest');
    if (contestIndex != -1) {
      final pathId = contestIndex + 1 < uri.pathSegments.length
          ? uri.pathSegments[contestIndex + 1]
          : null;
      Get.toNamed(
        '/contestPage',
        arguments: {'id': uri.queryParameters['id'] ?? pathId},
      );
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
