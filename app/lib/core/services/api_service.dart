import 'package:dio/dio.dart';

import '../constants/app_constants.dart';

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
  // TODO: Implement pending requests queue for token refresh
  // ignore: unused_field
  final List<_PendingRequest> _pendingRequests = [];

  ApiService._() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: AppConstants.apiConnectTimeout,
      receiveTimeout: AppConstants.apiReceiveTimeout,
      headers: {'Content-Type': 'application/json'},
    ));
    
    // Add interceptors for auth and logging
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // Add auth header if token exists
        if (_token != null) {
          options.headers['Authorization'] = 'Bearer $_token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        // Handle 401 errors - token expired
        if (error.response?.statusCode == 401 && !_isRefreshing) {
          _isRefreshing = true;
          
          // Try to refresh token
          if (_onTokenRefreshNeeded != null) {
            final refreshed = await _onTokenRefreshNeeded!();
            if (refreshed) {
              // Retry the original request
              final opts = error.requestOptions;
              opts.headers['Authorization'] = 'Bearer $_token';
              try {
                final response = await _dio.fetch(opts);
                _isRefreshing = false;
                handler.resolve(response);
                return;
              } catch (e) {
                _isRefreshing = false;
                handler.next(error);
                return;
              }
            }
          }
          
          _isRefreshing = false;
          _token = null;
        }
        handler.next(error);
      },
    ));
    
    // Add logging interceptor in debug mode
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
    ));
  }

  late final Dio _dio;

  /// Set callback for token refresh
  void setTokenRefreshCallback(TokenRefreshCallback callback) {
    _onTokenRefreshNeeded = callback;
  }

  /// Set the authentication token
  void setToken(String? token) {
    _token = token;
  }

  String? get token => _token;

  bool get isAuthenticated => _token != null;

  /// Get generic dynamic response - handles both List and Map
  /// Use this when the response structure is unknown or varies
  Future<dynamic> getAny(String path, {Map<String, dynamic>? queryParams}) async {
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
  Future<List<dynamic>> get(String path, {Map<String, dynamic>? queryParams}) async {
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
  Future<Map<String, dynamic>> getObject(String path, {Map<String, dynamic>? queryParams}) async {
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
        throw ApiException(0, 'Expected object but got list');
      }
      return {};
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// POST request - returns Map response
  Future<Map<String, dynamic>> post(
    String path, 
    Map<String, dynamic> body, 
    {Map<String, dynamic>? queryParams}
  ) async {
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
    Map<String, dynamic> body, 
    {Map<String, dynamic>? queryParams}
  ) async {
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
    Map<String, dynamic> body, 
    {Map<String, dynamic>? queryParams}
  ) async {
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
  Future<Map<String, dynamic>> delete(String path, {Map<String, dynamic>? queryParams}) async {
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
        options: Options(headers: {
          ..._authHeaders,
          'Content-Type': 'multipart/form-data',
        }),
      );
      
      final data = response.data;
      if (data is Map<String, dynamic>) return data;
      return {};
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Map<String, String> get _authHeaders => 
      _token != null ? {'Authorization': 'Bearer $_token'} : {};

  ApiException _handleError(DioException e) {
    String message;
    int statusCode = e.response?.statusCode ?? 0;

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        message = 'Kết nối quá hạn. Vui lòng kiểm tra mạng.';
        break;
      case DioExceptionType.sendTimeout:
        message = 'Gửi yêu cầu quá hạn. Vui lòng thử lại.';
        break;
      case DioExceptionType.receiveTimeout:
        message = 'Nhận phản hồi quá hạn. Vui lòng thử lại.';
        break;
      case DioExceptionType.connectionError:
        message = 'Không thể kết nối. Vui lòng kiểm tra mạng.';
        break;
      case DioExceptionType.badCertificate:
        message = 'Chứng chỉ bảo mật không hợp lệ.';
        break;
      case DioExceptionType.cancel:
        message = 'Yêu cầu bị hủy.';
        break;
      case DioExceptionType.badResponse:
        message = _parseErrorMessage(e.response?.data, statusCode);
        break;
      case DioExceptionType.unknown:
        message = e.message ?? 'Đã xảy ra lỗi không xác định.';
    }

    return ApiException(statusCode, message);
  }

  String _parseErrorMessage(dynamic data, int statusCode) {
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
        return 'Yêu cầu không hợp lệ.';
      case 401:
        return 'Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.';
      case 403:
        return 'Bạn không có quyền thực hiện thao tác này.';
      case 404:
        return 'Không tìm thấy dữ liệu.';
      case 409:
        return 'Xung đột dữ liệu. Vui lòng thử lại.';
      case 422:
        return 'Dữ liệu không hợp lệ.';
      case 429:
        return 'Quá nhiều yêu cầu. Vui lòng chờ và thử lại.';
      case 500:
        return 'Lỗi máy chủ. Vui lòng thử lại sau.';
      case 502:
      case 503:
      case 504:
        return 'Dịch vụ tạm thời không khả dụng.';
      default:
        return 'Đã xảy ra lỗi. Vui lòng thử lại.';
    }
  }
}

/// Internal class for tracking pending requests during token refresh
class _PendingRequest {
  final RequestOptions requestOptions;
  final ErrorInterceptorHandler handler;

  _PendingRequest(this.requestOptions, this.handler);
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
