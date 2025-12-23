import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import 'spiritual_background.dart';
import '../../features/home/home_page.dart';
import '../../features/learnings/learnings_page.dart';
import '../../features/guruji_connect/guruji_connect_page.dart';
import '../../features/events/events_page.dart';

class MainScaffold extends StatefulWidget {
  final Widget child;
  final int currentIndex;

  const MainScaffold({
    Key? key,
    required this.child,
    required this.currentIndex,
  }) : super(key: key);

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Siva Kundalini Sadhana'),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/notifications'),
          ),
        ],
      ),
      body: SpiritualBackground(child: widget.child),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: AppTheme.darkBrown.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: widget.currentIndex,
          onTap: (index) => _onItemTapped(context, index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppTheme.white,
          selectedItemColor: AppTheme.saffron,
          unselectedItemColor: AppTheme.darkBrown.withOpacity(0.6),
          selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.school_outlined),
              activeIcon: Icon(Icons.school),
              label: 'Learnings',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.connect_without_contact_outlined),
              activeIcon: Icon(Icons.connect_without_contact),
              label: 'Connect',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.event_outlined),
              activeIcon: Icon(Icons.event),
              label: 'Events',
            ),
          ],
        ),
      ),
    );
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/learnings');
        break;
      case 2:
        context.go('/guruji-connect');
        break;
      case 3:
        context.go('/events');
        break;
    }
  }
}
