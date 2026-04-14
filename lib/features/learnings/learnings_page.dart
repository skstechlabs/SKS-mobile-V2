import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/auth_guard.dart';
import '../../core/services/api_service.dart';
import '../../core/services/localization_service.dart';

class LearningsPage extends StatefulWidget {
  const LearningsPage({super.key});

  @override
  State<LearningsPage> createState() => _LearningsPageState();
}

class _LearningsPageState extends State<LearningsPage> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _errorMessage;
  Map<int, Map<String, dynamic>> _levelAccess = {};
  Map<String, dynamic>? _meditationTest;

  @override
  void initState() {
    super.initState();
    _loadLevelAccess();
  }

  Future<void> _loadLevelAccess() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('🔍 Loading level access from API...');
      final response = await _apiService.get('/api/level-progression/access');
      
      debugPrint('📦 API Response: $response');
      
      if (response['success'] == true) {
        final accessData = response['levelAccess'];
        debugPrint('📊 Level Access Data: $accessData');
        debugPrint('📊 Data Type: ${accessData.runtimeType}');
        
        // Handle both Map<String, dynamic> and Map<int, dynamic>
        final Map<int, Map<String, dynamic>> parsedAccess = {};
        
        if (accessData is Map) {
          accessData.forEach((key, value) {
            try {
              final levelNum = key is int ? key : int.parse(key.toString());
              if (value is Map) {
                parsedAccess[levelNum] = Map<String, dynamic>.from(value);
              }
            } catch (e) {
              debugPrint('⚠️ Error parsing level $key: $e');
            }
          });
        }
        
        debugPrint('✅ Parsed Level Access: $parsedAccess');
        
        setState(() {
          _levelAccess = parsedAccess;
          _meditationTest = response['meditationTest'] as Map<String, dynamic>?;
          _isLoading = false;
          _errorMessage = null;
        });
        
        debugPrint('✅ Level access loaded successfully: ${_levelAccess.length} levels');
      } else {
        final errorMsg = response['message'] ?? 'Failed to load classes';
        debugPrint('❌ API returned success=false: $errorMsg');
        setState(() {
          _isLoading = false;
          _errorMessage = errorMsg;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error loading level access: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load classes. Please check your connection.';
      });
    }
  }

  bool _isLevelUnlocked(int levelNumber) {
    return _levelAccess[levelNumber]?['unlocked'] == true;
  }

  bool _isLevelCompleted(int levelNumber) {
    return _levelAccess[levelNumber]?['completed'] == true;
  }

  int _getDaysCompleted(int levelNumber) {
    final value = _levelAccess[levelNumber]?['daysCompleted'];
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  int _getTotalDays(int levelNumber) {
    final value = _levelAccess[levelNumber]?['totalDays'];
    if (value == null) return 3;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 3;
    return 3;
  }

  @override
  Widget build(BuildContext context) {
    return AuthGuard(
      featureName: context.tr('learnings_title'),
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Show error message if API failed
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: AppTheme.saffron,
                size: 60,
              ),
              const SizedBox(height: 20),
              Text(
                context.tr('unable_to_load_classes'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                context.tr('unable_to_load_classes_desc'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _loadLevelAccess,
                icon: const Icon(Icons.refresh),
                label: Text(context.tr('retry')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.saffron,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('learnings_title'),
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              context.tr('learnings_subtitle'),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            
            // Online Courses Section
            _buildSectionHeader(context.tr('online_courses'), Icons.video_library),
            const SizedBox(height: 16),
            _buildLevelCard(
              context,
              classId: 1,
              levelNumber: 1,
              level: context.tr('level_1'),
              title: context.tr('brahmarandhra_opening'),
              icon: Icons.looks_one,
              color: AppTheme.saffron,
            ),
            _buildLevelCard(
              context,
              classId: 2,
              levelNumber: 2,
              level: context.tr('level_2'),
              title: context.tr('sushumna_nadi_activation'),
              icon: Icons.looks_two,
              color: AppTheme.gold,
            ),
            
            // Meditation Test (between Level 2 and Level 3)
            if (_isLevelCompleted(2))
              _buildMeditationTestCard(context),
            
            _buildLevelCard(
              context,
              classId: 3,
              levelNumber: 3,
              level: context.tr('level_3'),
              title: context.tr('chakra_activation'),
              icon: Icons.looks_3,
              color: AppTheme.gold,
            ),
            _buildLevelCard(
              context,
              classId: 4,
              levelNumber: 4,
              level: context.tr('level_4'),
              title: context.tr('kundalini_activation'),
              icon: Icons.looks_4,
              color: AppTheme.saffron,
            ),
            
            const SizedBox(height: 32),
            
            // Residential Courses Section
            _buildSectionHeader(context.tr('residential_courses'), Icons.home),
            const SizedBox(height: 8),
            Text(
              context.tr('residential_courses_desc'),
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 16),
            _buildResidentialCard(
              context,
              level: context.tr('level_5'),
              description: context.tr('advanced_practice_guruji'),
            ),
            _buildResidentialCard(
              context,
              level: context.tr('level_5_1'),
              description: context.tr('master_level_intensive'),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: AppTheme.saffronGradient,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppTheme.darkBrown,
          ),
        ),
      ],
    );
  }
  
  Widget _buildLevelCard(
    BuildContext context, {
    required int classId,
    required int levelNumber,
    required String level,
    required String title,
    required IconData icon,
    required Color color,
  }) {
    final isUnlocked = _isLevelUnlocked(levelNumber);
    final isCompleted = _isLevelCompleted(levelNumber);
    final daysCompleted = _getDaysCompleted(levelNumber);
    final totalDays = _getTotalDays(levelNumber);
    final minutesUntilNextLevelUnlock = _getMinutesUntilNextLevelUnlock(levelNumber);
    final levelUnlockMinutes = _getLevelUnlockMinutes(levelNumber);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isUnlocked ? Colors.white : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted
              ? AppTheme.saffron.withValues(alpha: 0.5)
              : isUnlocked
                  ? color.withValues(alpha: 0.3)
                  : Colors.grey.shade300,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isUnlocked
              ? () {
                  context.push(
                    '/classes/$classId/days',
                    extra: {
                      'classTitle': title,
                      'level': level,
                    },
                  );
                }
              : null,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppTheme.saffron.withValues(alpha: 0.2)
                        : isUnlocked
                            ? color.withValues(alpha: 0.1)
                            : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isCompleted
                        ? Icons.check_circle
                        : isUnlocked
                            ? icon
                            : Icons.lock_outline,
                    color: isCompleted
                        ? AppTheme.saffron
                        : isUnlocked
                            ? color
                            : Colors.grey.shade400,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        level,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isUnlocked ? color : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          color: isUnlocked
                              ? AppTheme.textPrimary
                              : Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Status badge
                      if (isCompleted)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildStatusBadge(
                              context.tr('completed'),
                              AppTheme.saffron,
                              Icons.check_circle,
                            ),
                            // Show unlock timing for next level
                            if (minutesUntilNextLevelUnlock != null && minutesUntilNextLevelUnlock > 0) ...[
                              const SizedBox(height: 6),
                              _buildStatusBadge(
                                '${context.tr('next_level_unlocks_in')} ${_formatUnlockTime(minutesUntilNextLevelUnlock, context)}',
                                AppTheme.gold,
                                Icons.lock_clock,
                              ),
                            ] else if (minutesUntilNextLevelUnlock != null && minutesUntilNextLevelUnlock == 0) ...[
                              const SizedBox(height: 6),
                              _buildStatusBadge(
                                context.tr('next_level_ready'),
                                AppTheme.saffron,
                                Icons.lock_open,
                              ),
                            ],
                          ],
                        )
                      else if (isUnlocked && daysCompleted > 0)
                        _buildStatusBadge(
                          '$daysCompleted/$totalDays ${context.tr('days')}',
                          AppTheme.gold,
                          Icons.play_circle_outline,
                        )
                      else if (isUnlocked)
                        _buildStatusBadge(
                          '3 ${context.tr('days')}',
                          AppTheme.saffron,
                          Icons.video_library,
                        )
                      else
                        _buildStatusBadge(
                          _getLockReason(levelNumber, context),
                          Colors.grey.shade600,
                          Icons.lock_outline,
                        ),
                    ],
                  ),
                ),
                if (isUnlocked)
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatUnlockTime(int minutes, BuildContext context) {
    if (minutes < 60) {
      return '$minutes ${context.tr('min')}';
    } else {
      final hours = (minutes / 60).floor();
      final remainingMinutes = minutes % 60;
      if (remainingMinutes == 0) {
        return '$hours ${context.tr('hours')}';
      } else {
        return '$hours ${context.tr('hours')} $remainingMinutes ${context.tr('min')}';
      }
    }
  }

  int? _getMinutesUntilNextLevelUnlock(int levelNumber) {
    final value = _levelAccess[levelNumber]?['minutesUntilNextLevelUnlock'];
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is double) return value.toInt();
    return null;
  }

  int _getLevelUnlockMinutes(int levelNumber) {
    final value = _levelAccess[levelNumber]?['levelUnlockMinutes'];
    if (value == null) return 1440;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 1440;
    if (value is double) return value.toInt();
    return 1440;
  }

  String _getLockReason(int levelNumber, BuildContext context) {
    if (levelNumber == 1) return context.tr('available');
    if (levelNumber == 2) return context.tr('complete_level_1');
    if (levelNumber == 3) {
      if (!_isLevelCompleted(2)) return context.tr('complete_level_2');
      if (_meditationTest?['passed'] != true) return context.tr('pass_meditation_test');
      return context.tr('locked');
    }
    if (levelNumber == 4) return context.tr('complete_level_3');
    return context.tr('locked');
  }

  Widget _buildStatusBadge(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeditationTestCard(BuildContext context) {
    final testPassed = _meditationTest?['passed'] == true;
    final testTaken = _meditationTest?['taken'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.gold.withValues(alpha: 0.2),
            AppTheme.saffron.withValues(alpha: 0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: testPassed
              ? AppTheme.saffron.withValues(alpha: 0.5)
              : AppTheme.gold.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: AppTheme.saffronGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.self_improvement,
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
                      context.tr('meditation_test'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.saffron,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      testPassed
                          ? context.tr('meditation_test_completed')
                          : context.tr('meditation_test_required'),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (testPassed)
                const Icon(
                  Icons.check_circle,
                  color: AppTheme.saffron,
                  size: 32,
                ),
            ],
          ),
          if (!testPassed) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: testTaken
                    ? null
                    : () {
                        // TODO: Navigate to meditation test
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(context.tr('meditation_test_coming_soon')),
                            backgroundColor: AppTheme.gold,
                          ),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.saffron,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  testTaken ? context.tr('test_submitted') : context.tr('take_test'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildResidentialCard(
    BuildContext context, {
    required String level,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.gold.withValues(alpha: 0.15),
            AppTheme.saffron.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.gold.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: AppTheme.saffronGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.school,
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
                  level,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.saffron,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.event_available,
                      size: 16,
                      color: AppTheme.gold,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      context.tr('apply_via_event'),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
