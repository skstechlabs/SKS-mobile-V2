import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/auth_guard.dart';

class LearningsPage extends StatelessWidget {
  const LearningsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AuthGuard(
      featureName: 'Classes',
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Learnings',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Your path to spiritual evolution',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            SizedBox(height: 24),
            
            // Online Courses Section
            _buildSectionHeader('Online Courses', Icons.video_library),
            SizedBox(height: 16),
            _buildLevelCard(
              context,
              level: 'Level 1',
              title: 'Brahmarandhra Opening',
              icon: Icons.looks_one,
              color: AppTheme.saffron,
            ),
            _buildLevelCard(
              context,
              level: 'Level 2',
              title: 'Sushumna Nadi Activation',
              icon: Icons.looks_two,
              color: AppTheme.gold,
            ),
            // _buildLevelCard(
            //   context,
            //   level: 'Entrance',
            //   title: 'Meditation Test',
            //   icon: Icons.assignment,
            //   color: AppTheme.saffron,
            // ),
            _buildDayTile(context, 'Meditation test'),
            _buildLevelCard(
              context,
              level: 'Level 3',
              title: 'Chakra Activation',
              icon: Icons.looks_3,
              color: AppTheme.gold,
            ),
            _buildLevelCard(
              context,
              level: 'Level 4',
              title: 'Kundalini Activation',
              icon: Icons.looks_4,
              color: AppTheme.saffron,
            ),
            
            SizedBox(height: 32),
            
            // Residential Courses Section
            _buildSectionHeader('Residential Courses', Icons.home),
            SizedBox(height: 8),
            Text(
              'In-person with Guruji. Available after completing Online Courses.',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
            SizedBox(height: 16),
            _buildResidentialCard(
              context,
              level: 'Level 5',
              description: 'Advanced practice with Guruji',
            ),
            _buildResidentialCard(
              context,
              level: 'Level 5.1',
              description: 'Master level intensive',
            ),
            
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: AppTheme.saffronGradient,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
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
    required String level,
    required String title,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          title: Text(
            level,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          subtitle: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textPrimary,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  _buildDayTile(context, 'Day 1'),
                  _buildDayTile(context, 'Day 2'),
                  _buildDayTile(context, 'Day 3'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDayTile(BuildContext context, String day) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        tileColor: AppTheme.beige.withValues(alpha: 0.3),
        leading: Icon(
          Icons.play_circle_outline,
          color: AppTheme.saffron,
          size: 28,
        ),
        title: Text(
          day,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppTheme.darkBrown,
          ),
        ),
        trailing: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.gold.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Coming Soon',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.gold,
            ),
          ),
        ),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$day video coming soon!'),
              duration: Duration(seconds: 2),
              backgroundColor: AppTheme.saffron,
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildResidentialCard(
    BuildContext context, {
    required String level,
    required String description,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(20),
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
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: AppTheme.saffronGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.school,
              color: Colors.white,
              size: 28,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  level,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.saffron,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.event_available,
                      size: 16,
                      color: AppTheme.gold,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Apply via event notification',
                      style: TextStyle(
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
