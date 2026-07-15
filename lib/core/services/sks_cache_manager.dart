import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// App-wide image cache manager.
///
/// Why a custom manager?
///   flutter_cache_manager's DefaultCacheManager uses:
///     stalePeriod = 30 days   (already generous)
///     maxNrOfCacheObjects = 200
///
///   BUT it still sends a conditional HTTP revalidation request (ETag /
///   If-Modified-Since) on every cold app launch, causing a network round-trip
///   and a brief shimmer/flash even when the image is fully cached on disk.
///
///   By setting stalePeriod = 365 days the manager treats every cached file
///   as valid for a full year without hitting the network. CDN images like
///   Cloudflare R2 / Imagedelivery.net never change their URL when content
///   changes (they use a new URL), so stale-forever is safe here.
///
///   maxNrOfCacheObjects = 500 ensures all CDN images the app uses fit in
///   the disk cache without evicting each other.
class SksCacheManager extends CacheManager with ImageCacheManager {
  static const String key = 'sksImageCache';

  static final SksCacheManager _instance = SksCacheManager._();
  factory SksCacheManager() => _instance;

  SksCacheManager._()
      : super(
          Config(
            key,
            // Treat cached images as valid for 365 days — no revalidation.
            stalePeriod: const Duration(days: 365),
            // Keep up to 500 images on disk.
            maxNrOfCacheObjects: 500,
            // Use the default file service (HTTP) — no custom changes needed.
            fileService: HttpFileService(),
          ),
        );
}
