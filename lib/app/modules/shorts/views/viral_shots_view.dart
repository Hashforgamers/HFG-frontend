import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class ViralShotsSection extends StatelessWidget {
  final YouTubeShortsController _controller = Get.put(YouTubeShortsController());

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
        GetBuilder<YouTubeShortsController>(
          builder: (controller) {
            if (controller.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            } else if (controller.shorts.isEmpty) {
              return const Center(
                child: Text(
                  'No shorts found',
                  style: TextStyle(color: Colors.white),
                ),
              );
            } else {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: controller.shorts
                      .map((short) => _buildViralShotItem(short, controller))
                      .toList(),
                ),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildViralShotItem(YouTubeShort short, YouTubeShortsController controller) {
    return GestureDetector(
      onTap: () {
        int index = controller.shorts.indexOf(short);
        Get.to(() => ShortVideoPlayer(shorts: controller.shorts, initialIndex: index));
      },
      child: Container(
        margin: const EdgeInsets.all(5),
        width: 120,
        height: 220,
        decoration: BoxDecoration(
          color: const Color(0xff1E1E1E),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: short.thumbnail,
                height: 220,
                width: 120,
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.red),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.9),
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
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
                            placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                            errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.red),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            short.channelName,
                            style: const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      short.title,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    ElevatedButton(
                      onPressed: () {
                        int index = controller.shorts.indexOf(short);
                        Get.to(() => ShortVideoPlayer(shorts: controller.shorts, initialIndex: index));
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 1, horizontal: 8),
                        backgroundColor: const Color(0xff00D701),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Watch Now', style: TextStyle(color: Colors.black)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class ShortVideoPlayer extends StatefulWidget {
  final List<YouTubeShort> shorts;
  final int initialIndex;

  ShortVideoPlayer({required this.shorts, this.initialIndex = 0});

  @override
  _ShortVideoPlayerState createState() => _ShortVideoPlayerState();
}

class _ShortVideoPlayerState extends State<ShortVideoPlayer> {
  late PageController _pageController;
  YoutubePlayerController? _youtubePlayerController;
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
      _youtubePlayerController?.dispose();
      _youtubePlayerController = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
          hideControls: true,
          hideThumbnail: true,
        ),
      );
      setState(() {});
    }
  }

  @override
  void dispose() {
    _youtubePlayerController?.dispose();
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
        itemBuilder: (context, index) {
          return YoutubePlayer(
            key: ObjectKey(_youtubePlayerController),
            controller: _youtubePlayerController!,
            showVideoProgressIndicator: true,
          );
        },
      ),
    );
  }
}
class ApiService {
  static const String _apiKey = 'ff0566d621126eb6442cc76e33807d74dde7473b9417be93dd1cbc757a6c6baf'; // Replace with your SerpAPI key
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
  var shorts = <YouTubeShort>[].obs;
  var isLoading = true.obs;
  final ApiService _apiService = ApiService();

  @override
  void onInit() {
    super.onInit();
    fetchYouTubeShorts();
  }

  Future<void> fetchYouTubeShorts() async {
    isLoading(true);
    try {
      shorts.value = await _apiService.fetchYouTubeShorts('Gaming Shorts');
    } catch (e) {
      log('Error fetching YouTube shorts: $e');
    } finally {
      isLoading(false);
    }
  }
}
