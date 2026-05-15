/// DevConnect — Named exception hierarchy.
///
/// All exceptions thrown by repositories and services should be one of these
/// typed subclasses. This allows callers to catch by type and show appropriate
/// UI (clean-code §4.4).
///
/// Usage:
/// ```dart
/// try {
///   await repo.doSomething();
/// } on ValidationException catch (e) {
///   // show field errors from e.details
/// } on AuthException {
///   // redirect to login
/// } on NetworkException {
///   // show retry button
/// } on AppException catch (e) {
///   // generic fallback
/// }
/// ```
library;

// ── Base ──────────────────────────────────────────────────────────────────────

/// Base class for all DevConnect exceptions.
abstract class AppException implements Exception {
  const AppException(this.messageKey, {this.statusCode, this.details});

  /// i18n key for the user-facing message (use AppStrings.of(context).t(key)).
  final String messageKey;

  /// HTTP status code, if applicable.
  final int? statusCode;

  /// Additional structured details (e.g. field errors for ValidationException).
  final Map<String, dynamic>? details;

  @override
  String toString() => 'AppException($messageKey, status=$statusCode)';
}

// ── Network ───────────────────────────────────────────────────────────────────

/// No internet, timeout, DNS failure, or connection refused.
class NetworkException extends AppException {
  const NetworkException([
    String messageKey = 'errors.connectionError',
    int? statusCode,
  ]) : super(messageKey, statusCode: statusCode);
}

// ── Auth ──────────────────────────────────────────────────────────────────────

/// Base for authentication-related errors.
abstract class AuthException extends AppException {
  const AuthException(super.messageKey, {super.statusCode});
}

/// User is not logged in (no token).
class UnauthenticatedException extends AuthException {
  const UnauthenticatedException()
    : super('errors.sessionExpired', statusCode: 401);
}

/// Token exists but is expired or invalid (401 from server).
class SessionExpiredException extends AuthException {
  const SessionExpiredException()
    : super('errors.sessionExpired', statusCode: 401);
}

// ── Validation ────────────────────────────────────────────────────────────────

/// 400 / 422 — request data is invalid.
///
/// [details] may contain field-level errors: `{'email': 'already taken'}`.
class ValidationException extends AppException {
  const ValidationException({
    String messageKey = 'errors.invalidData',
    Map<String, dynamic>? details,
  }) : super(messageKey, statusCode: 422, details: details);
}

// ── Not found ─────────────────────────────────────────────────────────────────

/// 404 — resource does not exist.
class NotFoundException extends AppException {
  const NotFoundException([String resource = ''])
    : super('errors.notFound', statusCode: 404);
}

// ── Conflict ──────────────────────────────────────────────────────────────────

/// 409 — duplicate resource (e.g. username/email already taken).
class ConflictException extends AppException {
  const ConflictException() : super('errors.conflict', statusCode: 409);
}

// ── Rate limit ────────────────────────────────────────────────────────────────

/// 429 — too many requests.
class RateLimitException extends AppException {
  const RateLimitException() : super('errors.tooManyRequests', statusCode: 429);
}

// ── Server ────────────────────────────────────────────────────────────────────

/// 500-599 — server-side error.
class ServerException extends AppException {
  const ServerException([int statusCode = 500])
    : super('errors.serverError', statusCode: statusCode);
}

// ── Unknown ───────────────────────────────────────────────────────────────────

/// Fallback for unexpected errors.
class UnknownException extends AppException {
  const UnknownException([String? message]) : super('errors.generic');
}

// ── Deprecated alias ──────────────────────────────────────────────────────────

/// Deprecated: use typed subclasses of [AppException] instead.
///
/// Kept for backward compatibility with existing callers that catch [ApiException].
/// Will be removed in a future cleanup.
@Deprecated(
  'Use AppException subclasses (NetworkException, AuthException, etc.)',
)
class ApiException extends AppException {
  const ApiException(int statusCode, String message)
    : super(message, statusCode: statusCode);

  /// Alias for messageKey — backward compat with old callers using .message.
  String get message => messageKey;

  bool get isAuthError => statusCode == 401;
  bool get isNetworkError => statusCode == 0;
  bool get isServerError => (statusCode ?? 0) >= 500;

  @override
  String toString() => 'ApiException($statusCode): $messageKey';
}
