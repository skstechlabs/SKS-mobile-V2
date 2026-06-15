import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Network diagnostic utility to help debug connectivity issues.
/// This helps identify if the problem is:
/// - No internet at all
/// - DNS resolution failing
/// - SSL/certificate issues
/// - Specific domain blocking
class NetworkDiagnostic {
  /// Run comprehensive network diagnostics
  static Future<Map<String, dynamic>> runFullDiagnostic() async {
    // On web, run simplified diagnostic (DNS lookups not available)
    if (kIsWeb) {
      return await _runWebDiagnostic();
    }

    final results = <String, dynamic>{};

    // Test 1: Raw internet connectivity (ping Google DNS)
    results['rawConnectivity'] = await _testRawConnectivity();

    // Test 2: DNS resolution
    results['dns'] = await _testDNS();

    // Test 3: HTTP/HTTPS connectivity
    results['http'] = await _testHTTP();

    // Test 4: Specific domains
    results['domains'] = await _testDomains();

    // Print comprehensive report
    _printReport(results);

    return results;
  }

  /// Test basic internet connectivity (can reach Google DNS)
  static Future<Map<String, dynamic>> _testRawConnectivity() async {
    // Skip on web (not supported)
    if (kIsWeb) {
      return {
        'status': 'skipped',
        'message': 'Raw connectivity test not available on web',
      };
    }

    try {
      final result = await InternetAddress.lookup('8.8.8.8')
          .timeout(const Duration(seconds: 5));
      return {
        'status': 'success',
        'message': 'Can reach internet (Google DNS)',
        'addresses': result.map((addr) => addr.address).toList(),
      };
    } on SocketException catch (e) {
      return {
        'status': 'fail',
        'message': 'Cannot reach internet',
        'error': e.toString(),
        'reason': 'Device has no internet connection',
      };
    } catch (e) {
      return {
        'status': 'fail',
        'message': 'Connectivity test failed',
        'error': e.toString(),
      };
    }
  }

  /// Test DNS resolution for multiple domains
  static Future<Map<String, dynamic>> _testDNS() async {
    // Skip on web (not supported)
    if (kIsWeb) {
      return {
        'summary': {
          'total': 0,
          'success': 0,
          'fail': 0,
          'status': 'skipped',
        },
        'message': 'DNS tests not available on web',
      };
    }

    final domains = [
      'google.com',
      'accounts.google.com',
      'imagedelivery.net',
      'app.sivakundalini.org',
      'firebase.google.com',
    ];

    final results = <String, dynamic>{};
    int successCount = 0;

    for (final domain in domains) {
      try {
        final addresses = await InternetAddress.lookup(domain)
            .timeout(const Duration(seconds: 5));
        results[domain] = {
          'status': 'success',
          'addresses': addresses.map((addr) => addr.address).toList(),
        };
        successCount++;
      } on SocketException catch (e) {
        results[domain] = {
          'status': 'fail',
          'error': e.osError?.message ?? 'DNS lookup failed',
          'reason': 'Cannot resolve domain to IP address',
        };
      } catch (e) {
        results[domain] = {
          'status': 'fail',
          'error': e.toString(),
        };
      }
    }

    results['summary'] = {
      'total': domains.length,
      'success': successCount,
      'fail': domains.length - successCount,
      'status': successCount == domains.length ? 'success' : 'partial',
    };

    return results;
  }

  /// Test HTTP/HTTPS requests
  static Future<Map<String, dynamic>> _testHTTP() async {
    final tests = {
      'google': 'https://www.google.com',
      'firebase': 'https://firebase.google.com',
      'imagedelivery': 'https://imagedelivery.net',
      'sks-api': 'https://app.sivakundalini.org/api/health',
    };

    final results = <String, dynamic>{};
    int successCount = 0;

    for (final entry in tests.entries) {
      try {
        final response = await http
            .get(Uri.parse(entry.value))
            .timeout(const Duration(seconds: 10));
        results[entry.key] = {
          'status': 'success',
          'statusCode': response.statusCode,
          'url': entry.value,
        };
        successCount++;
      } on SocketException catch (e) {
        results[entry.key] = {
          'status': 'fail',
          'error': 'DNS/Network: ${e.osError?.message ?? e.toString()}',
          'url': entry.value,
          'reason': 'Cannot resolve domain or reach server',
        };
      } on HandshakeException catch (e) {
        results[entry.key] = {
          'status': 'fail',
          'error': 'SSL/Certificate: ${e.message}',
          'url': entry.value,
          'reason': 'SSL certificate verification failed',
        };
      } on HttpException catch (e) {
        results[entry.key] = {
          'status': 'fail',
          'error': 'HTTP: ${e.message}',
          'url': entry.value,
        };
      } catch (e) {
        results[entry.key] = {
          'status': 'fail',
          'error': e.toString(),
          'url': entry.value,
        };
      }
    }

    results['summary'] = {
      'total': tests.length,
      'success': successCount,
      'fail': tests.length - successCount,
      'status': successCount == tests.length ? 'success' : 'partial',
    };

    return results;
  }

  /// Test specific domain resolution that app depends on
  static Future<Map<String, dynamic>> _testDomains() async {
    // Skip on web (not supported)
    if (kIsWeb) {
      return {
        'summary': {
          'total': 0,
          'success': 0,
          'fail': 0,
        },
        'message': 'Domain resolution tests not available on web',
      };
    }

    final criticalDomains = {
      'accounts.google.com': 'Required for Google Sign-In',
      'imagedelivery.net': 'Required for loading images',
      'app.sivakundalini.org': 'Required for API calls',
      'googleapis.com': 'Required for Google services',
    };

    final results = <String, dynamic>{};
    int successCount = 0;

    for (final entry in criticalDomains.entries) {
      try {
        final addresses = await InternetAddress.lookup(entry.key)
            .timeout(const Duration(seconds: 5));
        results[entry.key] = {
          'status': 'success',
          'purpose': entry.value,
          'addresses': addresses.map((addr) => addr.address).toList(),
        };
        successCount++;
      } catch (e) {
        results[entry.key] = {
          'status': 'fail',
          'purpose': entry.value,
          'error': e.toString(),
        };
      }
    }

    results['summary'] = {
      'total': criticalDomains.length,
      'success': successCount,
      'fail': criticalDomains.length - successCount,
    };

    return results;
  }

  /// Print formatted diagnostic report
  static void _printReport(Map<String, dynamic> results) {
    debugPrint('\n' + '═' * 60);
    debugPrint('🔍 NETWORK DIAGNOSTIC REPORT');
    debugPrint('═' * 60);

    // Raw Connectivity
    final rawConn = results['rawConnectivity'] as Map<String, dynamic>;
    debugPrint('\n📡 RAW CONNECTIVITY:');
    debugPrint('   Status: ${rawConn['status']}');
    debugPrint('   ${rawConn['message']}');
    if (rawConn['status'] == 'fail') {
      debugPrint('   ❌ Error: ${rawConn['error']}');
      debugPrint('   ⚠️  ${rawConn['reason']}');
    }

    // DNS
    final dns = results['dns'] as Map<String, dynamic>;
    final dnsSummary = dns['summary'] as Map<String, dynamic>;
    debugPrint('\n🌐 DNS RESOLUTION:');
    debugPrint(
        '   ${dnsSummary['success']}/${dnsSummary['total']} domains resolved');
    dns.forEach((key, value) {
      if (key == 'summary') return;
      final status = value['status'];
      if (status == 'fail') {
        debugPrint('   ❌ $key: ${value['error']}');
      }
    });

    // HTTP
    final httpResults = results['http'] as Map<String, dynamic>;
    final httpSummary = httpResults['summary'] as Map<String, dynamic>;
    debugPrint('\n🌍 HTTP/HTTPS TESTS:');
    debugPrint(
        '   ${httpSummary['success']}/${httpSummary['total']} requests successful');
    httpResults.forEach((key, value) {
      if (key == 'summary') return;
      final status = value['status'];
      if (status == 'fail') {
        debugPrint('   ❌ $key: ${value['error']}');
      }
    });

    // Critical Domains
    final domains = results['domains'] as Map<String, dynamic>;
    final domainsSummary = domains['summary'] as Map<String, dynamic>;
    debugPrint('\n🎯 CRITICAL DOMAINS:');
    debugPrint(
        '   ${domainsSummary['success']}/${domainsSummary['total']} accessible');
    domains.forEach((key, value) {
      if (key == 'summary') return;
      final status = value['status'];
      if (status == 'fail') {
        debugPrint('   ❌ $key: ${value['purpose']}');
        debugPrint('      Error: ${value['error']}');
      }
    });

    // Overall Status
    debugPrint('\n' + '─' * 60);
    final allGood = rawConn['status'] == 'success' &&
        dnsSummary['status'] == 'success' &&
        httpSummary['status'] == 'success';

    if (allGood) {
      debugPrint('✅ OVERALL: Network is working properly');
      debugPrint('   → Google Sign-In should work');
      debugPrint('   → If Google Sign-In still fails, issue is with:');
      debugPrint('     - SHA-1 certificate configuration');
      debugPrint('     - Google Play Services');
      debugPrint('     - Firebase project settings');
    } else {
      debugPrint('❌ OVERALL: Network has issues');
      if (rawConn['status'] == 'fail') {
        debugPrint('   → No internet connection');
        debugPrint('   → Check WiFi/mobile data');
      } else if (dnsSummary['status'] != 'success') {
        debugPrint('   → DNS resolution failing');
        debugPrint('   → Check DNS settings or use mobile data');
      } else {
        debugPrint('   → Some domains/services blocked');
        debugPrint('   → Check VPN, firewall, or network restrictions');
      }
    }
    debugPrint('═' * 60 + '\n');
  }

  /// Simplified diagnostic for web platform
  static Future<Map<String, dynamic>> _runWebDiagnostic() async {
    final results = <String, dynamic>{};

    debugPrint('\n' + '═' * 60);
    debugPrint('🔍 NETWORK DIAGNOSTIC REPORT (WEB)');
    debugPrint('═' * 60);

    // Test HTTP/HTTPS connectivity
    results['http'] = await _testHTTP();

    final httpResults = results['http'] as Map<String, dynamic>;
    final httpSummary = httpResults['summary'] as Map<String, dynamic>;
    
    debugPrint('\n🌍 HTTP/HTTPS TESTS:');
    debugPrint(
        '   ${httpSummary['success']}/${httpSummary['total']} requests successful');
    httpResults.forEach((key, value) {
      if (key == 'summary') return;
      final status = value['status'];
      if (status == 'success') {
        debugPrint('   ✅ $key: ${value['statusCode']}');
      } else {
        debugPrint('   ❌ $key: ${value['error']}');
      }
    });

    debugPrint('\n' + '─' * 60);
    final allGood = httpSummary['status'] == 'success';

    if (allGood) {
      debugPrint('✅ OVERALL: Network is working properly');
      debugPrint('   → All services accessible from browser');
    } else {
      debugPrint('❌ OVERALL: Some services unreachable');
      debugPrint('   → Check browser console for CORS or network errors');
      debugPrint('   → Verify internet connection');
    }
    debugPrint('═' * 60 + '\n');

    return results;
  }

  // Cache for Google Sign-In availability check to avoid repeated lookups
  static bool? _cachedGoogleAvailability;
  static DateTime? _lastCheckTime;

  /// Quick check if network is available for Google Sign-In
  /// Caches result for 30 seconds to avoid repeated DNS lookups
  static Future<bool> isGoogleSignInAvailable() async {
    // On web, always return true (browser handles connectivity)
    if (kIsWeb) {
      debugPrint('✅ Google Sign-In available (Web platform)');
      return true;
    }

    // Return cached result if checked within last 30 seconds
    if (_cachedGoogleAvailability != null &&
        _lastCheckTime != null &&
        DateTime.now().difference(_lastCheckTime!) < const Duration(seconds: 30)) {
      return _cachedGoogleAvailability!;
    }

    try {
      // Check if we can resolve Google accounts domain
      await InternetAddress.lookup('accounts.google.com')
          .timeout(const Duration(seconds: 5));
      _cachedGoogleAvailability = true;
      _lastCheckTime = DateTime.now();
      debugPrint('✅ Google Sign-In is available');
      return true;
    } catch (e) {
      _cachedGoogleAvailability = false;
      _lastCheckTime = DateTime.now();
      debugPrint('⚠️ Google Sign-In unavailable: Cannot reach accounts.google.com');
      debugPrint('   This is likely due to:');
      debugPrint('   - Network firewall blocking Google services');
      debugPrint('   - Geographic restrictions');
      debugPrint('   - VPN or proxy blocking');
      debugPrint('   → Try: Use mobile data, disable VPN, or use OTP login');
      return false;
    }
  }

  /// Clear the cached Google availability check (for manual refresh)
  static void clearCache() {
    _cachedGoogleAvailability = null;
    _lastCheckTime = null;
  }
}
