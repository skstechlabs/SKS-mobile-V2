import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/api_service.dart';
import '../../core/services/reminder_notification_service.dart';
import '../../core/widgets/auth_guard.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final _apiService = ApiService();
  final _notificationService = ReminderNotificationService();
  List<Map<String, dynamic>> _reminders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _loadReminders(); // Load once on init (uses cache if available)
  }

  Future<void> _initializeNotifications() async {
    await _notificationService.initialize();
    await _notificationService.requestPermissions();
  }

  Future<void> _loadReminders() async {
    if (!mounted) return;
    
    debugPrint('🔄 Loading reminders...');
    setState(() => _isLoading = true);
    
    try {
      // Use cached data, only refresh on pull-to-refresh
      final response = await _apiService.getReminders();
      
      debugPrint('📥 Reminders response: ${response['success']}, count: ${(response['reminders'] as List?)?.length ?? 0}');
      
      if (response['success'] == true && mounted) {
        final allReminders = List<Map<String, dynamic>>.from(response['reminders'] ?? []);
        
        // Filter out preset reminders (Morning and Evening Meditation) FOR DISPLAY ONLY
        // Check for both English and Telugu titles (and any other language variants)
        final filteredReminders = allReminders.where((reminder) {
          final title = (reminder['title'] as String).toLowerCase();
          // Filter out preset reminders in any language
          return title != 'morning meditation' && 
                 title != 'evening meditation' &&
                 title != 'ఉదయం ధ్యానం' && // Telugu Morning Meditation
                 title != 'సాయంత్రం ధ్యానం'; // Telugu Evening Meditation
        }).toList();
        
        debugPrint('✅ Loaded ${allReminders.length} reminders (${filteredReminders.length} shown after filtering presets)');
        
        setState(() {
          _reminders = filteredReminders;
          _isLoading = false;
        });
        
        // Reschedule ALL active reminders (including preset ones that are filtered from display)
        _scheduleActiveReminders(allReminders);
      } else if (mounted) {
        setState(() => _isLoading = false);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Failed to load reminders'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading reminders: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Network error. Please check your connection.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  /// Force refresh (called by pull-to-refresh)
  Future<void> _forceRefreshReminders() async {
    debugPrint('🔄 Force refreshing reminders...');
    
    try {
      final response = await _apiService.getReminders(forceRefresh: true);
      
      if (response['success'] == true && mounted) {
        final allReminders = List<Map<String, dynamic>>.from(response['reminders'] ?? []);
        
        // Filter out preset reminders (Morning and Evening Meditation) FOR DISPLAY ONLY
        // Check for both English and Telugu titles
        final filteredReminders = allReminders.where((reminder) {
          final title = (reminder['title'] as String).toLowerCase();
          return title != 'morning meditation' && 
                 title != 'evening meditation' &&
                 title != 'ఉదయం ధ్యానం' && // Telugu Morning Meditation
                 title != 'సాయంత్రం ధ్యానం'; // Telugu Evening Meditation
        }).toList();
        
        setState(() {
          _reminders = filteredReminders;
        });
        
        // Reschedule ALL active reminders (including preset ones)
        _scheduleActiveReminders(allReminders);
      }
    } catch (e) {
      debugPrint('❌ Error force refreshing: $e');
    }
  }

  Future<void> _scheduleActiveReminders(List<Map<String, dynamic>> reminders) async {
    try {
      for (var reminder in reminders) {
        if (reminder['isActive'] == true) {
          await _notificationService.scheduleReminder(
            id: reminder['id'] as int,
            title: reminder['title'] as String,
            message: reminder['message'] as String?,
            reminderTime: reminder['reminderTime'] as String,
            daysOfWeek: List<int>.from(reminder['daysOfWeek'] as List),
          );
        }
      }
    } catch (e) {
      // Silent fail for notification scheduling
      debugPrint('Error scheduling reminders: $e');
    }
  }

  Future<void> _toggleReminder(int id, bool currentStatus) async {
    // Show loading indicator
    if (!mounted) return;
    
    // Optimistically update UI
    setState(() {
      final index = _reminders.indexWhere((r) => r['id'] == id);
      if (index != -1) {
        _reminders[index]['isActive'] = !currentStatus;
      }
    });
    
    try {
      final response = await _apiService.toggleReminder(id);
      
      if (response['success'] == true) {
        final newStatus = !currentStatus;
        
        // Update notification scheduling
        if (newStatus) {
          // Find the reminder and schedule it
          final reminder = _reminders.firstWhere((r) => r['id'] == id);
          await _notificationService.scheduleReminder(
            id: id,
            title: reminder['title'] as String,
            message: reminder['message'] as String?,
            reminderTime: reminder['reminderTime'] as String,
            daysOfWeek: List<int>.from(reminder['daysOfWeek'] as List),
          );
        } else {
          // Cancel notifications
          await _notificationService.cancelReminder(id);
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Reminder ${newStatus ? 'enabled' : 'disabled'}'),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Revert optimistic update on failure
        if (mounted) {
          setState(() {
            final index = _reminders.indexWhere((r) => r['id'] == id);
            if (index != -1) {
              _reminders[index]['isActive'] = currentStatus;
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Failed to toggle reminder'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Revert optimistic update on error
      if (mounted) {
        setState(() {
          final index = _reminders.indexWhere((r) => r['id'] == id);
          if (index != -1) {
            _reminders[index]['isActive'] = currentStatus;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Network error. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteReminder(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reminder'),
        content: const Text('Are you sure you want to delete this reminder?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Optimistically remove from list immediately — no loading dialog needed
    final removedIndex = _reminders.indexWhere((r) => r['id'] == id);
    final removedReminder = removedIndex >= 0 ? _reminders[removedIndex] : null;
    if (removedIndex >= 0) {
      setState(() => _reminders.removeAt(removedIndex));
    }

    try {
      final response = await _apiService.deleteReminder(id);

      if (response['success'] == true) {
        // Cancel local notifications
        await _notificationService.cancelReminder(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reminder deleted'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Revert — put it back
        if (mounted && removedReminder != null) {
          setState(() {
            if (removedIndex <= _reminders.length) {
              _reminders.insert(removedIndex, removedReminder);
            } else {
              _reminders.add(removedReminder);
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Failed to delete reminder'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Revert on error
      if (mounted && removedReminder != null) {
        setState(() {
          if (removedIndex <= _reminders.length) {
            _reminders.insert(removedIndex, removedReminder);
          } else {
            _reminders.add(removedReminder);
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Network error. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDays(List<dynamic> days) {
    const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    if (days.length == 7) return 'Every day';
    return days.map((d) => dayNames[d as int]).join(', ');
  }

  /// Format time string — handles both HH:MM and HH:MM:SS from API
  String _formatTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return '';
    final parts = timeStr.split(':');
    if (parts.length >= 2) {
      final h = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 0;
      final period = h >= 12 ? 'PM' : 'AM';
      final displayH = h == 0 ? 12 : (h > 12 ? h - 12 : h);
      return '${displayH.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} $period';
    }
    return timeStr;
  }

  @override
  Widget build(BuildContext context) {
    return AuthGuard(
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          title: const Text('Reminders'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () async {
                await context.push('/reminders/add');
                _loadReminders();
              },
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _reminders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.alarm_off, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No custom reminders yet',
                          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap + to create a custom reminder',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.symmetric(horizontal: 32),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.info_outline, color: Colors.orange[700], size: 32),
                              const SizedBox(height: 8),
                              Text(
                                'Morning & Evening Meditation reminders are managed on the Home page',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.orange[900],
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _forceRefreshReminders,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _reminders.length,
                      itemBuilder: (context, index) {
                        final reminder = _reminders[index];
                        final isActive = reminder['isActive'] as bool;
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: Icon(
                              Icons.alarm,
                              color: isActive ? Colors.orange : Colors.grey,
                            ),
                            title: Text(
                              reminder['title'] as String,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isActive ? Colors.black : Colors.grey,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  '${_formatTime(reminder['reminderTime'] as String?)} • ${_formatDays(reminder['daysOfWeek'])}',
                                  style: TextStyle(
                                    color: isActive ? Colors.black87 : Colors.grey,
                                  ),
                                ),
                                if (reminder['message'] != null && (reminder['message'] as String).isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      reminder['message'] as String,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Switch(
                                  value: isActive,
                                  onChanged: (value) => _toggleReminder(
                                    reminder['id'] as int,
                                    isActive,
                                  ),
                                ),
                                PopupMenuButton(
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit, size: 20),
                                          SizedBox(width: 8),
                                          Text('Edit'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, size: 20, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('Delete', style: TextStyle(color: Colors.red)),
                                        ],
                                      ),
                                    ),
                                  ],
                                  onSelected: (value) async {
                                    if (value == 'edit') {
                                      await context.push('/reminders/edit/${reminder['id']}');
                                      _loadReminders();
                                    } else if (value == 'delete') {
                                      _deleteReminder(reminder['id'] as int);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}
