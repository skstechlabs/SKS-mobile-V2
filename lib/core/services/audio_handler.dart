import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';

class MyAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  static final MyAudioHandler _instance = MyAudioHandler._internal();
  factory MyAudioHandler() => _instance;
  MyAudioHandler._internal();

  final AudioPlayer _player = AudioPlayer();
  
  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async {
    // Implementation will be added by the audio service
  }

  @override
  Future<void> skipToPrevious() async {
    // Implementation will be added by the audio service
  }

  Future<void> setUrl(String url) async {
    try {
      if (url.startsWith('assets/')) {
        await _player.setAsset(url);
      } else {
        await _player.setUrl(url);
      }
      
      // Update media item for notification
      mediaItem.add(MediaItem(
        id: url,
        album: 'SKS App',
        title: 'Audio Track',
        artist: 'SKS',
        duration: _player.duration,
        artUri: Uri.parse('https://example.com/albumart.jpg'),
      ));
    } catch (e) {
      if (kDebugMode) {
        print('Error loading audio: $e');
      }
    }
  }

  void setMediaItem(String title, String artist, {Duration? duration}) {
    mediaItem.add(MediaItem(
      id: title,
      album: 'SKS App',
      title: title,
      artist: artist,
      duration: duration ?? _player.duration,
      artUri: Uri.parse('https://example.com/albumart.jpg'),
    ));
  }

  AudioPlayer get player => _player;
}