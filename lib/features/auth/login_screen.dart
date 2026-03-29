import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/otp_input_widget.dart';
import '../../core/services/api_service.dart';
import '../../core/services/onesignal_service.dart';
import 'auth_service.dart';
import 'auth_state.dart';
import 'user_model.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  final TextEditingController _phoneController = TextEditingController();
  final AuthService _authService = AuthService();
  final AuthState _authState = AuthState();
  final ApiService _apiService = ApiService();
  final OneSignalService _oneSignal = OneSignalService();

  bool _isLoading = false;
  bool _showOtpField = false;
  String _enteredOtp = '';

  // Resend timer
  Timer? _resendTimer;
  int _resendCountdown = 30;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _slideController.forward();
    _fadeController.forward();
    
    // Check if user is already signed in (from Google redirect)
    _checkExistingUser();
  }

  Future<void> _checkExistingUser() async {
    final user = _authService.currentUser;
    if (user != null) {
      // User is already signed in (likely from Google redirect)
      await _handleExistingUser(user);
    }
  }

  Future<void> _handleExistingUser(user) async {
    setState(() => _isLoading = true);

    try {
      // Determine auth provider
      String authProvider = 'phone';
      for (var info in user.providerData) {
        if (info.providerId == 'google.com') {
          authProvider = 'google';
          break;
        }
      }

      // Call backend login API
      final loginResult = await _apiService.login(
        authProvider: authProvider,
        mobile: user.phoneNumber ?? '',
        email: user.email,
        name: user.displayName,
        photo: user.photoURL,
      );

      if (loginResult['success'] == true) {
        final userData = loginResult['user'] as Map<String, dynamic>;
        final userModel = UserModel.fromJson(userData);
        _authState.setUser(userModel);

        // Set OneSignal external user ID
        await _oneSignal.setExternalUserId(userModel.uid);

        // Set user tags for targeting
        await _oneSignal.setTags({
          'auth_provider': authProvider,
          if (userModel.email.isNotEmpty) 'email': userModel.email,
          if (userModel.mobile.isNotEmpty) 'mobile': userModel.mobile,
        });

        if (mounted) {
          // Navigate based on profile completion status
          if (loginResult['is_new_user'] == true || !userModel.isProfileComplete) {
            context.go('/profile-setup');
          } else {
            // Check if notification permission is granted
            final hasNotificationPermission = await _oneSignal.hasPermission();
            if (hasNotificationPermission) {
              context.go('/');
            } else {
              context.go('/notification-permission');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error handling existing user: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _phoneController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    setState(() {
      _resendCountdown = 30;
      _canResend = false;
    });
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown == 0) {
        timer.cancel();
        setState(() => _canResend = true);
      } else {
        setState(() => _resendCountdown--);
      }
    });
  }

  Future<void> _sendOtp() async {
    if (_phoneController.text.length != 10) {
      _showSnackBar('Please enter a valid 10-digit mobile number');
      return;
    }
    setState(() => _isLoading = true);

    final result = await _authService.sendOtp(
      _phoneController.text,
      onError: (error) {
        setState(() => _isLoading = false);
        _showSnackBar(error);
      },
    );

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      setState(() => _showOtpField = true);
      _startResendTimer();
      _showSnackBar('OTP sent to +91 ${_phoneController.text}');
    } else {
      _showSnackBar(result['message'] ?? 'Failed to send OTP');
    }
  }

  Future<void> _verifyOtp() async {
    if (_enteredOtp.length != 6) {
      _showSnackBar('Please enter the complete 6-digit OTP');
      return;
    }
    setState(() => _isLoading = true);

    final result = await _authService.verifyOtp(_enteredOtp);

    if (result['success'] == true) {
      // Call backend login API
      final loginResult = await _apiService.login(
        authProvider: 'phone',
        mobile: result['mobile'] as String,
      );

      setState(() => _isLoading = false);

      if (loginResult['success'] == true) {
        final userData = loginResult['user'] as Map<String, dynamic>;
        final user = UserModel.fromJson(userData);
        _authState.setUser(user);

        // Set OneSignal external user ID
        await _oneSignal.setExternalUserId(user.uid);

        // Set user tags for targeting
        await _oneSignal.setTags({
          'auth_provider': 'phone',
          'mobile': user.mobile,
        });

        if (mounted) {
          // Navigate based on profile completion status
          if (loginResult['is_new_user'] == true || !user.isProfileComplete) {
            context.go('/profile-setup');
          } else {
            // Check if notification permission is granted
            final hasNotificationPermission = await _oneSignal.hasPermission();
            if (hasNotificationPermission) {
              context.go('/');
            } else {
              context.go('/notification-permission');
            }
          }
        }
      } else {
        _showSnackBar(loginResult['message'] ?? 'Login failed. Please try again.');
      }
    } else {
      setState(() => _isLoading = false);
      _showSnackBar(result['message'] ?? 'Invalid OTP. Please try again.');
    }
  }

  Future<void> _resendOtp() async {
    if (!_canResend) return;
    setState(() => _isLoading = true);

    final result = await _authService.resendOtp(
      _phoneController.text,
      onError: (error) {
        setState(() => _isLoading = false);
        _showSnackBar(error);
      },
    );

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      _startResendTimer();
      _showSnackBar('OTP resent successfully');
    } else {
      _showSnackBar(result['message'] ?? 'Failed to resend OTP');
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    final result = await _authService.signInWithGoogle();

    if (result['success'] == true) {
      // Call backend login API
      final loginResult = await _apiService.login(
        authProvider: 'google',
        mobile: result['mobile'] as String? ?? '',
        email: result['email'] as String?,
        name: result['name'] as String?,
        photo: result['photo'] as String?,
      );

      setState(() => _isLoading = false);

      if (loginResult['success'] == true) {
        final userData = loginResult['user'] as Map<String, dynamic>;
        final user = UserModel.fromJson(userData);
        _authState.setUser(user);

        // Set OneSignal external user ID
        await _oneSignal.setExternalUserId(user.uid);

        // Set user tags for targeting
        await _oneSignal.setTags({
          'auth_provider': 'google',
          'email': user.email,
          if (user.mobile.isNotEmpty) 'mobile': user.mobile,
        });

        if (mounted) {
          // Navigate based on profile completion status
          if (loginResult['is_new_user'] == true || !user.isProfileComplete) {
            context.go('/profile-setup');
          } else {
            // Check if notification permission is granted
            final hasNotificationPermission = await _oneSignal.hasPermission();
            if (hasNotificationPermission) {
              context.go('/');
            } else {
              context.go('/notification-permission');
            }
          }
        }
      } else {
        _showSnackBar(loginResult['message'] ?? 'Login failed. Please try again.');
      }
    } else {
      setState(() => _isLoading = false);
      _showSnackBar(result['message'] ?? 'Google sign-in failed.');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _goBackToPhone() {
    _resendTimer?.cancel();
    _authService.clearSession();
    setState(() {
      _showOtpField = false;
      _enteredOtp = '';
      _canResend = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.white, AppTheme.beige.withOpacity(0.2)],
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
                            const SizedBox(height: 48),

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
                                    child: Icon(Icons.person, size: 60, color: AppTheme.primary),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 28),

                            Text(
                              _showOtpField ? 'Verify OTP' : 'Welcome',
                              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primary,
                                  ),
                            ),

                            const SizedBox(height: 8),

                            Text(
                              _showOtpField
                                  ? 'Enter the 6-digit OTP sent to\n+91 ${_phoneController.text}'
                                  : 'Sign in to continue your spiritual journey',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                              textAlign: TextAlign.center,
                            ),

                            const SizedBox(height: 40),

                            // ── Phone Input ──
                            if (!_showOtpField) ...[
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [AppTheme.softShadow],
                                ),
                                child: TextField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(10),
                                  ],
                                  decoration: InputDecoration(
                                    hintText: 'Enter mobile number',
                                    prefixIcon: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                      child: Text(
                                        '+91',
                                        style: TextStyle(
                                          color: AppTheme.textPrimary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.all(18),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Send OTP Button
                              _buildPrimaryButton('Send OTP', _isLoading ? null : _sendOtp),

                              const SizedBox(height: 32),

                              // Divider
                              Row(
                                children: [
                                  Expanded(child: Divider(color: AppTheme.softGray)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Text('OR',
                                        style: TextStyle(
                                            color: AppTheme.textSecondary,
                                            fontWeight: FontWeight.w500)),
                                  ),
                                  Expanded(child: Divider(color: AppTheme.softGray)),
                                ],
                              ),

                              const SizedBox(height: 32),

                              // Google Sign-In
                              _buildGoogleButton(),
                            ],

                            // ── OTP Input ──
                            if (_showOtpField) ...[
                              OtpInputWidget(
                                key: ValueKey(_showOtpField),
                                onCompleted: (otp) => setState(() => _enteredOtp = otp),
                              ),

                              const SizedBox(height: 32),

                              // Verify Button
                              _buildPrimaryButton('Verify OTP', _isLoading ? null : _verifyOtp),

                              const SizedBox(height: 20),

                              // Resend Row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Didn't receive OTP? ",
                                    style: TextStyle(color: AppTheme.textSecondary),
                                  ),
                                  _canResend
                                      ? GestureDetector(
                                          onTap: _resendOtp,
                                          child: Text(
                                            'Resend',
                                            style: TextStyle(
                                              color: AppTheme.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        )
                                      : Text(
                                          'Resend in ${_resendCountdown}s',
                                          style: TextStyle(
                                            color: AppTheme.textSecondary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              // Change number
                              TextButton(
                                onPressed: _isLoading ? null : _goBackToPhone,
                                child: Text(
                                  'Change mobile number',
                                  style: TextStyle(
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],

                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),

                    // Skip
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: TextButton(
                        onPressed: () => context.go('/notification-permission'),
                        child: Text(
                          'Skip for now',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
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

  Widget _buildPrimaryButton(String label, VoidCallback? onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          disabledBackgroundColor: AppTheme.primary.withOpacity(0.6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
              )
            : Text(
                label,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
              ),
      ),
    );
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: _isLoading ? null : _signInWithGoogle,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.textPrimary,
          side: BorderSide(color: AppTheme.softGray),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Google "G" icon using colored text as placeholder
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppTheme.softGray),
              ),
              child: const Center(
                child: Text(
                  'G',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Continue with Google',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
