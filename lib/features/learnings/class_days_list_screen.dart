import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/api_service.dart';

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
      final response = await _apiService.get(
        '/api/classes/${widget.classId}/days',
      );

      if (response['success'] == true) {
        setState(() {
          _days = List<Map<String, dynamic>>.from(response['days'] ?? []);
          _isEnrolled = _days.isNotEmpty && _days.any((d) => d['isUnlocked'] == true);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response['message'] ?? 'Failed to load days';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading days: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _enrollInClass() async {
    setState(() => _isEnrolling = true);

    try {
      final response = await _apiService.post(
        '/api/classes/${widget.classId}/enroll',
        {},
      );

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isEnrolling = false);
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
    final hoursUntilUnlock = day['hoursUntilUnlock'] as int?;
    final completionPercentage = (day['completionPercentage'] as num?)?.toDouble() ?? 0.0;

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
                  context.push(
                    '/classes/days/${day['id']}/video?title=${Uri.encodeComponent(day['title'])}&dayNumber=${day['dayNumber']}',
                  );
                }
              : null,
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
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkBrown,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (day['description'] != null)
                        Text(
                          day['description'],
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 8),

                      // Status badge
                      if (isCompleted)
                        _buildStatusBadge(
                          'Completed',
                          AppTheme.saffron,
                          Icons.check_circle,
                        )
                      else if (isUnlocked)
                        Row(
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
                          ],
                        )
                      else if (hoursUntilUnlock != null)
                        _buildStatusBadge(
                          'Unlocks in ${hoursUntilUnlock}h',
                          AppTheme.textSecondary,
                          Icons.lock_clock,
                        )
                      else
                        _buildStatusBadge(
                          'Locked',
                          AppTheme.textSecondary,
                          Icons.lock_outline,
                        ),
                    ],
                  ),
                ),

                // Arrow icon
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
}
