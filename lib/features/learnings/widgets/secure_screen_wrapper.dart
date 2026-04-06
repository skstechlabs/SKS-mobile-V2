import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform;

/// A wrapper widget that provides screen recording and screenshot protection
/// for sensitive content like video classes
class SecureScreenWrapper extends StatefulWidget {
  final Widget child;

  const SecureScreenWrapper({
    super.key,
    required this.child,
  });

  @override
  State<SecureScreenWrapper> createState() => _SecureScreenWrapperState();
}

class _SecureScreenWrapperState extends State<SecureScreenWrapper> with WidgetsBindingObserver {
  static const platform = MethodChannel('com.spiritual.app/security');
  bool _isSecure = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _enableSecureMode();
  }

  @override
  void dispose() {
    _disableSecureMode();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (state == AppLifecycleState.resumed) {
      _enableSecureMode();
    }
  }

  Future<void> _enableSecureMode() async {
    if (_isSecure) return;

    try {
      // Try to enable platform-specific secure mode
      if (Platform.isAndroid) {
        await platform.invokeMethod('enableSecureMode');
        debugPrint('🔒 Android secure mode enabled (FLAG_SECURE)');
      } else if (Platform.isIOS) {
        // iOS doesn't have direct API, but we can detect screen recording
        await platform.invokeMethod('checkScreenRecording');
        debugPrint('🔒 iOS screen recording check enabled');
      }
      
      setState(() => _isSecure = true);
    } on PlatformException catch (e) {
      debugPrint('⚠️ Platform secure mode not available: ${e.message}');
      // Fallback: Use Flutter's secure mode
      _enableFlutterSecureMode();
    } catch (e) {
      debugPrint('⚠️ Error enabling secure mode: $e');
      _enableFlutterSecureMode();
    }
  }

  void _enableFlutterSecureMode() {
    // Fallback: Hide system UI to make recording harder
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [],
    );
    setState(() => _isSecure = true);
  }

  Future<void> _disableSecureMode() async {
    if (!_isSecure) return;

    try {
      if (Platform.isAndroid) {
        await platform.invokeMethod('disableSecureMode');
      }
      
      // Restore system UI
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.edgeToEdge,
        overlays: SystemUiOverlay.values,
      );
      
      setState(() => _isSecure = false);
    } catch (e) {
      debugPrint('Error disabling secure mode: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        // Watermark overlay (subtle, doesn't interfere with viewing)
        Positioned(
          bottom: 100,
          right: 20,
          child: Opacity(
            opacity: 0.3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '© Protected Content',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
