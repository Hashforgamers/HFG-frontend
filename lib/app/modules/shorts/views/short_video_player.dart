import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../controllers/viral_shorts_controller.dart';

class ShortVideoPlayer extends StatefulWidget {
  final List<YouTubeShort> shorts;
  final int initialIndex;

  const ShortVideoPlayer({required this.shorts, this.initialIndex = 0, super.key});

  @override
  State<ShortVideoPlayer> createState() => _ShortVideoPlayerState();
}

class _ShortVideoPlayerState extends State<ShortVideoPlayer> {
  late PageController _pageController;
  YoutubePlayerController? _ytController;
  YoutubePlayerController? _nextController;
  late List<String?> _videoIds;
  int _currentIndex = 0;
  int? _nextIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _videoIds = widget.shorts
        .map((short) => YoutubePlayer.convertUrlToId(short.link))
        .toList(growable: false);
    _pageController = PageController(initialPage: _currentIndex);
    _ytController = _createController(_currentIndex, autoPlay: true, mute: false);
    _prepareNext(_currentIndex);
  }

  YoutubePlayerController? _createController(
    int index, {
    required bool autoPlay,
    required bool mute,
  }) {
    if (index < 0 || index >= _videoIds.length) return null;
    final id = _videoIds[index];
    if (id == null || id.isEmpty) return null;
    return YoutubePlayerController(
      initialVideoId: id,
      flags: YoutubePlayerFlags(autoPlay: autoPlay, mute: mute),
    );
  }

  void _prepareNext(int fromIndex) {
    final candidate = fromIndex + 1;
    _nextController?.dispose();
    _nextController = null;
    _nextIndex = null;

    if (candidate >= _videoIds.length) return;
    final controller = _createController(candidate, autoPlay: true, mute: true);
    if (controller != null) {
      _nextController = controller;
      _nextIndex = candidate;
    }
  }

  void _onPageChanged(int index) {
    final previous = _ytController;
    if (index == _nextIndex && _nextController != null) {
      _ytController = _nextController;
      _nextController = null;
      _nextIndex = null;
      previous?.dispose();
    } else {
      _ytController?.dispose();
      _ytController = _createController(index, autoPlay: true, mute: false);
    }
    _prepareNext(index);
    if (mounted) {
      setState(() {
        _currentIndex = index;
      });
    }
    _ensurePlaybackAfterFrame();
  }

  void _ensurePlaybackAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = _ytController;
      if (!mounted || controller == null) return;
      controller.play();
      controller.unMute();
      Future<void>.delayed(const Duration(milliseconds: 220), () {
        if (!mounted) return;
        controller.play();
      });
    });
  }

  @override
  void dispose() {
    _ytController?.dispose();
    _nextController?.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView.builder(
        scrollDirection: Axis.vertical,
        controller: _pageController,
        onPageChanged: _onPageChanged,
        itemCount: widget.shorts.length,
        itemBuilder: (_, index) {
          if (_ytController == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (index != _currentIndex) {
            return Container(color: Colors.black);
          }
          return YoutubePlayer(
            key: ValueKey(_videoIds[_currentIndex]),
            controller: _ytController!,
            showVideoProgressIndicator: true,
          );
        },
      ),
    );
  }
}
