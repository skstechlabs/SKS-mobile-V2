import 'package:just_audio/just_audio.dart' as just_audio;
import 'package:just_audio/just_audio.dart';
import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'dart:developer' as developer;
import 'audio_handler.dart';

enum LoopMode { off, all, one }

class AudioPlayerService extends ChangeNotifier {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;
  AudioPlayerService._internal();

  late final AudioPlayer _audioPlayer;
  MyAudioHandler? _audioHandler;
  List<Map<String, String>> _playlist = [];
  int _currentIndex = 0;
  bool _isInitialized = false;
  bool _isLooping = false;
  LoopMode _loopMode = LoopMode.off;

  // Getters
  AudioPlayer get player => _audioPlayer;
  List<Map<String, String>> get playlist => _playlist;
  int get currentIndex => _currentIndex;
  bool get isInitialized => _isInitialized;
  bool get isLooping => _isLooping;
  LoopMode get loopMode => _loopMode;
  
  Map<String, String>? get currentSong { 
    if (_playlist.isEmpty || _currentIndex < 0 || _currentIndex >= _playlist.length) {
      return null;
    }
    return _playlist[_currentIndex];
  }

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      if (AudioService.running) {
        _audioHandler = MyAudioHandler();
        _audioPlayer = _audioHandler!.player;
      } else {
        _audioPlayer = AudioPlayer();
        developer.log('AudioService not running, using fallback AudioPlayer');
      }
    } catch (e) {
      // Fallback if AudioService is not initialized
      _audioPlayer = AudioPlayer();
      developer.log('Using fallback AudioPlayer: $e');
    }
    _isInitialized = true;
    
    // Listen to player state changes
    _audioPlayer.playerStateStream.listen((state) {
      notifyListeners();
    });
    
    // Listen to position changes
    _audioPlayer.positionStream.listen((position) {
      notifyListeners();
    });
    
    // Listen to duration changes
    _audioPlayer.durationStream.listen((duration) {
      notifyListeners();
    });

    // Handle song completion
    _audioPlayer.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        if (_loopMode == LoopMode.one) {
          // Loop current song
          _audioPlayer.seek(Duration.zero);
          _audioPlayer.play();
        } else if (_loopMode == LoopMode.all) {
          // Continue to next song in playlist
          nextSong();
        } else {
          // No loop, just move to next song
          nextSong();
        }
      }
    });
  }

  Future<void> setPlaylist(List<Map<String, String>> songs, {int startIndex = 0}) async {
    _playlist = songs;
    _currentIndex = startIndex;
    await _loadCurrentSong();
    notifyListeners();
  }

  Future<void> _loadCurrentSong() async {
    if (_playlist.isEmpty) return;
    
    final song = _playlist[_currentIndex];
    final url = song['url'];
    
    if (url != null && url.isNotEmpty) {
      try {
        final handler = _audioHandler;
        if (handler != null) {
          await handler.setUrl(url);
          
          // Update media item for background playback notification
          handler.setMediaItem(
            song['title'] ?? 'Unknown Title',
            song['artist'] ?? song['description'] ?? 'Unknown Artist',
          );
        } else {
          // Fallback method
          if (url.startsWith('assets/')) {
            await _audioPlayer.setAsset(url);
          } else {
            await _audioPlayer.setUrl(url);
          }
        }
      } catch (e) {
        developer.log('Error loading audio: $e');
      }
    }
  }

  Future<void> playSong(List<Map<String, String>> songs, int index) async {
    await setPlaylist(songs, startIndex: index);
    await play();
  }

  Future<void> play() async {
    try {
      final handler = _audioHandler;
      if (handler != null) {
        await handler.play();
      } else {
        await _audioPlayer.play();
      }
    } catch (e) {
      developer.log('Error playing audio: $e');
    } finally {
      notifyListeners();
    }
  }

  Future<void> pause() async {
    try {
      final handler = _audioHandler;
      if (handler != null) {
        await handler.pause();
      } else {
        await _audioPlayer.pause();
      }
    } catch (e) {
      developer.log('Error pausing audio: $e');
    } finally {
      notifyListeners();
    }
  }

  Future<void> stop() async {
    try {
      final handler = _audioHandler;
      if (handler != null) {
        await handler.stop();
      } else {
        await _audioPlayer.stop();
      }
    } catch (e) {
      developer.log('Error stopping audio: $e');
    } finally {
      _playlist = <Map<String, String>>[];
      _currentIndex = -1;
      notifyListeners();
    }
  }

  Future<void> nextSong() async {
    if (_playlist.isEmpty || _currentIndex < 0) return;
    
    try {
      _currentIndex = (_currentIndex + 1) % _playlist.length;
      await _loadCurrentSong();
      await play();
    } catch (e) {
      developer.log('Error playing next song: $e');
    } finally {
      notifyListeners();
    }
  }

  Future<void> previousSong() async {
    if (_playlist.isEmpty || _currentIndex < 0) return;
    
    try {
      _currentIndex = (_currentIndex - 1 + _playlist.length) % _playlist.length;
      await _loadCurrentSong();
      await play();
    } catch (e) {
      developer.log('Error playing previous song: $e');
    } finally {
      notifyListeners();
    }
  }

  Future<void> seekTo(Duration position) async {
    await _audioPlayer.seek(position);
  }

  Future<void> setVolume(double volume) async {
    await _audioPlayer.setVolume(volume.clamp(0.0, 1.0));
  }

  bool get isPlaying => _audioPlayer.playing;
  bool get isLoading => _audioPlayer.processingState == ProcessingState.loading;
  Duration get duration => _audioPlayer.duration ?? Duration.zero;
  Duration get position => _audioPlayer.position;

  Future<void> dispose() async {
    try {
      await _audioPlayer.dispose();
      _isInitialized = false;
      _playlist = <Map<String, String>>[];
      _currentIndex = -1;
    } catch (e) {
      developer.log('Error disposing audio player: $e');
    }
  }

  // Loop control methods
  Future<void> toggleLoopMode() async {
    switch (_loopMode) {
      case LoopMode.off:
        _loopMode = LoopMode.all;
        await _audioPlayer.setLoopMode(just_audio.LoopMode.all);
        break;
      case LoopMode.all:
        _loopMode = LoopMode.one;
        await _audioPlayer.setLoopMode(just_audio.LoopMode.one);
        break;
      case LoopMode.one:
        _loopMode = LoopMode.off;
        await _audioPlayer.setLoopMode(just_audio.LoopMode.off);
        break;
    }
    _isLooping = _loopMode != LoopMode.off;
    notifyListeners();
  }

  Future<void> setLoopMode(LoopMode mode) async {
    _loopMode = mode;
    _isLooping = mode != LoopMode.off;
    
    switch (mode) {
      case LoopMode.off:
        await _audioPlayer.setLoopMode(just_audio.LoopMode.off);
        break;
      case LoopMode.all:
        await _audioPlayer.setLoopMode(just_audio.LoopMode.all);
        break;
      case LoopMode.one:
        await _audioPlayer.setLoopMode(just_audio.LoopMode.one);
        break;
    }
    notifyListeners();
  }

  Future<void> playWithLoop(List<Map<String, String>> songs, int index, {LoopMode loopMode = LoopMode.all}) async {
    await setLoopMode(loopMode);
    await playSong(songs, index);
  }
}