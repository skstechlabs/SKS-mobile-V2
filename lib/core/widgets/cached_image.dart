import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_theme.dart';
import '../services/sks_cache_manager.dart';

/// Cached image widget with skeleton loader, retry logic, and error handling.
///
/// Fixes for images not loading on some devices:
/// - No disk cache size limit (removed maxWidthDiskCache/maxHeightDiskCache)
/// - Proper cache headers to prevent CDN blocking
/// - Retry on error (up to 3 times)
/// - Timeout via errorWidget fallback
/// - Works on all Android versions including Android 14+
class CachedImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final bool showShimmer;

  const CachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.showShimmer = true,
  });

  @override
  State<CachedImage> createState() => _CachedImageState();
}

class _CachedImageState extends State<CachedImage> {
  int _retryCount = 0;
  static const int _maxRetries = 3;
  // Increment key to force CachedNetworkImage to reload on retry
  int _imageKey = 0;

  void _onError(dynamic error) {
    final errorStr = error?.toString() ?? '';

    // These errors will NEVER self-recover — stop retrying immediately
    final isFatal = errorStr.contains('Failed host lookup') ||
        errorStr.contains('No address associated with hostname') ||
        errorStr.contains('SocketException') ||
        errorStr.contains('errno = 7') ||
        errorStr.contains('statusCode: 404') ||
        errorStr.contains('Invalid statusCode: 404') ||
        errorStr.contains('EncodingError') ||        // corrupt / undecodable image
        errorStr.contains('cannot be decoded') ||    // same, different phrasing
        errorStr.contains('Invalid image data') ||
        errorStr.contains('FormatException');        // bad image format

    if (!isFatal && _retryCount < _maxRetries && mounted) {
      Future.delayed(Duration(milliseconds: 800 * (_retryCount + 1)), () {
        if (mounted) {
          setState(() {
            _retryCount++;
            _imageKey++;
          });
        }
      });
    } else if (mounted) {
      // Fatal or max retries — jump straight to error widget, no more spinning
      setState(() => _retryCount = _maxRetries);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Asset images — no network needed
    if (!widget.imageUrl.startsWith('http://') &&
        !widget.imageUrl.startsWith('https://')) {
      return ClipRRect(
        borderRadius: widget.borderRadius ?? BorderRadius.zero,
        child: Image.asset(
          widget.imageUrl,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          errorBuilder: (_, __, ___) => _buildErrorWidget(),
        ),
      );
    }

    return ClipRRect(
      borderRadius: widget.borderRadius ?? BorderRadius.zero,
      child: CachedNetworkImage(
        key: ValueKey('${widget.imageUrl}_$_imageKey'),
        imageUrl: widget.imageUrl,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        // Use the app-wide cache manager: 365-day stale period, 500 images.
        // This prevents any network revalidation for images already on disk.
        cacheManager: SksCacheManager(),
        httpHeaders: const {
          'Accept': 'image/webp,image/apng,image/*,*/*;q=0.8',
        },
        placeholder: (context, url) {
          if (widget.placeholder != null) return widget.placeholder!;
          if (widget.showShimmer) return _buildShimmerPlaceholder();
          return _buildDefaultPlaceholder();
        },
        errorWidget: (context, url, error) {
          final errorStr = error?.toString() ?? '';
          final is404 = errorStr.contains('statusCode: 404') ||
              errorStr.contains('Invalid statusCode: 404');
          final isFatal = is404 ||
              errorStr.contains('EncodingError') ||
              errorStr.contains('cannot be decoded') ||
              errorStr.contains('Invalid image data') ||
              errorStr.contains('FormatException');
          // Log only on first attempt, and never spam encoding errors
          if (_retryCount == 0) {
            debugPrint('❌ Image load error (attempt $_retryCount): $url — $error');
          }
          _onError(error);
          // Show error widget immediately for fatal errors, spinner while retrying
          return (isFatal || _retryCount >= _maxRetries)
              ? (widget.errorWidget ?? _buildErrorWidget())
              : _buildDefaultPlaceholder();
        },
        fadeInDuration: const Duration(milliseconds: 200),
        fadeOutDuration: const Duration(milliseconds: 100),
        cacheKey: widget.imageUrl,
      ),
    );
  }

  Widget _buildShimmerPlaceholder() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: widget.width,
        height: widget.height,
        color: Colors.white,
      ),
    );
  }

  Widget _buildDefaultPlaceholder() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: AppTheme.softGray,
      child: const Center(
        child: CircularProgressIndicator(
          color: AppTheme.saffron,
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: AppTheme.softGray,
      child: const Center(
        child: Icon(
          Icons.image_not_supported,
          color: AppTheme.textSecondary,
          size: 40,
        ),
      ),
    );
  }
}

/// Circular cached image
class CachedCircleImage extends StatelessWidget {
  final String imageUrl;
  final double size;
  final bool showShimmer;

  const CachedCircleImage({
    super.key,
    required this.imageUrl,
    this.size = 100,
    this.showShimmer = true,
  });

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
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

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
    super.key,
    this.width,
    this.height = 200,
  });

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
            color: Colors.black.withValues(alpha: 0.05),
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
