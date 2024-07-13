import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../../../utils/widgets/loader.dart';

class ViralShotsSection extends StatelessWidget {
  final YouTubeShortsController _controller = Get.put(YouTubeShortsController());

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TRENDING SHORTS',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        Obx(() {
          if (_controller.isLoading.value) {
            return Center(child: CircularProgressIndicator());
          } else if (_controller.shorts.isEmpty) {
            return Center(child: Text('No shorts found'));
          } else {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _controller.shorts.map((short) => _buildViralShotItem(short)).toList(),
              ),
            );
          }
        }),
      ],
    );
  }

  Widget _buildViralShotItem(YouTubeShort short) {
    return GestureDetector(
      onTap: () {
        int index = _controller.shorts.indexOf(short);
        Get.to(() => ShortVideoPlayer(shorts: _controller.shorts, initialIndex: index));
      },
      child: Container(
        margin: EdgeInsets.all(5),
        width: 120,
        height: 220,
        decoration: BoxDecoration(
          color: Color(0xff1E1E1E),
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
                placeholder: (context, url) => Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) => Icon(Icons.error),
              ),
            ),
            Container(
              width: 120,
              height: 220,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(0.9)
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: short.channelImage,
                            height: 30,
                            width: 30,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Center(child: CircularProgressIndicator()),
                            errorWidget: (context, url, error) => Icon(Icons.error),
                          ),
                        ),
                        SizedBox(width: 5,),
                        Expanded(
                          child: Text(
                            short.channelName,
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    Spacer(),
                    Text(
                      short.title,
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          int index = _controller.shorts.indexOf(short);
                          Get.to(() => ShortVideoPlayer(shorts: _controller.shorts, initialIndex: index));
                        },
                        style: ElevatedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.symmetric(vertical: 1, horizontal: 8),
                          primary: Color(0xff00D701),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text('Watch Now',style: TextStyle(color: Colors.black),),
                      ),
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
  final CacheManager _cacheManager = CacheManager(Config(
    'videoCache',
    stalePeriod: const Duration(days: 7),
    maxNrOfCacheObjects: 20,
  ));

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _initializeController(_currentIndex);
    _preloadNextVideo(_currentIndex + 1);  // Preload the next video
  }

  void _initializeController(int index) async {
    final videoId = YoutubePlayer.convertUrlToId(widget.shorts[index].link);
    if (videoId != null) {
      final videoUrl = 'https://www.youtube.com/watch?v=$videoId';
      final fileInfo = await _cacheManager.getFileFromCache(videoUrl);
      if (fileInfo == null) {
        await _cacheManager.downloadFile(videoUrl);
      }

      _youtubePlayerController?.dispose();
      _youtubePlayerController = YoutubePlayerController(
        initialVideoId: videoId,
        flags: YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
          forceHD: false,
          hideControls: true,
          hideThumbnail: true,
        ),
      );
      setState(() {});
    } else {
      log('Error converting URL to video ID');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load video')));
    }
  }

  void _preloadNextVideo(int index) {
    if (index < widget.shorts.length) {
      final videoId = YoutubePlayer.convertUrlToId(widget.shorts[index].link);
      if (videoId != null) {
        final videoUrl = 'https://www.youtube.com/watch?v=$videoId';
        _cacheManager.downloadFile(videoUrl);
      }
    }
  }

  void _onControllerChange(int index) {
    _initializeController(index);
    _preloadNextVideo(index + 1);  // Preload the next video
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
            _onControllerChange(index);
          });
        },
        itemBuilder: (context, index) {
          return _youtubePlayerController != null
              ? YoutubePlayer(
            bufferIndicator: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('LOADING'),
                  RainbowLoadingBar(width: 80, height: 2),
                ],
              ),
            ),
            key: ObjectKey(_youtubePlayerController),
            controller: _youtubePlayerController!,
            showVideoProgressIndicator: true,
            onReady: () {
              log('Player is ready');
            },
            onEnded: (data) {
              if (index + 1 < widget.shorts.length) {
                _onControllerChange(index + 1);
              }
            },
          )
              : Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('LOADING'),
                RainbowLoadingBar(width: 80, height: 2),
              ],
            ),
          );
        },
      ),
    );
  }
}
class ApiService {
  static const String _apiKey = 'ff0566d621126eb6442cc76e33807d74dde7473b9417be93dd1cbc757a6c6baf'; // Replace with your SerpApi key
  static const String _baseUrl = 'https://serpapi.com/search';

  Future<List<YouTubeShort>> fetchYouTubeShorts(String query) async {
    final response = await http.get(Uri.parse('$_baseUrl?engine=youtube&search_query=$query&api_key=$_apiKey'));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body)['video_results'];
      // Filter out live streams
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
    fetchYouTubeShorts();
    super.onInit();
  }

  void fetchYouTubeShorts() async {
    try {
      isLoading(true);
      var fetchedShorts = await _apiService.fetchYouTubeShorts('live Gaming Shorts');
      if (fetchedShorts != null) {
        shorts.value = fetchedShorts;
      }
    } finally {
      isLoading(false);
    }
  }
}
