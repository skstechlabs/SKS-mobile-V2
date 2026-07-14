import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../../features/auth/auth_state.dart';

/// Wraps a widget that requires login.
/// - Not logged in → shows login prompt
/// - Logged in but blocked → shows blocked screen (cannot access classes)
/// - Logged in and not blocked → shows the child
///
/// On every mount it silently refreshes the block status from the server
/// so that admin block/unblock takes effect immediately without sign-out.
class AuthGuard extends StatefulWidget {
  final Widget child;
  final String featureName;

  const AuthGuard({
    super.key,
    required this.child,
    this.featureName = 'this feature',
  });

  @override
  State<AuthGuard> createState() => _AuthGuardState();
}

class _AuthGuardState extends State<AuthGuard> {
  final AuthState _authState = AuthState();

  @override
  void initState() {
    super.initState();
    _authState.addListener(_onAuthChanged);
    // Refresh block status every time this guard mounts (i.e. every time
    // the user navigates to a guarded screen like Classes).
    // Fire and forget — do NOT await so the screen renders immediately.
    _refreshBlockStatus();
  }

  @override
  void dispose() {
    _authState.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _refreshBlockStatus() async {
    if (_authState.isAuthenticated) {
      await _authState.refreshBlockStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_authState.isAuthenticated) {
      return _buildLoginPrompt(context);
    }

    if (_authState.isBlocked) {
      return _buildBlockedScreen(context, _authState.user?.blockReason);
    }

    return widget.child;
  }

  // ── Not logged in ──────────────────────────────────────────────────────────
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
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primary.withValues(alpha: 0.1),
                  ),
                  child: const Icon(Icons.lock_outline, size: 60, color: AppTheme.primary),
                ),
                const SizedBox(height: 32),
                Text(
                  'Login Required',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Please login to access ${widget.featureName}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textSecondary,
                        height: 1.5,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => context.go('/login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text(
                      'Login Now',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.go('/'),
                  child: const Text('Go Back to Home'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Blocked ────────────────────────────────────────────────────────────────
  Widget _buildBlockedScreen(BuildContext context, String? reason) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red.withValues(alpha: 0.1),
                  ),
                  child: const Icon(Icons.block, size: 60, color: Colors.red),
                ),
                const SizedBox(height: 32),
                Text(
                  'Access Restricted',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Your account has been restricted from accessing classes and course content.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textSecondary,
                        height: 1.5,
                      ),
                  textAlign: TextAlign.center,
                ),
                if (reason != null && reason.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline, color: Colors.red, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            reason,
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                Text(
                  'Please contact support if you believe this is a mistake.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => context.go('/'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text(
                      'Go to Home',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
