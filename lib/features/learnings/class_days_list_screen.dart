import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/api_service.dart';
import '../../core/services/localization_service.dart';

class ClassDaysListScreen extends StatefulWidget {
  final int classId;
  final String classTitle;
  final String level;

  const ClassDaysListScreen({
    super.key,
    required this.classId,
    required this.classTitle,
    required this.level,
  });

  @override
  State<ClassDaysListScreen> createState() => _ClassDaysListScreenState();
}

class _ClassDaysListScreenState extends State<ClassDaysListScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  bool _isEnrolling = false;
  String? _error;
  List<Map<String, dynamic>> _days = [];
  bool _isEnrolled = false;

  @override
  void initState() {
    super.initState();
    _loadDays();
  }

  Future<void> _loadDays() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      debugPrint('📚 Loading days for class ${widget.classId}');
      
      // Get user's current language preference
      final currentLanguage = LocalizationService().currentLocale.languageCode;
      debugPrint('🌐 Using language: $currentLanguage');
      
      final response = await _apiService.get(
        '/api/classes-v2/${widget.classId}/days',
        queryParameters: {'language': currentLanguage},
      );

      debugPrint('📦 Days response: $response');

      if (response['success'] == true) {
        final daysData = response['days'];
        if (daysData == null) {
          setState(() {
            _error = 'No days data received from server';
            _isLoading = false;
          });
          return;
        }
        
        setState(() {
          _days = List<Map<String, dynamic>>.from(daysData);
          _isEnrolled = _days.isNotEmpty && _days.any((d) => d['isUnlocked'] == true);
          _isLoading = false;
        });
        debugPrint('✅ Loaded ${_days.length} days, enrolled: $_isEnrolled');
      } else if (response['isBlocked'] == true) {
        // User is blocked from accessing classes
        setState(() {
          _isLoading = false;
          _error = null;
        });
        
        if (mounted) {
          _showUserBlockedDialog(
            reason: response['blockInfo']?['reason'] ?? 'Your account has been blocked',
            blockType: response['blockInfo']?['type'] ?? 'permanent',
            expiresAt: response['blockInfo']?['expiresAt'],
          );
        }
      } else if (response['isRestricted'] == true) {
        // User is restricted from this specific class
        setState(() {
          _isLoading = false;
          _error = null;
        });
        
        if (mounted) {
          _showClassRestrictedDialog(
            reason: response['restrictionInfo']?['reason'] ?? 'You are restricted from accessing this class',
            restrictionType: response['restrictionInfo']?['type'] ?? 'specific_class',
            expiresAt: response['restrictionInfo']?['expiresAt'],
          );
        }
      } else if (response['levelLocked'] == true) {
        // Level is locked due to level_unlock_minutes timing
        final minutesUntilUnlock = response['minutesUntilUnlock'] ?? 0;
        final hoursUntilUnlock = response['hoursUntilUnlock'] ?? 0;
        final levelUnlockMinutes = response['levelUnlockMinutes'] ?? 1440;
        
        setState(() {
          _isLoading = false;
          _error = null;
        });
        
        // Show level locked dialog
        if (mounted) {
          _showLevelLockedDialog(
            minutesUntilUnlock: minutesUntilUnlock,
            hoursUntilUnlock: hoursUntilUnlock,
            levelUnlockMinutes: levelUnlockMinutes,
          );
        }
      } else {
        final errorMsg = response['message'] ?? 'Failed to load days';
        debugPrint('❌ Failed to load days: $errorMsg');
        setState(() {
          _error = errorMsg;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error loading days: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() {
        _error = 'Error loading days. Please check your connection.';
        _isLoading = false;
      });
    }
  }

  void _showUserBlockedDialog({
    required String reason,
    required String blockType,
    String? expiresAt,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.block, color: Colors.red, size: 32),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Account Blocked'),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your account has been blocked from accessing classes.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Reason:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reason,
                    style: const TextStyle(fontSize: 14),
                  ),
                  if (blockType == 'temporary' && expiresAt != null) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Block Type:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Temporary (expires: ${_formatDateTime(expiresAt)})',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ] else ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Block Type: Permanent',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.red),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'If you believe this is a mistake, please contact support.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.pop(); // Go back to classes list
            },
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  void _showClassRestrictedDialog({
    required String reason,
    required String restrictionType,
    String? expiresAt,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning, color: Colors.orange, size: 32),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Access Restricted'),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'You are restricted from accessing this class.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Reason:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reason,
                    style: const TextStyle(fontSize: 14),
                  ),
                  if (expiresAt != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Restriction expires: ${_formatDateTime(expiresAt)}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ] else ...[
                    const SizedBox(height: 12),
                    const Text(
                      'This is a permanent restriction.',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Please contact support for more information.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.pop(); // Go back to classes list
            },
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return isoString;
    }
  }

  void _showLevelLockedDialog({
    required int minutesUntilUnlock,
    required int hoursUntilUnlock,
    required int levelUnlockMinutes,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.lock_clock, color: AppTheme.gold, size: 32),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Level Locked'),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This level is not yet accessible.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'You must wait ${_formatUnlockTime(minutesUntilUnlock)} after completing the previous level before accessing this content.',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.beige.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.gold.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time, color: AppTheme.gold, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Unlocks in: ${_formatUnlockTime(minutesUntilUnlock)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkBrown,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'This waiting period is designed to give you time to integrate the teachings from the previous level.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.pop(); // Go back to classes list
            },
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  String _formatUnlockTime(int minutes) {
    if (minutes < 60) {
      return '$minutes minutes';
    } else {
      final hours = (minutes / 60).floor();
      final remainingMinutes = minutes % 60;
      if (remainingMinutes == 0) {
        return '$hours ${hours == 1 ? 'hour' : 'hours'}';
      } else {
        return '$hours ${hours == 1 ? 'hour' : 'hours'} $remainingMinutes minutes';
      }
    }
  }

  Future<void> _enrollInClass() async {
    setState(() => _isEnrolling = true);

    try {
      final response = await _apiService.post(
        '/api/classes/${widget.classId}/enroll',
        {},
      );

      if (!mounted) return;

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully enrolled! Day 1 is now unlocked.'),
            backgroundColor: AppTheme.saffron,
          ),
        );
        // Reload days to show unlocked status
        await _loadDays();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Enrollment failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isEnrolling = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.level,
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              widget.classTitle,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          style: const TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _loadDays,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _days.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.video_library_outlined,
                              size: 64,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No days available yet',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Videos will be added soon',
                              style: TextStyle(color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        // Enrollment banner if not enrolled
                        if (!_isEnrolled)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.saffron.withOpacity(0.1),
                                  AppTheme.gold.withOpacity(0.1),
                                ],
                              ),
                            ),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.lock_outline,
                                  size: 48,
                                  color: AppTheme.saffron,
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Enroll to Start Learning',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Get access to all video lessons',
                                  style: TextStyle(color: AppTheme.textSecondary),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _isEnrolling ? null : _enrollInClass,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.saffron,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 32,
                                      vertical: 16,
                                    ),
                                  ),
                                  child: _isEnrolling
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text(
                                          'Enroll Now',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ],
                            ),
                          ),

                        // Days list
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _days.length,
                            itemBuilder: (context, index) {
                              final day = _days[index];
                              return _buildDayCard(day);
                            },
                          ),
                        ),
                      ],
                    ),
    );
  }

  Widget _buildDayCard(Map<String, dynamic> day) {
    final isUnlocked = day['isUnlocked'] == true;
    final isCompleted = day['isCompleted'] == true;
    final dayNumber = day['dayNumber'] as int? ?? 1;
    
    // Safe parsing of hoursUntilUnlock - handle both int and string
    int? hoursUntilUnlock;
    if (day['minutesUntilUnlock'] != null) {
      final minutes = day['minutesUntilUnlock'] is int 
          ? day['minutesUntilUnlock'] as int
          : int.tryParse(day['minutesUntilUnlock'].toString()) ?? 0;
      hoursUntilUnlock = (minutes / 60).ceil();
    }
    
    // Safe parsing of stats
    final completionPercentage = (day['completionPercentage'] as num?)?.toDouble() ?? 0.0;
    final watchTimeSeconds = (day['watchTimeSeconds'] as num?)?.toInt() ?? 0;
    final completedAt = day['completedAt'] as String?;
    final startedAt = day['startedAt'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted
              ? AppTheme.saffron.withOpacity(0.3)
              : AppTheme.softGray,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                  // Safely get day ID, class ID, and day number
                  final dayId = day['id']?.toString() ?? '0';
                  final dayNumber = day['dayNumber']?.toString() ?? '1';
                  final title = day['title']?.toString() ?? 'Video';
                  final classIdStr = widget.classId.toString();
                  
                  context.push(
                    '/classes/days/$dayId/video?title=${Uri.encodeComponent(title)}&dayNumber=$dayNumber&classId=$classIdStr',
                  );
                }
              : () {
                  // 🆕 Show detailed lock info when tapping locked day
                  _showLockedDayDialog(day, hoursUntilUnlock);
                },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppTheme.saffron.withOpacity(0.1)
                        : isUnlocked
                            ? AppTheme.gold.withOpacity(0.1)
                            : AppTheme.softGray.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isCompleted
                        ? Icons.check_circle
                        : isUnlocked
                            ? Icons.play_circle_outline
                            : Icons.lock_outline,
                    color: isCompleted
                        ? AppTheme.saffron
                        : isUnlocked
                            ? AppTheme.gold
                            : AppTheme.textSecondary,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        day['title'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isUnlocked ? AppTheme.darkBrown : AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (day['description'] != null)
                        Text(
                          day['description'],
                          style: TextStyle(
                            fontSize: 13,
                            color: isUnlocked ? AppTheme.textSecondary : AppTheme.textSecondary.withOpacity(0.6),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 8),

                      // Status badge and stats
                      if (isCompleted)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildStatusBadge(
                              'Completed',
                              AppTheme.saffron,
                              Icons.check_circle,
                            ),
                            if (completedAt != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                'Completed: ${_formatDate(completedAt)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                            if (watchTimeSeconds > 0) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Watch time: ${_formatWatchTime(watchTimeSeconds)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        )
                      else if (isUnlocked)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (completionPercentage > 0)
                              _buildStatusBadge(
                                '${completionPercentage.toStringAsFixed(0)}% watched',
                                AppTheme.gold,
                                Icons.play_circle_outline,
                              )
                            else
                              _buildStatusBadge(
                                'Start watching',
                                AppTheme.gold,
                                Icons.play_circle_outline,
                              ),
                            if (startedAt != null && completionPercentage > 0) ...[
                              const SizedBox(height: 6),
                              Text(
                                'Started: ${_formatDate(startedAt)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                            if (watchTimeSeconds > 0) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Watch time: ${_formatWatchTime(watchTimeSeconds)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (hoursUntilUnlock != null && hoursUntilUnlock > 0)
                              _buildStatusBadge(
                                'Unlocks in ${_formatUnlockTime(hoursUntilUnlock * 60)}',
                                AppTheme.textSecondary,
                                Icons.lock_clock,
                              )
                            else if (dayNumber == 1)
                              _buildStatusBadge(
                                'Enroll to unlock',
                                AppTheme.textSecondary,
                                Icons.lock_outline,
                              )
                            else
                              _buildStatusBadge(
                                'Complete previous day',
                                AppTheme.textSecondary,
                                Icons.lock_outline,
                              ),
                            // 🆕 Add notification hint
                            if (!isUnlocked && dayNumber > 1) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    Icons.notifications_outlined,
                                    size: 12,
                                    color: AppTheme.textSecondary.withOpacity(0.7),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'You\'ll be notified when unlocked',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: AppTheme.textSecondary.withOpacity(0.7),
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                    ],
                  ),
                ),

                // Arrow icon or info icon
                Icon(
                  isUnlocked ? Icons.arrow_forward_ios : Icons.info_outline,
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

  // 🆕 Show detailed info when tapping locked day
  void _showLockedDayDialog(Map<String, dynamic> day, int? hoursUntilUnlock) {
    final dayNumber = day['dayNumber'] as int? ?? 1;
    final title = day['title'] as String? ?? 'Day $dayNumber';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.lock_clock, color: AppTheme.gold, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Day $dayNumber Locked',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Lock reason
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.beige.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.gold.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline, size: 18, color: AppTheme.gold),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Why is this locked?',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (dayNumber == 1)
                    const Text(
                      'Please enroll in this class to start watching videos.',
                      style: TextStyle(fontSize: 13),
                    )
                  else if (hoursUntilUnlock != null && hoursUntilUnlock > 0)
                    Text(
                      'This day will unlock ${_formatUnlockTime(hoursUntilUnlock * 60)} after completing Day ${dayNumber - 1}.',
                      style: const TextStyle(fontSize: 13),
                    )
                  else
                    Text(
                      'Complete Day ${dayNumber - 1} to unlock this day.',
                      style: const TextStyle(fontSize: 13),
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Notification info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.notifications_active, size: 20, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'You\'ll receive a push notification when this day unlocks!',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue.shade900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            if (hoursUntilUnlock != null && hoursUntilUnlock > 0) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 18, color: AppTheme.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Unlocks in: ${_formatUnlockTime(hoursUntilUnlock * 60)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkBrown,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
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
  
  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);
      
      if (diff.inDays == 0) {
        return 'Today';
      } else if (diff.inDays == 1) {
        return 'Yesterday';
      } else if (diff.inDays < 7) {
        return '${diff.inDays} days ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return '';
    }
  }
  
  String _formatWatchTime(int seconds) {
    if (seconds < 60) {
      return '${seconds}s';
    } else if (seconds < 3600) {
      final minutes = seconds ~/ 60;
      return '${minutes}m';
    } else {
      final hours = seconds ~/ 3600;
      final minutes = (seconds % 3600) ~/ 60;
      return '${hours}h ${minutes}m';
    }
  }
}
