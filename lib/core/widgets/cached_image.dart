import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_theme.dart';

/// Cached image widget with skeleton loader and error handling
/// Automatically caches images from CDN to device storage
class CachedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final bool showShimmer;
  
  const CachedImage({
    Key? key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.showShimmer = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // If it's an asset path, use Image.asset
    if (!imageUrl.startsWith('http://') && !imageUrl.startsWith('https://')) {
      return ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: Image.asset(
          imageUrl,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('Asset image error: $imageUrl - $error');
            return _buildErrorWidget();
          },
        ),
      );
    }
    
    // Use cached network image for CDN images with better error handling
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) {
          if (placeholder != null) return placeholder!;
          if (showShimmer) return _buildShimmerPlaceholder();
          return _buildDefaultPlaceholder();
        },
        errorWidget: (context, url, error) {
          debugPrint('Network image error: $url - $error');
          // Don't show error widget, just show placeholder
          // This prevents "Something went wrong" errors
          return errorWidget ?? _buildDefaultPlaceholder();
        },
        // Cache configuration - more aggressive caching
        fadeInDuration: const Duration(milliseconds: 200),
        fadeOutDuration: const Duration(milliseconds: 100),
        memCacheWidth: width?.toInt(),
        memCacheHeight: height?.toInt(),
        maxWidthDiskCache: 1000,
        maxHeightDiskCache: 1000,
        // Use cache first, then network
        cacheKey: imageUrl,
      ),
    );
  }
  
  Widget _buildShimmerPlaceholder() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        color: Colors.white,
      ),
    );
  }
  
  Widget _buildDefaultPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: AppTheme.softGray,
      child: Center(
        child: CircularProgressIndicator(
          color: AppTheme.saffron,
          strokeWidth: 2,
        ),
      ),
    );
  }
  
  Widget _buildErrorWidget() {
    return Container(
      width: width,
      height: height,
      color: AppTheme.softGray,
      child: Center(
        child: Icon(
          Icons.image_not_supported,
          color: AppTheme.textSecondary,
          size: 48,
        ),
      ),
    );
  }
}

/// Circular cached image with skeleton loader
class CachedCircleImage extends StatelessWidget {
  final String imageUrl;
  final double size;
  final bool showShimmer;
  
  const CachedCircleImage({
    Key? key,
    required this.imageUrl,
    this.size = 100,
    this.showShimmer = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CachedImage(
      imageUrl: imageUrl,
      width: size,
      height: size,
      fit: BoxFit.cover,
      borderRadius: BorderRadius.circular(size / 2),
      showShimmer: showShimmer,
    );
  }
}

/// Skeleton loader for list items
class SkeletonLoader extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  
  const SkeletonLoader({
    Key? key,
    required this.width,
    required this.height,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        ),
      ),
    );
  }
}

/// Skeleton loader for cards
class SkeletonCard extends StatelessWidget {
  final double? width;
  final double height;
  
  const SkeletonCard({
    Key? key,
    this.width,
    this.height = 200,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonLoader(
            width: double.infinity,
            height: height * 0.6,
            borderRadius: BorderRadius.circular(12),
          ),
          const SizedBox(height: 12),
          SkeletonLoader(
            width: double.infinity,
            height: 16,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          SkeletonLoader(
            width: 150,
            height: 14,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}
