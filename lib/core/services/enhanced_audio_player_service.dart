import 'package:just_audio/just_audio.dart' as just_audio;
import 'package:just_audio/just_audio.dart';
import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'dart:developer' as developer;
import '../models/audio_model.dart';
import 'audio_cache_service.dart';
import 'audio_handler.dart';

enum LoopMode { off, all, one }

class EnhancedAudioPlayerService extends ChangeNotifier {
  static final EnhancedAudioPlayerService _instance =
      EnhancedAudioPlayerService._internal();
  factory EnhancedAudioPlayerService() => _instance;
  EnhancedAudioPlayerService._internal();

  late final AudioPlayer _audioPlayer;
  MyAudioHandler? _audioHandler;
  final AudioCacheService _cacheService = AudioCacheService();
  
  List<AudioModel> _playlist = [];
  int _currentIndex = 0;
  bool _isInitialized = false;
  bool _isLooping = false;
  LoopMode _loopMode = LoopMode.off;
  bool _isLoadingAudio = false;
  double _downloadProgress = 0.0;

  // Getters
  AudioPlayer get player => _audioPlayer;
  List<AudioModel> get playlist => _playlist;
  int get currentIndex => _currentIndex;
  bool get isInitialized => _isInitialized;
  bool get isLooping => _isLooping;
  LoopMode get loopMode => _loopMode;
  bool get isLoadingAudio => _isLoadingAudio;
  double get downloadProgress => _downloadProgress;

  AudioModel? get currentSong {
    if (_playlist.isEmpty ||
        _currentIndex < 0 ||
        _currentIndex >= _playlist.length) {
      return null;
    }
    return _playlist[_currentIndex];
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize cache service
      await _cacheService.initialize();

      if (AudioService.running) {
        _audioHandler = MyAudioHandler();
        _audioPlayer = _audioHandler!.player;
      } else {
        _audioPlayer = AudioPlayer();
        developer.log('AudioService not running, using fallback AudioPlayer');
      }
    } catch (e) {
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
          _audioPlayer.seek(Duration.zero);
          _audioPlayer.play();
        } else if (_loopMode == LoopMode.all) {
          nextSong();
        } else {
          nextSong();
        }
      }
    });
  }

  Future<void> setPlaylist(List<AudioModel> songs, {int startIndex = 0}) async {
    _playlist = songs;
    _currentIndex = startIndex;
    await _loadCurrentSong();
    notifyListeners();
  }

  Future<void> _loadCurrentSong() async {
    if (_playlist.isEmpty) return;

    final song = _playlist[_currentIndex];
    final url = song.audioUrl;

    if (url.isEmpty) return;

    try {
      _isLoadingAudio = true;
      _downloadProgress = 0.0;
      notifyListeners();

      // Check if audio is cached
      String? audioPath = await _cacheService.getCachedFilePath(url);

      if (audioPath == null) {
        // Download and cache audio with progress
        developer.log('Downloading audio: ${song.title}');
        audioPath = await _cacheService.downloadWithProgress(
          url,
          onProgress: (progress) {
            _downloadProgress = progress;
            notifyListeners();
          },
        );
      } else {
        developer.log('Using cached audio: ${song.title}');
        _downloadProgress = 1.0;
      }

      if (audioPath != null) {
        final handler = _audioHandler;
        if (handler != null) {
          // Use local cached file
          await handler.player.setFilePath(audioPath);

          // Update media item for background playback
          handler.setMediaItem(
            song.title,
            song.artist ?? song.description ?? 'Unknown Artist',
          );
        } else {
          // Fallback method
          await _audioPlayer.setFilePath(audioPath);
        }
      } else {
        // Fallback to streaming if download fails
        developer.log('Download failed, streaming: ${song.title}');
        final handler = _audioHandler;
        if (handler != null) {
          await handler.setUrl(url);
          handler.setMediaItem(
            song.title,
            song.artist ?? song.description ?? 'Unknown Artist',
          );
        } else {
          await _audioPlayer.setUrl(url);
        }
      }
    } catch (e) {
      developer.log('Error loading audio: $e');
    } finally {
      _isLoadingAudio = false;
      notifyListeners();
    }
  }

  Future<void> playSong(List<AudioModel> songs, int index) async {
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
      _playlist = [];
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
  bool get isLoading =>
      _audioPlayer.processingState == ProcessingState.loading || _isLoadingAudio;
  Duration get duration => _audioPlayer.duration ?? Duration.zero;
  Duration get position => _audioPlayer.position;

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  // Preload next song in background for seamless playback
  Future<void> preloadNextSong() async {
    if (_playlist.isEmpty || _currentIndex < 0) return;

    final nextIndex = (_currentIndex + 1) % _playlist.length;
    final nextSong = _playlist[nextIndex];

    final isCached = await _cacheService.isCached(nextSong.audioUrl);
    if (!isCached) {
      developer.log('Preloading next song: ${nextSong.title}');
      _cacheService.downloadAndCache(nextSong.audioUrl);
    }
  }

  // Preload entire playlist in background
  Future<void> preloadPlaylist() async {
    if (_playlist.isEmpty) return;

    final urls = _playlist.map((song) => song.audioUrl).toList();
    await _cacheService.preloadAudios(urls);
  }

  // Clear cache for specific song
  Future<void> clearSongCache(AudioModel song) async {
    await _cacheService.clearCache(song.audioUrl);
  }

  // Clear all audio cache
  Future<void> clearAllCache() async {
    await _cacheService.clearAllCache();
  }

  // Get cache size
  Future<String> getCacheSize() async {
    final size = await _cacheService.getCacheSize();
    return _cacheService.formatCacheSize(size);
  }

  Future<void> dispose() async {
    try {
      await _audioPlayer.dispose();
      _isInitialized = false;
      _playlist = [];
      _currentIndex = -1;
    } catch (e) {
      developer.log('Error disposing audio player: $e');
    }
    super.dispose();
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

  Future<void> playWithLoop(List<AudioModel> songs, int index,
      {LoopMode loopMode = LoopMode.all}) async {
    await setLoopMode(loopMode);
    await playSong(songs, index);
  }
}
