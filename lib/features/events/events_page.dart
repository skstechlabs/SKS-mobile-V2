import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../core/services/localization_service.dart';
import '../../core/theme/app_theme.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  final _apiService = ApiService();
  List<Map<String, dynamic>> _events = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiService.getEvents();
      
      if (response['success'] == true && mounted) {
        setState(() {
          _events = List<Map<String, dynamic>>.from(response['events'] ?? []);
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() {
          _errorMessage = response['message'] ?? 'Failed to load events';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Network error. Please check your connection.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _registerForEvent(int eventId) async {
    final response = await _apiService.registerForEvent(eventId);
    
    if (response['success'] == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('successfully_registered')),
          backgroundColor: Colors.green,
        ),
      );
      _loadEvents(); // Reload to update registration status
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message'] ?? context.tr('failed_to_register')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadEvents,
              child: Text(context.tr('retry')),
            ),
          ],
        ),
      );
    }

    if (_events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              context.tr('no_upcoming_events'),
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('check_back_later'),
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadEvents,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('upcoming_events'),
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                context.tr('join_spiritual_gatherings'),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              ..._events.map((event) => _buildEventCard(event)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    final eventId = event['id'] as int;
    final title = event['title'] as String;
    final description = event['description'] as String?;
    final eventDate = event['eventDate'] as String?;
    final eventTime = event['eventTime'] as String?;
    final location = event['location'] as String?;
    final imageUrl = event['imageUrl'] as String?;
    final isRegistered = event['isRegistered'] as bool? ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl != null && imageUrl.isNotEmpty)
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                image: DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            )
          else
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                gradient: LinearGradient(
                  colors: [AppTheme.primary, AppTheme.saffron],
                ),
              ),
              child: const Center(
                child: Icon(Icons.event, size: 64, color: Colors.white),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (description != null && description.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                if (eventDate != null) ...[
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.calendar_today, size: 20, color: AppTheme.primary),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        eventDate,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                if (eventTime != null) ...[
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.access_time, size: 20, color: AppTheme.primary),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        eventTime,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                if (location != null && location.isNotEmpty) ...[
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.location_on, size: 20, color: AppTheme.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          location,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isRegistered ? null : () => _registerForEvent(eventId),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: isRegistered ? Colors.grey : AppTheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(isRegistered ? Icons.check_circle : Icons.person_add, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          isRegistered ? context.tr('already_registered') : context.tr('register_now'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
