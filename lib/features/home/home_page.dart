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
import '../../core/widgets/cached_image.dart';
import '../../core/services/image_preloader_service.dart';

import '../audio/now_playing_screen.dart';
import '../../core/utils/audio_navigation.dart';

/// Helper function to get the correct ImageProvider for CDN or asset images
ImageProvider _getImageProvider(String imageUrl) {
  if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
    return CachedNetworkImageProvider(imageUrl);
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
        ImagePreloaderService().warmMemoryCache(context);
      }
    });

    // Quote rotation is now handled by _QuoteRotatorWidget — no timer here.
    
    // Load events from database
    _loadEvents();
    _loadPresetReminders();
    _loadGatherings();
    _loadQuotes();
    _loadAudios();
    
    // Listen for language changes to refresh quotes
    LocalizationService().addListener(_onLanguageChanged);
  }
  
  void _onLanguageChanged() {
    debugPrint('[HomePage] Language changed, refreshing quotes');
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

  Future<void> _loadAudios() async {
    try {
      // Use cached data by default
      await _audioProvider.fetchAllAudios();
      // Preload secondary images in background after audios load
      ImagePreloaderService().preloadSecondaryImages();
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
          _buildQuickActions(),        // Bhajans, Classes, Events, Kalpataru
          _buildDailyQuoteCard(),      // Today's Inspiration (image card)
          _buildMeditationTimer(),     // Purple timer card
          _buildRingtoneSettings(),    // Sivoham Ringtone
          _buildWallpaperSettings(),   // Guruji Wallpapers
          _buildMeditationMusic(),     // Meditation music player
          _buildBhajans(),             // Top bhajans
          // _buildGuruJourney(),
          // _buildKundaliniScience(),
          // _buildBenefits(),
          // _build7Chakras(),
          _buildRecentGatherings(),
          _buildUpcomingPrograms(),
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

  // ── Quick-action icon grid: About Guruji, Kundalini, Chakras, Reminders ──
  Widget _buildQuickActions() {
    final actions = [
      _QuickAction(
        iconPath: 'assets/images/icons/Gurudev-icon.png',
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
        iconPath: 'assets/images/icons/remainders-icon.png',
        label: context.tr('quick_daily_reminders'),
        onTap: () => context.push('/reminders'),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: actions.map(_buildQuickActionItem).toList(),
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
    // Fallback quotes from translations — shown when API is unavailable
    // Uses all meaningful quote keys already present in both en.json and te.json
    final fallbackQuotes = [
      {'quote_text': context.tr('guru_journey_quote')},
      {'quote_text': context.tr('kundalini_quote')},
      {'quote_text': context.tr('kundalini_highlight_1')},
      {'quote_text': context.tr('kundalini_highlight_2')},
      {'quote_text': context.tr('kundalini_highlight_3')},
    ];
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
                            child: const Text(
                              'Start Meditation',
                              style: TextStyle(
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

  Widget _buildRingtoneSettings() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: GestureDetector(
        onTap: () => context.push('/settings/ringtone'),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8F0),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.tagBorder),
            boxShadow: [AppTheme.softShadow],
          ),
          child: Stack(
            children: [
              // Decorative right circle
              Positioned(
                right: -20,
                top: -20,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primary.withValues(alpha: 0.07),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 18),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.music_note_rounded,
                          color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            context.tr('sivoham_ringtone'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            context.tr('set_as_ringtone'),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        context.tr('set_now'),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
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
          height: 100,
          decoration: BoxDecoration(
            color: AppTheme.tagBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.tagBorder),
            boxShadow: [AppTheme.softShadow],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20, top: -20,
                child: Container(
                  width: 110, height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.gold.withValues(alpha: 0.10),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                child: Row(
                  children: [
                    Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                        gradient: AppTheme.goldGradient,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.wallpaper_rounded, color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(context.tr('wisdom_wallpaper'),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary)),
                          const SizedBox(height: 3),
                          Text(context.tr('set_daily_wallpaper'),
                              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        gradient: AppTheme.goldGradient,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(context.tr('set_now'),
                          style: const TextStyle(color: Colors.white, fontSize: 12,
                              fontWeight: FontWeight.w700)),
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
              final imageUrl = gathering['imageUrl'] as String? ?? '';
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
                          Container(
                            height: 180,
                            width: 300,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(20)),
                              color: AppTheme.softGray,
                            ),
                            child: imageUrl.isNotEmpty
                                ? CachedImage(
                                    imageUrl: imageUrl,
                                    width: 300,
                                    height: 180,
                                    fit: BoxFit.cover,
                                    borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(20)),
                                    showShimmer: true,
                                  )
                                : Center(
                                    child: Icon(
                                      Icons.event,
                                      color: AppTheme.textSecondary,
                                      size: 48,
                                    ),
                                  ),
                          ),
                          // Play button overlay
                          if (videoUrl.isNotEmpty)
                            Positioned.fill(
                              child: IgnorePointer(
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(20)),
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withOpacity(0.3),
                                      ],
                                    ),
                                  ),
                                  child: Center(
                                    child: Container(
                                      padding: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppTheme.saffron.withOpacity(0.9),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
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
