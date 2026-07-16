import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/api_service.dart';
import '../../core/services/onesignal_service.dart';
import '../../core/services/localization_service.dart';
import '../../core/widgets/cached_image.dart';
import '../auth/auth_service.dart';
import '../auth/auth_state.dart';
import '../auth/user_model.dart';
import '../../core/widgets/login_gate.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final AuthState _authState = AuthState();
  final ApiService _apiService = ApiService();
  final OneSignalService _oneSignal = OneSignalService();

  bool _isLoading = false;
  UserModel? _user;
  Map<String, dynamic> _meditationStats = {};

  // ── Safe int parser — handles String, int, double from MSSQL BIGINT ────────
  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadMeditationStats();
    // Rebuild whenever the language changes
    LocalizationService().addListener(_onLocaleChanged);
  }

  @override
  void dispose() {
    LocalizationService().removeListener(_onLocaleChanged);
    super.dispose();
  }

  void _onLocaleChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadProfile() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final result = await _apiService.getProfile();
      if (result['success'] == true && result['user'] != null) {
        final user = UserModel.fromJson(result['user']);
        setState(() => _user = user);
        await _authState.setUser(user);
      } else {
        setState(() => _user = _authState.user);
      }
    } catch (e) {
      setState(() => _user = _authState.user);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMeditationStats() async {
    try {
      final result = await _apiService.getMeditationStats(period: 'all');
      if (result['success'] == true && mounted) {
        final lifetime = result['lifetime'] as Map<String, dynamic>? ?? {};
        final streak   = result['streak']   as Map<String, dynamic>? ?? {};
        setState(() => _meditationStats = {
          'currentStreak':        _parseInt(streak['current'] ?? result['current_streak']),
          'totalDurationSeconds': _parseInt(lifetime['total_duration_seconds']
              ?? result['summary']?['total_duration_seconds']),
          'totalSessions':        _parseInt(lifetime['total_sessions']
              ?? result['summary']?['total_sessions']),
          'totalDays':            _parseInt(lifetime['total_meditation_days']),
        });
      }
    } catch (_) {}
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppTheme.cardSurface,
        title: Text(
          context.tr('logout'),
          style: const TextStyle(
              color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: Text(
          context.tr('logout_confirmation'),
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              context.tr('cancel'),
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              context.tr('logout'),
              style: const TextStyle(
                  color: Colors.red, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await _apiService.logout();
      await _oneSignal.removeExternalUserId();
      await _authService.signOut();
      await _authState.logout();
      if (mounted) context.go('/login');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('logout_failed'))),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Not logged in — return the shared gate directly
    if (!_isLoading && _user == null) {
      return LoginGate(
        title: context.tr('profile'),
        featureHint: '👤 View and edit your profile & spiritual progress',
        showBackButton: true,
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        backgroundColor: AppTheme.cream,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: AppTheme.textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          context.tr('profile'),
          style: const TextStyle(
            color: AppTheme.primary,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary))
          : _buildContent(),
    );
  }

  // ── Main profile content ──────────────────────────────────────────────────
  Widget _buildContent() {
    final user = _user!;
    final displayName = user.name.isNotEmpty ? user.name : 'Sadhak';

    final streakDays   = _parseInt(_meditationStats['currentStreak']);
    final totalMinutes = _parseInt(_meditationStats['totalDurationSeconds']) ~/ 60;
    final hours = totalMinutes ~/ 60;
    final mins  = totalMinutes % 60;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: 8),

          // ── Avatar ──────────────────────────────────────────────────
          Center(
            child: Stack(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.tagBg,
                    border: Border.all(
                        color: AppTheme.tagBorder, width: 2.5),
                  ),
                  child: ClipOval(
                    child: user.photo.isNotEmpty
                        ? CachedImage(
                            imageUrl: user.photo,
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: AppTheme.tagBg,
                            child: const Icon(Icons.person_rounded,
                                size: 60, color: AppTheme.primary),
                          ),
                  ),
                ),
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: GestureDetector(
                    onTap: () => context.push('/edit-profile'),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppTheme.cardSurface,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppTheme.tagBorder, width: 1.5),
                        boxShadow: [AppTheme.softShadow],
                      ),
                      child: const Icon(Icons.edit_rounded,
                          size: 15, color: AppTheme.primary),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Name + subtitle ─────────────────────────────────────────
          Text(
            displayName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.tr('seeker_of_truth'),
            style: const TextStyle(
                fontSize: 14, color: AppTheme.textSecondary),
          ),

          const SizedBox(height: 24),

          // ── Stats row ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: '🔥',
                    iconBg: const Color(0xFFFFF3E0),
                    label: context.tr('sadhana_streak'),
                    value: '$streakDays ${context.tr('days')}',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: '⏱',
                    iconBg: const Color(0xFFE0F2F1),
                    label: context.tr('meditation_time'),
                    value: '${hours}h ${mins}m',
                    valueColor: const Color(0xFF00897B),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Menu items ──────────────────────────────────────────────
          _buildMenuSection([
            _MenuItem(
              icon: Icons.route_outlined,
              label: context.tr('my_journey'),
              subtitle: context.tr('track_your_progress'),
              onTap: () => context.push('/meditation/history'),
            ),
          ]),

          const SizedBox(height: 12),

          _buildMenuSection([
            _MenuItem(
              icon: Icons.edit_outlined,
              label: context.tr('edit_profile'),
              subtitle: context.tr('update_your_information'),
              onTap: () => context.push('/edit-profile'),
            ),
            _MenuItem(
              icon: Icons.language_outlined,
              label: context.tr('change_language'),
              subtitle: context.tr('app_language_preferences'),
              onTap: () => context.push('/settings/language'),
            ),
            _MenuItem(
              icon: Icons.help_outline_rounded,
              label: context.tr('help_support'),
              subtitle: context.tr('contact_guruji_team'),
              onTap: () => context.push('/guruji-connect'),
            ),
          ]),

          const SizedBox(height: 12),

          // ── Logout ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              onTap: _handleLogout,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  color: AppTheme.cardSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: Colors.red.withValues(alpha: 0.2)),
                  boxShadow: [AppTheme.softShadow],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.logout_rounded,
                        color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      context.tr('logout'),
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildMenuSection(List<_MenuItem> items) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [AppTheme.softShadow],
      ),
      child: Column(
        children: items.asMap().entries.map((e) {
          final i = e.key;
          final item = e.value;
          return Column(
            children: [
              _buildMenuItem(item),
              if (i < items.length - 1)
                Divider(
                  height: 1,
                  indent: 58,
                  color: AppTheme.softGray.withValues(alpha: 0.6),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMenuItem(_MenuItem item) {
    return GestureDetector(
      onTap: item.onTap,
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppTheme.tagBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(item.icon,
                  size: 20, color: AppTheme.textPrimary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  if (item.subtitle != null)
                    Text(
                      item.subtitle!,
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppTheme.textSecondary, size: 18),
          ],
        ),
      ),
    );
  }
}

// ── Stat card widget ──────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String icon;
  final Color iconBg;
  final String label;
  final String value;
  final Color? valueColor;

  const _StatCard({
    required this.icon,
    required this.iconBg,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [AppTheme.softShadow],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(icon,
                  style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.textSecondary),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: valueColor ?? AppTheme.textPrimary,
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

// ── Menu item data class ──────────────────────────────────────────────────────
class _MenuItem {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  const _MenuItem({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.onTap,
  });
}
