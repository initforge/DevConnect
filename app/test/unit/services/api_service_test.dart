import 'package:flutter_test/flutter_test.dart';
import 'package:devconnect/core/errors/app_exceptions.dart';
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
      const exception = NotFoundException('Resource not found');
      expect(exception.statusCode, 404);
    });

    test('ApiException toString() formats correctly', () {
      const exception = ServerException(500);
      expect(exception.toString(), contains('500'));
    });

    test('ApiException handles zero status code', () {
      const exception = NetworkException('Unknown error', 0);
      expect(exception.statusCode, 0);
    });

    test('ApiException isAuthError returns true for 401', () {
      const exception = SessionExpiredException();
      expect(exception.statusCode, 401);
    });

    test('ApiException isAuthError returns false for other codes', () {
      const exception = NotFoundException();
      expect(exception.statusCode, 404);
    });

    test('ApiException isNetworkError returns true for code 0', () {
      const exception = NetworkException('Network error', 0);
      expect(exception.statusCode, 0);
    });

    test('ApiException isServerError returns true for 5xx', () {
      const exception = ServerException(500);
      expect(exception.statusCode, 500);
    });

    test('ApiException isServerError returns false for 4xx', () {
      const exception = NotFoundException();
      expect(exception.statusCode, 404);
    });
  });
}
