import 'package:flutter_test/flutter_test.dart';
import 'package:devconnect/core/services/api_service.dart';

void main() {
  late ApiService apiService;

  setUp(() {
    apiService = ApiService.instance;
    apiService.setToken(null);
  });

  group('ApiService - Token Management', () {
    test('setToken() updates the auth token', () {
      apiService.setToken('test_token_123');
      expect(apiService.token, 'test_token_123');
    });

    test('setToken() accepts null token', () {
      apiService.setToken('test_token');
      apiService.setToken(null);
      expect(apiService.token, isNull);
    });

    test('token persists after multiple setToken calls', () {
      apiService.setToken('first_token');
      apiService.setToken('second_token');
      expect(apiService.token, 'second_token');
    });

    test('isAuthenticated returns true when token exists', () {
      apiService.setToken('valid_token');
      expect(apiService.isAuthenticated, isTrue);
    });

    test('isAuthenticated returns false when token is null', () {
      apiService.setToken(null);
      expect(apiService.isAuthenticated, isFalse);
    });
  });

  group('ApiService - API Exception', () {
    test('ApiException has correct status code and message', () {
      final exception = ApiException(404, 'Resource not found');
      expect(exception.statusCode, 404);
      expect(exception.message, 'Resource not found');
    });

    test('ApiException toString() formats correctly', () {
      final exception = ApiException(500, 'Server error');
      expect(exception.toString(), 'ApiException(500): Server error');
    });

    test('ApiException handles zero status code', () {
      final exception = ApiException(0, 'Unknown error');
      expect(exception.statusCode, 0);
      expect(exception.message, 'Unknown error');
    });

    test('ApiException isAuthError returns true for 401', () {
      final exception = ApiException(401, 'Unauthorized');
      expect(exception.isAuthError, isTrue);
    });

    test('ApiException isAuthError returns false for other codes', () {
      final exception = ApiException(404, 'Not found');
      expect(exception.isAuthError, isFalse);
    });

    test('ApiException isNetworkError returns true for code 0', () {
      final exception = ApiException(0, 'Network error');
      expect(exception.isNetworkError, isTrue);
    });

    test('ApiException isServerError returns true for 5xx', () {
      final exception = ApiException(500, 'Server error');
      expect(exception.isServerError, isTrue);
    });

    test('ApiException isServerError returns false for 4xx', () {
      final exception = ApiException(404, 'Not found');
      expect(exception.isServerError, isFalse);
    });
  });
}
