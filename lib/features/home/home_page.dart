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

import '../chakras/chakra_detail_page.dart';
import '../songs/all_songs_page.dart';
import '../guru_journey/guru_journey_page.dart';
import '../kundalini_science/kundalini_science_page.dart';
import '../benefits/benefits_page.dart';
import '../video/youtube_player.dart';

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
  int _currentQuoteIndex = 0;
  late AnimationController _glowController;
  late Timer _autoScrollTimer;
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

    // Initialize quote index
    _currentQuoteIndex = 0;

    // Start timer for quote rotation (3 seconds interval)
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        final quotesToDisplay = _quotes.isNotEmpty ? _quotes : [];
        if (quotesToDisplay.isNotEmpty) {
          setState(() {
            _currentQuoteIndex = (_currentQuoteIndex + 1) % quotesToDisplay.length;
          });
        }
      }
    });
    
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
          _quotes = quotes;
        });
        debugPrint('[HomePage] ✅ Loaded ${quotes.length} quotes');
      }
    } catch (e) {
      debugPrint('[HomePage] ❌ Error loading quotes: $e');
      // On error, quotes list stays empty - no fallback to AppConstants
      // This ensures we always use API data
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
          
          // Check which preset reminders are active - language-agnostic checking
          for (var reminder in reminders) {
            final title = (reminder['title'] as String).toLowerCase();
            final time = (reminder['reminderTime'] as String? ?? '');
            
            // Check for morning meditation (6:00 AM) - language agnostic
            if (time == '06:00' || time.startsWith('06:00')) {
              _presetReminders['morning_meditation'] = reminder['isActive'] as bool;
            } 
            // Check for evening meditation (18:00 / 6:00 PM) - language agnostic
            else if (time == '18:00' || time.startsWith('18:00')) {
              _presetReminders['evening_meditation'] = reminder['isActive'] as bool;
            }
            // Fallback: check title keywords (works for any language that uses English keywords)
            else if (title.contains('morning') && title.contains('meditation')) {
              _presetReminders['morning_meditation'] = reminder['isActive'] as bool;
            } else if (title.contains('evening') && title.contains('meditation')) {
              _presetReminders['evening_meditation'] = reminder['isActive'] as bool;
            }
          }
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
    } catch (e) {
      debugPrint('Error loading audios: $e');
    }
  }

  void _onAudioStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _glowController.dispose();
    _audioService.removeListener(_onAudioStateChanged);
    LocalizationService().removeListener(_onLanguageChanged);
    if (_quotes.isNotEmpty) {
      _autoScrollTimer.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      // Performance optimizations
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildDailyQuotes(),
          _buildDailyReminders(),
          _buildMeditationTimer(),
          _buildRingtoneSettings(),
          _buildWallpaperSettings(),
          _buildMeditationMusic(),
          _buildBhajans(),
          _buildGuruJourney(),
          _buildKundaliniScience(),
          _buildBenefits(),
          _build7Chakras(),
          _buildRecentGatherings(),
          _buildUpcomingPrograms(),
          _buildVisionMission(),
          _buildOurValues(),
          SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return SizedBox.shrink();
  }

  Widget _buildDailyQuotes() {
    // Use database quotes - no fallback to AppConstants
    if (_quotes.isEmpty) {
      return SizedBox.shrink();
    }

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
                  child: SingleChildScrollView(
                    child: Text(
                      _quotes[_currentQuoteIndex % _quotes.length]['quote_text'] as String,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.6,
                        color: Color(0xFF6D4C41),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
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
    );
  }

  Widget _buildDailyReminders() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.saffron, AppTheme.saffron.withValues(alpha: 0.7)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.alarm,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    context.tr('daily_reminders'),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () => context.push('/reminders'),
                icon: const Icon(Icons.settings, size: 18),
                label: Text(context.tr('manage')),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.saffron,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            context.tr('enable_reminders_subtitle'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
          ),
          const SizedBox(height: 20),
          
          // Vertical reminder cards
          _buildReminderCard(
            title: context.tr('morning_meditation'),
            description: context.tr('daily_at') + ' 6:00 AM',
            subtitle: context.tr('start_day_peace'),
            icon: Icons.wb_sunny,
            color: Colors.orange,
            isActive: _presetReminders['morning_meditation'] ?? false,
            onToggle: () => _togglePresetReminder('morning_meditation', context.tr('morning_meditation'), '06:00'),
          ),
          const SizedBox(height: 12),
          _buildReminderCard(
            title: context.tr('evening_meditation'),
            description: context.tr('daily_at') + ' 6:00 PM',
            subtitle: context.tr('end_day_gratitude'),
            icon: Icons.nightlight_round,
            color: Colors.deepPurple,
            isActive: _presetReminders['evening_meditation'] ?? false,
            onToggle: () => _togglePresetReminder('evening_meditation', context.tr('evening_meditation'), '18:00'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildReminderCard({
    required String title,
    required String description,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isActive,
    required VoidCallback onToggle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color, color.withValues(alpha: 0.7)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Transform.scale(
            scale: 0.9,
            child: Switch(
              value: isActive,
              onChanged: (_) => onToggle(),
              activeThumbColor: Colors.white,
              activeTrackColor: color,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: Colors.grey.shade300,
            ),
          ),
        ],
      ),
    );
  }
  
  void _togglePresetReminder(String key, String title, String defaultTime) async {
    final currentState = _presetReminders[key] ?? false;
    
    // Optimistically update UI
    setState(() {
      _presetReminders[key] = !currentState;
    });
    
    try {
      if (!currentState) {
        // Create/activate reminder
        await _createOrActivateReminder(title, defaultTime);
      } else {
        // Deactivate (delete) reminder
        await _deactivateReminder(defaultTime);
      }
      
      // After successful toggle, FORCE refresh preset reminders to ensure sync
      // Use forceRefresh to bypass cache
      final response = await _apiService.getReminders(forceRefresh: true);
      if (response['success'] == true && mounted) {
        final reminders = List<Map<String, dynamic>>.from(response['reminders'] ?? []);
        
        setState(() {
          // Reset to false first
          _presetReminders['morning_meditation'] = false;
          _presetReminders['evening_meditation'] = false;
          
          // Check which preset reminders are active - language-agnostic checking
          for (var reminder in reminders) {
            final time = (reminder['reminderTime'] as String? ?? '');
            
            // Check for morning meditation (6:00 AM) - language agnostic
            if (time == '06:00' || time.startsWith('06:00')) {
              _presetReminders['morning_meditation'] = reminder['isActive'] as bool;
            } 
            // Check for evening meditation (18:00 / 6:00 PM) - language agnostic
            else if (time == '18:00' || time.startsWith('18:00')) {
              _presetReminders['evening_meditation'] = reminder['isActive'] as bool;
            }
          }
        });
      }
      
    } catch (e) {
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
    // Check if reminder already exists - use TIME instead of title for matching
    // FORCE REFRESH to get latest data
    final response = await _apiService.getReminders(forceRefresh: true);
    if (response['success'] == true) {
      final reminders = List<Map<String, dynamic>>.from(response['reminders'] ?? []);
      
      // Find existing reminder by TIME (language-agnostic)
      final existing = reminders.firstWhere(
        (r) {
          final time = (r['reminderTime'] as String? ?? '');
          return time == defaultTime || time.startsWith(defaultTime);
        },
        orElse: () => {},
      );
      
      bool success = false;
      String? errorMessage;
      
      if (existing.isNotEmpty) {
        // Check if it needs to be activated
        final isCurrentlyActive = existing['isActive'] as bool;
        if (!isCurrentlyActive) {
          // Activate existing reminder
          final toggleResponse = await _apiService.toggleReminder(existing['id'] as int);
          success = toggleResponse['success'] == true;
          errorMessage = toggleResponse['message'];
        } else {
          // Already active
          success = true;
        }
      } else {
        // Create new reminder with English title (will be used for ALL languages)
        // Use standardized English titles so they work across languages
        final standardTitle = defaultTime == '06:00' 
            ? 'Morning Meditation' 
            : 'Evening Meditation';
            
        final createResponse = await _apiService.createReminder(
          title: standardTitle,
          message: 'Time for your meditation practice',
          reminderTime: defaultTime,
          daysOfWeek: [0, 1, 2, 3, 4, 5, 6], // All days (Sunday to Saturday)
          isActive: true,
        );
        success = createResponse['success'] == true;
        errorMessage = createResponse['message'];
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success 
              ? '${context.tr('reminder_set')} $defaultTime'
              : errorMessage ?? 'Failed to set reminder'),
            backgroundColor: success ? Colors.green : Colors.red,
            duration: Duration(seconds: success ? 3 : 4),
          ),
        );
      }
    }
  }
  
  Future<void> _deactivateReminder(String defaultTime) async {
    // FORCE REFRESH to get latest data
    final response = await _apiService.getReminders(forceRefresh: true);
    if (response['success'] == true) {
      final reminders = List<Map<String, dynamic>>.from(response['reminders'] ?? []);
      
      // Find existing reminder by TIME (language-agnostic)
      final existing = reminders.firstWhere(
        (r) {
          final time = (r['reminderTime'] as String? ?? '');
          return time == defaultTime || time.startsWith(defaultTime);
        },
        orElse: () => {},
      );
      
      if (existing.isNotEmpty) {
        debugPrint('🗑️ Deleting reminder ID: ${existing['id']} at time: $defaultTime');
        
        // DELETE the reminder instead of just toggling it off
        // This ensures it disappears from "Manage Reminders" screen
        final deleteResponse = await _apiService.deleteReminder(existing['id'] as int);
        
        debugPrint('🗑️ Delete response: ${deleteResponse['success']}');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(deleteResponse['success'] == true 
                ? context.tr('reminder_deactivated')
                : deleteResponse['message'] ?? 'Failed to deactivate reminder'),
              backgroundColor: deleteResponse['success'] == true ? Colors.orange : Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  Widget _buildMeditationTimer() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => context.push('/meditation/timer'),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF7C3AED),
                    const Color(0xFF9333EA),
                    const Color(0xFFA855F7),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.timer,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('meditation_timer'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          context.tr('track_meditation_practice'),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // View History Button
          GestureDetector(
            onTap: () => context.push('/meditation/history'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.analytics_outlined,
                    color: const Color(0xFF7C3AED),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    context.tr('view_meditation_journey'),
                    style: const TextStyle(
                      color: Color(0xFF7C3AED),
                      fontSize: 15,
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: GestureDetector(
        onTap: () => context.push('/settings/ringtone'),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFF6B6B),
                Color(0xFFFF8E53),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF6B6B).withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.music_note,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('sivoham_ringtone'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.tr('set_as_ringtone'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWallpaperSettings() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: GestureDetector(
        onTap: () => context.push('/settings/wallpaper'),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF667eea),
                Color(0xFF764ba2),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF667eea).withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.wallpaper,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('wisdom_wallpaper'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.tr('set_daily_wallpaper'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVisionMission() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        children: [
          // Vision Card - Beautiful gradient card
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFF3E0),
                  Color(0xFFFFE0B2),
                  Color(0xFFFFCC80),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.saffron.withOpacity(0.3),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withOpacity(0.5),
                  width: 1.5,
                ),
              ),
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon and Title Row
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.saffron,
                              Color(0xFFFF6B35),
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.saffron.withOpacity(0.4),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.visibility_outlined,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('our_vision'),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFD84315),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              height: 3,
                              width: 60,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppTheme.saffron,
                                    Colors.transparent,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  // Vision Text
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      context.tr('vision_text'),
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.7,
                        color: Color(0xFF424242),
                        letterSpacing: 0.3,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 24),
          
          // Mission Card - Beautiful gradient card
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFE3F2FD),
                  Color(0xFFBBDEFB),
                  Color(0xFF90CAF9),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.3),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withOpacity(0.5),
                  width: 1.5,
                ),
              ),
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon and Title Row
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primary,
                              Color(0xFF1565C0),
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withOpacity(0.4),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.explore_outlined,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('our_mission'),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0D47A1),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              height: 3,
                              width: 60,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppTheme.primary,
                                    Colors.transparent,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  // Mission Text
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      context.tr('mission_text'),
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.7,
                        color: Color(0xFF424242),
                        letterSpacing: 0.3,
                      ),
                      textAlign: TextAlign.justify,
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

  Widget _buildOurValues() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF3E5F5),
              Color(0xFFE1BEE7),
              Color(0xFFCE93D8),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon and Title Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF9C27B0),
                          Color(0xFFAB47BC),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purple.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.stars,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('our_values'),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6A1B9A),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: 3,
                          width: 60,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFF9C27B0),
                                Colors.transparent,
                              ],
                            ),
                            borderRadius: BorderRadius.all(Radius.circular(2)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Values List
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(16),
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
        ),
      ),
    );
  }

  Widget _buildValueItem(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF9C27B0),
                Color(0xFFAB47BC),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF424242),
              letterSpacing: 0.3,
            ),
          ),
        ),
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
              // Check if this meditation is currently playing
              final currentSong = _audioService.currentSong;
              final bool isCurrentlyPlaying;
              if (currentSong == null) {
                isCurrentlyPlaying = false;
              } else if (currentSong is AudioModel) {
                isCurrentlyPlaying = currentSong.id == firstMeditation.id && _audioService.isPlaying;
              } else {
                isCurrentlyPlaying = (currentSong as Map)['title'] == firstMeditation.title && _audioService.isPlaying;
              }

              if (isCurrentlyPlaying) {
                // If playing, pause it
                await _audioService.pause();
              } else {
                // If not playing or different song, play it
                await _audioService.playSong(meditations, 0);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Playing "${firstMeditation.title}"'),
                      duration: Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                      margin: EdgeInsets.only(
                        bottom: MediaQuery.of(context).size.height - 100,
                        left: 10,
                        right: 10,
                      ),
                    ),
                  );
                }
              }
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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AllSongsPage(),
                ),
              );
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
          if (isCurrentSong && _audioService.isPlaying) {
            await _audioService.pause();
          } else {
            await _audioService.playSong(bhajans, index);
          }
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
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GuruJourneyPage(),
            ),
          );
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
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => KundaliniSciencePage(),
            ),
          );
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
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BenefitsPage(),
            ),
          );
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
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChakraDetailPage(initialIndex: 0),
            ),
          );
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
                        // Play YouTube video in-app
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => YouTubeVideoPlayer(
                              videoId: videoId,
                              title: title,
                            ),
                          ),
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
    // Don't show section while loading or if no events
    if (_isLoadingEvents || _upcomingEvents.isEmpty) {
      return SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('upcoming_programs'),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
          ),
          SizedBox(height: 16),
          ..._upcomingEvents.map((event) {
            final title = event['title'] as String? ?? 'Untitled Event';
            final eventDate = event['eventDate'] as String? ?? '';
            final location = event['location'] as String? ?? '';
            final imageUrl = event['imageUrl'] as String?;
            
            return InkWell(
              onTap: () {
                // Navigate to events tab
                context.go('/events');
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: double.infinity,
                margin: EdgeInsets.only(bottom: 16),
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
                    // Event image or placeholder
                    if (imageUrl != null && imageUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        child: CachedImage(
                          imageUrl: imageUrl,
                          width: double.infinity,
                          height: 180,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      Container(
                        height: 180,
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(20)),
                          gradient: LinearGradient(
                            colors: [AppTheme.primary, AppTheme.saffron],
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.event,
                            size: 64,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(16),
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
                                  fontSize: 16,
                                ),
                          ),
                          if (eventDate.isNotEmpty) ...[
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: AppTheme.primary,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  eventDate,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: AppTheme.primary,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13,
                                      ),
                                ),
                              ],
                            ),
                          ],
                          if (location.isNotEmpty) ...[
                            SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 16,
                                  color: AppTheme.textSecondary,
                                ),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    location,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: AppTheme.textSecondary,
                                          fontSize: 13,
                                        ),
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
          }).toList(),
        ],
      ),
    );
  }
}
