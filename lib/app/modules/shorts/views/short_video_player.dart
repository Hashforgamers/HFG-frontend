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
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _loadController(_currentIndex);
  }

  void _loadController(int index) {
    final id = YoutubePlayer.convertUrlToId(widget.shorts[index].link);
    if (id != null) {
      _ytController?.dispose();
      _ytController = YoutubePlayerController(
        initialVideoId: id,
        flags: const YoutubePlayerFlags(autoPlay: true, mute: false),
      );
      setState(() {});
    }
  }

  @override
  void dispose() {
    _ytController?.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView.builder(
        scrollDirection: Axis.vertical,
        controller: _pageController,
        onPageChanged: (index) => _loadController(index),
        itemCount: widget.shorts.length,
        itemBuilder: (_, __) {
          return YoutubePlayer(
            key: ObjectKey(_ytController),
            controller: _ytController!,
            showVideoProgressIndicator: true,
          );
        },
      ),
    );
  }
}
