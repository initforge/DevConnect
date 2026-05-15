import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

import '../constants/app_constants.dart';
import '../localization/app_strings.dart';
import 'websocket_service.dart';

/// Token refresh callback type
typedef TokenRefreshCallback = Future<bool> Function();

/// ApiService — Centralized API client for DevConnect
///
/// Handles all HTTP requests with:
/// - Token authentication
/// - Error handling
/// - Response type handling (both List and Map responses)
/// - Token refresh on 401
class ApiService {
  static final ApiService _instance = ApiService._();
  static ApiService get instance => _instance;

  String? _token;
  TokenRefreshCallback? _onTokenRefreshNeeded;
  bool _isRefreshing = false;
  final List<_PendingRequest> _pendingRequests = [];

  ApiService._() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: AppConstants.apiConnectTimeout,
        receiveTimeout: AppConstants.apiReceiveTimeout,
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // Add interceptors for auth and logging
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Add auth header if token exists
          if (_token != null) {
            options.headers['Authorization'] = 'Bearer $_token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final statusCode = error.response?.statusCode;
          final skipRetry = error.requestOptions.extra['skipAuthRetry'] == true;

          if (statusCode != 401 || skipRetry) {
            handler.next(error);
            return;
          }

          _pendingRequests.add(
            _PendingRequest(error.requestOptions, handler, error),
          );

          if (_isRefreshing) {
            return;
          }

          _isRefreshing = true;
          try {
            final refreshed =
                _onTokenRefreshNeeded != null
                    ? await _onTokenRefreshNeeded!()
                    : false;

            if (!refreshed || _token == null) {
              _token = null;
              await _failPendingRequests();
              return;
            }

            await _processPendingRequests();
          } catch (_) {
            _token = null;
            await _failPendingRequests();
          } finally {
            _isRefreshing = false;
          }
        },
      ),
    );

    // Add logging interceptor in debug mode
    _dio.interceptors.add(
      LogInterceptor(requestBody: true, responseBody: true, error: true),
    );
  }

  late final Dio _dio;

  /// Set callback for token refresh
  void setTokenRefreshCallback(TokenRefreshCallback callback) {
    _onTokenRefreshNeeded = callback;
  }

  /// Set the authentication token
  void setToken(String? token) {
    _token = token;
    if (token == null) {
      WebSocketService.instance.disconnect();
    } else {
      WebSocketService.instance.connect(token: token);
    }
  }

  String? get token => _token;

  bool get isAuthenticated => _token != null;

  /// Get generic dynamic response - handles both List and Map
  /// Use this when the response structure is unknown or varies
  Future<dynamic> getAny(
    String path, {
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParams,
        options: Options(headers: _authHeaders),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get response as List - throws if response is not a List
  Future<List<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParams,
        options: Options(headers: _authHeaders),
      );

      // Handle different response formats
      final data = response.data;
      if (data == null) return [];
      if (data is List) return data;
      if (data is Map<String, dynamic>) {
        // Check for data array in common wrapper formats
        if (data.containsKey('data') && data['data'] is List) {
          return data['data'] as List;
        }
        if (data.containsKey('items') && data['items'] is List) {
          return data['items'] as List;
        }
        // Return empty list if no array found
        return [];
      }
      return [];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get response as Map - throws if response is not a Map
  Future<Map<String, dynamic>> getObject(
    String path, {
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParams,
        options: Options(headers: _authHeaders),
      );

      // Handle different response formats
      final data = response.data;
      if (data == null) return {};
      if (data is Map<String, dynamic>) return data;
      if (data is List && data.isNotEmpty) {
        // If response is a list with one item, return that item
        if (data.length == 1 && data[0] is Map<String, dynamic>) {
          return data[0] as Map<String, dynamic>;
        }
        throw ApiException(
          0,
          AppStrings.current().t('errors.expectedObjectButGotList'),
        );
      }
      return {};
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// POST request - returns Map response
  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body, {
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: body,
        queryParameters: queryParams,
        options: Options(headers: _authHeaders),
      );

      final data = response.data;
      if (data is Map<String, dynamic>) return data;
      if (data is List && data.isNotEmpty && data[0] is Map<String, dynamic>) {
        return data[0] as Map<String, dynamic>;
      }
      return {};
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// PUT request - returns Map response
  Future<Map<String, dynamic>> put(
    String path,
    Map<String, dynamic> body, {
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: body,
        queryParameters: queryParams,
        options: Options(headers: _authHeaders),
      );

      final data = response.data;
      if (data is Map<String, dynamic>) return data;
      return {};
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// PATCH request - returns Map response
  Future<Map<String, dynamic>> patch(
    String path,
    Map<String, dynamic> body, {
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      final response = await _dio.patch(
        path,
        data: body,
        queryParameters: queryParams,
        options: Options(headers: _authHeaders),
      );

      final data = response.data;
      if (data is Map<String, dynamic>) return data;
      return {};
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// DELETE request - returns Map response
  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        queryParameters: queryParams,
        options: Options(headers: _authHeaders),
      );

      final data = response.data;
      if (data is Map<String, dynamic>) return data;
      return {};
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Stream SSE response as a stream of String chunks.
  /// Returns a broadcast stream that emits each SSE data event as it arrives.
  Stream<String> streamSse(String path, {Map<String, dynamic>? body}) {
    final controller = StreamController<String>.broadcast();

    _dio
        .post(
          path,
          data: body,
          options: Options(
            headers: _authHeaders,
            responseType: ResponseType.stream,
            followRedirects: false,
          ),
        )
        .then((response) async {
          final stream = response.data as ResponseBody;
          final buffer = StringBuffer();

          await for (final List<int> bytes in stream.stream) {
            final chunk = utf8.decode(bytes);
            for (final line in chunk.split('\n')) {
              if (line.startsWith('data: ')) {
                final data = line.substring(6);
                if (data == '[DONE]') {
                  await controller.close();
                  return;
                }
                buffer.write(data);
                controller.add(buffer.toString());
              }
            }
          }
          if (!controller.isClosed) {
            await controller.close();
          }
        })
        .catchError((error) {
          if (!controller.isClosed) {
            controller.addError(error);
            controller.close();
          }
        });

    return controller.stream;
  }

  /// Upload file with progress tracking
  Future<Map<String, dynamic>> uploadFile(
    String path, {
    required String filePath,
    required String fieldName,
    Map<String, dynamic>? additionalFields,
    void Function(int, int)? onSendProgress,
  }) async {
    try {
      final formData = FormData.fromMap({
        fieldName: await MultipartFile.fromFile(filePath),
        ...?additionalFields,
      });

      final response = await _dio.post(
        path,
        data: formData,
        onSendProgress: onSendProgress,
        options: Options(
          headers: {..._authHeaders, 'Content-Type': 'multipart/form-data'},
        ),
      );

      final data = response.data;
      if (data is Map<String, dynamic>) return data;
      return {};
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Upload file from bytes (works on all platforms including web)
  Future<Map<String, dynamic>> uploadFileBytes(
    String path, {
    required List<int> bytes,
    required String fileName,
    String fieldName = 'file',
    Map<String, dynamic>? additionalFields,
    void Function(int, int)? onSendProgress,
  }) async {
    try {
      // Detect content type from file extension
      MediaType? contentType;
      final ext = fileName.split('.').last.toLowerCase();
      const mimeMap = {
        'jpg': 'image/jpeg',
        'jpeg': 'image/jpeg',
        'png': 'image/png',
        'gif': 'image/gif',
        'webp': 'image/webp',
        'bmp': 'image/bmp',
      };
      if (mimeMap.containsKey(ext)) {
        final parts = mimeMap[ext]!.split('/');
        contentType = MediaType(parts[0], parts[1]);
      }

      final formData = FormData.fromMap({
        fieldName: MultipartFile.fromBytes(
          bytes,
          filename: fileName,
          contentType: contentType,
        ),
        ...?additionalFields,
      });

      final response = await _dio.post(
        path,
        data: formData,
        onSendProgress: onSendProgress,
        options: Options(
          headers: {..._authHeaders, 'Content-Type': 'multipart/form-data'},
        ),
      );

      final data = response.data;
      if (data is Map<String, dynamic>) return data;
      return {};
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> _processPendingRequests() async {
    while (_pendingRequests.isNotEmpty) {
      final pendingRequests = List<_PendingRequest>.from(_pendingRequests);
      _pendingRequests.clear();

      for (final pending in pendingRequests) {
        final options = pending.requestOptions;
        options.headers['Authorization'] = 'Bearer $_token';
        options.extra['skipAuthRetry'] = true;

        try {
          final response = await _dio.fetch(options);
          pending.handler.resolve(response);
        } on DioException catch (error) {
          pending.handler.next(error);
        } catch (error) {
          pending.handler.next(
            DioException(requestOptions: options, error: error),
          );
        }
      }
    }
  }

  Future<void> _failPendingRequests() async {
    if (_pendingRequests.isEmpty) return;

    final pendingRequests = List<_PendingRequest>.from(_pendingRequests);
    _pendingRequests.clear();
    for (final pending in pendingRequests) {
      pending.handler.next(pending.error);
    }
  }

  Map<String, String> get _authHeaders =>
      _token != null ? {'Authorization': 'Bearer $_token'} : {};

  ApiException _handleError(DioException e) {
    final strings = AppStrings.current();
    String message;
    int statusCode = e.response?.statusCode ?? 0;

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        message = strings.t('errors.connectionTimeout');
        break;
      case DioExceptionType.sendTimeout:
        message = strings.t('errors.sendTimeout');
        break;
      case DioExceptionType.receiveTimeout:
        message = strings.t('errors.receiveTimeout');
        break;
      case DioExceptionType.connectionError:
        message = strings.t('errors.connectionError');
        break;
      case DioExceptionType.badCertificate:
        message = strings.t('errors.badCertificate');
        break;
      case DioExceptionType.cancel:
        message = strings.t('errors.cancelled');
        break;
      case DioExceptionType.badResponse:
        message = _parseErrorMessage(e.response?.data, statusCode);
        break;
      case DioExceptionType.unknown:
        message = e.message ?? strings.t('errors.unknown');
    }

    return ApiException(statusCode, message);
  }

  String _parseErrorMessage(dynamic data, int statusCode) {
    final strings = AppStrings.current();
    // Try to extract error message from response
    if (data is Map<String, dynamic>) {
      if (data.containsKey('error')) {
        return data['error'].toString();
      }
      if (data.containsKey('message')) {
        return data['message'].toString();
      }
      if (data.containsKey('msg')) {
        return data['msg'].toString();
      }
    }

    // Fallback to status code based messages
    switch (statusCode) {
      case 400:
        return strings.t('errors.invalidRequest');
      case 401:
        return strings.t('errors.sessionExpired');
      case 403:
        return strings.t('errors.permissionDenied');
      case 404:
        return strings.t('errors.notFound');
      case 409:
        return strings.t('errors.conflict');
      case 422:
        return strings.t('errors.invalidData');
      case 429:
        return strings.t('errors.tooManyRequests');
      case 500:
        return strings.t('errors.serverError');
      case 502:
      case 503:
      case 504:
        return strings.t('errors.serviceUnavailable');
      default:
        return strings.t('errors.generic');
    }
  }
}

/// Internal class for tracking pending requests during token refresh
class _PendingRequest {
  final RequestOptions requestOptions;
  final ErrorInterceptorHandler handler;
  final DioException error;

  _PendingRequest(this.requestOptions, this.handler, this.error);
}

/// Custom exception for API errors
class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';

  /// Check if this is an authentication error
  bool get isAuthError => statusCode == 401;

  /// Check if this is a network error
  bool get isNetworkError => statusCode == 0;

  /// Check if this is a server error
  bool get isServerError => statusCode >= 500;
}
