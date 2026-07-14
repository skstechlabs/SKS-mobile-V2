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
  bool _hasLoadedOnce = false;

  @override
  void initState() {
    super.initState();
    // Load events on init
    _loadEvents(forceRefresh: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload events when page becomes visible (but not on first load)
    if (_hasLoadedOnce && mounted) {
      _loadEvents(forceRefresh: true);
    }
    _hasLoadedOnce = true;
  }

  Future<void> _loadEvents({bool forceRefresh = false}) async {
    if (!mounted) return;
    
    // Only show loading on initial load, not on refresh
    if (!forceRefresh) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final response = await _apiService.getEvents(forceRefresh: forceRefresh);
      
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
      _loadEvents(forceRefresh: true); // Force refresh after registration
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
      color: AppTheme.primary,
      onRefresh: () => _loadEvents(forceRefresh: true),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Events',
                style: TextStyle(
                  fontSize: 26, fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                context.tr('join_spiritual_gatherings'),
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 20),
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
    final isRegistered = event['isRegistered'] as bool? ?? false;

    // Parse date for the "DD / Mon" badge from the design
    String? dayStr, monthStr;
    if (eventDate != null) {
      try {
        final parts = eventDate.split(' ');
        if (parts.length >= 2) {
          dayStr = parts[0].replaceAll(',', '');
          monthStr = parts[1].substring(0, 3);
        }
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [AppTheme.cardShadow],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Date badge (design: number + month stacked) ──────────────
          if (dayStr != null)
            Container(
              width: 58,
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.tagBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.tagBorder),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    dayStr,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    monthStr ?? '',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              width: 58,
              height: 70,
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.event, color: Colors.white, size: 28),
            ),

          // ── Content ──────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 14, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                      height: 1.3,
                    ),
                  ),
                  if (description != null && description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  if (eventTime != null)
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded,
                            size: 13, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          eventTime,
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textSecondary),
                        ),
                        if (location != null && location.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.location_on_outlined,
                              size: 13, color: AppTheme.textSecondary),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              location,
                              style: const TextStyle(
                                  fontSize: 12, color: AppTheme.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: isRegistered
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Colors.green.shade200),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle,
                                    size: 14,
                                    color: Colors.green.shade600),
                                const SizedBox(width: 4),
                                Text(
                                  context.tr('already_registered'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : GestureDetector(
                            onTap: () => _registerForEvent(eventId),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 7),
                              decoration: BoxDecoration(
                                gradient: AppTheme.primaryGradient,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primary
                                        .withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Text(
                                context.tr('register_now'),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
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
}
