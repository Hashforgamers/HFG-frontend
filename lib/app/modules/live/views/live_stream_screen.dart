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
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class LiveStreamScreen extends StatefulWidget {
  final String streamId;

  const LiveStreamScreen({super.key, required this.streamId});

  @override
  State<LiveStreamScreen> createState() => _LiveStreamScreenState();
}

class _LiveStreamScreenState extends State<LiveStreamScreen> with WidgetsBindingObserver {
  late final HashLiveService _service;
  late final HashLiveController _controller;
  YoutubePlayerController? _youtubeController;
  String? _videoId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _service = Get.isRegistered<HashLiveService>() ? Get.find<HashLiveService>() : Get.put(HashLiveService(), permanent: true);
    _controller = Get.isRegistered<HashLiveController>() ? Get.find<HashLiveController>() : Get.put(HashLiveController(), permanent: true);
    _service.joinLiveStream(widget.streamId);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _service.leaveLiveStream(widget.streamId);
    }
    if (state == AppLifecycleState.resumed) {
      _service.joinLiveStream(widget.streamId);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _youtubeController?.dispose();
    _service.leaveLiveStream(widget.streamId);
    super.dispose();
  }

  void _syncYoutubeController(String url) {
    final newId = LiveYoutubeUtils.extractVideoId(url);
    if (newId == null || newId.isEmpty) return;
    if (_videoId == newId && _youtubeController != null) return;
    _videoId = newId;
    _youtubeController?.dispose();
    _youtubeController = YoutubePlayerController(
      initialVideoId: newId,
      flags: const YoutubePlayerFlags(autoPlay: true, mute: false, isLive: true),
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
          return const Scaffold(backgroundColor: LiveUi.bg, body: Center(child: CircularProgressIndicator(color: LiveUi.accentSoft)));
        }
        if (stream == null) {
          return Scaffold(
            backgroundColor: LiveUi.bg,
            body: Center(child: Text('Stream not found', style: GoogleFonts.inter(color: Colors.white70))),
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
            title: Text('Hash Live', style: GoogleFonts.orbitron(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
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
                      child: _youtubeController == null
                          ? Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(colors: [Color(0xFF2C3E50), Color(0xFF111111)]),
                              ),
                              alignment: Alignment.center,
                              child: Text('Invalid YouTube link', style: GoogleFonts.inter(color: Colors.white70)),
                            )
                          : YoutubePlayer(
                              controller: _youtubeController!,
                              showVideoProgressIndicator: true,
                              progressIndicatorColor: LiveUi.accentSoft,
                            ),
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
                        backgroundImage: stream.hostPhotoUrl.isNotEmpty ? CachedNetworkImageProvider(stream.hostPhotoUrl) : null,
                        backgroundColor: LiveUi.surface,
                        child: stream.hostPhotoUrl.isEmpty ? const Icon(Icons.person, color: Colors.white) : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(stream.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
                            Text('@${stream.hostName} • ${stream.game}', style: LiveUi.body.copyWith(fontSize: 11)),
                          ],
                        ),
                      ),
                      if (!isOwnStream)
                        Obx(
                          () => ElevatedButton(
                            onPressed: _controller.isFollowSubmitting.value ? null : () => _controller.toggleFollow(stream.hostUid),
                            style: ElevatedButton.styleFrom(backgroundColor: LiveUi.accent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12)),
                            child: Text(_controller.isFollowingHost.value ? 'Following' : 'Follow'),
                          ),
                        )
                      else
                        ElevatedButton(
                          onPressed: () async {
                            await _controller.endLive();
                            if (mounted) Get.back();
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: LiveUi.accent),
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
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: LiveUi.accent, borderRadius: BorderRadius.circular(12)),
                        child: Text('LIVE', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 10)),
                      ),
                      const SizedBox(width: 8),
                      StreamBuilder<int>(
                        stream: _service.watchViewerCount(widget.streamId),
                        builder: (_, snap) => Text('${snap.data ?? 0} watching', style: GoogleFonts.inter(color: LiveUi.accentSoft, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _service.watchMessages(widget.streamId),
                    builder: (_, snapshotMessages) {
                      final messages = snapshotMessages.data ?? const <Map<String, dynamic>>[];
                      if (messages.isEmpty) {
                        return Center(child: Text('No chat yet. Say hello!', style: LiveUi.body));
                      }
                      return ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: messages.length,
                        itemBuilder: (_, i) {
                          final message = messages[i];
                          final name = (message['sender_name'] ?? 'Player').toString();
                          final text = (message['text'] ?? '').toString();
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                            decoration: LiveUi.cardDecoration(radius: 12),
                            child: RichText(
                              text: TextSpan(
                                style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                                children: [
                                  TextSpan(text: '$name: ', style: const TextStyle(color: LiveUi.accentSoft, fontWeight: FontWeight.w700)),
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
                  decoration: BoxDecoration(color: const Color(0xCC000000), boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 10)]),
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
                          gradient: const LinearGradient(colors: [Color(0xFF2C3E50), Color(0xFF111111)]),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(onPressed: _sendMessage, icon: const Icon(Icons.send, color: Colors.white)),
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
