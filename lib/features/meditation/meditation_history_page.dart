import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/api_service.dart';

class MeditationHistoryPage extends StatefulWidget {
  const MeditationHistoryPage({Key? key}) : super(key: key);

  @override
  State<MeditationHistoryPage> createState() => _MeditationHistoryPageState();
}

class _MeditationHistoryPageState extends State<MeditationHistoryPage> {
  final ApiService _apiService = ApiService();
  
  bool _isLoadingSessions = true;
  bool _isLoadingStats = true;
  bool _isLoadingStreak = true;
  
  List<Map<String, dynamic>> _sessions = [];
  Map<String, dynamic>? _stats;
  Map<String, dynamic>? _streak;
  
  String _selectedPeriod = 'week';
  
  bool get _isLoggedIn => FirebaseAuth.instance.currentUser != null;

  @override
  void initState() {
    super.initState();
    if (_isLoggedIn) {
      _loadData();
    } else {
      setState(() {
        _isLoadingSessions = false;
        _isLoadingStats = false;
        _isLoadingStreak = false;
      });
    }
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadSessions(),
      _loadStats(),
      _loadStreak(),
    ]);
  }

  Future<void> _loadSessions() async {
    setState(() => _isLoadingSessions = true);
    
    try {
      final response = await _apiService.getMeditationSessions(limit: 20);
      
      if (response['success'] == true && mounted) {
        setState(() {
          _sessions = List<Map<String, dynamic>>.from(response['sessions'] ?? []);
          _isLoadingSessions = false;
        });
      } else if (mounted) {
        setState(() {
          _sessions = [];
          _isLoadingSessions = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _sessions = [];
          _isLoadingSessions = false;
        });
      }
    }
  }

  Future<void> _loadStats() async {
    setState(() => _isLoadingStats = true);
    
    try {
      final response = await _apiService.getMeditationStats(period: _selectedPeriod);
      
      if (response['success'] == true && mounted) {
        setState(() {
          _stats = response['summary'] as Map<String, dynamic>?;
          _isLoadingStats = false;
        });
      } else if (mounted) {
        setState(() {
          _stats = null;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _stats = null;
          _isLoadingStats = false;
        });
      }
    }
  }

  Future<void> _loadStreak() async {
    setState(() => _isLoadingStreak = true);
    
    try {
      final response = await _apiService.getMeditationStreak();
      
      if (response['success'] == true && mounted) {
        setState(() {
          _streak = response;
          _isLoadingStreak = false;
        });
      } else if (mounted) {
        setState(() {
          _streak = null;
          _isLoadingStreak = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _streak = null;
          _isLoadingStreak = false;
        });
      }
    }
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    // Show login prompt if not logged in
    if (!_isLoggedIn) {
      return Scaffold(
        backgroundColor: AppTheme.white,
        appBar: AppBar(
          title: const Text('Meditation History'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.saffron.withValues(alpha: 0.2),
                        AppTheme.saffron.withValues(alpha: 0.1),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_outline,
                    size: 60,
                    color: AppTheme.saffron,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Login Required',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Login to view your meditation history, track your progress, and see your streaks.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () => context.push('/login'),
                  icon: const Icon(Icons.login),
                  label: const Text('Login Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.saffron,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: AppTheme.white,
      appBar: AppBar(
        title: const Text('Meditation History'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Streak cards
              _buildStreakSection(),
              
              const SizedBox(height: 24),
              
              // Period selector
              _buildPeriodSelector(),
              
              const SizedBox(height: 16),
              
              // Statistics cards
              _buildStatsSection(),
              
              const SizedBox(height: 24),
              
              // Recent sessions
              _buildSessionsSection(),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStreakSection() {
    if (_isLoadingStreak) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    
    final currentStreak = _streak?['current_streak'] ?? 0;
    final longestStreak = _streak?['longest_streak'] ?? 0;
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: _buildStreakCard(
              'Current Streak',
              currentStreak,
              Icons.local_fire_department,
              Colors.orange,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStreakCard(
              'Longest Streak',
              longestStreak,
              Icons.emoji_events,
              Colors.amber,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCard(String title, int days, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.1),
            color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            '$days',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Text(
            'Statistics',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          DropdownButton<String>(
            value: _selectedPeriod,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: 'day', child: Text('Today')),
              DropdownMenuItem(value: 'week', child: Text('Week')),
              DropdownMenuItem(value: 'month', child: Text('Month')),
              DropdownMenuItem(value: 'year', child: Text('Year')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedPeriod = value);
                _loadStats();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    if (_isLoadingStats) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    
    final totalDuration = _stats?['total_duration_seconds'] ?? 0;
    final totalSessions = _stats?['total_sessions'] ?? 0;
    final longestSession = _stats?['longest_session_seconds'] ?? 0;
    final avgDuration = _stats?['avg_daily_duration_seconds'] ?? 0;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Time',
                  _formatDuration(totalDuration),
                  Icons.timer_outlined,
                  AppTheme.saffron,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Sessions',
                  '$totalSessions',
                  Icons.self_improvement,
                  Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Longest',
                  _formatDuration(longestSession),
                  Icons.trending_up,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Daily Avg',
                  _formatDuration(avgDuration),
                  Icons.analytics_outlined,
                  Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.softGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Recent Sessions',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        if (_isLoadingSessions)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_sessions.isEmpty)
          Padding(
            padding: const EdgeInsets.all(40),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.self_improvement,
                    size: 64,
                    color: AppTheme.textSecondary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No meditation sessions yet',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start your first session to track your progress',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _sessions.length,
            itemBuilder: (context, index) {
              final session = _sessions[index];
              return _buildSessionCard(session);
            },
          ),
      ],
    );
  }

  Widget _buildSessionCard(Map<String, dynamic> session) {
    final durationSeconds = session['duration_seconds'] as int? ?? 0;
    final startTime = session['start_time'] as String?;
    final sessionDate = session['session_date'] as String?;
    
    DateTime? dateTime;
    if (startTime != null) {
      try {
        dateTime = DateTime.parse(startTime);
      } catch (e) {
        // Ignore parse error
      }
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.softGray),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.saffron,
                  AppTheme.saffron.withValues(alpha: 0.7),
                ],
              ),
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
                  _formatDuration(durationSeconds),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dateTime != null
                      ? DateFormat('MMM dd, yyyy • hh:mm a').format(dateTime)
                      : sessionDate ?? 'Unknown date',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 24,
          ),
        ],
      ),
    );
  }
}
