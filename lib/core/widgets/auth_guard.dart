import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../../features/auth/auth_state.dart';

class AuthGuard extends StatelessWidget {
  final Widget child;
  final String featureName;

  const AuthGuard({
    super.key,
    required this.child,
    this.featureName = 'this feature',
  });

  @override
  Widget build(BuildContext context) {
    final authState = AuthState();

    if (!authState.isAuthenticated) {
      return _buildLoginPrompt(context);
    }

    return child;
  }

  Widget _buildLoginPrompt(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Lock Icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primary.withValues(alpha: 0.1),
                  ),
                  child: Icon(
                    Icons.lock_outline,
                    size: 60,
                    color: AppTheme.primary,
                  ),
                ),

                const SizedBox(height: 32),

                // Title
                Text(
                  'Login Required',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                // Message
                Text(
                  'Please login to access $featureName',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textSecondary,
                        height: 1.5,
                      ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                // Login Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      context.go('/login');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Login Now',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Back Button
                TextButton(
                  onPressed: () {
                    context.go('/');
                  },
                  child: const Text('Go Back to Home'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
