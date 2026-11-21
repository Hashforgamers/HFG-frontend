import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:hash/core/utils/app_logger.dart';

class OptimizedImageCacheManager {
  static final OptimizedImageCacheManager _instance = OptimizedImageCacheManager._internal();
  factory OptimizedImageCacheManager() => _instance;
  OptimizedImageCacheManager._internal();

  // Custom cache manager for better memory management
  static final CustomCacheManager _customCacheManager = CustomCacheManager();
  
  // Cache for frequently used images
  final Map<String, ImageProvider> _imageCache = {};
  
  // Maximum cache size
  static const int maxCacheSize = 50;
  
  // Image dimensions for optimization
  static const Map<String, int> _imageDimensions = {
    'avatar': 80,
    'thumbnail': 200,
    'banner': 400,
    'full': 800,
  };

  /// Get optimized image provider with caching
  ImageProvider getOptimizedImage(
    String imageUrl, {
    String? type,
    int? width,
    int? height,
    Map<String, String>? headers,
  }) {
    final cacheKey = _generateCacheKey(imageUrl, type, width, height);
    
    // Return cached image if available
    if (_imageCache.containsKey(cacheKey)) {
      return _imageCache[cacheKey]!;
    }
    
    // Create optimized image provider
    final imageProvider = CachedNetworkImageProvider(
      imageUrl,
      cacheManager: _customCacheManager,
      cacheKey: cacheKey,
      maxWidth: width ?? _imageDimensions[type ?? 'full'],
      maxHeight: height,
      headers: headers,
      errorListener: (error) => _handleImageError(cacheKey, error),
    );
    
    // Cache the image provider
    _cacheImage(cacheKey, imageProvider);
    
    return imageProvider;
  }

  /// Get optimized avatar image
  ImageProvider getAvatarImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return const AssetImage('assets/images/default_avatar.png');
    }
    
    return getOptimizedImage(
      imageUrl,
      type: 'avatar',
      width: _imageDimensions['avatar'],
      height: _imageDimensions['avatar'],
    );
  }

  /// Get optimized thumbnail image
  ImageProvider getThumbnailImage(String imageUrl) {
    return getOptimizedImage(
      imageUrl,
      type: 'thumbnail',
      width: _imageDimensions['thumbnail'],
    );
  }

  /// Get optimized banner image
  ImageProvider getBannerImage(String imageUrl) {
    return getOptimizedImage(
      imageUrl,
      type: 'banner',
      width: _imageDimensions['banner'],
    );
  }

  /// Preload images for better performance
  Future<void> preloadImages(List<String> imageUrls, BuildContext context, {String? type}) async {
    for (final imageUrl in imageUrls) {
      try {
        final imageProvider = getOptimizedImage(imageUrl, type: type);
        await precacheImage(imageProvider, context);
      } catch (e) {
        AppLogger.d('Failed to preload image: $imageUrl - $e');
      }
    }
  }

  /// Clear cache to free memory
  void clearCache() {
    _imageCache.clear();
    _customCacheManager.emptyCache();
  }

  /// Remove specific image from cache
  void removeFromCache(String imageUrl, {String? type, int? width, int? height}) {
    final cacheKey = _generateCacheKey(imageUrl, type, width, height);
    _imageCache.remove(cacheKey);
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'cachedImages': _imageCache.length,
      'maxCacheSize': maxCacheSize,
      'cacheUsage': '${_imageCache.length / maxCacheSize * 100}%',
    };
  }

  String _generateCacheKey(String imageUrl, String? type, int? width, int? height) {
    return '${imageUrl}_${type ?? 'full'}_${width ?? 0}_${height ?? 0}';
  }

  void _cacheImage(String cacheKey, ImageProvider imageProvider) {
    // Manage cache size
    if (_imageCache.length >= maxCacheSize) {
      // Remove oldest entries (simple LRU)
      final oldestKey = _imageCache.keys.first;
      _imageCache.remove(oldestKey);
    }
    
    _imageCache[cacheKey] = imageProvider;
  }

  void _handleImageError(String cacheKey, dynamic error) {
    AppLogger.d('Image loading error for $cacheKey: $error');
    _imageCache.remove(cacheKey);
  }
}

/// Custom cache manager with optimized settings
class CustomCacheManager extends CacheManager with ImageCacheManager {
  static const key = 'optimizedImageCache';
  
  static CustomCacheManager? _instance;
  
  factory CustomCacheManager() {
    _instance ??= CustomCacheManager._();
    return _instance!;
  }
  
  CustomCacheManager._() : super(
    Config(
      key,
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 100,
      repo: JsonCacheInfoRepository(databaseName: key),
      fileService: HttpFileService(),
    ),
  );
}

/// Optimized image widget
class OptimizedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final String? type;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;

  const OptimizedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.type,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final imageProvider = OptimizedImageCacheManager().getOptimizedImage(
      imageUrl,
      type: type,
      width: width?.toInt(),
      height: height?.toInt(),
    );

    Widget imageWidget = CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => placeholder ?? _buildDefaultPlaceholder(),
      errorWidget: (context, url, error) => errorWidget ?? _buildDefaultErrorWidget(),
      cacheManager: CustomCacheManager(),
      memCacheWidth: width?.toInt(),
      memCacheHeight: height?.toInt(),
    );

    if (borderRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _buildDefaultPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[800],
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
        ),
      ),
    );
  }

  Widget _buildDefaultErrorWidget() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[900],
      child: const Icon(
        Icons.error_outline,
        color: Colors.grey,
        size: 24,
      ),
    );
  }
}
