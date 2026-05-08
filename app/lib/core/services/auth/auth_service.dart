import 'dart:async';
import '../api_service.dart';
import '../app_preferences.dart';
import 'package:devconnect/core/constants/app_constants.dart';

/// Authentication state
enum AuthStatus {
  unknown,
  authenticated,
  unauthenticated,
}

/// Auth state class
class AuthState {
  final AuthStatus status;
  final String? userId;
  final String? token;
  final String? error;
  final bool isRefreshing;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.userId,
    this.token,
    this.error,
    this.isRefreshing = false,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.unknown;

  AuthState copyWith({
    AuthStatus? status,
    String? userId,
    String? token,
    String? error,
    bool? isRefreshing,
  }) {
    return AuthState(
      status: status ?? this.status,
      userId: userId ?? this.userId,
      token: token ?? this.token,
      error: error,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

/// AuthService handles authentication with token refresh
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final ApiService _api = ApiService.instance;
  final AppPreferences? _prefs = _tryGetPrefs();

  String? _token;
  String? _refreshToken;
  Timer? _refreshTimer;

  String? get token => _token;
  bool get isAuthenticated => _token != null;

  static AppPreferences? _tryGetPrefs() {
    try {
      return AppPreferences.instance;
    } catch (_) {
      return null;
    }
  }

  /// Initialize auth service with stored token
  Future<AuthState> initialize() async {
    final prefs = _prefs;
    if (prefs == null) {
      return const AuthState(status: AuthStatus.unauthenticated);
    }

    _token = prefs.token;
    _refreshToken = prefs.refreshToken;

    if (_token != null) {
      _api.setToken(_token);
      return AuthState(
        status: AuthStatus.authenticated,
        userId: prefs.user?['id'],
        token: _token,
      );
    }

    return const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Login with email and password
  Future<AuthState> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _api.post(
        AppConstants.apiAuthLogin,
        {'email': email, 'password': password},
      );

      _token = response['token'] as String?;
      _refreshToken = response['refreshToken'] as String?;

      if (_token != null) {
        _api.setToken(_token);
        await _saveTokens();

        return AuthState(
          status: AuthStatus.authenticated,
          userId: response['userId'] as String?,
          token: _token,
        );
      }

      return const AuthState(
        status: AuthStatus.unauthenticated,
        error: 'Invalid response from server',
      );
    } on ApiException catch (e) {
      return AuthState(
        status: AuthStatus.unauthenticated,
        error: e.message,
      );
    } catch (e) {
      return AuthState(
        status: AuthStatus.unauthenticated,
        error: e.toString(),
      );
    }
  }

  /// Register new user
  Future<AuthState> register({
    required String email,
    required String password,
    required String username,
    required String displayName,
  }) async {
    try {
      final response = await _api.post(
        AppConstants.apiAuthRegister,
        {
          'email': email,
          'password': password,
          'username': username,
          'displayName': displayName,
        },
      );

      _token = response['token'] as String?;
      _refreshToken = response['refreshToken'] as String?;

      if (_token != null) {
        _api.setToken(_token);
        await _saveTokens();

        return AuthState(
          status: AuthStatus.authenticated,
          userId: response['userId'] as String?,
          token: _token,
        );
      }

      return const AuthState(
        status: AuthStatus.unauthenticated,
        error: 'Registration failed',
      );
    } on ApiException catch (e) {
      return AuthState(
        status: AuthStatus.unauthenticated,
        error: e.message,
      );
    } catch (e) {
      return AuthState(
        status: AuthStatus.unauthenticated,
        error: e.toString(),
      );
    }
  }

  /// Refresh token before it expires
  Future<bool> refreshToken() async {
    if (_refreshToken == null) return false;

    try {
      final response = await _api.post(
        AppConstants.apiAuthRefresh,
        {'refreshToken': _refreshToken},
      );

      _token = response['token'] as String?;
      if (_token != null) {
        _api.setToken(_token);
        await _saveTokens();
        _scheduleTokenRefresh();
        return true;
      }
      return false;
    } catch (_) {
      await logout();
      return false;
    }
  }

  /// Schedule token refresh before expiry
  void _scheduleTokenRefresh() {
    _refreshTimer?.cancel();
    // Refresh 5 minutes before token expires (assuming 30min expiry)
    _refreshTimer = Timer(const Duration(minutes: 25), () {
      refreshToken();
    });
  }

  /// Logout and clear all tokens
  Future<void> logout() async {
    _refreshTimer?.cancel();
    _token = null;
    _refreshToken = null;
    _api.setToken(null);

    final prefs = _prefs;
    if (prefs != null) {
      await prefs.clearAuth();
    }
  }

  /// Save tokens to secure storage
  Future<void> _saveTokens() async {
    final prefs = _prefs;
    if (prefs != null && _token != null) {
      await prefs.saveToken(_token!);
      if (_refreshToken != null) {
        await prefs.saveRefreshToken(_refreshToken!);
      }
    }
  }

  /// Handle token expiration
  Future<void> handleTokenExpired() async {
    final refreshed = await refreshToken();
    if (!refreshed) {
      await logout();
    }
  }
}
