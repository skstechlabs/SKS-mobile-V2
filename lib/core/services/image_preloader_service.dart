import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../constants/cdn_images.dart';
import '../services/sks_cache_manager.dart';
import '../services/api_service.dart';
import '../services/localization_service.dart';
import 'dart:developer' as developer;

/// Service to preload critical images for better performance
class ImagePreloaderService {
  static final ImagePreloaderService _instance = ImagePreloaderService._internal();
  factory ImagePreloaderService() => _instance;
  ImagePreloaderService._internal();

  bool _isPreloaded = false;
  bool get isPreloaded => _isPreloaded;

  /// Preload critical images that are shown on home screen.
  ///
  /// Safe to call multiple times — subsequent calls with a live context
  /// will re-attempt if a previous call used an unmounted context.
  Future<void> preloadCriticalImages(BuildContext context) async {
    // If already preloaded successfully with a valid (mounted) context, skip.
    if (_isPreloaded) {
      developer.log('✅ Images already preloaded');
      return;
    }

    try {
      developer.log('🖼️  Starting image preload...');
      
      // List of critical images to preload (shown on home screen)
      final criticalImages = [
        CdnImages.guruji25,      // Daily wisdom
        CdnImages.guruji30,      // Daily wisdom
        CdnImages.guruji32,      // Guru journey card
        CdnImages.kundalini,     // Kundalini science card
        CdnImages.meditation,    // Benefits card & meditation music
        CdnImages.chakras,       // Chakras card
      ];

      // Preload images in parallel (faster)
      await Future.wait(
        criticalImages.map((imageUrl) => _preloadImage(context, imageUrl)),
        eagerError: false, // Continue even if some images fail
      );

      // Only mark as preloaded if the context is still valid
      if (context.mounted) {
        _isPreloaded = true;
        developer.log('✅ Critical images preloaded successfully');
      } else {
        developer.log('⚠️ Context unmounted after preload — will retry on next mounted context');
        // Do NOT set _isPreloaded = true so we retry from the next live context
      }
    } catch (e) {
      developer.log('⚠️  Image preload error: $e');
      // Don't mark as done — allow retry from a valid context
    }
  }

  /// Preload a single image — uses [SksCacheManager] so the download lands
  /// in the same 365-day cache bucket that [CachedImage] reads from.
  Future<void> _preloadImage(BuildContext context, String imageUrl) async {
    try {
      final imageProvider = CachedNetworkImageProvider(
        imageUrl,
        cacheManager: SksCacheManager(),
      );
      await precacheImage(imageProvider, context);
      developer.log('✅ Preloaded: ${imageUrl.split('/').last}');
    } catch (e) {
      developer.log('⚠️  Failed to preload ${imageUrl.split('/').last}: $e');
    }
  }

  /// Preload all images (for better UX after initial load)
  Future<void> preloadAllImages(BuildContext context) async {
    try {
      developer.log('🖼️  Preloading all images...');
      
      final allImages = [
        // Main images
        CdnImages.guruji,
        CdnImages.gurujiLogo,
        CdnImages.gurujiMeditation,
        CdnImages.gurujiSmile,
        CdnImages.kallaBairava,
        CdnImages.kundalini,
        CdnImages.meditation,
        CdnImages.chakras,
        CdnImages.shivaratri,
        
        // Chakra images
        CdnImages.muladhara,
        CdnImages.swadhisthana,
        CdnImages.manipura,
        CdnImages.anahatha,
        CdnImages.vishuddha,
        CdnImages.ajna,
        CdnImages.sahasrara,
        
        // Daily wisdom images
        CdnImages.guruji25,
        CdnImages.guruji26,
        CdnImages.guruji30,
        CdnImages.guruji32,
      ];

      // Preload in batches of 5 to avoid overwhelming the network
      for (var i = 0; i < allImages.length; i += 5) {
        final batch = allImages.skip(i).take(5).toList();
        await Future.wait(
          batch.map((imageUrl) => _preloadImage(context, imageUrl)),
          eagerError: false,
        );
        // Small delay between batches
        await Future.delayed(const Duration(milliseconds: 100));
      }

      developer.log('✅ All images preloaded');
    } catch (e) {
      developer.log('⚠️  Error preloading all images: $e');
    }
  }

  /// Clear preload status (for testing)
  void reset() {
    _isPreloaded = false;
  }

  /// Preload meditation sounds in the background so they're ready when the
  /// user navigates to the Meditation page (zero wait time on play).
  /// Call this once after app boot — it caches files to disk and pre-buffers
  /// the audio players so `play()` is instant.
  static Future<void> preloadMeditationSounds() async {
    try {
      final languageCode = LocalizationService().currentLocale.languageCode;
      final languageMap = {
        'en': 'english', 'hi': 'hindi', 'te': 'telugu', 'kn': 'kannada',
      };
      final lang = languageMap[languageCode] ?? 'english';

      final response = await ApiService().get(
        '/api/audios',
        queryParameters: {'category': 'meditation_sound', 'language': lang},
      );

      if (response['success'] != true) return;
      final audios = response['audios'] as List? ?? [];

      final directory = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${directory.path}/meditation_sounds');
      if (!await cacheDir.exists()) await cacheDir.create(recursive: true);

      for (final audio in audios) {
        final url = audio['audio_url'] as String?;
        final title = (audio['title'] as String? ?? '').toLowerCase();
        if (url == null) continue;
        final filename = title.contains('start')
            ? 'meditation_start_$lang.mp3'
            : title.contains('end')
                ? 'meditation_end_$lang.mp3'
                : null;
        if (filename == null) continue;

        final file = File('${cacheDir.path}/$filename');
        if (!await file.exists()) {
          final res = await http.get(Uri.parse(url));
          if (res.statusCode == 200) {
            await file.writeAsBytes(res.bodyBytes);
            debugPrint('✅ Pre-cached meditation sound: $filename');
          }
        } else {
          debugPrint('✅ Meditation sound already cached: $filename');
        }
      }
    } catch (e) {
      debugPrint('⚠️ Background meditation sound preload failed: $e');
    }
  }
}
