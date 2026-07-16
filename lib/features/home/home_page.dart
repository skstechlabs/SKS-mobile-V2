import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/enhanced_audio_player_service.dart';
import '../../core/providers/audio_provider.dart';
import '../../core/models/audio_model.dart';
import '../../core/services/api_service.dart';
import '../../core/services/localization_service.dart';
import '../../core/services/quotes_service.dart';
import '../../core/services/image_preloader_service.dart';
import '../../core/widgets/cached_image.dart';
import 'widgets/youtube_playlist_section.dart';
import '../../core/services/sks_cache_manager.dart';

import '../audio/now_playing_screen.dart';
import '../../core/utils/audio_navigation.dart';

/// Returns the correct [ImageProvider] for a URL or asset path.
/// CDN images use [SksCacheManager] so they are never re-downloaded once cached.
ImageProvider _getImageProvider(String imageUrl) {
  if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
    return CachedNetworkImageProvider(imageUrl, cacheManager: SksCacheManager());
  }
  return AssetImage(imageUrl);
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _glowController;
  // Timer removed — quote rotation now handled by _QuoteRotatorWidget
  // to avoid rebuilding the entire HomePage every 3 seconds.
  final EnhancedAudioPlayerService _audioService = EnhancedAudioPlayerService();
  final AudioProvider _audioProvider = AudioProvider();
  final ApiService _apiService = ApiService();
  final QuotesService _quotesService = QuotesService();
  
  List<Map<String, dynamic>> _upcomingEvents = [];
  bool _isLoadingEvents = true;
  
  List<Map<String, dynamic>> _gatherings = [];
  bool _isLoadingGatherings = true;
  
  // Quotes from database - now stores full quote objects
  List<Map<String, dynamic>> _quotes = [];
  
  // Backend spiritual calendar events (admin-managed)
  List<Map<String, dynamic>> _backendCalendarEvents = [];
  
  // Preset reminders state
  final Map<String, bool> _presetReminders = {
    'morning_meditation': false,
    'evening_meditation': false,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _audioService.initialize();
    _audioService.addListener(_onAudioStateChanged);
    _audioProvider.addListener(_onAudioProviderChanged);

    // Warm in-memory image cache now that the widget tree is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ImagePreloaderService().preloadCriticalImages(context);
      }
    });

    // Quote rotation is now handled by _QuoteRotatorWidget — no timer here.
    
    // Load events from database
    _loadEvents();
    _loadPresetReminders();
    _loadGatherings();
    _loadQuotes();
    _loadAudios();
    _loadCalendarEvents();
    
    // Listen for language changes to refresh quotes
    LocalizationService().addListener(_onLanguageChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Trigger image preload from the home page context.
    // This is the fallback for cases where the splash context was already
    // disposed before preloading could complete (e.g. fresh install).
    // ImagePreloaderService guards against double-preloading internally.
    if (!ImagePreloaderService().isPreloaded) {
      ImagePreloaderService().preloadCriticalImages(context);
    }
  }
  
  void _onLanguageChanged() {
    debugPrint('[HomePage] Language changed, refreshing quotes');
    // Clear stale quotes immediately so the card shows fallback in the new
    // language rather than the old-language API quotes while fetching.
    if (mounted) {
      setState(() {
        _quotes = [];
      });
    }
    _loadQuotes();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Removed aggressive reload on resume - cache handles data freshness
    // Only specific user actions (pull-to-refresh, explicit refresh button) will force refresh
  }
  
  /// Extract YouTube video ID from various URL formats
  /// Supports:
  /// - https://www.youtube.com/watch?v=VIDEO_ID
  /// - https://youtu.be/VIDEO_ID
  /// - https://youtube.com/shorts/VIDEO_ID
  /// - https://www.youtube.com/embed/VIDEO_ID
  String? _extractYouTubeVideoId(String url) {
    try {
      final uri = Uri.parse(url);
      
      // Format: youtube.com/watch?v=VIDEO_ID
      if (uri.host.contains('youtube.com') && uri.path == '/watch') {
        return uri.queryParameters['v'];
      }
      
      // Format: youtu.be/VIDEO_ID
      if (uri.host == 'youtu.be') {
        return uri.pathSegments.isNotEmpty ? uri.pathSegments[0] : null;
      }
      
      // Format: youtube.com/shorts/VIDEO_ID
      if (uri.host.contains('youtube.com') && uri.pathSegments.isNotEmpty) {
        if (uri.pathSegments[0] == 'shorts' && uri.pathSegments.length > 1) {
          return uri.pathSegments[1];
        }
        // Format: youtube.com/embed/VIDEO_ID
        if (uri.pathSegments[0] == 'embed' && uri.pathSegments.length > 1) {
          return uri.pathSegments[1];
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('Error extracting YouTube video ID: $e');
      return null;
    }
  }
  
  Future<void> _loadQuotes() async {
    try {
      debugPrint('[HomePage] Loading quotes from QuotesService');
      final quotes = await _quotesService.getQuotes();
      
      if (mounted) {
        setState(() {
          // If API returned quotes use them, otherwise _quotes stays empty
          // and _buildDailyQuoteCard will use translation-based fallbacks
          _quotes = quotes;
        });
        debugPrint('[HomePage] ✅ Loaded ${quotes.length} quotes');
        
        // If API returned nothing, trigger a rebuild so the fallback quotes
        // from translations are shown immediately
        if (quotes.isEmpty && mounted) {
          debugPrint('[HomePage] No API quotes — using translation fallbacks');
          setState(() {}); // force rebuild so _buildDailyQuoteCard picks up fallbacks
        }
      }
    } catch (e) {
      debugPrint('[HomePage] ❌ Error loading quotes: $e');
      // Trigger rebuild so fallback translation quotes render
      if (mounted) setState(() {});
    }
  }
  
  Future<void> _loadPresetReminders() async {
    try {
      // Use cached data by default
      final response = await _apiService.getReminders();
      if (response['success'] == true && mounted) {
        final reminders = List<Map<String, dynamic>>.from(response['reminders'] ?? []);
        
        setState(() {
          // Reset to false first
          _presetReminders['morning_meditation'] = false;
          _presetReminders['evening_meditation'] = false;
          
          // Check which preset reminders exist and are active
          // Check for BOTH English and Telugu titles (case-insensitive)
          for (var reminder in reminders) {
            final title = (reminder['title'] as String).toLowerCase();
            final isActive = reminder['isActive'] as bool;
            
            // Check for Morning Meditation (English or Telugu)
            if (title == 'morning meditation' || title == 'ఉదయం ధ్యానం') {
              // Only show as ON if active, ignore inactive ones
              if (isActive) {
                _presetReminders['morning_meditation'] = true;
              }
            } 
            // Check for Evening Meditation (English or Telugu)
            else if (title == 'evening meditation' || title == 'సాయంత్రం ధ్యానం') {
              // Only show as ON if active, ignore inactive ones
              if (isActive) {
                _presetReminders['evening_meditation'] = true;
              }
            }
          }
          
          debugPrint('📍 Preset reminders state: morning=${_presetReminders['morning_meditation']}, evening=${_presetReminders['evening_meditation']}');
        });
      }
    } catch (e) {
      // Silent fail - reminders are optional
      debugPrint('Error loading preset reminders: $e');
    }
  }
  
  Future<void> _loadEvents() async {
    if (!mounted) return;
    
    try {
      // Use cached data by default
      final response = await _apiService.getEvents();
      
      if (response['success'] == true && mounted) {
        final allEvents = List<Map<String, dynamic>>.from(response['events'] ?? []);
        setState(() {
          // Limit to 2-3 events for home page
          _upcomingEvents = allEvents.take(3).toList();
          _isLoadingEvents = false;
        });
      } else if (mounted) {
        setState(() {
          _upcomingEvents = [];
          _isLoadingEvents = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _upcomingEvents = [];
          _isLoadingEvents = false;
        });
      }
    }
  }
  
  /// Sanitize a gathering image URL — replace known broken/dead R2 buckets
  /// with a local fallback asset so the card always shows something.
  String _sanitizeGatheringImage(String url) {
    if (url.isEmpty) return '';
    // The old bucket pub-355e960f52b74285b588743c0efff20b.r2.dev is dead
    if (url.contains('pub-355e960f52b74285b588743c0efff20b.r2.dev') ||
        url.contains('pub-dd90b1233fb04abcb6ca3930721e7056.r2.dev')) {
      return ''; // Return empty so the fallback icon shows
    }
    return url;
  }

  /// Fallback widget for gatherings whose API image URL is broken.
  /// Tries to match the title to a known local asset; else shows icon.
  Widget _buildGatheringFallbackImage(String title) {
    final t = title.toLowerCase();
    String? asset;
    if (t.contains('sivaratri') || t.contains('shivaratri')) {
      asset = 'assets/images/recentGatherings/MahaSivaratri_2025.jpg';
    } else if (t.contains('anniversary') || t.contains('sks 8')) {
      asset = 'assets/images/recentGatherings/SKS_8th_anniversary.jpg';
    } else if (t.contains('vastra') || t.contains('daanam')) {
      asset = 'assets/images/recentGatherings/Vastra_Daanam.jpeg';
    } else if (t.contains('bliss') || t.contains('center')) {
      asset = 'assets/images/recentGatherings/Bliss_Center.jpeg';
    } else if (t.contains('guru poornima') || t.contains('janmadinam')) {
      asset = 'assets/images/recentGatherings/GuruPoornima_2025.jpg';
    }

    if (asset != null) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: Image.asset(
          asset,
          width: 300,
          height: 180,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _gatheringIconFallback(),
        ),
      );
    }
    return _gatheringIconFallback();
  }

  Widget _gatheringIconFallback() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        gradient: LinearGradient(
          colors: [
            AppTheme.saffron.withValues(alpha: 0.3),
            AppTheme.gold.withValues(alpha: 0.2),
          ],
        ),
      ),
      child: Center(
        child: Icon(Icons.event, color: AppTheme.saffron, size: 52),
      ),
    );
  }

  Future<void> _loadGatherings() async {
    if (!mounted) return;
    
    try {
      // Use cached data by default
      final response = await _apiService.getGatherings();
      
      if (response['success'] == true && mounted) {
        final allGatherings = List<Map<String, dynamic>>.from(response['gatherings'] ?? []);
        setState(() {
          _gatherings = allGatherings;
          _isLoadingGatherings = false;
        });
      } else if (mounted) {
        setState(() {
          _gatherings = [];
          _isLoadingGatherings = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _gatherings = [];
          _isLoadingGatherings = false;
        });
      }
    }
  }

  Future<void> _loadCalendarEvents() async {
    try {
      final lang = _isTelugu ? 'te' : 'en';
      final response = await _apiService.getSpiritualCalendarEvents(lang: lang, days: 60);
      if (response['success'] == true && mounted) {
        setState(() {
          _backendCalendarEvents = List<Map<String, dynamic>>.from(response['events'] ?? []);
        });
      }
    } catch (e) {
      debugPrint('[HomePage] Calendar events load error: $e');
    }
  }

  Future<void> _loadAudios() async {
    try {
      // Use cached data by default
      await _audioProvider.fetchAllAudios();
      // Preload remaining images in background after audios load
      ImagePreloaderService().preloadAllImages(context);
    } catch (e) {
      debugPrint('Error loading audios: $e');
    }
  }

  void _onAudioStateChanged() {
    // Do NOT rebuild the entire home page on audio state changes.
    // MiniAudioPlayer is its own widget that listens independently.
    // HomePage only needs to rebuild if audio affects a visible home element.
  }

  void _onAudioProviderChanged() {
    // Rebuild when audio data loads (bhajans/meditations appear)
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _glowController.dispose();
    _audioService.removeListener(_onAudioStateChanged);
    _audioProvider.removeListener(_onAudioProviderChanged);
    LocalizationService().removeListener(_onLanguageChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGurujiHeaderSection(), // Guruji image + name (as before)
          _buildQuickActions(),        // About Guruji, Kundalini, Chakras, Kalpataru
          _buildDailyQuoteCard(),      // Today's Inspiration (image card)
          _buildMeditationMusic(),     // Chanting / Meditation music
          _buildMeditationTimer(),     // Purple timer card
          _buildSpiritualCalendar(),   // Telugu Spiritual Calendar
          _buildRingtoneSettings(),    // Sivoham Ringtone
          _buildWallpaperSettings(),   // Guruji Wallpapers
          _buildDailyReminders(),      // Daily Reminders
          const SizedBox(height: 20),
          _buildRecentGatherings(),
          _buildUpcomingPrograms(),
          _buildYouTubePlaylists(),
          _buildVisionMission(),
          _buildOurValues(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return const SizedBox.shrink();
  }

  // ── Guruji image + name section (exactly as before) ───────────────────────
  Widget _buildGurujiHeaderSection() {
    return Column(
      children: [
        // Full-width Guruji image
        SizedBox(
          height: 260,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedImage(
                imageUrl: 'https://pub-dd90b1233fb04abcb6ca3930721e7056.r2.dev/mobile/Guruji_dashboard.png',
                fit: BoxFit.cover,
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      AppTheme.cream.withValues(alpha: 0.85),
                    ],
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Guruji name section — identical to the previous design
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            children: [
              // Decorative divider
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 30, height: 1.5,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        Colors.transparent,
                        AppTheme.gold.withValues(alpha: 0.5),
                      ]),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Icon(Icons.auto_awesome,
                        size: 13,
                        color: AppTheme.gold.withValues(alpha: 0.7)),
                  ),
                  Container(
                    width: 30, height: 1.5,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        AppTheme.gold.withValues(alpha: 0.5),
                        Colors.transparent,
                      ]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Moksha Guru subtitle
              Text(
                context.tr('parama_pujya'),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary.withValues(alpha: 0.8),
                  letterSpacing: 2.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              // Guruji's name
              Text(
                context.tr('sri_jeeveswara_yogi'),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                  letterSpacing: 0.5,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              // Bottom decorative divider
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 30, height: 1.5,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        Colors.transparent,
                        AppTheme.gold.withValues(alpha: 0.5),
                      ]),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Icon(Icons.auto_awesome,
                        size: 13,
                        color: AppTheme.gold.withValues(alpha: 0.7)),
                  ),
                  Container(
                    width: 30, height: 1.5,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        AppTheme.gold.withValues(alpha: 0.5),
                        Colors.transparent,
                      ]),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Quick-action icon grid: About Guruji, Kundalini, Chakras, Kalpataru ──
  Widget _buildQuickActions() {
    final actions = [
      _QuickAction(
        iconPath: 'assets/images/icons/guruji-icon.png',
        label: context.tr('quick_about_guruji'),
        onTap: () => context.push('/guru-journey'),
      ),
      _QuickAction(
        iconPath: 'assets/images/icons/kundalini-icon.png',
        label: context.tr('quick_kundalini'),
        onTap: () => context.push('/kundalini-science'),
      ),
      _QuickAction(
        iconPath: 'assets/images/icons/chakras-icon.png',
        label: context.tr('quick_chakras'),
        onTap: () => context.push('/chakras', extra: {'initialIndex': 0}),
      ),
      _QuickAction(
        iconPath: 'assets/images/icons/kalpatharu-icon.png',
        label: context.tr('kalpataru'),
        onTap: () => context.go('/kalpataru'),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      // RepaintBoundary isolates this row so audio/quote setState calls on
      // the parent HomePage never trigger a repaint of the icons.
      child: RepaintBoundary(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: actions.map(_buildQuickActionItem).toList(),
        ),
      ),
    );
  }

  Widget _buildQuickActionItem(_QuickAction action) {
    return GestureDetector(
      onTap: action.onTap,
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: AppTheme.tagBg,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.tagBorder, width: 1),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.07),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                action.iconPath,
                width: 70,
                height: 70,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            action.label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Today's Inspiration — Guruji image with quotes overlay ──────────────
  Widget _buildDailyQuoteCard() {
    // Fallback quotes — shown only when API is unavailable AND no cache exists.
    // These keys exist in both en.json and te.json so they display in the
    // correct language automatically when context.tr() is called.
    final fallbackQuotes = [
      {'quote_text': context.tr('daily_quote_1')},
      {'quote_text': context.tr('daily_quote_2')},
      {'quote_text': context.tr('daily_quote_3')},
      {'quote_text': context.tr('daily_quote_4')},
      {'quote_text': context.tr('daily_quote_5')},
    ];

    // Prefer API quotes (already language-filtered by QuotesService).
    // Only fall back when _quotes is genuinely empty (API + cache both failed).
    final quotes = _quotes.isNotEmpty ? _quotes : fallbackQuotes;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [AppTheme.softShadow],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Full-width Guruji image — natural size, no crop
            Image.asset(
              'assets/images/Guruji-quotes.png',
              width: double.infinity,
              fit: BoxFit.fitWidth,
            ),
            // Left-side gradient so quotes are readable without covering Guruji
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Color(0xEEF5EDE2), // strong warm cream on left
                      Color(0xCCF5EDE2), // slightly transparent mid
                      Color(0x44F5EDE2), // very light toward Guruji
                      Colors.transparent, // fully clear on right (Guruji side)
                    ],
                    stops: [0.0, 0.35, 0.55, 0.75],
                  ),
                ),
              ),
            ),
            // Quote text — left side only, never overlaps Guruji
            Positioned(
              left: 18,
              top: 18,
              bottom: 18,
              right: 160, // keeps text clear of Guruji image on right
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Opening quote mark
                  Text(
                    '\u201C',
                    style: TextStyle(
                      fontSize: 36,
                      height: 0.8,
                      color: AppTheme.primary.withValues(alpha: 0.6),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Rotating quote
                  _QuoteRotatorWidget(quotes: quotes),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyQuotes() {
    // Always show Guruji header, quote card only when quotes are available
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image with increased height for better presence
        Container(
          height: 280,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedImage(
                imageUrl: AppConstants.dailyWisdomImages[1], // CDN image
                fit: BoxFit.cover,
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.5),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 20),

        // Guruji name section with spiritual and respectful styling
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Decorative top element
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 30,
                    height: 1.5,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          AppTheme.saffron.withValues(alpha: 0.4),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(
                      Icons.auto_awesome,
                      size: 14,
                      color: AppTheme.saffron.withValues(alpha: 0.6),
                    ),
                  ),
                  Container(
                    width: 30,
                    height: 1.5,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.saffron.withValues(alpha: 0.4),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Moksha Guru - spiritual styling
              Text(
                context.tr('parama_pujya'),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.saffron.withValues(alpha: 0.7),
                  letterSpacing: 2.5,
                  height: 1.4,
                  fontFamily: 'serif',
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 6),
              
              // Guruji's name - elegant and respectful
              Text(
                context.tr('sri_jeeveswara_yogi'),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFD84315),
                  letterSpacing: 0.8,
                  height: 1.3,
                  fontFamily: 'serif',
                  shadows: [
                    Shadow(
                      color: AppTheme.saffron.withValues(alpha: 0.1),
                      offset: Offset(0, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 12),
              
              // Decorative bottom element
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 30,
                    height: 1.5,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          AppTheme.saffron.withValues(alpha: 0.4),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(
                      Icons.auto_awesome,
                      size: 14,
                      color: AppTheme.saffron.withValues(alpha: 0.6),
                    ),
                  ),
                  Container(
                    width: 30,
                    height: 1.5,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.saffron.withValues(alpha: 0.4),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        SizedBox(height: 16),

        // Quote card - only show if we have quotes
        if (_quotes.isNotEmpty) ...[
          // Beautiful quote card with lighter, calming background - Full width
          Container(
            height: 180, // Fixed height for consistency
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFFBF5),
                  Color(0xFFFFF9F0),
                  Color(0xFFFFF6EB),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.saffron.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: AppTheme.saffron.withValues(alpha: 0.15),
                    width: 1.5,
                  ),
                  bottom: BorderSide(
                    color: AppTheme.saffron.withValues(alpha: 0.15),
                    width: 1.5,
                  ),
                ),
              ),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Opening quote icon
                  Icon(
                    Icons.format_quote,
                    size: 32,
                    color: AppTheme.saffron.withValues(alpha: 0.5),
                  ),
                  
                  SizedBox(height: 12),
                  
                  // Quote text with beautiful typography and scrollable if needed
                  Expanded(
                    child: _QuoteRotatorWidget(quotes: _quotes),
                  ),
                  
                  SizedBox(height: 12),
                  
                  // Decorative divider with dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppTheme.saffron.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 6),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppTheme.saffron.withValues(alpha: 0.7),
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 6),
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppTheme.saffron.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 16),
        ],
      ],
    );
  }

  void _togglePresetReminder(String key, String title, String defaultTime) async {
    final currentState = _presetReminders[key] ?? false;
    
    debugPrint('🔄 Toggle $title: $currentState → ${!currentState}');
    
    // Optimistically update UI
    setState(() {
      _presetReminders[key] = !currentState;
    });
    
    try {
      if (!currentState) {
        // Create/activate reminder
        debugPrint('➕ Creating reminder: $title');
        await _createOrActivateReminder(title, defaultTime);
      } else {
        // Deactivate (delete) reminder
        debugPrint('🗑️ Deleting reminder: $title');
        await _deactivateReminder(defaultTime);
      }
      
      // Wait a bit for the server to process the change
      await Future.delayed(Duration(milliseconds: 500));
      
      // After successful toggle, FORCE refresh preset reminders to ensure sync
      // Use forceRefresh to bypass cache
      debugPrint('🔄 Refreshing reminders after toggle...');
      final response = await _apiService.getReminders(forceRefresh: true);
      
      debugPrint('📦 API Response: ${response['success']}, reminders count: ${(response['reminders'] as List?)?.length ?? 0}');
      
      if (response['success'] == true && mounted) {
        final reminders = List<Map<String, dynamic>>.from(response['reminders'] ?? []);
        
        // Log all reminders for debugging
        for (var reminder in reminders) {
          debugPrint('  - ${reminder['title']} (active: ${reminder['isActive']}, id: ${reminder['id']})');
        }
        
        setState(() {
          // Reset to false first
          _presetReminders['morning_meditation'] = false;
          _presetReminders['evening_meditation'] = false;
          
          // Check which preset reminders exist and are active
          // Check for BOTH English and Telugu titles (case-insensitive)
          for (var reminder in reminders) {
            final reminderTitle = (reminder['title'] as String).toLowerCase();
            final isActive = reminder['isActive'] as bool;
            
            // Check for Morning Meditation (English or Telugu)
            if (reminderTitle == 'morning meditation' || reminderTitle == 'ఉదయం ధ్యానం') {
              // Only show as ON if active, ignore inactive ones
              if (isActive) {
                _presetReminders['morning_meditation'] = true;
                debugPrint('✅ Found active Morning Meditation');
              } else {
                debugPrint('⚠️ Found inactive Morning Meditation');
              }
            } 
            // Check for Evening Meditation (English or Telugu)
            else if (reminderTitle == 'evening meditation' || reminderTitle == 'సాయంత్రం ధ్యానం') {
              // Only show as ON if active, ignore inactive ones
              if (isActive) {
                _presetReminders['evening_meditation'] = true;
                debugPrint('✅ Found active Evening Meditation');
              } else {
                debugPrint('⚠️ Found inactive Evening Meditation');
              }
            }
          }
          
          debugPrint('📍 After toggle - Preset reminders state: morning=${_presetReminders['morning_meditation']}, evening=${_presetReminders['evening_meditation']}');
        });
      }
      
    } catch (e) {
      debugPrint('❌ Toggle error: $e');
      // Revert on error
      if (mounted) {
        setState(() {
          _presetReminders[key] = currentState;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('failed_to_update')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _createOrActivateReminder(String title, String defaultTime) async {
    // Check if reminder already exists - use TITLE for matching (time format is inconsistent)
    // FORCE REFRESH to get latest data
    final response = await _apiService.getReminders(forceRefresh: true);
    if (response['success'] == true) {
      final reminders = List<Map<String, dynamic>>.from(response['reminders'] ?? []);
      
      // Find ALL reminders with matching title (case-insensitive)
      // Check for both English and Telugu variants
      final matchingReminders = reminders.where((r) {
        final rTitle = (r['title'] as String).toLowerCase();
        final targetTitle = title.toLowerCase();
        
        // Match exact title OR Telugu equivalent
        if (targetTitle == 'morning meditation') {
          return rTitle == 'morning meditation' || rTitle == 'ఉదయం ధ్యానం';
        } else if (targetTitle == 'evening meditation') {
          return rTitle == 'evening meditation' || rTitle == 'సాయంత్రం ధ్యానం';
        }
        return rTitle == targetTitle;
      }).toList();
      
      debugPrint('🔍 Found ${matchingReminders.length} existing "${title}" reminders');
      
      // Delete ALL inactive ones, keep only ONE active one
      bool hasActiveReminder = false;
      int? activeReminderId;
      
      for (var reminder in matchingReminders) {
        final isActive = reminder['isActive'] as bool;
        final id = reminder['id'] as int;
        
        if (isActive && !hasActiveReminder) {
          // Keep the first active one
          hasActiveReminder = true;
          activeReminderId = id;
          debugPrint('✅ Keeping active reminder ID: $id');
        } else {
          // Delete duplicates or inactive ones
          debugPrint('🗑️ Deleting ${isActive ? "duplicate" : "inactive"} reminder ID: $id');
          await _apiService.deleteReminder(id);
        }
      }
      
      // If we found an active reminder, we're done
      if (hasActiveReminder) {
        debugPrint('✅ Active "$title" reminder already exists (ID: $activeReminderId)');
        return;
      }
      
      // No active reminder found, create a new one
      debugPrint('➕ Creating new "$title" reminder');
      final createResponse = await _apiService.createReminder(
        title: title,
        message: 'Time for your meditation practice',
        reminderTime: defaultTime,
        daysOfWeek: [0, 1, 2, 3, 4, 5, 6], // All days
        isActive: true,
      );
      
      if (createResponse['success'] == true) {
        debugPrint('✅ Created "$title" reminder successfully');
      } else {
        debugPrint('❌ Failed to create "$title" reminder: ${createResponse['message']}');
      }
    }
  }
  
  Future<void> _deactivateReminder(String defaultTime) async {
    // FORCE REFRESH to get latest data
    final response = await _apiService.getReminders(forceRefresh: true);
    if (response['success'] == true) {
      final reminders = List<Map<String, dynamic>>.from(response['reminders'] ?? []);
      
      // Determine which type based on time
      final reminderTitle = defaultTime == '06:00' ? 'Morning Meditation' : 'Evening Meditation';
      
      // Find ALL reminders with matching title (case-insensitive)
      // Check for both English and Telugu variants
      final matchingReminders = reminders.where((r) {
        final rTitle = (r['title'] as String).toLowerCase();
        
        if (reminderTitle == 'Morning Meditation') {
          return rTitle == 'morning meditation' || rTitle == 'ఉదయం ధ్యానం';
        } else {
          return rTitle == 'evening meditation' || rTitle == 'సాయంత్రం ధ్యానం';
        }
      }).toList();
      
      debugPrint('🗑️ Deleting ALL ${matchingReminders.length} "$reminderTitle" reminders');
      
      // Delete ALL matching reminders (both active and inactive)
      for (var reminder in matchingReminders) {
        final id = reminder['id'] as int;
        final isActive = reminder['isActive'] as bool;
        
        debugPrint('🗑️ Deleting reminder ID: $id (${isActive ? "active" : "inactive"})');
        final deleteResponse = await _apiService.deleteReminder(id);
        
        if (deleteResponse['success'] == true) {
          debugPrint('✅ Deleted reminder ID: $id');
        } else {
          debugPrint('❌ Failed to delete reminder ID: $id - ${deleteResponse['message']}');
        }
      }
      
      if (matchingReminders.isEmpty) {
        debugPrint('⚠️ No "$reminderTitle" reminders found to delete');
      }
    }
  }

  Widget _buildMeditationTimer() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          // ── Daily Sadhana card ────────────────────────────────────────
          GestureDetector(
            onTap: () => context.push('/meditation/timer'),
            child: Container(
              height: 160,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xFFF5EDE2),
                    Color(0xFFF8F2EA),
                    Color(0xFFF0EAE4),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [AppTheme.softShadow],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Left: Guruji image, face/head only ───────────
                  ClipRRect(
                    borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(20)),
                    child: Image.asset(
                      'assets/images/icons/Guruji_Thratakam-icon.png',
                      width: 155,
                      height: 160,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                    ),
                  ),
                  // ── Right: text + button ──────────────────────────
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 20, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.tr('daily_sadhana_title'),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                context.tr('daily_sadhana_subtitle'),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 11),
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              context.tr('meditation_start'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // ── View Meditation Journey button ───────────────────────────
          GestureDetector(
            onTap: () => context.push('/meditation/history'),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: AppTheme.cardSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.tagBorder, width: 1.5),
                boxShadow: [AppTheme.softShadow],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bar_chart_rounded,
                      color: AppTheme.primary, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    context.tr('view_meditation_journey'),
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpiritualCalendar() {
    final now = DateTime.now();
    final events = _getSpiritualEvents(now);
    final todayEvents = events.where((e) => _isSameDay(e.date, now)).toList();
    final upcomingEvents = events
        .where((e) => e.date.isAfter(now) && e.date.isBefore(now.add(const Duration(days: 30))))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final teluguMonths = _isTelugu ? [
      'చైత్రం', 'వైశాఖం', 'జ్యేష్ఠం', 'ఆషాఢం',
      'శ్రావణం', 'భాద్రపదం', 'ఆశ్వయుజం', 'కార్తీకం',
      'మార్గశిరం', 'పుష్యం', 'మాఘం', 'ఫాల్గుణం',
    ] : [
      'Chaitra', 'Vaishakha', 'Jyeshtha', 'Ashadha',
      'Shravana', 'Bhadrapada', 'Ashwayuja', 'Karthika',
      'Margasira', 'Pushya', 'Magha', 'Phalguna',
    ];
    // Approximate Telugu month (offset ~2 months from Gregorian)
    final teluguMonthIdx = (now.month + 10) % 12;
    final teluguMonth = teluguMonths[teluguMonthIdx];
    final teluguYear = now.year - (now.month <= 3 ? 57 : 56); // approx Saka era
    final tithi = _getTithi(now);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section header ──────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 4, height: 22,
                decoration: BoxDecoration(
                  color: AppTheme.gold,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '🕉️  ${_t('ఆధ్యాత్మిక పంచాంగం', 'Spiritual Calendar')}',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Today's panchang card ────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFF8EE), Color(0xFFFFF3DC)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.gold.withValues(alpha: 0.40), width: 1.5),
              boxShadow: [AppTheme.softShadow],
            ),
            child: Column(
              children: [
                // Gold header bar
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: AppTheme.goldGradient,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                  ),
                  child: Row(
                    children: [
                      const Text('📅', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Text(
                        '${_t('నేడు', 'Today')} · ${_formatDate(now)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          teluguMonth,
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                // Panchang details grid
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _panchaangItem('🌙', _t('తిథి', 'Tithi'), tithi.name),
                          const SizedBox(width: 8),
                          _panchaangItem('☀️', _t('పక్షం', 'Paksha'), tithi.paksha),
                          const SizedBox(width: 8),
                          _panchaangItem('✨', _t('శక సంవత్సరం', 'Saka Year'), '$teluguYear'),
                        ],
                      ),
                      if (todayEvents.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.20)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '🎊  ${_t('నేటి విశేషాలు', "Today's Events")}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              ...todayEvents.map((e) => Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Row(
                                  children: [
                                    Text(e.emoji, style: const TextStyle(fontSize: 14)),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        e.titleTe,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppTheme.textPrimary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Upcoming events list ─────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: AppTheme.cardSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.tagBorder),
              boxShadow: [AppTheme.softShadow],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: Row(
                    children: [
                      const Text('🗓️', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Text(
                        _t('రాబోయే విశేష తిథులు', 'Upcoming Sacred Days'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _t('30 రోజులు', '30 days'),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFEDD5BC)),
                if (upcomingEvents.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _t('రాబోయే ఈవెంట్లు లేవు', 'No upcoming events'),
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                    ),
                  )
                else
                  ...upcomingEvents.take(6).map((e) => _buildEventRow(e, now)),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _panchaangItem(String emoji, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.70),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.gold.withValues(alpha: 0.20)),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
            const SizedBox(height: 2),
            Text(value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildEventRow(_SpiritualEvent event, DateTime now) {
    final daysLeft = event.date.difference(now).inDays;
    final isVeryClose = daysLeft <= 3;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: const Color(0xFFEDD5BC).withValues(alpha: 0.50))),
      ),
      child: Row(
        children: [
          // Event type colour dot
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: event.color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: event.color.withValues(alpha: 0.30)),
            ),
            child: Center(child: Text(event.emoji, style: const TextStyle(fontSize: 18))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.titleTe,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    )),
                const SizedBox(height: 2),
                Text(
                  _formatDate(event.date),
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isVeryClose
                  ? AppTheme.primary.withValues(alpha: 0.12)
                  : AppTheme.tagBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isVeryClose
                    ? AppTheme.primary.withValues(alpha: 0.30)
                    : AppTheme.tagBorder,
              ),
            ),
            child: Text(
              daysLeft == 0 ? _t('నేడు', 'Today') : '$daysLeft ${_t('రోజులు', 'days')}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isVeryClose ? AppTheme.primary : AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  bool get _isTelugu => LocalizationService().currentLocale.languageCode == 'te';
  String _t(String te, String en) => _isTelugu ? te : en;

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _formatDate(DateTime d) {
    final months = _isTelugu
        ? ['జన', 'ఫిబ్ర', 'మార్చి', 'ఏప్రి', 'మే', 'జూన్', 'జులై', 'ఆగ', 'సెప్ట', 'అక్టో', 'నవం', 'డిసెం']
        : ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  _TithiInfo _getTithi(DateTime date) {
    // Approximate lunar tithi from Julian date
    const double synodicMonth = 29.53058867;
    final jd = _julianDay(date);
    const double knownNewMoon = 2459215.5; // Jan 13 2021 new moon (JD)
    final daysSince = jd - knownNewMoon;
    final moonAge = daysSince % synodicMonth;
    final tithi = (moonAge / synodicMonth * 30).floor() + 1;

    final tithiNames = _isTelugu ? [
      'ప్రతిపద', 'ద్వితీయ', 'తృతీయ', 'చతుర్థి', 'పంచమి',
      'షష్ఠి', 'సప్తమి', 'అష్టమి', 'నవమి', 'దశమి',
      'ఏకాదశి', 'ద్వాదశి', 'త్రయోదశి', 'చతుర్దశి', 'పూర్ణిమ',
      'ప్రతిపద', 'ద్వితీయ', 'తృతీయ', 'చతుర్థి', 'పంచమి',
      'షష్ఠి', 'సప్తమి', 'అష్టమి', 'నవమి', 'దశమి',
      'ఏకాదశి', 'ద్వాదశి', 'త్రయోదశి', 'చతుర్దశి', 'అమావాస్య',
    ] : [
      'Pratipada', 'Dwitiya', 'Tritiya', 'Chaturthi', 'Panchami',
      'Shashti', 'Saptami', 'Ashtami', 'Navami', 'Dashami',
      'Ekadashi', 'Dwadashi', 'Trayodashi', 'Chaturdashi', 'Purnima',
      'Pratipada', 'Dwitiya', 'Tritiya', 'Chaturthi', 'Panchami',
      'Shashti', 'Saptami', 'Ashtami', 'Navami', 'Dashami',
      'Ekadashi', 'Dwadashi', 'Trayodashi', 'Chaturdashi', 'Amavasya',
    ];
    final idx = (tithi - 1).clamp(0, 29);
    final paksha = idx < 15 ? _t('శుక్ల పక్షం', 'Shukla Paksha') : _t('కృష్ణ పక్షం', 'Krishna Paksha');
    return _TithiInfo(name: tithiNames[idx], paksha: paksha);
  }

  double _julianDay(DateTime date) {
    final y = date.year;
    final m = date.month;
    final d = date.day + date.hour / 24.0;
    final a = (14 - m) ~/ 12;
    final yr = y + 4800 - a;
    final mo = m + 12 * a - 3;
    return d + (153 * mo + 2) ~/ 5 + 365 * yr + yr ~/ 4 - yr ~/ 100 + yr ~/ 400 - 32045;
  }

  List<_SpiritualEvent> _getSpiritualEvents(DateTime now) {
    final year = now.year;
    final List<_SpiritualEvent> events = [];

    // ── Full moons, new moons, Maha Shivaratri & Ekadashi ───────────────────
    // Maha Shivaratri = day before Amavasya (Krishna Chaturdashi, 14th tithi)
    final double synodicMonth = 29.53058867;
    final double knownNewMoon = 2459215.5;
    for (int i = -2; i < 15; i++) {
      final nmJD  = knownNewMoon + i * synodicMonth;          // New moon (Amavasya)
      final fmJD  = knownNewMoon + (i + 0.5) * synodicMonth; // Full moon (Pournami)
      final msJD  = nmJD - 1;                                  // Day before Amavasya = Maha Shivaratri

      final nmDate = _fromJulianDay(nmJD);
      final fmDate = _fromJulianDay(fmJD);
      final msDate = _fromJulianDay(msJD);

      if (fmDate.year == year || fmDate.year == year + 1) {
        events.add(_SpiritualEvent(
          date: fmDate, emoji: '🌕',
          titleTe: _t('పూర్ణిమ', 'Pournami'),
          color: AppTheme.gold, type: 'lunar',
        ));
      }
      if (msDate.year == year || msDate.year == year + 1) {
        events.add(_SpiritualEvent(
          date: msDate, emoji: '🕉️',
          titleTe: _t('మాస శివరాత్రి', 'Masa Shivaratri'),
          color: const Color(0xFF5C35B0), type: 'shivaratri',
        ));
      }
      if (nmDate.year == year || nmDate.year == year + 1) {
        events.add(_SpiritualEvent(
          date: nmDate, emoji: '🌑',
          titleTe: _t('అమావాస్య', 'Amavasya'),
          color: const Color(0xFF37474F), type: 'lunar',
        ));
      }
    }

    // ── Ekadashi (11th lunar day — every ~15 days) ────────────────────────
    for (int i = 0; i < 25; i++) {
      final ek1JD = knownNewMoon + i * synodicMonth + 10.5; // Shukla Ekadashi
      final ek2JD = knownNewMoon + i * synodicMonth + 25.5; // Krishna Ekadashi
      for (final jd in [ek1JD, ek2JD]) {
        final d = _fromJulianDay(jd);
        if (d.year == year) {
          events.add(_SpiritualEvent(
            date: d, emoji: '🌿',
            titleTe: _t('ఏకాదశి', 'Ekadashi'),
            color: const Color(0xFF2E7D32), type: 'ekadashi',
          ));
        }
      }
    }

    // ── Backend / admin-managed events (festivals, Guruji birthday etc.) ────
    for (final e in _backendCalendarEvents) {
      try {
        final dateStr = e['date']?.toString() ?? '';
        if (dateStr.isEmpty) continue;
        final date = DateTime.parse(dateStr);
        events.add(_SpiritualEvent(
          date: date,
          emoji: e['emoji']?.toString() ?? '🕉️',
          titleTe: e['title']?.toString() ?? '',
          color: _parseColor(e['colorHex']?.toString()),
          type:  e['type']?.toString() ?? 'festival',
        ));
      } catch (_) {}
    }

    // ── Fallback static festivals (used when backend is unreachable) ─────────
    if (_backendCalendarEvents.isEmpty) {
      final festivals = [
        _SpiritualEvent(date: DateTime(year, 1, 14), emoji: '🌾', titleTe: _t('మకర సంక్రాంతి', 'Makar Sankranti'), color: const Color(0xFF2E7D32), type: 'festival'),
        _SpiritualEvent(date: DateTime(year, 3, 30), emoji: '🌸', titleTe: _t('ఉగాది', 'Ugadi'), color: const Color(0xFF1565C0), type: 'festival'),
        _SpiritualEvent(date: DateTime(year, 7, 22), emoji: '🙏', titleTe: _t('గురుజీ జయంతి', "Guruji's Birthday"), color: AppTheme.primary, type: 'guruji'),
        _SpiritualEvent(date: DateTime(year, 8, 26), emoji: '🐘', titleTe: _t('వినాయక చవితి', 'Vinayaka Chavithi'), color: const Color(0xFF2E7D32), type: 'festival'),
        _SpiritualEvent(date: DateTime(year, 10, 20), emoji: '🪔', titleTe: _t('దీపావళి', 'Diwali'), color: AppTheme.gold, type: 'festival'),
      ];
      events.addAll(festivals);
    }

    return events;
  }

  /// Parse a hex color string like '#C4622D' into a Flutter Color.
  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return AppTheme.primary;
    try {
      final clean = hex.replaceFirst('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return AppTheme.primary;
    }
  }

  DateTime _fromJulianDay(double jd) {
    final z = jd.floor() + 1;
    final a = ((z - 1867216.25) / 36524.25).floor();
    final b = z + a - (a ~/ 4) + 1;
    final c = ((b - 122.1) / 365.25).floor();
    final d = (365.25 * c).floor();
    final e = ((b - d) / 30.6001).floor();
    final day = b - d - (30.6001 * e).floor();
    final month = e < 14 ? e - 1 : e - 13;
    final year = month > 2 ? c - 4716 : c - 4715;
    return DateTime(year, month, day);
  }

  Widget _buildRingtoneSettings() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: GestureDetector(
        onTap: () => context.push('/settings/ringtone'),
        child: Container(
          // No fixed height — let content determine size
          constraints: const BoxConstraints(minHeight: 88),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8F0),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.tagBorder),
            boxShadow: [AppTheme.softShadow],
          ),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                right: -20, top: -20,
                child: Container(
                  width: 120, height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primary.withValues(alpha: 0.07),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/icons/ringtone-icon.png',
                      width: 64,
                      height: 64,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            context.tr('sivoham_ringtone'),
                            style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary, height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            context.tr('set_as_ringtone'),
                            style: const TextStyle(
                              fontSize: 11, color: AppTheme.textSecondary, height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        context.tr('set_now'),
                        style: const TextStyle(
                          color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWallpaperSettings() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: GestureDetector(
        onTap: () => context.push('/settings/wallpaper'),
        child: Container(
          // No fixed height — let content determine size
          constraints: const BoxConstraints(minHeight: 88),
          decoration: BoxDecoration(
            color: AppTheme.tagBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.tagBorder),
            boxShadow: [AppTheme.softShadow],
          ),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                right: -20, top: -20,
                child: Container(
                  width: 120, height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.gold.withValues(alpha: 0.10),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/icons/wallpaper-icon.png',
                      width: 64,
                      height: 64,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            context.tr('wisdom_wallpaper'),
                            style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary, height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            context.tr('set_daily_wallpaper'),
                            style: const TextStyle(
                              fontSize: 11, color: AppTheme.textSecondary, height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        gradient: AppTheme.goldGradient,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        context.tr('set_now'),
                        style: const TextStyle(
                          color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailyReminders() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: GestureDetector(
        onTap: () => context.push('/reminders'),
        child: Container(
          constraints: const BoxConstraints(minHeight: 88),
          decoration: BoxDecoration(
            color: AppTheme.tagBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.tagBorder),
            boxShadow: [AppTheme.softShadow],
          ),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                right: -20, top: -20,
                child: Container(
                  width: 120, height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primary.withValues(alpha: 0.07),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/icons/remainders-icon.png',
                      width: 64,
                      height: 64,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            context.tr('daily_reminders'),
                            style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary, height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            context.tr('enable_reminders_subtitle'),
                            style: const TextStyle(
                              fontSize: 11, color: AppTheme.textSecondary, height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        context.tr('manage'),
                        style: const TextStyle(
                          color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildYouTubePlaylists() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        YouTubePlaylistSection(
          config: const PlaylistConfig(
            title: 'Energy and Aura',
            subtitle: 'Pictures of Pujya Gurudev',
            playlistId: 'PL5n5gvsTFZLyL154q7-4Bp51EnACr2Kcr',
            accentColor: Color(0xFFE65100),
            bgColor: Color(0xFFFFF3EE),
            emoji: '✨',
          ),
        ),
        const SizedBox(height: 28),
        YouTubePlaylistSection(
          config: const PlaylistConfig(
            title: 'Journeys of Transformation',
            subtitle: 'Stories of spiritual awakening',
            playlistId: 'PL5n5gvsTFZLxNeqKLWpTPYfdWBU84zKzE',
            accentColor: Color(0xFF6A1B9A),
            bgColor: Color(0xFFFAF4FF),
            emoji: '🌟',
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildVisionMission() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        children: [
          _buildInfoCard(
            icon: Icons.visibility_outlined,
            title: context.tr('our_vision'),
            body: context.tr('vision_text'),
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            icon: Icons.explore_outlined,
            title: context.tr('our_mission'),
            body: context.tr('mission_text'),
          ),
        ],
      ),
    );
  }

  /// Shared warm-themed card for Vision / Mission
  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String body,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.tagBorder, width: 1),
        boxShadow: [AppTheme.softShadow],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        )),
                    const SizedBox(height: 3),
                    Container(
                      height: 2, width: 48,
                      decoration: BoxDecoration(
                        gradient: AppTheme.goldGradient,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.tagBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              body,
              style: const TextStyle(
                fontSize: 14,
                height: 1.7,
                color: AppTheme.textSecondary,
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.justify,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOurValues() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.tagBorder, width: 1),
        boxShadow: [AppTheme.softShadow],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  gradient: AppTheme.goldGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.tr('our_values'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        )),
                    const SizedBox(height: 3),
                    Container(
                      height: 2, width: 48,
                      decoration: BoxDecoration(
                        gradient: AppTheme.goldGradient,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Values list
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.tagBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildValueItem(context.tr('value_surrenderance'), Icons.favorite_border),
                const SizedBox(height: 12),
                _buildValueItem(context.tr('value_practice'), Icons.self_improvement),
                const SizedBox(height: 12),
                _buildValueItem(context.tr('value_service'), Icons.volunteer_activism),
                const SizedBox(height: 12),
                _buildValueItem(context.tr('value_gratitude'), Icons.spa),
                const SizedBox(height: 12),
                _buildValueItem(context.tr('value_acceptance_forgiveness'), Icons.healing),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValueItem(String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppTheme.textHint),
      ],
    );
  }

  Widget _buildMeditationMusic() {
    final meditations = _audioProvider.meditations;
    final firstMeditation = meditations.isNotEmpty ? meditations[0] : null;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title with padding
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Text(
            context.tr('daily_meditation'),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        // Full width image
        GestureDetector(
          onTap: () async {
            if (firstMeditation != null) {
              final currentSong = _audioService.currentSong;
              final bool isCurrentlyPlaying;
              if (currentSong == null) {
                isCurrentlyPlaying = false;
              } else if (currentSong is AudioModel) {
                isCurrentlyPlaying = currentSong.id == firstMeditation.id && _audioService.isPlaying;
              } else {
                isCurrentlyPlaying = (currentSong as Map)['title'] == firstMeditation.title && _audioService.isPlaying;
              }

              if (!isCurrentlyPlaying) {
                await _audioService.playSong(meditations, 0);
              }
              if (mounted) openNowPlaying(context);
            }
          },
          child: Container(
            height: 240,
            width: double.infinity,
            decoration: BoxDecoration(
              border: () {
                if (firstMeditation == null || _audioService.currentSong == null) return null;
                final currentSong = _audioService.currentSong;
                final bool isPlaying;
                if (currentSong is AudioModel) {
                  isPlaying = currentSong.id == firstMeditation.id && _audioService.isPlaying;
                } else {
                  isPlaying = (currentSong as Map)['title'] == firstMeditation.title && _audioService.isPlaying;
                }
                return isPlaying ? Border.all(color: AppTheme.primary, width: 3) : null;
              }(),
              image: DecorationImage(
                image: _getImageProvider(AppConstants.gurujiTeachingImageUrl),
                fit: BoxFit.contain,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        () {
                          if (firstMeditation == null || _audioService.currentSong == null) return Icons.play_arrow;
                          final currentSong = _audioService.currentSong;
                          final bool isPlaying;
                          if (currentSong is AudioModel) {
                            isPlaying = currentSong.id == firstMeditation.id && _audioService.isPlaying;
                          } else {
                            isPlaying = (currentSong as Map)['title'] == firstMeditation.title && _audioService.isPlaying;
                          }
                          return isPlaying ? Icons.pause : Icons.play_arrow;
                        }(),
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.tr('guided_meditation'),
                        style:
                            Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                      ),
                      if (firstMeditation != null)
                        Text(
                          '${firstMeditation.durationSeconds ~/ 60}:${(firstMeditation.durationSeconds % 60).toString().padLeft(2, '0')}',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBhajans() {
    final bhajans = _audioProvider.bhajans;
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr('bhajans'),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Icon(Icons.repeat, color: AppTheme.softGray, size: 24),
            ],
          ),
          SizedBox(height: 16),
          if (bhajans.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text('Loading bhajans...'),
              ),
            )
          else
            ...bhajans
                .take(3)
                .map((bhajan) => _buildBhajanCard(bhajan))
                .toList(),
          SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {
              context.push('/all-songs');
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppTheme.primary, width: 2),
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  context.tr('all_songs'),
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, color: AppTheme.primary, size: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBhajanCard(AudioModel bhajan) {
    final currentSong = _audioService.currentSong;
    final bool isCurrentSong;
    if (currentSong == null) {
      isCurrentSong = false;
    } else if (currentSong is AudioModel) {
      isCurrentSong = currentSong.id == bhajan.id;
    } else {
      isCurrentSong = (currentSong as Map)['title'] == bhajan.title;
    }
    final isPlaying = isCurrentSong && _audioService.isPlaying;
    
    // Get translated song title
    String getSongTitle(String originalTitle) {
      final titleMap = {
        'Sri Jeeveswarastakam': 'song_sri_jeeveswarastakam',
        'Gundello Gudi': 'song_gundello_gudi',
        'Nirvana Shatkam': 'song_nirvana_shatkam',
        'Jeeveswara Yogi Taluva': 'song_jeeveswara_yogi_taluva',
        'Pralaya Kala Beekara': 'song_pralaya_kala_beekara',
        'Ni Namamalo Undhi Moksha Dwaram': 'song_ni_namamalo',
      };
      return context.tr(titleMap[originalTitle] ?? originalTitle);
    }

    return GestureDetector(
      onTap: () async {
        final bhajans = _audioProvider.bhajans;
        final index = bhajans.indexWhere((b) => b.id == bhajan.id);
        if (index != -1) {
          if (!(isCurrentSong && _audioService.isPlaying)) {
            await _audioService.playSong(bhajans, index);
          }
          if (mounted) openNowPlaying(context);
        }
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isCurrentSong
              ? AppTheme.saffron.withOpacity(0.1)
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: isCurrentSong
              ? Border.all(color: AppTheme.saffron, width: 2)
              : null,
        ),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: _getImageProvider(bhajan.thumbnailUrl ?? 'assets/images/placeholder.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                if (isCurrentSong)
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.black.withOpacity(0.5),
                    ),
                    child: Icon(
                      isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
              ],
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    getSongTitle(bhajan.title),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: isCurrentSong ? AppTheme.saffron : null,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    bhajan.artist ?? bhajan.description ?? 'Divine Chants',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${bhajan.durationSeconds ~/ 60}:${(bhajan.durationSeconds % 60).toString().padLeft(2, '0')}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                ),
                SizedBox(height: 4),
                Icon(
                  isCurrentSong && isPlaying ? Icons.pause : Icons.play_arrow,
                  color:
                      isCurrentSong ? AppTheme.saffron : AppTheme.textSecondary,
                  size: 24,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuruJourney() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: GestureDetector(
        onTap: () {
          context.push('/guru-journey');
        },
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            image: DecorationImage(
              image: _getImageProvider(AppConstants.guruJourneyImageUrl),
              fit: BoxFit.cover,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.saffron.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFF6B4A).withValues(alpha: 0.88),
                  Color(0xFFFF8A65).withValues(alpha: 0.85),
                ],
              ),
            ),
            child: Stack(
              children: [
                // Content
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        context.tr('guru_journey'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.tr('learn_about_guruji'),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.95),
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Text(
                            context.tr('know_more'),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward,
                            color: Colors.white,
                            size: 16,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKundaliniScience() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: GestureDetector(
        onTap: () {
          context.push('/kundalini-science');
        },
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            image: DecorationImage(
              image: _getImageProvider(AppConstants.kundaliniScienceImageUrl),
              fit: BoxFit.cover,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.gold.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF00897B).withValues(alpha: 0.88),
                  Color(0xFF26A69A).withValues(alpha: 0.85),
                ],
              ),
            ),
            child: Stack(
              children: [
                // Content
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        context.tr('kundalini_science'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.tr('understand_kundalini'),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.95),
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Text(
                            context.tr('learn_more'),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward,
                            color: Colors.white,
                            size: 16,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBenefits() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: GestureDetector(
        onTap: () {
          context.push('/benefits');
        },
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            image: DecorationImage(
              image: _getImageProvider(AppConstants.benefitsImageUrl),
              fit: BoxFit.cover,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.saffron.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFE91E63).withValues(alpha: 0.88),
                  Color(0xFFEC407A).withValues(alpha: 0.85),
                ],
              ),
            ),
            child: Stack(
              children: [
                // Content
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        context.tr('benefits'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.tr('discover_benefits'),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.95),
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Text(
                            context.tr('discover_benefits'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward,
                            color: Colors.white,
                            size: 16,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _build7Chakras() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: GestureDetector(
        onTap: () {
          context.push('/chakras', extra: {'initialIndex': 0});
        },
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            image: DecorationImage(
              image: _getImageProvider(AppConstants.chakrasImageUrl),
              fit: BoxFit.cover,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.saffron.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.purple.withValues(alpha: 0.85),
                  Colors.deepPurple.withValues(alpha: 0.75),
                ],
              ),
            ),
            child: Stack(
              children: [
                // Content
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        context.tr('seven_chakras'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.tr('explore_chakras'),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.95),
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Text(
                            context.tr('swipe_to_explore'),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward,
                            color: Colors.white,
                            size: 16,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentGatherings() {
    // Show loading state
    if (_isLoadingGatherings) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: CircularProgressIndicator(color: AppTheme.saffron),
        ),
      );
    }
    
    // Don't show section if no gatherings
    if (_gatherings.isEmpty) {
      return SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            context.tr('recent_gatherings'),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        SizedBox(height: 16),
        SizedBox(
          height: 340,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 20),
            itemCount: _gatherings.length,
            itemBuilder: (context, index) {
              final gathering = _gatherings[index];
              final title = gathering['title'] as String? ?? 'Untitled';
              final date = gathering['date'] as String? ?? '';
              final description = gathering['description'] as String? ?? '';
              final imageUrl = _sanitizeGatheringImage(
                  gathering['imageUrl'] as String? ?? '');
              final videoUrl = gathering['videoUrl'] as String? ?? '';
              final participants = gathering['participants'] as String?;
              
              return InkWell(
                onTap: () async {
                  if (videoUrl.isNotEmpty) {
                    try {
                      // Extract YouTube video ID from URL
                      String? videoId = _extractYouTubeVideoId(videoUrl);
                      
                      if (videoId != null) {
                        // Play YouTube video in-app via go_router
                        context.push(
                          '/youtube-player',
                          extra: {'videoId': videoId, 'title': title},
                        );
                      } else {
                        // Fallback to external browser if video ID extraction fails
                        final uri = Uri.parse(videoUrl);
                        await launchUrl(uri,
                            mode: LaunchMode.externalApplication);
                      }
                    } catch (e) {
                      debugPrint('Error launching video: $e');
                    }
                  }
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 300,
                  margin: EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(20)),
                            child: SizedBox(
                              height: 180,
                              width: 300,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  // Saffron gradient — always visible
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          AppTheme.saffron.withValues(alpha: 0.85),
                                          AppTheme.gold.withValues(alpha: 0.6),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Try imageUrl first, then YouTube thumbnail
                                  if (imageUrl.isNotEmpty)
                                    Image.network(
                                      imageUrl,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (_, child, prog) =>
                                          prog == null ? child : const SizedBox.shrink(),
                                      errorBuilder: (_, __, ___) {
                                        // Try YouTube thumbnail as secondary fallback
                                        final ytId = _extractYouTubeVideoId(videoUrl);
                                        if (ytId != null) {
                                          return Image.network(
                                            'https://i.ytimg.com/vi/$ytId/hqdefault.jpg',
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                const SizedBox.shrink(),
                                          );
                                        }
                                        return const SizedBox.shrink();
                                      },
                                    )
                                  else if (videoUrl.isNotEmpty) ...[
                                    // No imageUrl — use YouTube thumbnail directly
                                    Builder(builder: (ctx) {
                                      final ytId = _extractYouTubeVideoId(videoUrl);
                                      if (ytId == null) return const SizedBox.shrink();
                                      return Image.network(
                                        'https://i.ytimg.com/vi/$ytId/hqdefault.jpg',
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const SizedBox.shrink(),
                                      );
                                    }),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          // Play button overlay
                          if (videoUrl.isNotEmpty)
                            Positioned.fill(
                              child: IgnorePointer(
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(20)),
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withValues(alpha: 0.3),
                                      ],
                                    ),
                                  ),
                                  child: Center(
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppTheme.saffron.withValues(alpha: 0.9),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.play_arrow,
                                        color: Colors.white,
                                        size: 32,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 14,
                                    color: AppTheme.primary,
                                  ),
                                  SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      date,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: AppTheme.primary,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 12,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                              if (participants != null && participants.isNotEmpty) ...[
                                SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.people,
                                      size: 14,
                                      color: AppTheme.textSecondary,
                                    ),
                                    SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        participants,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: AppTheme.textSecondary,
                                              fontSize: 12,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              SizedBox(height: 6),
                              Expanded(
                                child: Text(
                                  description,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: AppTheme.textSecondary,
                                        fontSize: 12,
                                        height: 1.3,
                                      ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 20),
      ],
    );
  }

  Widget _buildUpcomingPrograms() {
    if (_isLoadingEvents || _upcomingEvents.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
            child: Text(
              context.tr('upcoming_programs'),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          ..._upcomingEvents.map((event) => _buildEventCard(event)).toList(),
        ],
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    final title    = event['title']    as String? ?? 'Untitled Event';
    final rawDate  = event['eventDate'] as String? ?? '';
    final location = event['location'] as String? ?? '';
    final imageUrl = event['imageUrl'] as String?;

    // Format ISO date to readable string
    final displayDate = _formatEventDate(rawDate);

    return GestureDetector(
      onTap: () => context.go('/events'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppTheme.cardSurface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [AppTheme.cardShadow],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image or placeholder
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: SizedBox(
                width: double.infinity,
                height: 160,
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? CachedImage(
                        imageUrl: imageUrl,
                        width: double.infinity,
                        height: 160,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppTheme.primary, AppTheme.lightSaffron],
                          ),
                        ),
                        child: const Center(
                          child: Icon(Icons.event_rounded,
                              size: 56, color: Colors.white),
                        ),
                      ),
              ),
            ),
            // Details
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (displayDate.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded,
                            size: 14, color: AppTheme.primary),
                        const SizedBox(width: 6),
                        Text(
                          displayDate,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (location.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded,
                            size: 14, color: AppTheme.textSecondary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            location,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Converts ISO 8601 date string to a readable format like "22 Jul 2026"
  String _formatEventDate(String raw) {
    if (raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      // If it's already a readable string just return it
      return raw;
    }
  }
} // end _HomePageState

/// Simple data holder for quick-action grid items.
class _QuickAction {
  final String iconPath;
  final String label;
  final VoidCallback onTap;
  const _QuickAction({required this.iconPath, required this.label, required this.onTap});
}

/// Self-contained widget that rotates through quotes every 3 seconds.
/// Isolates the Timer-driven setState to this widget only,
/// preventing the entire HomePage from rebuilding on each tick.
class _QuoteRotatorWidget extends StatefulWidget {
  final List<Map<String, dynamic>> quotes;

  const _QuoteRotatorWidget({required this.quotes});

  @override
  State<_QuoteRotatorWidget> createState() => _QuoteRotatorWidgetState();
}

class _QuoteRotatorWidgetState extends State<_QuoteRotatorWidget> {
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didUpdateWidget(_QuoteRotatorWidget old) {
    super.didUpdateWidget(old);
    // Reset index if quotes list changed
    if (old.quotes != widget.quotes) {
      _index = 0;
    }
  }

  void _startTimer() {
    _timer?.cancel();
    if (widget.quotes.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (mounted && widget.quotes.isNotEmpty) {
          setState(() {
            _index = (_index + 1) % widget.quotes.length;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.quotes.isEmpty) return const SizedBox.shrink();
    final quote = widget.quotes[_index % widget.quotes.length]['quote_text'] as String? ?? '';
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
      child: Text(
        key: ValueKey(_index),
        quote,
        style: const TextStyle(
          fontSize: 13,
          height: 1.6,
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.2,
          fontStyle: FontStyle.italic,
        ),
        textAlign: TextAlign.left,
        maxLines: 6,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// Spiritual calendar event data model
class _SpiritualEvent {
  final DateTime date;
  final String emoji;
  final String titleTe;
  final Color color;
  final String type;

  const _SpiritualEvent({
    required this.date,
    required this.emoji,
    required this.titleTe,
    required this.color,
    required this.type,
  });
}

/// Lunar tithi information
class _TithiInfo {
  final String name;
  final String paksha;
  const _TithiInfo({required this.name, required this.paksha});
}
