import 'dart:io';

import 'package:flutter/foundation.dart';

/// Centralized API configuration.
///
/// URL resolution priority:
///   1. `--dart-define=API_BASE_URL=...` -> normalized to production host
///   2. Platform-aware default -> production host
///   3. Final fallback -> production host
class AppConfig {
  AppConfig._();

  static const String _defineApiUrl = String.fromEnvironment('API_BASE_URL');
  static const String _defineLocalIp = String.fromEnvironment('LOCAL_IP');

  static const String _productionOrigin = 'https://sareebypaalu.com';
  static const String _productionHost = 'sareebypaalu.com';
  static const String _prefix = '/api/v1';

  /// The resolved API base URL for the current platform / build mode.
  static String get apiBaseUrl {
    if (_defineApiUrl.isNotEmpty) {
      return _normalizeApiBaseUrl(_defineApiUrl);
    }

    if (_defineLocalIp.isNotEmpty) {
      return _productionBaseUrl;
    }

    if (kDebugMode || kProfileMode) {
      if (kIsWeb) {
        return _productionBaseUrl;
      }

      try {
        if (Platform.isAndroid ||
            Platform.isIOS ||
            Platform.isWindows ||
            Platform.isLinux ||
            Platform.isMacOS) {
          return _productionBaseUrl;
        }
      } catch (_) {
        // Platform not available (for example, web).
      }
    }

    return _productionBaseUrl;
  }

  static String get _productionBaseUrl => '$_productionOrigin$_prefix';

  static String _normalizeApiBaseUrl(String rawValue) {
    final trimmed = rawValue.trim();
    if (trimmed.isEmpty) return _productionBaseUrl;

    final parsed = Uri.tryParse(trimmed);
    if (parsed == null) return _productionBaseUrl;

    final path = _normalizedApiPath(parsed.path);
    return Uri(
      scheme: 'https',
      host: _productionHost,
      path: path,
    ).toString();
  }

  static String _normalizedApiPath(String path) {
    final trimmed = path.trim();
    if (trimmed.isEmpty || trimmed == '/') return _prefix;

    final normalized = trimmed.startsWith('/') ? trimmed : '/$trimmed';

    if (normalized == '/api') return '/api';
    if (normalized.startsWith('/api/')) return normalized.replaceAll(RegExp(r'/+$'), '');

    return _prefix;
  }

  /// Human-readable name of the current target for logging.
  static String get effectivePlatform {
    if (_defineApiUrl.isNotEmpty) return 'custom (normalized to production)';
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
