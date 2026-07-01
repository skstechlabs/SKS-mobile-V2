import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/api_service.dart';

class ReminderFormScreen extends StatefulWidget {
  final int? reminderId;

  const ReminderFormScreen({super.key, this.reminderId});

  @override
  State<ReminderFormScreen> createState() => _ReminderFormScreenState();
}

class _ReminderFormScreenState extends State<ReminderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  
  TimeOfDay _selectedTime = const TimeOfDay(hour: 6, minute: 0);
  final List<bool> _selectedDays = List.filled(7, false);
  bool _isLoading = false;
  bool _isSaving = false;

  final List<String> _dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  @override
  void initState() {
    super.initState();
    if (widget.reminderId != null) {
      _loadReminder();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadReminder() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final response = await _apiService.getReminders();
      
      if (response['success'] == true && mounted) {
        final reminders = List<Map<String, dynamic>>.from(response['reminders'] ?? []);
        final reminder = reminders.firstWhere(
          (r) => r['id'] == widget.reminderId,
          orElse: () => {},
        );
        
        if (reminder.isNotEmpty) {
          _titleController.text = reminder['title'] as String;
          _messageController.text = (reminder['message'] as String?) ?? '';
          
          final timeStr = reminder['reminderTime'] as String;
          final parts = timeStr.split(':');
          _selectedTime = TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          );
          
          final days = List<int>.from(reminder['daysOfWeek'] as List);
          for (var day in days) {
            _selectedDays[day] = true;
          }
        }
        
        setState(() => _isLoading = false);
      } else if (mounted) {
        setState(() => _isLoading = false);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Failed to load reminder'),
              backgroundColor: Colors.red,
            ),
          );
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Network error. Please check your connection.'),
            backgroundColor: Colors.red,
          ),
        );
        context.pop();
      }
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    
    if (time != null) {
      setState(() => _selectedTime = time);
    }
  }

  String _formatTime(TimeOfDay time) {
    // Backend requires strict HH:MM format (two digits each, 24-hour)
    // e.g. "06:00", "14:30" — NOT "6:00" or "6:00 AM"
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _saveReminder() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (!_selectedDays.contains(true)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one day'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isSaving = true);

    try {
      final selectedDayIndices = <int>[];
      for (var i = 0; i < _selectedDays.length; i++) {
        if (_selectedDays[i]) selectedDayIndices.add(i);
      }

      final response = widget.reminderId == null
          ? await _apiService.createReminder(
              title: _titleController.text.trim(),
              message: _messageController.text.trim().isEmpty 
                  ? null 
                  : _messageController.text.trim(),
              reminderTime: _formatTime(_selectedTime),
              daysOfWeek: selectedDayIndices,
            )
          : await _apiService.updateReminder(
              id: widget.reminderId!,
              title: _titleController.text.trim(),
              message: _messageController.text.trim().isEmpty 
                  ? null 
                  : _messageController.text.trim(),
              reminderTime: _formatTime(_selectedTime),
              daysOfWeek: selectedDayIndices,
            );

      if (mounted) setState(() => _isSaving = false);

      if (response['success'] == true && mounted) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.reminderId == null 
                  ? 'Reminder created successfully' 
                  : 'Reminder updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          context.pop(true); // Return true to indicate success
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to save reminder'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Network error. Please check your connection.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(widget.reminderId == null ? 'Add Reminder' : 'Edit Reminder'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        hintText: 'e.g., Morning Meditation',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a title';
                        }
                        if (value.trim().length < 3) {
                          return 'Title must be at least 3 characters';
                        }
                        if (value.trim().length > 200) {
                          return 'Title must be less than 200 characters';
                        }
                        return null;
                      },
                      maxLength: 200,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        labelText: 'Message (Optional)',
                        hintText: 'e.g., Time for your daily meditation',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      maxLength: 500,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Time',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _isSaving ? null : _selectTime,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: _isSaving ? Colors.grey : Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(4),
                          color: _isSaving ? Colors.grey.shade100 : null,
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.access_time, color: _isSaving ? Colors.grey : null),
                            const SizedBox(width: 16),
                            Text(
                              _selectedTime.format(context),
                              style: TextStyle(
                                fontSize: 16,
                                color: _isSaving ? Colors.grey : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Repeat on',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: List.generate(7, (index) {
                        return FilterChip(
                          label: Text(_dayNames[index]),
                          selected: _selectedDays[index],
                          onSelected: _isSaving ? null : (selected) {
                            setState(() => _selectedDays[index] = selected);
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveReminder,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(widget.reminderId == null ? 'Create Reminder' : 'Update Reminder'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
