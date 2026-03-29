import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../auth/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
    ));

    _controller.forward();

    // On web: check if returning from Google redirect sign-in
    // On others: go straight to login
    Future.delayed(const Duration(milliseconds: 2000), () async {
      if (!mounted) return;

      if (kIsWeb) {
        final result = await AuthService().getRedirectResult();
        if (!mounted) return;
        if (result != null && result['success'] == true) {
          // User signed in with Google via redirect
          // Navigate to login screen which will handle the backend API call
          context.go('/login');
          return;
        }
      }

      context.go('/login');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.white,
              AppTheme.beige.withOpacity(0.3),
              AppTheme.white,
            ],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Gurudev Image with Glow Effect
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withOpacity(0.3),
                              blurRadius: 30,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/Guruji.JPG',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.beige,
                                ),
                                child: Icon(
                                  Icons.person,
                                  size: 80,
                                  color: AppTheme.primary,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Gurudev Name
                      Text(
                        'Parama Pujya Sri Jeeveswara Yogi',
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Text(
                      //   'Divine Path',
                      //   style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      //     color: AppTheme.textSecondary,
                      //     fontWeight: FontWeight.w300,
                      //   ),
                      //   textAlign: TextAlign.center,
                      // ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}