// Optimized and modularized ViralShotsSection with efficient YouTube shorts handling
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../../../utils/widgets/glow_neon_loader.dart';

class ViralShotsSection extends StatelessWidget {
  final YouTubeShortsController _controller = Get.put(YouTubeShortsController());

  ViralShotsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'TRENDING SHORTS',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Obx(() {
          if (_controller.isLoading.value) {
            return const Center(child: RainbowGlowingLoader(size: 50));
          }
          if (_controller.shorts.isEmpty) {
            return const Center(child: Text('No shorts found', style: TextStyle(color: Colors.white)));
          }
          return SizedBox(
            height: 220,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _controller.shorts.length,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) => ViralShotItem(
                short: _controller.shorts[index],
                index: index,
                controller: _controller,
              ),
            ),
          );
        })
      ],
    );
  }
}

class ViralShotItem extends StatelessWidget {
  final YouTubeShort short;
  final int index;
  final YouTubeShortsController controller;

  const ViralShotItem({super.key, required this.short, required this.index, required this.controller});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.to(() => ShortVideoPlayer(shorts: controller.shorts, initialIndex: index)),
      child: Container(
        width: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: const Color(0xff1E1E1E),
        ),
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: short.thumbnail,
                width: 120,
                height: 220,
                fit: BoxFit.cover,
                placeholder: (context, url) => const RainbowGlowingLoader(size: 30),
                errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.red),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: short.channelImage,
                          height: 30,
                          width: 30,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const RainbowGlowingLoader(size: 20),
                          errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.red),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(short.channelName,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      )
                    ],
                  ),
                  const Spacer(),
                  Text(short.title,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 5),
                  ElevatedButton(
                    onPressed: () => Get.to(() => ShortVideoPlayer(shorts: controller.shorts, initialIndex: index)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xffDE3A3A),
                      padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Watch Now', style: TextStyle(color: Colors.white, fontSize: 10)),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class ShortVideoPlayer extends StatefulWidget {
  final List<YouTubeShort> shorts;
  final int initialIndex;

  const ShortVideoPlayer({super.key, required this.shorts, required this.initialIndex});

  @override
  State<ShortVideoPlayer> createState() => _ShortVideoPlayerState();
}

class _ShortVideoPlayerState extends State<ShortVideoPlayer> {
  late PageController _pageController;
  YoutubePlayerController? _youtubeController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _initializeController(_currentIndex);
  }

  void _initializeController(int index) {
    final videoId = YoutubePlayer.convertUrlToId(widget.shorts[index].link);
    if (videoId != null) {
      _youtubeController?.dispose();
      _youtubeController = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(autoPlay: true, mute: false, hideControls: true, hideThumbnail: true),
      );
      setState(() {});
    }
  }

  @override
  void dispose() {
    _youtubeController?.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: widget.shorts.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
            _initializeController(index);
          });
        },
        itemBuilder: (_, index) => YoutubePlayer(
          key: ObjectKey(_youtubeController),
          controller: _youtubeController!,
          showVideoProgressIndicator: true,
        ),
      ),
    );
  }
}

class ApiService {
  static const String _apiKey = 'ff0566d621126eb6442cc76e33807d74dde7473b9417be93dd1cbc757a6c6baf';
  static const String _baseUrl = 'https://serpapi.com/search';

  Future<List<YouTubeShort>> fetchYouTubeShorts(String query) async {
    final response = await http.get(Uri.parse('$_baseUrl?engine=youtube&search_query=$query&api_key=$_apiKey'));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body)['video_results'];
      data = data.where((item) => item['live'] == null || !item['live']).toList();
      return data.map((item) => YouTubeShort.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load YouTube shorts');
    }
  }
}

class YouTubeShort {
  final String title;
  final String link;
  final String thumbnail;
  final String channelName;
  final String channelImage;

  YouTubeShort({
    required this.title,
    required this.link,
    required this.thumbnail,
    required this.channelName,
    required this.channelImage,
  });

  factory YouTubeShort.fromJson(Map<String, dynamic> json) {
    return YouTubeShort(
      title: json['title'],
      link: json['link'],
      thumbnail: json['thumbnail']['static'],
      channelName: json['channel']['name'],
      channelImage: json['channel']['thumbnail'],
    );
  }
}

class YouTubeShortsController extends GetxController {
  final shorts = <YouTubeShort>[].obs;
  final isLoading = true.obs;
  final ApiService _api = ApiService();

  @override
  void onInit() {
    super.onInit();
    fetchYouTubeShorts();
  }

  Future<void> fetchYouTubeShorts() async {
    isLoading(true);
    try {
      shorts.value = await _api.fetchYouTubeShorts('Gaming Shorts');
    } catch (e) {
      log('Error fetching shorts: $e');
    } finally {
      isLoading(false);
    }
  }
}