import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/cdn_images.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/auth_guard.dart';
import '../../core/widgets/cached_image.dart';
import '../../core/widgets/offline_banner.dart';
import '../../core/services/api_service.dart';
import '../../core/services/connectivity_service.dart';
import '../../core/services/localization_service.dart';
import '../auth/auth_state.dart';

class LearningsPage extends StatefulWidget {
  const LearningsPage({super.key});
  @override
  State<LearningsPage> createState() => _LearningsPageState();
}

class _LearningsPageState extends State<LearningsPage> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _errorMessage;
  Map<int, Map<String, dynamic>> _levelAccess = {};
  Map<String, dynamic>? _meditationTest;

  // Course display data
  static final _courses = [
    _CourseInfo(1, 'brahmarandhra_opening', 'discover_power_within', CdnImages.kundalini),
    _CourseInfo(2, 'sushumna_nadi_activation', 'balance_energy_centres', CdnImages.chakras),
    _CourseInfo(3, 'chakra_activation', 'understand_cosmic_energy', CdnImages.gurujiMeditation),
    _CourseInfo(4, 'kundalini_activation', 'deepen_meditation', CdnImages.meditation),
  ];

  @override
  void initState() {
    super.initState();
    _loadLevelAccess();
  }

  Future<void> _loadLevelAccess() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final response = await _apiService.get('/api/level-progression/access');
      if (response['success'] == true) {
        final accessData = response['levelAccess'];
        final Map<int, Map<String, dynamic>> parsed = {};
        if (accessData is Map) {
          accessData.forEach((key, value) {
            try {
              final n = key is int ? key : int.parse(key.toString());
              if (value is Map) parsed[n] = Map<String, dynamic>.from(value);
            } catch (_) {}
          });
        }
        if (!mounted) return;
        setState(() {
          _levelAccess = parsed;
          _meditationTest = response['meditationTest'] as Map<String, dynamic>?;
          _isLoading = false;
        });
      } else {
        final msg = response['message'] ?? 'Failed to load classes';
        if (!mounted) return;
        if (msg.toLowerCase().contains('not authenticated') ||
            msg.toLowerCase().contains('unauthorized')) {
          if (AuthState().user == null) { if (mounted) context.go('/login'); return; }
          setState(() { _isLoading = false; });
          return;
        }
        setState(() { _isLoading = false; _errorMessage = msg; });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() { _isLoading = false; _errorMessage = 'Unable to load classes.'; });
    }
  }

  bool _unlocked(int n) {
    // All levels locked when not authenticated
    if (AuthState().user == null) return false;
    // Level 1 is always accessible once authenticated
    if (n == 1) return true;
    return _levelAccess[n]?['unlocked'] == true;
  }
  bool _completed(int n) => _levelAccess[n]?['completed'] == true;
  int _done(int n) {
    final v = _levelAccess[n]?['daysCompleted'];
    if (v == null) return 0; if (v is int) return v;
    if (v is String) return int.tryParse(v) ?? 0; return 0;
  }
  int _total(int n) {
    final v = _levelAccess[n]?['totalDays'];
    if (v == null) return 3; if (v is int) return v;
    if (v is String) return int.tryParse(v) ?? 3; return 3;
  }
  int? _minsUntilUnlock(int n) {
    final v = _levelAccess[n]?['minutesUntilNextLevelUnlock'];
    if (v == null) return null; if (v is int) return v;
    if (v is String) return int.tryParse(v);
    if (v is double) return v.toInt(); return null;
  }
  String _lockReason(int n) {
    if (n == 1) return context.tr('available');
    if (n == 2) return context.tr('complete_level_1');
    if (n == 3) {
      if (!_completed(2)) return context.tr('complete_level_2');
      if (_meditationTest?['passed'] != true) return context.tr('pass_meditation_test');
      return context.tr('locked');
    }
    if (n == 4) return context.tr('complete_level_3');
    return context.tr('locked');
  }
  String _fmtTime(int m) {
    if (m < 60) return '$m min';
    final h = m ~/ 60, r = m % 60;
    return r == 0 ? '${h}h' : '${h}h ${r}m';
  }

  @override
  Widget build(BuildContext context) {
    return AuthGuard(
      featureName: context.tr('learnings_title'),
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (ConnectivityService().isOffline) {
      return OfflineScreen(message: 'Classes require internet.', onRetry: _loadLevelAccess);
    }
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.error_outline, color: AppTheme.primary, size: 56),
            const SizedBox(height: 16),
            Text(context.tr('unable_to_load_classes'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            Text(context.tr('unable_to_load_classes_desc'),
                style: const TextStyle(color: AppTheme.textSecondary),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _loadLevelAccess,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(12)),
                child: Text(context.tr('retry'),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        _buildHeader(),
        ..._courses.map(_buildCourseCard),
        if (_completed(2)) _buildMeditationTestCard(),
        _buildResidentialCard(level: context.tr('level_5'),
            description: context.tr('advanced_practice_guruji')),
        _buildResidentialCard(level: context.tr('level_5_1'),
            description: context.tr('master_level_intensive')),
      ],
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.tr('learnings_title'),
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 2),
          Text(context.tr('learnings_subtitle'),
              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── Course card ───────────────────────────────────────────────────────────
  Widget _buildCourseCard(_CourseInfo c) {
    final unlocked = _unlocked(c.levelNumber);
    final completed = _completed(c.levelNumber);
    final done = _done(c.levelNumber);
    final total = _total(c.levelNumber);
    final progress = total > 0 ? done / total : 0.0;
    final mins = _minsUntilUnlock(c.levelNumber);
    final pct = (progress * 100).round();
    final progressLabel = completed ? '100% Complete'
        : unlocked && done > 0 ? '$pct% Complete'
        : unlocked ? context.tr('available')
        : AuthState().user == null ? context.tr('login_required')
        : _lockReason(c.levelNumber);

    return GestureDetector(
      onTap: () {
        if (AuthState().user == null) {
          // Not logged in — prompt login
          context.go('/login');
          return;
        }
        if (unlocked) {
          context.push('/classes/${c.levelNumber}/days',
              extra: {'classTitle': context.tr(c.titleKey), 'level': 'Level ${c.levelNumber}'});
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppTheme.cardSurface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [AppTheme.cardShadow],
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
              child: SizedBox(
                width: 110, height: 120,
                child: unlocked
                    ? CachedImage(imageUrl: c.imageUrl, fit: BoxFit.cover)
                    : Stack(fit: StackFit.expand, children: [
                        CachedImage(imageUrl: c.imageUrl, fit: BoxFit.cover),
                        Container(
                          color: Colors.black.withValues(alpha: 0.45),
                          child: const Icon(Icons.lock_rounded, color: Colors.white, size: 28)),
                      ]),
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.tr(c.titleKey),
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold,
                            color: unlocked ? AppTheme.textPrimary : AppTheme.textSecondary)),
                    const SizedBox(height: 4),
                    Text(context.tr(c.subtitleKey),
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary,
                            height: 1.3),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: unlocked ? progress.clamp(0.0, 1.0) : 0.0,
                        backgroundColor: AppTheme.softGray,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            completed ? AppTheme.primary : AppTheme.gold),
                        minHeight: 4,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(children: [
                      Text(progressLabel,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                              color: unlocked ? AppTheme.primary : AppTheme.textHint)),
                      if (unlocked && mins != null && mins > 0) ...[
                        const Spacer(),
                        Text('⏱ ${_fmtTime(mins)}',
                            style: const TextStyle(fontSize: 10, color: AppTheme.textHint)),
                      ],
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Meditation test card ──────────────────────────────────────────────────
  Widget _buildMeditationTestCard() {
    final passed = _meditationTest?['passed'] == true;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: passed
            ? AppTheme.primary.withValues(alpha: 0.4)
            : AppTheme.gold.withValues(alpha: 0.3)),
        boxShadow: [AppTheme.softShadow],
      ),
      child: Row(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.self_improvement_rounded, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(context.tr('meditation_test'),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 3),
          Text(passed ? context.tr('meditation_test_completed')
              : context.tr('meditation_test_offline_notice'),
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.3),
              maxLines: 2, overflow: TextOverflow.ellipsis),
        ])),
        if (passed)
          const Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 24),
      ]),
    );
  }

  // ── Residential card ──────────────────────────────────────────────────────
  Widget _buildResidentialCard({required String level, required String description}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.tagBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.tagBorder),
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(gradient: AppTheme.goldGradient,
              borderRadius: BorderRadius.circular(11)),
          child: const Icon(Icons.school_rounded, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(level, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
              color: AppTheme.primary)),
          const SizedBox(height: 3),
          Text(description, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          const SizedBox(height: 4),
          Text(context.tr('apply_via_event'),
              style: const TextStyle(fontSize: 11, color: AppTheme.textHint,
                  fontStyle: FontStyle.italic)),
        ])),
      ]),
    );
  }
}

// ── Course data ───────────────────────────────────────────────────────────────
class _CourseInfo {
  final int levelNumber;
  final String titleKey;
  final String subtitleKey;
  final String imageUrl;
  // Not const — avoids hot-reload "cannot remove fields" errors when class shape changes
  _CourseInfo(this.levelNumber, this.titleKey, this.subtitleKey, this.imageUrl);
}
