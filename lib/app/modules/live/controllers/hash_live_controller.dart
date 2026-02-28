import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:hash/app/modules/live/models/live_stream_model.dart';
import 'package:hash/app/modules/live/services/hash_live_service.dart';
import 'package:hash/app/modules/live/utils/live_youtube_utils.dart';

class HashLiveController extends GetxController {
  static const int _minTitleLength = 3;
  static const int _maxTitleLength = 80;

  final HashLiveService _service = Get.isRegistered<HashLiveService>()
      ? Get.find<HashLiveService>()
      : Get.put(HashLiveService(), permanent: true);

  final selectedTab = 0.obs;
  final isSubmitting = false.obs;
  final isFollowSubmitting = false.obs;
  final isStreamingFromCafe = false.obs;
  final activeStreamId = ''.obs;
  final chatController = TextEditingController();
  final isHost = false.obs;
  final isFollowingHost = false.obs;

  final titleController = TextEditingController();
  final youtubeController = TextEditingController();
  final selectedGame = ''.obs;
  final scheduledAt = Rxn<DateTime>();

  final games = const ['Valorant', 'BGMI', 'FIFA', 'CS2', 'CODM'];

  Stream<List<LiveStreamModel>> get liveStreams => _service.watchLiveStreams();

  void setTab(int index) => selectedTab.value = index;

  void setGame(String value) => selectedGame.value = value;

  void setStreamingFromCafe(bool value) => isStreamingFromCafe.value = value;

  bool _isValidYoutubeUrl(String input) {
    return LiveYoutubeUtils.isSupportedUrl(input);
  }

  Future<String?> startLive() async {
    final title = titleController.text.trim();
    final game = selectedGame.value.trim();
    final url = youtubeController.text.trim();

    if (title.length < _minTitleLength) {
      _showError('Stream title must be at least $_minTitleLength characters.');
      return null;
    }
    if (title.length > _maxTitleLength) {
      _showError('Stream title must be at most $_maxTitleLength characters.');
      return null;
    }
    if (game.isEmpty) {
      _showError('Please select a game.');
      return null;
    }
    if (!_isValidYoutubeUrl(url)) {
      _showError('Please enter a valid YouTube live link.');
      return null;
    }

    try {
      isSubmitting.value = true;
      final streamId = await _service.startOrUpdateLive(
        streamId: activeStreamId.value.isEmpty ? null : activeStreamId.value,
        title: title,
        game: game,
        youtubeUrl: url,
        streamingFromCafe: isStreamingFromCafe.value,
      );
      activeStreamId.value = streamId;
      isHost.value = true;
      _showSuccess('You are live now.');
      return streamId;
    } catch (e) {
      _showError(
        _cleanError(e, fallback: 'Failed to start live. Please try again.'),
      );
      return null;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<String?> scheduleStream() async {
    final title = titleController.text.trim();
    final game = selectedGame.value.trim();
    final when = scheduledAt.value;

    if (title.length < _minTitleLength) {
      _showError('Stream title must be at least $_minTitleLength characters.');
      return null;
    }
    if (title.length > _maxTitleLength) {
      _showError('Stream title must be at most $_maxTitleLength characters.');
      return null;
    }
    if (game.isEmpty) {
      _showError('Please select a game.');
      return null;
    }
    if (when == null || when.isBefore(DateTime.now())) {
      _showError('Please choose a future schedule time.');
      return null;
    }

    try {
      isSubmitting.value = true;
      final upcomingId = await _service.scheduleUpcomingStream(
        title: title,
        game: game,
        startAt: when,
        streamingFromCafe: isStreamingFromCafe.value,
      );
      _showSuccess('Stream scheduled successfully.');
      return upcomingId;
    } catch (e) {
      _showError(
        _cleanError(
          e,
          fallback: 'Failed to schedule stream. Please try again.',
        ),
      );
      return null;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> endLive({String? streamId}) async {
    try {
      isSubmitting.value = true;
      final targetStreamId =
          (streamId ?? activeStreamId.value).trim().isNotEmpty
          ? (streamId ?? activeStreamId.value).trim()
          : await _service.resolveCurrentHostActiveStreamId();

      if (targetStreamId.isEmpty) {
        _showError('No active stream found to end.');
        return;
      }

      await _service.endLive(targetStreamId);
      activeStreamId.value = '';
      isHost.value = false;
      _showSuccess('Live stream ended.');
    } catch (e) {
      _showError('Failed to end live stream.');
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> syncFollowState(String hostUid) async {
    if (hostUid.isEmpty || hostUid == _service.currentUid) {
      isFollowingHost.value = false;
      return;
    }
    isFollowingHost.value = await _service.isFollowingHost(hostUid);
  }

  Future<void> toggleFollow(String hostUid) async {
    if (isFollowSubmitting.value || hostUid.isEmpty) return;
    try {
      isFollowSubmitting.value = true;
      isFollowingHost.value = await _service.toggleFollowHost(hostUid);
    } catch (e) {
      _showError('Failed to update follow status.');
    } finally {
      isFollowSubmitting.value = false;
    }
  }

  @override
  void onClose() {
    titleController.dispose();
    youtubeController.dispose();
    chatController.dispose();
    super.onClose();
  }

  void _showError(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  void _showSuccess(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  String _cleanError(Object error, {required String fallback}) {
    final raw = error.toString().replaceFirst('Exception: ', '').trim();
    if (raw.isEmpty) return fallback;
    if (raw.toLowerCase().contains('permission-denied')) {
      return 'Permission denied for live stream write. Check Firestore rules.';
    }
    if (raw.toLowerCase().contains('failed-precondition')) {
      return 'Database index missing. Please create the required Firestore index.';
    }
    return raw;
  }
}
