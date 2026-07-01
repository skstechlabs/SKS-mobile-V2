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

  // Nullable instead of late final — prevents LateInitializationError on
  // warm restart where the Dart singleton survives but initialize() is called
  // a second time (or where the previous AudioPlayer was disposed).
  AudioPlayer? _audioPlayer;
  MyAudioHandler? _audioHandler;
  final AudioCacheService _cacheService = AudioCacheService();

  List<AudioModel> _playlist = [];
  int _currentIndex = 0;
  bool _isInitialized = false;
  bool _isLooping = false;
  LoopMode _loopMode = LoopMode.off;
  bool _isLoadingAudio = false;
  double _downloadProgress = 0.0;

  // ── Safe accessor — auto-initializes if called before initialize() ─────────
  AudioPlayer get player {
    if (_audioPlayer == null) {
      developer.log('⚠️ EnhancedAudioPlayerService: player accessed before initialize(), creating fallback');
      _audioPlayer = AudioPlayer();
    }
    return _audioPlayer!;
  }

  // Getters
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
    // On warm restart the singleton survives but the underlying AudioPlayer
    // platform channel may be torn down. Re-initialize if the player is gone
    // or if we have never initialized.
    if (_isInitialized && _audioPlayer != null) {
      // Quick sanity check: if the player's processing state is not accessible,
      // it has been disposed — force a fresh initialization.
      try {
        _ = _audioPlayer!.processingState; // throws if disposed
        return; // still healthy — nothing to do
      } catch (_) {
        developer.log('⚠️ EnhancedAudioPlayerService: existing player is disposed, re-initializing');
        _audioPlayer = null;
        _audioHandler = null;
        _isInitialized = false;
      }
    }

    try {
      await _cacheService.initialize();

      if (AudioService.running) {
        _audioHandler = MyAudioHandler();
        _audioPlayer = _audioHandler!.player;
        developer.log('✅ EnhancedAudioPlayerService using AudioHandler player');
      } else {
        _audioPlayer = AudioPlayer();
        developer.log('✅ EnhancedAudioPlayerService using standalone AudioPlayer');
      }
    } catch (e) {
      _audioPlayer = AudioPlayer();
      developer.log('⚠️ EnhancedAudioPlayerService fallback player: $e');
    }

    _isInitialized = true;

    // Stream subscriptions — always re-attach on (re-)initialization
    _audioPlayer!.playerStateStream.listen((_) => notifyListeners());
    _audioPlayer!.positionStream.listen((_) => notifyListeners());
    _audioPlayer!.durationStream.listen((_) => notifyListeners());
    _audioPlayer!.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        if (_loopMode == LoopMode.one) {
          _audioPlayer!.seek(Duration.zero);
          _audioPlayer!.play();
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

      final cached = await _cacheService.getCachedFilePath(url);

      if (cached != null) {
        developer.log('Using cached audio: ${song.title}');
        _downloadProgress = 1.0;
        final h = _audioHandler;
        if (h != null) {
          await h.player.setFilePath(cached);
          h.setMediaItem(song.title, song.artist ?? song.description ?? '');
        } else {
          await player.setFilePath(cached);
        }
      } else {
        developer.log('Streaming audio: ${song.title}');
        final h = _audioHandler;
        if (h != null) {
          await h.setUrl(url);
          h.setMediaItem(song.title, song.artist ?? song.description ?? '');
        } else {
          await player.setAudioSource(
            LockCachingAudioSource(Uri.parse(url)),
            preload: true,
          );
        }
        // Cache in background
        _cacheService.downloadAndCache(url).then((p) {
          if (p != null) developer.log('Audio cached: ${song.title}');
        }).catchError((e) => developer.log('Background cache failed: $e'));
      }
    } catch (e) {
      developer.log('Error loading audio: $e');
      try {
        await player.setUrl(url);
      } catch (fe) {
        developer.log('Fallback streaming failed: $fe');
      }
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
      final h = _audioHandler;
      if (h != null) {
        await h.play();
      } else {
        await player.play();
      }
      preloadNextSong();
    } catch (e) {
      developer.log('Error playing audio: $e');
    } finally {
      notifyListeners();
    }
  }

  Future<void> pause() async {
    try {
      final h = _audioHandler;
      if (h != null) {
        await h.pause();
      } else {
        await player.pause();
      }
    } catch (e) {
      developer.log('Error pausing audio: $e');
    } finally {
      notifyListeners();
    }
  }

  Future<void> stop() async {
    try {
      final h = _audioHandler;
      if (h != null) {
        await h.stop();
      } else {
        await player.stop();
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
    try {
      await player.seek(position);
    } catch (e) {
      developer.log('seekTo error: $e');
    }
  }

  Future<void> seek(Duration position) => seekTo(position);

  Future<void> setVolume(double volume) async {
    try {
      await player.setVolume(volume.clamp(0.0, 1.0));
    } catch (e) {
      developer.log('setVolume error: $e');
    }
  }

  bool get isPlaying {
    try {
      return _audioPlayer?.playing ?? false;
    } catch (_) {
      return false;
    }
  }

  bool get isLoading {
    try {
      return (_audioPlayer?.processingState == ProcessingState.loading) ||
          _isLoadingAudio;
    } catch (_) {
      return _isLoadingAudio;
    }
  }

  Duration get duration {
    try {
      return _audioPlayer?.duration ?? Duration.zero;
    } catch (_) {
      return Duration.zero;
    }
  }

  Duration get position {
    try {
      return _audioPlayer?.position ?? Duration.zero;
    } catch (_) {
      return Duration.zero;
    }
  }

  Future<void> preloadNextSong() async {
    if (_playlist.isEmpty || _currentIndex < 0) return;
    final nextIndex = (_currentIndex + 1) % _playlist.length;
    final next = _playlist[nextIndex];
    final isCached = await _cacheService.isCached(next.audioUrl);
    if (!isCached) {
      _cacheService.downloadAndCache(next.audioUrl);
    }
  }

  Future<void> preloadPlaylist({int maxCount = 5}) async {
    if (_playlist.isEmpty) return;
    for (var song in _playlist.take(maxCount)) {
      final isCached = await _cacheService.isCached(song.audioUrl);
      if (!isCached) {
        _cacheService.downloadAndCache(song.audioUrl).then((p) {
          if (p != null) developer.log('Preloaded: ${song.title}');
        }).catchError((e) => developer.log('Preload failed for ${song.title}: $e'));
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
  }

  Future<void> clearSongCache(AudioModel song) async {
    await _cacheService.clearCache(song.audioUrl);
  }

  Future<void> clearAllCache() async {
    await _cacheService.clearAllCache();
  }

  Future<String> getCacheSize() async {
    final size = await _cacheService.getCacheSize();
    return _cacheService.formatCacheSize(size);
  }

  Future<void> toggleLoopMode() async {
    switch (_loopMode) {
      case LoopMode.off:
        _loopMode = LoopMode.all;
        try { await player.setLoopMode(just_audio.LoopMode.all); } catch (_) {}
        break;
      case LoopMode.all:
        _loopMode = LoopMode.one;
        try { await player.setLoopMode(just_audio.LoopMode.one); } catch (_) {}
        break;
      case LoopMode.one:
        _loopMode = LoopMode.off;
        try { await player.setLoopMode(just_audio.LoopMode.off); } catch (_) {}
        break;
    }
    _isLooping = _loopMode != LoopMode.off;
    notifyListeners();
  }

  Future<void> setLoopMode(LoopMode mode) async {
    _loopMode = mode;
    _isLooping = mode != LoopMode.off;
    try {
      switch (mode) {
        case LoopMode.off:
          await player.setLoopMode(just_audio.LoopMode.off);
          break;
        case LoopMode.all:
          await player.setLoopMode(just_audio.LoopMode.all);
          break;
        case LoopMode.one:
          await player.setLoopMode(just_audio.LoopMode.one);
          break;
      }
    } catch (e) {
      developer.log('setLoopMode error: $e');
    }
    notifyListeners();
  }

  Future<void> playWithLoop(List<AudioModel> songs, int index,
      {LoopMode loopMode = LoopMode.all}) async {
    await setLoopMode(loopMode);
    await playSong(songs, index);
  }

  @override
  Future<void> dispose() async {
    try {
      await _audioPlayer?.dispose();
    } catch (_) {}
    _audioPlayer = null;
    _audioHandler = null;
    _isInitialized = false;
    _playlist = [];
    _currentIndex = -1;
    super.dispose();
  }
}
