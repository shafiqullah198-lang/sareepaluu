import 'package:flutter/foundation.dart';
import 'dart:io';

/// Centralized API configuration.
///
/// URL resolution priority:
///   1. `--dart-define=API_BASE_URL=...` → always wins
///   2. Platform-aware auto-detection (all platforms use production)
///   3. Fallback to production domain
///
/// For physical device testing, run with:
///   flutter run --dart-define=LOCAL_IP=192.168.18.51
class AppConfig {
  AppConfig._();

  // ── dart-define overrides ────────────────────────────────────────────────
  static const String _defineApiUrl = String.fromEnvironment('API_BASE_URL');
  static const String _defineLocalIp = String.fromEnvironment('LOCAL_IP');

  // ── Default port ─────────────────────────────────────────────────────────
  static const int _port = 8000;
  static const String _prefix = '/api/v1';

  // ── Resolved base URL ────────────────────────────────────────────────────

  /// The resolved API base URL for the current platform / build mode.
  static String get apiBaseUrl {
    // 1. Explicit override always wins
    if (_defineApiUrl.isNotEmpty) return _defineApiUrl;

    // 2. Physical device override
    if (_defineLocalIp.isNotEmpty) {
      return 'https://sareebypaalu.com$_prefix';
    }

    // 3. Auto-detect by platform (only available in debug/profile builds)
    if (kDebugMode || kProfileMode) {
      if (kIsWeb) {
        // Chrome / Flutter Web → production domain
        return 'https://sareebypaalu.com$_prefix';
      }
      try {
        if (Platform.isAndroid) {
          // Real Android device → production domain
          return 'https://sareebypaalu.com$_prefix';
        }
        if (Platform.isIOS) {
          // iOS simulator → production domain
          return 'https://sareebypaalu.com$_prefix';
        }
        if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
          // Desktop → production domain
          return 'https://sareebypaalu.com$_prefix';
        }
      } catch (_) {
        // Platform not available (e.g., web)
      }
    }

    // 4. Final fallback to production domain
    return 'https://sareebypaalu.com$_prefix';
  }

  // ── Diagnostics ───────────────────────────────────────────────────────────

  /// Human-readable name of the current target for logging.
  static String get effectivePlatform {
    if (_defineApiUrl.isNotEmpty) return 'custom (dart-define)';
    if (_defineLocalIp.isNotEmpty) return 'physical device (production)';
    if (kIsWeb) return 'web (production)';
    try {
      if (Platform.isAndroid) return 'Android (production)';
      if (Platform.isIOS) return 'iOS (production)';
      if (Platform.isWindows) return 'Windows (production)';
      if (Platform.isLinux) return 'Linux (production)';
      if (Platform.isMacOS) return 'macOS (production)';
    } catch (_) {}
    return 'unknown';
  }

  static bool get isDebug => kDebugMode;
}
