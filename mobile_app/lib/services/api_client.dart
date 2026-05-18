import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/app_config.dart';
import 'api_exception.dart';
import 'token_store.dart';

class ApiClient {
  ApiClient(this._tokenStore) {
    if (kDebugMode) {
      debugPrint('[ApiClient] Base URL → ${AppConfig.apiBaseUrl}');
      debugPrint('[ApiClient] Platform   → ${AppConfig.effectivePlatform}');
    }

    dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 60),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Full request/response logging in debug mode
    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          requestHeader: true,
          requestBody: true,
          responseHeader: false,
          responseBody: true,
          error: true,
          logPrint: (obj) => debugPrint('[Dio] $obj'),
        ),
      );
    }

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onError: _onError,
      ),
    );
  }

  final TokenStore _tokenStore;
  late final Dio dio;

  // Notified when a 401 cannot be recovered (token expired, refresh failed).
  // Listeners (e.g. AuthProvider) can redirect to login.
  final List<VoidCallback> _unauthorizedListeners = [];

  void addUnauthorizedListener(VoidCallback callback) {
    _unauthorizedListeners.add(callback);
  }

  void removeUnauthorizedListener(VoidCallback callback) {
    _unauthorizedListeners.remove(callback);
  }

  void _notifyUnauthorized() {
    for (final cb in _unauthorizedListeners) {
      cb();
    }
  }

  // ── Interceptors ─────────────────────────────────────────────────────────

  Future<void> _onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _tokenStore.access;
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  Future<void> _onError(
      DioException error, ErrorInterceptorHandler handler) async {
    // 401 → attempt silent token refresh once, then give up
    if (error.response?.statusCode == 401 &&
        !error.requestOptions.path.contains('/auth/refresh/') &&
        !error.requestOptions.path.contains('/auth/login/')) {
      final refreshed = await _refreshToken();
      if (refreshed) {
        try {
          // Retry the original request with the new token
          final token = await _tokenStore.access;
          error.requestOptions.headers['Authorization'] = 'Bearer $token';
          final retry = await dio.fetch(error.requestOptions);
          return handler.resolve(retry);
        } catch (retryError) {
          // Retry failed — fall through to error handling
        }
      }
      // Refresh failed — clear tokens and notify
      await _tokenStore.clear();
      _notifyUnauthorized();
    }

    // Convert DioException → ApiException for clean UI handling
    handler.next(
      DioException(
        requestOptions: error.requestOptions,
        response: error.response,
        type: error.type,
        error: ApiException.fromDioException(error),
        message: ApiException.fromDioException(error).message,
      ),
    );
  }

  // ── Token refresh ─────────────────────────────────────────────────────────

  Future<bool> _refreshToken() async {
    final refresh = await _tokenStore.refresh;
    if (refresh == null) return false;
    try {
      final res = await Dio(
        BaseOptions(
          baseUrl: AppConfig.apiBaseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      ).post('/auth/refresh/', data: {'refresh': refresh});
      final newAccess = res.data['access'] as String?;
      if (newAccess == null) return false;
      await _tokenStore.saveAccess(newAccess);
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('[ApiClient] Token refresh failed: $e');
      return false;
    }
  }

  // ── Convenience wrappers ──────────────────────────────────────────────────

  /// Performs a GET and returns the response data, re-throwing as [ApiException].
  Future<dynamic> get(String path, {Map<String, dynamic>? params}) async {
    try {
      final res = await dio.get(path, queryParameters: params);
      return res.data;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Performs a POST and returns the response data, re-throwing as [ApiException].
  Future<dynamic> post(String path, {dynamic data}) async {
    try {
      final res = await dio.post(path, data: data);
      return res.data;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Performs a PATCH and returns the response data, re-throwing as [ApiException].
  Future<dynamic> patch(String path, {dynamic data}) async {
    try {
      final res = await dio.patch(path, data: data);
      return res.data;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Performs a DELETE, re-throwing as [ApiException].
  Future<dynamic> delete(String path) async {
    try {
      final res = await dio.delete(path);
      return res.data;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
