import 'package:flutter/foundation.dart';

import '../services/api_client.dart';
import '../services/api_exception.dart';
import '../services/token_store.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._api, this._tokens) {
    // Listen for 401s that couldn't be recovered (refresh token expired)
    _api.addUnauthorizedListener(_onForceLogout);
  }

  final ApiClient _api;
  final TokenStore _tokens;

  bool loading = false;
  bool authenticated = false;
  String? error;
  Map<String, dynamic>? user;

  @override
  void dispose() {
    _api.removeUnauthorizedListener(_onForceLogout);
    super.dispose();
  }

  // Called by ApiClient when token refresh fails — hard logout
  void _onForceLogout() {
    authenticated = false;
    user = null;
    error = 'Your session has expired. Please log in again.';
    notifyListeners();
  }

  /// Bootstrap: restore auth state from stored tokens on app start.
  Future<void> bootstrap() async {
    final token = await _tokens.access;
    if (token == null) {
      authenticated = false;
      notifyListeners();
      return;
    }
    // Verify token is still valid by loading the current user
    try {
      await loadMe();
      authenticated = true;
    } on ApiException catch (e) {
      if (e.type == ApiErrorType.unauthorized) {
        // Token stale → clear and go to login
        await _tokens.clear();
        authenticated = false;
      } else {
        // Network issue — assume still authenticated, will fail gracefully later
        authenticated = true;
      }
    } catch (_) {
      authenticated = false;
    }
    notifyListeners();
  }

  /// Authenticate with username + password.
  Future<bool> login(String username, String password) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final data = await _api.post(
        '/auth/login/',
        data: {'username': username, 'password': password},
      );
      await _tokens.save(
        data['access'] as String,
        data['refresh'] as String,
      );
      authenticated = true;
      await loadMe();
      return true;
    } on ApiException catch (e) {
      error = e.type == ApiErrorType.unauthorized || e.type == ApiErrorType.badRequest
          ? 'Invalid username or password.'
          : e.message;
      return false;
    } catch (e) {
      error = 'Unexpected error. Please try again.';
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// Fetch the current user from /auth/me/.
  Future<void> loadMe() async {
    final data = await _api.get('/auth/me/');
    user = Map<String, dynamic>.from(data as Map);
    notifyListeners();
  }

  /// Log out the current user and clear tokens.
  Future<void> logout() async {
    final refresh = await _tokens.refresh;
    if (refresh != null) {
      try {
        await _api.post('/auth/logout/', data: {'refresh': refresh});
      } catch (_) {
        // Best-effort — ignore errors on logout
      }
    }
    await _tokens.clear();
    authenticated = false;
    user = null;
    error = null;
    notifyListeners();
  }
}
