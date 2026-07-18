import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../services/localization_service.dart';

/// Shared "not logged in" gate widget.
///
/// Used everywhere a feature requires authentication:
///   - ProfileScreen
///   - AuthGuard (Classes, etc.)
///   - MeditationJourneyPage
///   - MeditationHistoryPage / MeditationSessionsPage
///   - Any future gated screen
///
/// Always shows:
///   - Guruji logo + warm message about benefits of joining
///   - Login button
///   - Change Language option
///   - Help & Support option
///
/// Parameters:
///   [title]       — Screen heading, e.g. "My Profile"
///   [featureHint] — One short line specific to the feature, e.g. "track your meditation journey"
///   [useGoRouter] — true = context.go('/login'), false = context.push('/login')
///                   Default false (push) so back button works from inner screens
///   [showBackButton] — whether to show an appBar back button (default true)
class LoginGate extends StatelessWidget {
  final String title;
  final String? featureHint;
  final bool useGoRouter;
  final bool showBackButton;

  const LoginGate({
    super.key,
    required this.title,
    this.featureHint,
    this.useGoRouter = false,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        backgroundColor: AppTheme.cream,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded,
                    color: AppTheme.textPrimary, size: 20),
                onPressed: () {
                  if (context.canPop()) context.pop();
                  else context.go('/');
                },
              )
            : null,
        title: Text(
          title,
          style: const TextStyle(
            color: AppTheme.primary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 32),

                // ── Guruji logo ──────────────────────────────────────────
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primary.withValues(alpha: 0.12),
                        AppTheme.saffron.withValues(alpha: 0.08),
                      ],
                    ),
                    border: Border.all(
                        color: AppTheme.primary.withValues(alpha: 0.25),
                        width: 2),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/Guruji_logo.JPG',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                          Icons.self_improvement,
                          size: 44,
                          color: AppTheme.primary),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Headline ─────────────────────────────────────────────
                Text(
                  context.tr('welcome'),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  context.tr('login_subtitle'),
                  style: const TextStyle(
                      fontSize: 14, color: AppTheme.textSecondary),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                // ── Benefits card ────────────────────────────────────────
                _BenefitsCard(featureHint: featureHint),

                const SizedBox(height: 28),

                // ── Login button ─────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (useGoRouter) {
                        context.go('/login');
                      } else {
                        context.push('/login');
                      }
                    },
                    icon: const Icon(Icons.login_rounded,
                        color: Colors.white, size: 20),
                    label: Text(
                      context.tr('login'),
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 2,
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // ── Divider ──────────────────────────────────────────────
                Row(children: [
                  Expanded(child: Divider(color: AppTheme.softGray.withValues(alpha: 0.6))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('or',
                        style: TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary.withValues(alpha: 0.7))),
                  ),
                  Expanded(child: Divider(color: AppTheme.softGray.withValues(alpha: 0.6))),
                ]),

                const SizedBox(height: 20),

                // ── Quick-access options (no login needed) ───────────────
                _QuickTile(
                  icon: Icons.language_outlined,
                  title: context.tr('change_language'),
                  subtitle: 'Switch between English and Telugu',
                  onTap: () => context.push('/settings/language'),
                ),
                const SizedBox(height: 10),
                _QuickTile(
                  icon: Icons.help_outline_rounded,
                  title: context.tr('help_support'),
                  subtitle: 'Contact the Gurudev team',
                  onTap: () => context.push('/guruji-connect'),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Benefits card ─────────────────────────────────────────────────────────────
class _BenefitsCard extends StatelessWidget {
  final String? featureHint;
  const _BenefitsCard({this.featureHint});

  @override
  Widget build(BuildContext context) {
    final items = [
      if (featureHint != null && featureHint!.isNotEmpty) featureHint!,
      '🧘 Track your meditation streaks & journey',
      '📊 See your progress, stats and leaderboard',
      '🔔 Get personalized spiritual reminders',
      '📚 Access your Kundalini Sadhana courses',
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primary.withValues(alpha: 0.07),
            AppTheme.saffron.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: AppTheme.primary.withValues(alpha: 0.15), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.emoji_events_rounded,
                color: AppTheme.saffron, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Be part of our spiritual family',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary.withValues(alpha: 0.9),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        color: AppTheme.saffron, size: 15),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textPrimary,
                            height: 1.4),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

// ── Quick-access tile (no login needed) ───────────────────────────────────────
class _QuickTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.softGray),
          boxShadow: [AppTheme.softShadow],
        ),
        child: Row(children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.tagBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: AppTheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary)),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: AppTheme.textSecondary, size: 18),
        ]),
      ),
    );
  }
}
