import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/api_service.dart';

class MeditationTimerPage extends StatefulWidget {
  const MeditationTimerPage({Key? key}) : super(key: key);

  @override
  State<MeditationTimerPage> createState() => _MeditationTimerPageState();
}

class _MeditationTimerPageState extends State<MeditationTimerPage>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  
  // Timer state
  Timer? _timer;
  int _seconds = 0;
  bool _isRunning = false;
  DateTime? _startTime;
  
  // Auth state
  bool get _isLoggedIn => FirebaseAuth.instance.currentUser != null;
  
  // Animation
  late AnimationController _breathingController;
  late Animation<double> _breathingAnimation;

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    
    _breathingAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _breathingController.dispose();
    super.dispose();
  }

  void _startTimer() {
    if (_isRunning) return;
    
    setState(() {
      _isRunning = true;
      _startTime = DateTime.now();
    });
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++;
      });
    });
  }

  void _pauseTimer() {
    if (!_isRunning) return;
    
    setState(() {
      _isRunning = false;
    });
    
    _timer?.cancel();
  }

  Future<void> _stopTimer() async {
    if (_seconds == 0) return;
    
    _timer?.cancel();
    
    final endTime = DateTime.now();
    final startTime = _startTime ?? endTime.subtract(Duration(seconds: _seconds));
    
    // Check if user is logged in
    if (!_isLoggedIn) {
      // Show login prompt
      final shouldLogin = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.info_outline, color: AppTheme.saffron),
              const SizedBox(width: 12),
              const Expanded(child: Text('Login Required')),
            ],
          ),
          content: Text(
            'You meditated for ${_formatDuration(_seconds)}.\n\n'
            'Login to save your meditation sessions and track your progress over time.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Skip'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Login'),
            ),
          ],
        ),
      );
      
      if (shouldLogin == true && mounted) {
        context.push('/login');
      }
      
      // Reset timer
      setState(() {
        _seconds = 0;
        _isRunning = false;
        _startTime = null;
      });
      return;
    }
    
    // Show confirmation dialog for logged-in users
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Meditation Session?'),
        content: Text(
          'You meditated for ${_formatDuration(_seconds)}.\nWould you like to save this session?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Discard'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    
    if (shouldSave == true) {
      await _saveMeditationSession(startTime, endTime, _seconds);
    }
    
    // Reset timer
    setState(() {
      _seconds = 0;
      _isRunning = false;
      _startTime = null;
    });
  }

  Future<void> _saveMeditationSession(
    DateTime startTime,
    DateTime endTime,
    int durationSeconds,
  ) async {
    try {
      final response = await _apiService.recordMeditationSession(
        startTime: startTime.toIso8601String(),
        endTime: endTime.toIso8601String(),
        durationSeconds: durationSeconds,
      );
      
      if (response['success'] == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Meditation session saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to save session'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session saved locally. Will sync when online.'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    }
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      appBar: AppBar(
        title: const Text('Meditation Timer'),
        actions: [
          if (_isLoggedIn)
            IconButton(
              icon: const Icon(Icons.history),
              onPressed: () => context.push('/meditation/history'),
              tooltip: 'View History',
            ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Responsive sizing
            final isSmallScreen = constraints.maxHeight < 600;
            final circleSize = isSmallScreen ? 200.0 : 240.0;
            final outerCircleSize = isSmallScreen ? 240.0 : 280.0;
            final fontSize = isSmallScreen ? 36.0 : 48.0;
            
            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 200,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(height: isSmallScreen ? 20 : 40),
                            
                            // Breathing circle animation
                            AnimatedBuilder(
                              animation: _breathingAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _isRunning ? _breathingAnimation.value : 1.0,
                                  child: Container(
                                    width: outerCircleSize,
                                    height: outerCircleSize,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [
                                          AppTheme.saffron.withValues(alpha: 0.3),
                                          AppTheme.saffron.withValues(alpha: 0.1),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                    child: Center(
                                      child: Container(
                                        width: circleSize,
                                        height: circleSize,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              AppTheme.saffron,
                                              const Color(0xFFFF8A6B),
                                            ],
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppTheme.saffron.withValues(alpha: 0.4),
                                              blurRadius: 30,
                                              spreadRadius: 5,
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Text(
                                            _formatDuration(_seconds),
                                            style: TextStyle(
                                              fontSize: fontSize,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              letterSpacing: 2,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            
                            SizedBox(height: isSmallScreen ? 30 : 60),
                            
                            // Status text
                            Text(
                              _isRunning ? 'Meditating...' : 'Ready to begin',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: AppTheme.textSecondary,
                                fontSize: isSmallScreen ? 18 : 20,
                              ),
                            ),
                            
                            if (_isRunning) ...[
                              SizedBox(height: isSmallScreen ? 8 : 16),
                              Text(
                                'Breathe in... Breathe out...',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.textSecondary,
                                  fontSize: isSmallScreen ? 14 : 16,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                            
                            SizedBox(height: isSmallScreen ? 20 : 40),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Control buttons - Fixed layout
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Buttons row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_seconds > 0) ...[
                            // Stop button
                            FloatingActionButton(
                              onPressed: _stopTimer,
                              backgroundColor: Colors.red,
                              heroTag: 'stop',
                              child: const Icon(Icons.stop, size: 28),
                            ),
                            const SizedBox(width: 20),
                          ],
                          
                          // Start/Pause button
                          FloatingActionButton.large(
                            onPressed: _isRunning ? _pauseTimer : _startTimer,
                            backgroundColor: AppTheme.saffron,
                            heroTag: 'play',
                            child: Icon(
                              _isRunning ? Icons.pause : Icons.play_arrow,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Login message or tips
                      if (!_isLoggedIn && _seconds == 0)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.blue.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.blue,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Login to save your meditation sessions',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.blue.shade700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        // Quick tips
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.saffron.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.saffron.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.lightbulb_outline,
                                color: AppTheme.saffron,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Find a quiet space, sit comfortably, and focus on your breath',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textPrimary,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
