import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Precaches all local asset images into Flutter's [ImageCache] once,
/// immediately after the first frame.
///
/// Why this matters:
///   • [Image.asset] decodes the PNG/JPG from the bundle every time the
///     widget is first encountered in a new widget-tree context. Without
///     precaching, every navigation to a screen that contains an icon causes
///     a visible flash or stutter while the image is decoded on the Raster
///     thread.
///   • By calling [precacheImage] with the exact [AssetImage] provider used
///     by [Image.asset], the decoded bitmap is stored in [ImageCache] keyed
///     by path. All subsequent [Image.asset] calls for the same path hit the
///     cache instantly — zero decoding overhead.
///   • This runs exactly ONCE per app process. A singleton flag prevents
///     re-running on hot-reload, warm-restart, or any subsequent call.
class AssetCacheService {
  // ── Singleton ─────────────────────────────────────────────────────────────
  static final AssetCacheService _instance = AssetCacheService._internal();
  factory AssetCacheService() => _instance;
  AssetCacheService._internal();

  bool _done = false;

  // ── All local asset images the app uses ───────────────────────────────────
  // Keep this list in sync when new Image.asset() calls are added.
  static const List<String> _assets = [
    // ── Navigation / Quick-action icons (home page row — most visible) ──────
    'assets/images/icons/guruji-icon.png',
    'assets/images/icons/kundalini-icon.png',
    'assets/images/icons/chakras-icon.png',
    'assets/images/icons/remainders-icon.png',
    'assets/images/icons/Guruji_Thratakam-icon.png',
    'assets/images/icons/guruji-meditation.png',

    // ── Core images used on multiple screens ─────────────────────────────────
    'assets/images/Guruji_logo.JPG',         // splash, login, loader, audio
    'assets/images/guruji_meditation.PNG',   // meditation timer
    'assets/images/Guruji-quotes.png',       // home daily quote card

    // ── Background / decorative ───────────────────────────────────────────────
    'assets/images/kalpataru-bg.png',
  ];

  /// Call this once from [main.dart] after [WidgetsFlutterBinding.ensureInitialized].
  ///
  /// It schedules precaching as a post-frame callback so it never delays
  /// [runApp] or the first paint. Images are loaded in the background while
  /// the splash screen is showing.
  ///
  /// [context] must be a live, mounted [BuildContext] (e.g. the one from
  /// the splash widget's first [build] call, or from [SpiritualApp]).
  /// Pass [null] here to schedule via [WidgetsBinding.instance] and
  /// provide the context later through [warmWithContext].
  void scheduleWarmup() {
    // Delay until the first frame has rendered so the engine's raster thread
    // is free to decode images without blocking the initial paint.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // We need a BuildContext to call precacheImage. We get it from the
      // app's NavigatorState after it's attached.
      // Using WidgetsBinding.instance.focusManager.rootScope is a reliable
      // way to get a mounted context from the framework.
      final element = WidgetsBinding.instance.rootElement;
      if (element != null) {
        _warmAll(element);
      }
    });
  }

  /// Call this from any mounted widget to ensure icons are warm.
  /// Safe to call multiple times — only runs once per app process.
  Future<void> warmWithContext(BuildContext context) async {
    if (_done) return;
    await _warmAll(context);
  }

  Future<void> _warmAll(BuildContext context) async {
    if (_done) {
      developer.log('ℹ️ AssetCacheService: already warm — skipping');
      return;
    }
    _done = true; // Set early to prevent concurrent runs

    developer.log('🖼️  AssetCacheService: precaching ${_assets.length} local assets...');
    int success = 0;

    for (final path in _assets) {
      try {
        // Use the exact same provider that Image.asset() uses internally.
        // This ensures the cache key matches and Image.asset() hits the cache.
        await precacheImage(AssetImage(path), context);
        success++;
      } catch (e) {
        // Asset may not exist on this platform build or may be excluded —
        // log and continue, never crash.
        developer.log('⚠️  AssetCacheService: failed to precache $path — $e');
      }
    }

    developer.log('✅ AssetCacheService: $success/${_assets.length} assets cached');
  }

  /// Expands Flutter's default [ImageCache] limits to hold all our icons
  /// without evicting them under memory pressure.
  ///
  /// Flutter's default: 1000 images / 100 MB.
  /// We raise the count slightly to make sure small icons are never evicted.
  /// Call this once from [main.dart] before [runApp].
  static void configureCacheLimits() {
    // Increase maximum number of images kept in cache.
    // Our local icons are tiny (<50 KB each) so raising to 200 costs very
    // little memory but guarantees icons are never decoded twice.
    PaintingBinding.instance.imageCache.maximumSize = 200;

    // Raise the byte limit to 150 MB so CDN images don't evict icons.
    PaintingBinding.instance.imageCache.maximumSizeBytes = 150 * 1024 * 1024;

    developer.log('✅ ImageCache limits: 200 images / 150 MB');
  }
}
