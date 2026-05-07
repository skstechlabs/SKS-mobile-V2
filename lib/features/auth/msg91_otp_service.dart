import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/constants/app_env.dart';

/// Launches the MSG91 OTP widget in a bottom sheet WebView.
/// On success returns { success: true, access_token: '...' }.
/// The caller passes the access_token to ApiService.loginWithPhone() which
/// verifies it with MSG91 and creates/returns the user record.
class Msg91OtpService {
  static final Msg91OtpService _instance = Msg91OtpService._internal();
  factory Msg91OtpService() => _instance;
  Msg91OtpService._internal();

  /// Show the MSG91 OTP widget and wait for the result.
  /// Returns { 'success': true, 'access_token': '...' } on success.
  /// The caller is responsible for calling loginWithPhone(access_token) on the backend.
  /// Returns { 'success': false, 'message': '...' } on failure/cancel.
  Future<Map<String, dynamic>> showOtpWidget(
    BuildContext context, {
    String? prefillPhone,
  }) async {
    final completer = Completer<Map<String, dynamic>>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (_) => _Msg91WebViewSheet(
        widgetId: AppEnv.msg91WidgetId,
        prefillPhone: prefillPhone,
        onSuccess: (accessToken) {
          // Return the raw access_token — backend login/phone will verify it
          if (!completer.isCompleted) {
            completer.complete({'success': true, 'access_token': accessToken});
          }
        },
        onCancel: () {
          if (!completer.isCompleted) {
            completer.complete({'success': false, 'message': 'OTP cancelled.'});
          }
        },
        onError: (error) {
          if (!completer.isCompleted) {
            completer.complete({'success': false, 'message': error});
          }
        },
      ),
    );

    // If sheet was dismissed without completing (swipe down)
    if (!completer.isCompleted) {
      completer.complete({'success': false, 'message': 'OTP cancelled.'});
    }

    return completer.future;
  }
}

// ── Internal WebView sheet ─────────────────────────────────────────────────

class _Msg91WebViewSheet extends StatefulWidget {
  final String widgetId;
  final String? prefillPhone;
  final void Function(String accessToken) onSuccess;
  final void Function() onCancel;
  final void Function(String error) onError;

  const _Msg91WebViewSheet({
    required this.widgetId,
    required this.onSuccess,
    required this.onCancel,
    required this.onError,
    this.prefillPhone,
  });

  @override
  State<_Msg91WebViewSheet> createState() => _Msg91WebViewSheetState();
}

class _Msg91WebViewSheetState extends State<_Msg91WebViewSheet> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'FlutterMsg91',
        onMessageReceived: (JavaScriptMessage message) {
          _handleMsg91Event(message.message);
        },
      )
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) {
          if (mounted) setState(() => _isLoading = false);
        },
        onWebResourceError: (error) {
          widget.onError('Failed to load OTP widget: ${error.description}');
          if (mounted) Navigator.of(context).pop();
        },
      ))
      ..loadHtmlString(_buildHtml());
  }

  /// Parse events sent from the MSG91 widget JS back to Flutter.
  void _handleMsg91Event(String message) {
    debugPrint('📱 MSG91 event: $message');

    if (message.startsWith('SUCCESS:')) {
      final accessToken = message.substring('SUCCESS:'.length);
      widget.onSuccess(accessToken);
      if (mounted) Navigator.of(context).pop();
    } else if (message == 'CANCEL') {
      widget.onCancel();
      if (mounted) Navigator.of(context).pop();
    } else if (message.startsWith('ERROR:')) {
      final error = message.substring('ERROR:'.length);
      widget.onError(error);
      if (mounted) Navigator.of(context).pop();
    }
  }

  /// Build the HTML page that hosts the MSG91 OTP widget.
  String _buildHtml() {
    final prefill = widget.prefillPhone != null
        ? '"mobile": "${widget.prefillPhone}",'
        : '';

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0" />
  <title>Verify OTP</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
      background: #fff;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: flex-start;
      min-height: 100vh;
      padding: 24px 16px;
    }
    #msg91-widget-container {
      width: 100%;
      max-width: 400px;
    }
    .loading {
      color: #888;
      font-size: 14px;
      margin-top: 40px;
    }
  </style>
</head>
<body>
  <div id="msg91-widget-container">
    <p class="loading">Loading OTP widget...</p>
  </div>

  <script
    src="https://control.msg91.com/app/assets/otp-provider/otp-provider.js"
    onload="initWidget()"
    onerror="onScriptError()">
  </script>

  <script>
    function initWidget() {
      var config = {
        widgetId: "${widget.widgetId}",
        tokenAuth: "${AppEnv.msg91AuthToken}",
        $prefill
        success: function(data) {
          // data.message contains the access_token
          var token = data.message || data.access_token || data.token || JSON.stringify(data);
          FlutterMsg91.postMessage("SUCCESS:" + token);
        },
        failure: function(error) {
          var msg = (error && error.message) ? error.message : JSON.stringify(error);
          FlutterMsg91.postMessage("ERROR:" + msg);
        }
      };

      // Render the widget
      if (window.initSendOTP) {
        window.initSendOTP(config);
      } else {
        FlutterMsg91.postMessage("ERROR:MSG91 SDK not loaded");
      }
    }

    function onScriptError() {
      FlutterMsg91.postMessage("ERROR:Failed to load MSG91 script. Check your internet connection.");
    }
  </script>
</body>
</html>
''';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Verify Mobile Number',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    widget.onCancel();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // WebView
          Expanded(
            child: Stack(
              children: [
                WebViewWidget(controller: _controller),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
