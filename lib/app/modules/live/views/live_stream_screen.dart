import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/home/widgets/app_mode_segmented_toggle.dart';
import 'package:hash/app/modules/live/controllers/hash_live_controller.dart';
import 'package:hash/app/modules/live/models/live_stream_model.dart';
import 'package:hash/app/modules/live/services/hash_live_service.dart';
import 'package:hash/app/modules/live/utils/live_youtube_utils.dart';
import 'package:hash/app/modules/live/widgets/live_ui.dart';
import 'package:hash/core/service/squad_missions_service.dart';
import 'package:hash/core/service_locator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class LiveStreamScreen extends StatefulWidget {
  final String streamId;

  const LiveStreamScreen({super.key, required this.streamId});

  @override
  State<LiveStreamScreen> createState() => _LiveStreamScreenState();
}

class _LiveStreamScreenState extends State<LiveStreamScreen>
    with WidgetsBindingObserver {
  late final HashLiveService _service;
  late final HashLiveController _controller;
  YoutubePlayerController? _youtubeController;
  String? _videoId;
  String? _blockedVideoId;
  bool _showPlaybackFallback = false;
  String _playbackFallbackMessage =
      'This live stream is not available right now.';
  Timer? _playbackHealthTimer;
  DateTime? _watchStartedAt;
  final SquadMissionsService _squadMissionsService =
      locator<SquadMissionsService>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _service = Get.isRegistered<HashLiveService>()
        ? Get.find<HashLiveService>()
        : Get.put(HashLiveService(), permanent: true);
    _controller = Get.isRegistered<HashLiveController>()
        ? Get.find<HashLiveController>()
        : Get.put(HashLiveController(), permanent: true);
    _watchStartedAt = DateTime.now();
    _service.joinLiveStream(widget.streamId);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _service.leaveLiveStream(widget.streamId);
    }
    if (state == AppLifecycleState.resumed) {
      _service.joinLiveStream(widget.streamId);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _playbackHealthTimer?.cancel();
    _youtubeController?.dispose();
    _service.leaveLiveStream(widget.streamId);
    final startedAt = _watchStartedAt;
    if (startedAt != null) {
      final watchedMinutes = DateTime.now().difference(startedAt).inMinutes;
      if (watchedMinutes > 0) {
        _squadMissionsService.trackAction(
          action: SquadMissionAction.watchLive,
          increment: watchedMinutes,
        );
      }
    }
    super.dispose();
  }

  void _syncYoutubeController(String url) {
    final newId = LiveYoutubeUtils.extractVideoId(url);
    if (newId == null || newId.isEmpty) return;
    if (_blockedVideoId == newId && _showPlaybackFallback) return;
    if (_videoId == newId && _youtubeController != null) return;
    _videoId = newId;
    _blockedVideoId = null;
    _showPlaybackFallback = false;
    _playbackFallbackMessage = 'This live stream is not available right now.';
    _playbackHealthTimer?.cancel();
    _youtubeController?.dispose();
    _youtubeController = YoutubePlayerController(
      initialVideoId: newId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        isLive: true,
        disableDragSeek: true,
        enableCaption: false,
      ),
    );
    final controller = _youtubeController!;
    controller.addListener(() {
      if (_youtubeController != controller) return;
      final value = controller.value;
      if (!mounted) return;
      if (value.hasError) {
        _activatePlaybackFallback(
          'This YouTube live is not running right now.',
        );
        return;
      }
      if (value.isReady ||
          value.playerState == PlayerState.playing ||
          value.playerState == PlayerState.buffering ||
          value.playerState == PlayerState.paused) {
        _playbackHealthTimer?.cancel();
        if (_showPlaybackFallback) {
          setState(() => _showPlaybackFallback = false);
        }
      }
    });
    _schedulePlaybackHealthCheck(newId);
  }

  void _schedulePlaybackHealthCheck(String expectedVideoId) {
    _playbackHealthTimer?.cancel();
    _playbackHealthTimer = Timer(const Duration(seconds: 8), () {
      if (!mounted) return;
      if (_videoId != expectedVideoId) return;
      final controller = _youtubeController;
      if (controller == null) return;
      final value = controller.value;
      final isPlayable =
          value.isReady ||
          value.playerState == PlayerState.playing ||
          value.playerState == PlayerState.buffering ||
          value.playerState == PlayerState.paused;
      if (!isPlayable || value.hasError) {
        _activatePlaybackFallback(
          'This YouTube live is offline or unavailable right now.',
        );
      }
    });
  }

  void _activatePlaybackFallback(String message) {
    _playbackHealthTimer?.cancel();
    final controller = _youtubeController;
    _youtubeController = null;
    try {
      controller?.pause();
    } catch (_) {}
    controller?.dispose();
    if (!mounted) return;
    setState(() {
      _blockedVideoId = _videoId;
      _showPlaybackFallback = true;
      _playbackFallbackMessage = message;
    });
  }

  Future<void> _retryPlayback() async {
    final currentUrl = _videoId;
    if (currentUrl == null || currentUrl.isEmpty) return;
    setState(() {
      _showPlaybackFallback = false;
      _blockedVideoId = null;
      _playbackFallbackMessage = 'Retrying stream...';
    });
    _syncYoutubeController('https://www.youtube.com/watch?v=$currentUrl');
  }

  Widget _buildStreamStatePane({
    required String title,
    required String message,
    String? youtubeUrl,
    bool showRetry = false,
  }) {
    final thumbnailUrl = youtubeUrl == null
        ? null
        : LiveYoutubeUtils.thumbnailUrl(youtubeUrl);
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF272C36), Color(0xFF1E222B)],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (thumbnailUrl != null && thumbnailUrl.isNotEmpty)
            CachedNetworkImage(
              imageUrl: thumbnailUrl,
              fit: BoxFit.cover,
              errorWidget: (_, _, _) => const SizedBox.shrink(),
            ),
          Container(color: Colors.black.withValues(alpha: 0.72)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.live_tv, color: Colors.white, size: 42),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    if (showRetry)
                      ElevatedButton.icon(
                        onPressed: _retryPlayback,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    if (youtubeUrl != null && youtubeUrl.trim().isNotEmpty)
                      ElevatedButton.icon(
                        onPressed: () async {
                          final uri = Uri.tryParse(youtubeUrl.trim());
                          if (uri != null) {
                            await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        },
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Open in YouTube'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaybackPane(LiveStreamModel stream) {
    if (_showPlaybackFallback) {
      return _buildStreamStatePane(
        title: 'Stream unavailable',
        message: _playbackFallbackMessage,
        youtubeUrl: stream.youtubeUrl,
        showRetry: true,
      );
    }

    if (_youtubeController == null) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF272C36), Color(0xFF1E222B)],
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          'Invalid YouTube link',
          style: GoogleFonts.inter(color: Colors.white70),
        ),
      );
    }

    return YoutubePlayer(
      controller: _youtubeController!,
      showVideoProgressIndicator: true,
      progressIndicatorColor: LiveUi.accentSoft,
    );
  }

  Future<void> _sendMessage() async {
    final text = _controller.chatController.text.trim();
    if (text.isEmpty) return;
    await _service.sendMessage(widget.streamId, text);
    _controller.chatController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<LiveStreamModel?>(
      stream: _service.watchStream(widget.streamId),
      builder: (context, snapshot) {
        final stream = snapshot.data;
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: LiveUi.bg,
            body: Center(
              child: CircularProgressIndicator(color: LiveUi.accentSoft),
            ),
          );
        }
        if (stream == null) {
          return Scaffold(
            backgroundColor: LiveUi.bg,
            body: Center(
              child: Text(
                'Stream not found',
                style: GoogleFonts.inter(color: Colors.white70),
              ),
            ),
          );
        }
        if (!stream.isLive) {
          return Scaffold(
            backgroundColor: LiveUi.bg,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text(
                'Hash Live',
                style: GoogleFonts.orbitron(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ),
            body: Container(
              decoration: LiveUi.pageDecoration(),
              padding: const EdgeInsets.all(12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: _buildStreamStatePane(
                    title: 'Stream ended',
                    message:
                        'This live stream has ended automatically or was closed by the host.',
                    youtubeUrl: stream.youtubeUrl,
                  ),
                ),
              ),
            ),
          );
        }

        _syncYoutubeController(stream.youtubeUrl);
        _controller.syncFollowState(stream.hostUid);
        final isOwnStream = _service.currentUid == stream.hostUid;

        return Scaffold(
          backgroundColor: LiveUi.bg,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              'Hash Live',
              style: GoogleFonts.orbitron(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(56),
              child: Padding(
                padding: EdgeInsets.fromLTRB(12, 0, 12, 10),
                child: AppModeSegmentedToggle(compact: true),
              ),
            ),
          ),
          body: Container(
            decoration: LiveUi.pageDecoration(),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                  decoration: LiveUi.cardDecoration(radius: 18),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: _buildPlaybackPane(stream),
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                  padding: const EdgeInsets.all(12),
                  decoration: LiveUi.cardDecoration(radius: 14),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: stream.hostPhotoUrl.isNotEmpty
                            ? CachedNetworkImageProvider(stream.hostPhotoUrl)
                            : null,
                        backgroundColor: LiveUi.surface,
                        child: stream.hostPhotoUrl.isEmpty
                            ? const Icon(Icons.person, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stream.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '@${stream.hostName} • ${stream.game}',
                              style: LiveUi.body.copyWith(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      if (!isOwnStream)
                        Obx(
                          () => ElevatedButton(
                            onPressed: _controller.isFollowSubmitting.value
                                ? null
                                : () =>
                                      _controller.toggleFollow(stream.hostUid),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: LiveUi.accent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                            ),
                            child: Text(
                              _controller.isFollowingHost.value
                                  ? 'Following'
                                  : 'Follow',
                            ),
                          ),
                        )
                      else
                        ElevatedButton(
                          onPressed: () async {
                            await _controller.endLive(streamId: stream.id);
                            if (mounted) Get.back();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: LiveUi.accent,
                          ),
                          child: const Text('End Live'),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: LiveUi.accent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'LIVE',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      StreamBuilder<int>(
                        stream: _service.watchViewerCount(widget.streamId),
                        builder: (_, snap) => Text(
                          '${snap.data ?? 0} watching',
                          style: GoogleFonts.inter(
                            color: LiveUi.accentSoft,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _service.watchMessages(widget.streamId),
                    builder: (_, snapshotMessages) {
                      final messages =
                          snapshotMessages.data ??
                          const <Map<String, dynamic>>[];
                      if (messages.isEmpty) {
                        return Center(
                          child: Text(
                            'No chat yet. Say hello!',
                            style: LiveUi.body,
                          ),
                        );
                      }
                      return ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: messages.length,
                        itemBuilder: (_, i) {
                          final message = messages[i];
                          final name = (message['sender_name'] ?? 'Player')
                              .toString();
                          final text = (message['text'] ?? '').toString();
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 9,
                            ),
                            decoration: LiveUi.cardDecoration(radius: 12),
                            child: RichText(
                              text: TextSpan(
                                style: GoogleFonts.inter(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                                children: [
                                  TextSpan(
                                    text: '$name: ',
                                    style: const TextStyle(
                                      color: LiveUi.accentSoft,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  TextSpan(text: text),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  decoration: BoxDecoration(
                    color: const Color(0xCC000000),
                    boxShadow: [
                      BoxShadow(color: Colors.black54, blurRadius: 10),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller.chatController,
                          style: const TextStyle(color: Colors.white),
                          decoration: LiveUi.input(hint: 'Type a message'),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFA726), Color(0xFFFF6D00)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: _sendMessage,
                          icon: const Icon(Icons.send, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
