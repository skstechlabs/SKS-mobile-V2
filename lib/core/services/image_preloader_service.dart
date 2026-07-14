import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../constants/cdn_images.dart';
import 'dart:developer' as developer;

/// Image preloader that downloads CDN images to a plain file cache.
///
/// Why not DefaultCacheManager?
/// flutter_cache_manager stores metadata in SQLite (cacheObject table).
/// That table is created lazily — calling getSingleFile() before the DB
/// is initialized throws "no such table: cacheObject". This is especially
/// likely at app startup / after clearing cache / first install.
///
/// Our solution: use plain http.get() + file I/O. No SQLite dependency.
/// Files are stored in getApplicationDocumentsDirectory()/img_cache/.
/// CachedNetworkImage still uses its own manager for rendering — we just
/// ensure the files exist on disk so rendering is instant.
class ImagePreloaderService {
  static final ImagePreloaderService _instance =
      ImagePreloaderService._internal();
  factory ImagePreloaderService() => _instance;
  ImagePreloaderService._internal();

  bool _phase1Done = false;
  bool _phase2Done = false;
  Directory? _cacheDir;

  static const _critical = [
    CdnImages.guruji25,
    CdnImages.guruji30,
    CdnImages.guruji32,
    CdnImages.gurujiSmile,
    CdnImages.gurujiMeditation,
    CdnImages.kundalini,
    CdnImages.meditation,
    CdnImages.chakras,
    CdnImages.guruji,
  ];

  static const _secondary = [
    CdnImages.gurujiLogo,
    CdnImages.kallaBairava,
    CdnImages.shivaratri,
    CdnImages.guruji26,
    CdnImages.muladhara,
    CdnImages.swadhisthana,
    CdnImages.manipura,
    CdnImages.anahatha,
    CdnImages.vishuddha,
    CdnImages.ajna,
    CdnImages.sahasrara,
  ];

  Future<Directory> get _dir async {
    _cacheDir ??= Directory(
        '${(await getApplicationDocumentsDirectory()).path}/img_cache')
      ..createSync(recursive: true);
    return _cacheDir!;
  }

  // ── Phase 1: Download to plain file cache (no SQLite) ───────────────────

  Future<void> preloadToDisk() async {
    if (_phase1Done) return;
    try {
      developer.log('🖼️ Preloading critical images to disk...');
      await Future.wait(
        _critical.map(_downloadToFile),
        eagerError: false,
      ).timeout(const Duration(seconds: 12), onTimeout: () {
        developer.log('⏰ Image preload timeout — continuing');
        return [];
      });
      _phase1Done = true;
      developer.log('✅ Critical images cached to disk');
      _preloadSecondaryInBackground();
    } catch (e) {
      developer.log('⚠️ preloadToDisk error: $e');
      _phase1Done = true;
    }
  }

  // ── Phase 2: Warm Flutter's in-memory image cache ───────────────────────

  Future<void> warmMemoryCache(BuildContext context) async {
    if (_phase2Done) return;
    try {
      developer.log('🖼️ Warming in-memory image cache...');
      await Future.wait(
        _critical.map((url) => _precache(context, url)),
        eagerError: false,
      ).timeout(const Duration(seconds: 5), onTimeout: () => []);
      _phase2Done = true;
      developer.log('✅ In-memory cache warmed');
    } catch (e) {
      developer.log('⚠️ warmMemoryCache error: $e');
      _phase2Done = true;
    }
  }

  // ── Phase 3: Background ──────────────────────────────────────────────────

  void _preloadSecondaryInBackground() {
    Future.microtask(() async {
      try {
        for (final url in _secondary) {
          await _downloadToFile(url);
          await Future.delayed(const Duration(milliseconds: 200));
        }
        developer.log('✅ Secondary images cached to disk');
      } catch (e) {
        developer.log('⚠️ Secondary preload error: $e');
      }
    });
  }

  // ── Legacy aliases (existing call sites keep working) ───────────────────

  Future<void> preloadCriticalImages(BuildContext context) async {
    await preloadToDisk();
    if (context.mounted) await warmMemoryCache(context);
  }

  void preloadSecondaryImages() => _preloadSecondaryInBackground();

  // ── Core helpers ─────────────────────────────────────────────────────────

  /// Download [url] to a deterministic file path. Idempotent — skips if
  /// file already exists and is non-empty (avoids re-downloading).
  Future<void> _downloadToFile(String url) async {
    try {
      final dir = await _dir;
      final key = md5.convert(utf8.encode(url)).toString();
      final file = File('${dir.path}/$key');

      if (await file.exists() && await file.length() > 0) {
        return; // already cached
      }

      final response = await http.get(
        Uri.parse(url),
        headers: const {
          'Accept': 'image/webp,image/apng,image/*,*/*;q=0.8',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        await file.writeAsBytes(response.bodyBytes);
        developer.log('✅ Cached: ${url.split('/').last}');
      }
    } catch (e) {
      developer.log('⚠️ Failed to cache ${url.split('/').last}: $e');
    }
  }

  Future<void> _precache(BuildContext context, String url) async {
    try {
      if (!context.mounted) return;
      // Use CachedNetworkImageProvider — it uses cached_network_image's own
      // manager which initializes correctly at render time.
      await precacheImage(CachedNetworkImageProvider(url), context);
    } catch (_) {}
  }

  Future<void> refreshAll(BuildContext context) async {
    _phase1Done = false;
    _phase2Done = false;
    try {
      final dir = await _dir;
      if (await dir.exists()) await dir.delete(recursive: true);
      await dir.create(recursive: true);
    } catch (_) {}
    await preloadToDisk();
    if (context.mounted) await warmMemoryCache(context);
  }
}
