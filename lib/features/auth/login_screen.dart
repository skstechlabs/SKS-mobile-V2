import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/api_service.dart';
import '../../core/services/onesignal_service.dart';
import '../../core/services/localization_service.dart';
import '../../core/utils/network_diagnostic.dart';
import 'auth_service.dart';
import 'auth_state.dart';
import 'msg91_otp_service.dart';
import 'user_model.dart';

/// Login screen — shows sign-in UI only.
/// All auto-login / session-restore logic lives in SplashScreen.
/// This screen is only reached when the user genuinely needs to sign in.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  final AuthService _authService = AuthService();
  final AuthState _authState = AuthState();
  final ApiService _apiService = ApiService();
  final OneSignalService _oneSignal = OneSignalService();
  final Msg91OtpService _msg91 = Msg91OtpService();

  bool _isLoading = false;
  // Prevents double-tap / concurrent sign-in attempts
  bool _loginInProgress = false;
  // Tracks if Google Sign-In is available (checked once on init)
  bool? _isGoogleAvailable;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _slideController.forward();
    _fadeController.forward();

    // Check Google Sign-In availability once on init
    _checkGoogleAvailability();
  }

  Future<void> _checkGoogleAvailability() async {
    final available = await NetworkDiagnostic.isGoogleSignInAvailable();
    if (mounted) {
      setState(() {
        _isGoogleAvailable = available;
      });
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  // ── MSG91 OTP ──────────────────────────────────────────────────────────────
  // NOTE: OTP login is disabled for now - only Google Sign-In is enabled
  // Keeping this code for future use when OTP is implemented
  // ignore: unused_element
  Future<void> _startOtpLogin() async {
    if (_loginInProgress || !mounted) return;
    _loginInProgress = true;
    setState(() => _isLoading = true);

    try {
      final result = await _msg91.showOtpWidget(context);
      if (!mounted) {
        _loginInProgress = false;
        return;
      }

      if (result['success'] == true) {
        final accessToken = result['access_token'] as String? ?? '';
        if (accessToken.isEmpty) {
          _resetLoading();
          _showSnackBar('OTP verification failed. Please try again.');
          return;
        }
        final loginResult = await _apiService.loginWithPhone(accessToken);
        _loginInProgress = false;
        if (!mounted) return;
        await _handleLoginResult(loginResult, authProvider: 'phone');
      } else {
        _resetLoading();
        final msg = result['message'] as String? ?? '';
        if (msg.isNotEmpty && msg != 'OTP cancelled.') _showSnackBar(msg);
      }
    } catch (e) {
      _resetLoading();
      debugPrint('OTP login error: $e');
      if (mounted) _showSnackBar('OTP verification failed. Please try again.');
    }
  }

  // ── Google Sign-In ─────────────────────────────────────────────────────────
  Future<void> _signInWithGoogle() async {
    if (_loginInProgress || !mounted) return;
    _loginInProgress = true;
    setState(() => _isLoading = true);

    try {
      // Pre-check: Verify network connectivity for Google Sign-In
      // Only check if we haven't checked recently (uses cache)
      final networkOk = await NetworkDiagnostic.isGoogleSignInAvailable();
      if (!networkOk) {
        _resetLoading();
        _showSnackBar(
            'Cannot reach Google servers. Try mobile data or use OTP login.');
        return;
      }

      // Step 1: Google / Firebase sign-in on device
      final result = await _authService.signInWithGoogle();
      _loginInProgress = false;

      if (!mounted) return;

      if (result['success'] != true) {
        setState(() => _isLoading = false);
        if (result['pending'] == true) return; // web redirect in progress
        final msg = result['message'] as String? ?? 'Google sign-in failed.';
        if (!msg.contains('cancelled')) _showSnackBar(msg);
        return;
      }

      // Step 2: Backend login — use the fresh token returned by signInWithGoogle
      final freshIdToken = result['idToken'] as String?;
      final mobile = (result['mobile'] as String?)?.isNotEmpty == true
          ? result['mobile'] as String
          : (result['email'] as String? ?? '');

      Map<String, dynamic>? loginResult;
      for (int attempt = 1; attempt <= 3; attempt++) {
        loginResult = await _apiService.loginWithGoogle(
          mobile: mobile,
          email: result['email'] as String?,
          name: result['name'] as String?,
          photo: result['photo'] as String?,
          // Use fresh token on first attempt; re-fetch on retries
          idToken: attempt == 1 ? freshIdToken : null,
        );
        if (loginResult['success'] == true) break;

        final errCode = loginResult['error_code'] as String? ?? '';
        if (errCode == 'TOKEN_EXPIRED' ||
            errCode == 'TOKEN_INVALID' ||
            errCode == 'TOKEN_REVOKED') {
          debugPrint('❌ Token rejected on attempt $attempt: $errCode');
          break;
        }
        if (attempt < 3) {
          debugPrint('⚠️ Backend attempt $attempt failed, retrying...');
          await Future.delayed(Duration(milliseconds: 600 * attempt));
        }
      }

      if (!mounted) return;
      await _handleLoginResult(loginResult!, authProvider: 'google');
    } catch (e) {
      _loginInProgress = false;
      debugPrint('Google sign-in error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('Google sign-in failed. Please try again.');
      }
    }
  }

  // ── Handle backend response ────────────────────────────────────────────────
  Future<void> _handleLoginResult(
    Map<String, dynamic> loginResult, {
    required String authProvider,
  }) async {
    if (!mounted) return;

    if (loginResult['success'] != true) {
      setState(() => _isLoading = false);
      _showSnackBar(
          loginResult['message'] as String? ?? 'Login failed. Please try again.');
      return;
    }

    // Cache the user
    final user =
        UserModel.fromJson(loginResult['user'] as Map<String, dynamic>);
    await _authState.setUser(user);

    // OneSignal — CRITICAL: Only register if permission was granted
    // This ensures the push token exists before linking to user
    try {
      final hasPermission = await _oneSignal.hasPermission();
      if (hasPermission) {
        await _oneSignal.setExternalUserId(user.uid);
        await _oneSignal.setTags({
          'auth_provider': authProvider,
          if (user.email.isNotEmpty) 'email': user.email,
          if (user.mobile.isNotEmpty) 'mobile': user.mobile,
        });
        debugPrint('✅ OneSignal registered for user: ${user.uid}');
      } else {
        debugPrint('⚠️ OneSignal: Permission not granted, skipping registration');
        debugPrint('   User will be registered when they grant permission later');
      }
    } catch (e) {
      debugPrint('❌ OneSignal registration error: $e');
    }

    if (!mounted) return;

    final isNewUser = loginResult['is_new_user'] == true;
    if (isNewUser || !user.isProfileComplete) {
      final isLanguageSelected = await LocalizationService.isLanguageSelected();
      if (!mounted) return;
      context.go(isLanguageSelected ? '/profile-setup' : '/language-selection');
    } else {
      if (!mounted) return;
      context.go('/');
    }
  }

  void _resetLoading() {
    _loginInProgress = false;
    if (mounted) setState(() => _isLoading = false);
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.white, AppTheme.beige.withValues(alpha: 0.2)],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 60),

                            // Logo
                            Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [AppTheme.glowShadow],
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/images/Guruji_logo.JPG',
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: AppTheme.beige,
                                    child: const Icon(Icons.person,
                                        size: 60, color: AppTheme.primary),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 32),

                            Text(
                              context.tr('welcome'),
                              style: Theme.of(context)
                                  .textTheme
                                  .displayMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primary,
                                  ),
                            ),

                            const SizedBox(height: 8),

                            Text(
                              context.tr('login_subtitle'),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(color: AppTheme.textSecondary),
                              textAlign: TextAlign.center,
                            ),

                            const SizedBox(height: 48),

                            // Google Sign-In button (primary)
                            _buildGoogleButton(),

                            // OTP button is disabled - not yet implemented
                            // Keeping the code for future use when OTP is enabled
                            // _buildPrimaryButton(
                            //   label: context.tr('send_otp'),
                            //   icon: Icons.phone_android,
                            //   onPressed: _isLoading ? null : _startOtpLogin,
                            // ),

                            // Show network warning if Google is unavailable
                            if (_isGoogleAvailable == false) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: Colors.orange.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline,
                                        size: 18, color: Colors.orange.shade700),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Google Sign-In unavailable. Use OTP or try mobile data.',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.orange.shade900,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 24),

                            // DEBUG: Network diagnostic button (only in debug mode)
                            if (kDebugMode) ...[
                              const SizedBox(height: 8),
                              TextButton.icon(
                                onPressed: _isLoading
                                    ? null
                                    : () async {
                                        _showSnackBar(
                                            'Running network diagnostics...');
                                        // Clear cache before running fresh diagnostic
                                        NetworkDiagnostic.clearCache();
                                        await NetworkDiagnostic
                                            .runFullDiagnostic();
                                        // Re-check Google availability
                                        await _checkGoogleAvailability();
                                        if (mounted) {
                                          _showSnackBar(
                                              'Check console for diagnostic report');
                                        }
                                      },
                                icon: const Icon(Icons.network_check,
                                    size: 18, color: AppTheme.textSecondary),
                                label: const Text(
                                  'Test Network (Debug)',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textSecondary),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    // Skip
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: TextButton(
                        onPressed: _isLoading
                            ? null
                            : () => context.go('/notification-permission'),
                        child: Text(
                          context.tr('skip_for_now'),
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // NOTE: This button is not currently used since OTP is disabled
  // ignore: unused_element
  Widget _buildPrimaryButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5),
              )
            : Icon(icon, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          disabledBackgroundColor: AppTheme.primary.withValues(alpha: 0.6),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Widget _buildGoogleButton() {
    final isDisabled = _isLoading || _isGoogleAvailable == false;
    
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: isDisabled ? null : _signInWithGoogle,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.textPrimary,
          disabledForegroundColor: AppTheme.textSecondary,
          side: BorderSide(
            color: isDisabled ? AppTheme.softGray.withValues(alpha: 0.5) : AppTheme.softGray,
          ),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isDisabled 
                      ? AppTheme.softGray.withValues(alpha: 0.5) 
                      : AppTheme.softGray,
                ),
              ),
              child: Center(
                child: Text('G',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDisabled 
                            ? Colors.red.withValues(alpha: 0.5)
                            : Colors.red)),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _isGoogleAvailable == false 
                  ? 'Google Sign-In Unavailable'
                  : 'Continue with Google',
              style: TextStyle(
                fontSize: 16, 
                fontWeight: FontWeight.w600,
                color: isDisabled ? AppTheme.textSecondary : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
