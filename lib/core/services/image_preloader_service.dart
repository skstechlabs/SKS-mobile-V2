import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../constants/cdn_images.dart';
import 'dart:developer' as developer;

/// Service to preload critical images for better performance
class ImagePreloaderService {
  static final ImagePreloaderService _instance = ImagePreloaderService._internal();
  factory ImagePreloaderService() => _instance;
  ImagePreloaderService._internal();

  bool _isPreloaded = false;
  bool get isPreloaded => _isPreloaded;

  /// Preload critical images that are shown on home screen
  Future<void> preloadCriticalImages(BuildContext context) async {
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

      _isPreloaded = true;
      developer.log('✅ Critical images preloaded successfully');
    } catch (e) {
      developer.log('⚠️  Image preload error: $e');
      // Don't throw - app should work even if preload fails
      _isPreloaded = true; // Mark as done to avoid retry
    }
  }

  /// Preload a single image
  Future<void> _preloadImage(BuildContext context, String imageUrl) async {
    try {
      // Use CachedNetworkImageProvider to cache the image
      final imageProvider = CachedNetworkImageProvider(imageUrl);
      await precacheImage(imageProvider, context);
      developer.log('✅ Preloaded: ${imageUrl.split('/').last}');
    } catch (e) {
      developer.log('⚠️  Failed to preload ${imageUrl.split('/').last}: $e');
      // Don't throw - continue with other images
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
}
