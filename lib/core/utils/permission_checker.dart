import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';
import '../widgets/sks_loader.dart';


class PermissionChecker extends StatefulWidget {
  const PermissionChecker({Key? key}) : super(key: key);

  @override
  State<PermissionChecker> createState() => _PermissionCheckerState();
}

class _PermissionCheckerState extends State<PermissionChecker> {
  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    bool hasAllPermissions = false;

    if (kIsWeb) {
      // For web, check basic permissions status without requesting
      final cameraStatus = await Permission.camera.status;
      final micStatus = await Permission.microphone.status;
      final notificationStatus = await Permission.notification.status;
      
      // If at least one major permission is granted, consider permissions sufficient
      hasAllPermissions = cameraStatus.isGranted || micStatus.isGranted || notificationStatus.isGranted;
    } else {
      // For mobile, check all required permissions status without requesting
      final permissions = [
        Permission.camera,
        Permission.microphone,
        Permission.storage,
        Permission.photos,
        Permission.notification,
        Permission.location,
      ];

      // Check current status of all permissions
      final statuses = await Future.wait(
        permissions.map((permission) => permission.status),
      );
      
      // Check if at least half of the permissions are granted
      int grantedCount = statuses.where((status) => status.isGranted).length;
      hasAllPermissions = grantedCount >= (permissions.length / 2).ceil();
    }

    if (mounted) {
      if (hasAllPermissions) {
        context.go('/');
      } else {
        // Show permission screen
        context.go('/permission-screen');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.orange.shade50,
              Colors.amber.shade50,
            ],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SKSLoader(size: 80),
              SizedBox(height: 24),
              Text(
                'Checking permissions...',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}