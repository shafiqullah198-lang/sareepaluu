import 'package:flutter/foundation.dart';
import 'dart:io';

/// Centralized API configuration.
///
/// URL resolution priority:
///   1. `--dart-define=API_BASE_URL=...` → always wins
///   2. Platform-aware auto-detection in debug mode
///   3. Fallback to localhost (web / desktop)
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
      return 'http://$_defineLocalIp:$_port$_prefix';
    }

    // 3. Auto-detect by platform (only available in debug/profile builds)
    if (kDebugMode || kProfileMode) {
      if (kIsWeb) {
        // Chrome / Flutter Web → same origin
        return 'http://localhost:$_port$_prefix';
      }
      try {
        if (Platform.isAndroid) {
          // Real Android device → host machine LAN IP (192.168.18.51)
          return 'http://192.168.18.51:$_port$_prefix';
        }
        if (Platform.isIOS) {
          // iOS simulator loopback → host machine
          return 'http://localhost:$_port$_prefix';
        }
        if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
          // Desktop (development)
          return 'http://127.0.0.1:$_port$_prefix';
        }
      } catch (_) {
        // Platform not available (e.g., web)
      }
    }

    // 4. Final fallback
    return 'http://127.0.0.1:$_port$_prefix';
  }

  // ── Diagnostics ───────────────────────────────────────────────────────────

  /// Human-readable name of the current target for logging.
  static String get effectivePlatform {
    if (_defineApiUrl.isNotEmpty) return 'custom (dart-define)';
    if (_defineLocalIp.isNotEmpty) return 'physical device ($apiBaseUrl)';
    if (kIsWeb) return 'web (Chrome/browser)';
    try {
      if (Platform.isAndroid) return 'Android real device (192.168.18.51)';
      if (Platform.isIOS) return 'iOS simulator';
      if (Platform.isWindows) return 'Windows desktop';
      if (Platform.isLinux) return 'Linux desktop';
      if (Platform.isMacOS) return 'macOS desktop';
    } catch (_) {}
    return 'unknown';
  }

  static bool get isDebug => kDebugMode;
}
