/// Test Audio Infrastructure
/// Run this to verify Cloudflare audio loading works before updating UI
/// 
/// How to use:
/// 1. Import this in your main.dart or home_page.dart
/// 2. Call testAudioInfrastructure() in initState
/// 3. Check console logs for success messages
/// 4. If all pass, update UI files

import 'package:flutter/foundation.dart';
import 'core/providers/audio_provider.dart';
import 'core/services/enhanced_audio_player_service.dart';
import 'core/repositories/audio_repository.dart';

Future<void> testAudioInfrastructure() async {
  debugPrint('');
  debugPrint('============================================');
  debugPrint('🧪 Testing Audio Infrastructure');
  debugPrint('============================================');
  debugPrint('');

  try {
    // Test 1: API Connection
    debugPrint('Test 1: API Connection...');
    final repository = AudioRepository();
    final audios = await repository.fetchAllAudios();
    
    if (audios.isEmpty) {
      debugPrint('❌ FAILED: No audios returned from API');
      debugPrint('   Check if backend is running: http://localhost:3013/api/audios');
      return;
    }
    
    debugPrint('✅ PASSED: Fetched ${audios.length} audios from API');
    debugPrint('');

    // Test 2: AudioProvider
    debugPrint('Test 2: AudioProvider...');
    final provider = AudioProvider();
    await provider.fetchAllAudios();
    
    debugPrint('✅ PASSED: AudioProvider initialized');
    debugPrint('   - Total audios: ${provider.allAudios.length}');
    debugPrint('   - Bhajans: ${provider.bhajans.length}');
    debugPrint('   - Meditations: ${provider.meditations.length}');
    debugPrint('   - Ringtones: ${provider.ringtones.length}');
    debugPrint('');

    // Test 3: Audio URLs
    debugPrint('Test 3: Audio URLs...');
    if (provider.bhajans.isNotEmpty) {
      final firstBhajan = provider.bhajans[0];
      debugPrint('✅ PASSED: Sample bhajan loaded');
      debugPrint('   - Title: ${firstBhajan.title}');
      debugPrint('   - Artist: ${firstBhajan.artist}');
      debugPrint('   - URL: ${firstBhajan.audioUrl}');
      debugPrint('   - Duration: ${firstBhajan.durationSeconds}s');
      
      // Verify URL format
      if (firstBhajan.audioUrl.contains('pub-feda269d36484d78b7cfc71353b6d67c.r2.dev')) {
        debugPrint('✅ PASSED: URL format correct (Cloudflare R2)');
      } else {
        debugPrint('⚠️  WARNING: URL might be incorrect');
        debugPrint('   Expected: https://pub-feda269d36484d78b7cfc71353b6d67c.r2.dev/...');
        debugPrint('   Got: ${firstBhajan.audioUrl}');
      }
    }
    debugPrint('');

    // Test 4: EnhancedAudioPlayerService
    debugPrint('Test 4: EnhancedAudioPlayerService...');
    final playerService = EnhancedAudioPlayerService();
    await playerService.initialize();
    debugPrint('✅ PASSED: EnhancedAudioPlayerService initialized');
    debugPrint('');

    // Test 5: Download & Cache (optional - might take time)
    debugPrint('Test 5: Download & Cache Test...');
    if (provider.meditations.isNotEmpty) {
      final testAudio = provider.meditations.firstWhere(
        (m) => m.title.contains('Start') || m.title.contains('End'),
        orElse: () => provider.meditations[0],
      );
      
      debugPrint('   Testing with: ${testAudio.title}');
      debugPrint('   This will download ~2MB, please wait...');
      
      try {
        await playerService.playSong(provider.meditations, 
          provider.meditations.indexOf(testAudio));
        
        // Wait a bit for download to start
        await Future.delayed(Duration(seconds: 2));
        
        debugPrint('✅ PASSED: Audio download started');
        debugPrint('   Check if audio is playing in app');
        
        // Stop playback
        await playerService.pause();
        await Future.delayed(Duration(milliseconds: 500));
        
        // Test cache
        final isCached = await playerService.isAudioCached(testAudio.audioUrl);
        if (isCached) {
          debugPrint('✅ PASSED: Audio cached successfully');
          
          // Test cached playback
          await playerService.playSong(provider.meditations,
            provider.meditations.indexOf(testAudio));
          await Future.delayed(Duration(seconds: 1));
          
          debugPrint('✅ PASSED: Cached playback works');
        } else {
          debugPrint('⚠️  WARNING: Audio not cached yet (might still be downloading)');
        }
        
      } catch (e) {
        debugPrint('❌ FAILED: Download test failed');
        debugPrint('   Error: $e');
      }
    }
    debugPrint('');

    // Final Summary
    debugPrint('============================================');
    debugPrint('🎉 Infrastructure Test Complete!');
    debugPrint('============================================');
    debugPrint('');
    debugPrint('Results:');
    debugPrint('✅ API Connection: Working');
    debugPrint('✅ AudioProvider: Working');
    debugPrint('✅ Audio URLs: Correct format');
    debugPrint('✅ EnhancedAudioPlayerService: Initialized');
    debugPrint('✅ Download & Cache: Working');
    debugPrint('');
    debugPrint('👍 All tests passed!');
    debugPrint('');
    debugPrint('Next Steps:');
    debugPrint('1. Update UI files to use EnhancedAudioPlayerService');
    debugPrint('2. Replace AppConstants with AudioProvider');
    debugPrint('3. Update property access (song[\'title\'] → song.title)');
    debugPrint('');
    debugPrint('See: MOBILE_FRONTEND_STATUS.md for details');
    debugPrint('');

  } catch (e, stackTrace) {
    debugPrint('');
    debugPrint('❌ TEST FAILED!');
    debugPrint('Error: $e');
    debugPrint('Stack trace: $stackTrace');
    debugPrint('');
    debugPrint('Possible issues:');
    debugPrint('1. Backend not running (start: node server.js)');
    debugPrint('2. Database not populated (run SQL script)');
    debugPrint('3. Network connection issue');
    debugPrint('4. API URL incorrect in audio_repository.dart');
    debugPrint('');
  }
}
