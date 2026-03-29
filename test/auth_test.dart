import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spiritual_app/features/splash/splash_screen.dart';
import 'package:spiritual_app/features/auth/login_screen.dart';
import 'package:spiritual_app/core/widgets/otp_input_widget.dart';

void main() {
  group('Authentication Screens', () {
    testWidgets('SplashScreen should build without errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SplashScreen(),
        ),
      );
      
      expect(find.byType(SplashScreen), findsOneWidget);
    });

    testWidgets('LoginScreen should build without errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );
      
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('OtpInputWidget should build without errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OtpInputWidget(
              onCompleted: (otp) {},
            ),
          ),
        ),
      );
      
      expect(find.byType(OtpInputWidget), findsOneWidget);
    });
  });
}