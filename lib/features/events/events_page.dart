import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shimmer_loading.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({Key? key}) : super(key: key);

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildFilterChips(),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: AppConstants.upcomingEvents.length,
            itemBuilder: (context, index) {
              return _buildEventCard(AppConstants.upcomingEvents[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    final filters = ['All', 'Upcoming', 'This Month', 'Past'];
    return Container(
      height: 60,
      padding: EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedFilter = filter);
              },
              backgroundColor: AppTheme.white,
              selectedColor: AppTheme.saffron,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppTheme.darkBrown,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              CachedNetworkImage(
                imageUrl: event['imageUrl']!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => ShimmerLoading(
                  width: double.infinity,
                  height: 200,
                  borderRadius: BorderRadius.zero,
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.saffron,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Upcoming',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event['title']!,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 18, color: AppTheme.saffron),
                    SizedBox(width: 8),
                    Text(
                      _formatDate(event['date']!),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 18, color: AppTheme.saffron),
                    SizedBox(width: 8),
                    Text(
                      event['location']!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  event['description']!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.darkBrown.withOpacity(0.7),
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: Icon(Icons.app_registration),
                        label: Text('Register'),
                      ),
                    ),
                    SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppTheme.saffron),
                        foregroundColor: AppTheme.saffron,
                      ),
                      child: Text('Details'),
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

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('EEEE, MMM d, yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }
}
