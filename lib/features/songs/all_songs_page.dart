import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/models/audio_model.dart';
import '../../core/providers/audio_provider.dart';
import '../../core/services/enhanced_audio_player_service.dart';
import '../../core/services/localization_service.dart';
import '../../core/services/sks_cache_manager.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/audio_navigation.dart';

ImageProvider _imgProvider(String url) {
  if (url.startsWith('http://') || url.startsWith('https://')) {
    return CachedNetworkImageProvider(url, cacheManager: SksCacheManager());
  }
  return const AssetImage('assets/images/Guruji_logo.JPG');
}

class AllSongsPage extends StatefulWidget {
  const AllSongsPage({super.key});

  @override
  State<AllSongsPage> createState() => _AllSongsPageState();
}

class _AllSongsPageState extends State<AllSongsPage> {
  final EnhancedAudioPlayerService _service = EnhancedAudioPlayerService();
  final AudioProvider _provider = AudioProvider();
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service.initialize();
    _service.addListener(_onAudioChanged);
    _loadSongs();
  }

  @override
  void dispose() {
    _service.removeListener(_onAudioChanged);
    super.dispose();
  }

  void _onAudioChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadSongs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await _provider.fetchAllAudios();
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) setState(() {
        _isLoading = false;
        _error = 'Failed to load songs';
      });
    }
  }

  List<AudioModel> get _songs => _provider.bhajans;

  /// Play song at [index] and open the full player.
  Future<void> _play(int index) async {
    await _service.playSong(_songs, index);
    if (mounted) _openPlayer();
  }

  /// Play all songs from the beginning and open the full player.
  Future<void> _playAll() async {
    if (_songs.isEmpty) return;
    await _service.setLoopMode(LoopMode.all);
    await _service.playSong(_songs, 0);
    if (mounted) _openPlayer();
  }

  /// Shuffle all songs and open the full player.
  Future<void> _shuffle() async {
    if (_songs.isEmpty) return;
    final shuffled = List<AudioModel>.from(_songs)..shuffle();
    await _service.setLoopMode(LoopMode.all);
    await _service.playSong(shuffled, 0);
    if (mounted) _openPlayer();
  }

  void _openPlayer() {
    openNowPlaying(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        backgroundColor: AppTheme.cream,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              context.tr('all_songs'),
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (!_isLoading && _songs.isNotEmpty)
              Text(
                '${_songs.length} ${context.tr('songs').toLowerCase()}',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                          onPressed: _loadSongs,
                          child: const Text('Retry')),
                    ],
                  ),
                )
              : _songs.isEmpty
                  ? const Center(child: Text('No songs available'))
                  : Column(
                      children: [
                        // ── Play All / Shuffle buttons ─────────────────
                        Container(
                          color: Colors.white,
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                          child: Row(
                            children: [
                              // Play All
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _playAll,
                                  icon: const Icon(Icons.play_arrow_rounded,
                                      size: 22),
                                  label: Text(
                                    context.tr('play_all'),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(14),
                                    ),
                                    elevation: 0,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Shuffle
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _shuffle,
                                  icon: const Icon(Icons.shuffle_rounded,
                                      size: 20),
                                  label: const Text(
                                    'Shuffle',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.primary,
                                    side: const BorderSide(
                                        color: AppTheme.primary, width: 1.5),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(14),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: Color(0xFFF0F0F0)),

                        // ── Song list ──────────────────────────────────
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.only(
                                top: 8, left: 16, right: 16, bottom: 16),
                            itemCount: _songs.length,
                            itemBuilder: (_, i) =>
                                _SongTile(
                              song: _songs[i],
                              index: i,
                              service: _service,
                              onTap: () => _play(i),
                              onTapPlaying: () => _openPlayer(),
                            ),
                          ),
                        ),
                      ],
                    ),
    );
  }
}

// ── Song tile ────────────────────────────────────────────────────────────────

class _SongTile extends StatelessWidget {
  final AudioModel song;
  final int index;
  final EnhancedAudioPlayerService service;
  final VoidCallback onTap;        // starts playback
  final VoidCallback onTapPlaying; // opens player if already this song

  const _SongTile({
    required this.song,
    required this.index,
    required this.service,
    required this.onTap,
    required this.onTapPlaying,
  });

  bool get _isCurrent {
    final cur = service.currentSong;
    if (cur == null) return false;
    if (cur is AudioModel) return cur.id == song.id;
    return (cur as Map)['title'] == song.title;
  }

  bool get _isPlaying => _isCurrent && service.isPlaying;

  String _dur(int s) {
    final m = s ~/ 60;
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }

  @override
  Widget build(BuildContext context) {
    final isCur = _isCurrent;
    final isPlay = _isPlaying;

    return GestureDetector(
      onTap: () {
        if (isCur) {
          // Already the active song — tap opens player
          if (isPlay) {
            onTapPlaying();
          } else {
            service.play().then((_) => onTapPlaying());
          }
        } else {
          onTap();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color:
              isCur ? AppTheme.saffron.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isCur
              ? Border.all(
                  color: AppTheme.saffron.withValues(alpha: 0.5), width: 1.5)
              : Border.all(color: const Color(0xFFF0F0F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Track number / equalizer icon
            SizedBox(
              width: 28,
              child: isCur
                  ? Icon(Icons.graphic_eq,
                      color: AppTheme.saffron, size: 20)
                  : Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
            ),
            const SizedBox(width: 10),

            // Album art
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: _imgProvider(
                          song.thumbnailUrl ?? ''),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                if (isCur)
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.black.withValues(alpha: 0.4),
                    ),
                    child: Icon(
                      isPlay ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),

            // Title + artist
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isCur ? AppTheme.saffron : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    song.artist ?? song.description ?? 'Divine Chants',
                    style: TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Duration
            Text(
              _dur(song.durationSeconds),
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(width: 4),

            // Play / pause icon
            Icon(
              isPlay ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: isCur ? AppTheme.saffron : AppTheme.primary,
              size: 26,
            ),
          ],
        ),
      ),
    );
  }
}
