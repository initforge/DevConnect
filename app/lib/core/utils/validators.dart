/// Centralized validators for DevConnect.
///
/// Each method returns an i18n key (String) when invalid, or null when valid.
/// Callers use AppStrings.of(context).t(key) to display the message.
///
/// See clean-code §3.3 for the rationale.
library;

class Validators {
  Validators._();

  // ── Email ──────────────────────────────────────────────────────────────────

  /// Returns an i18n key if [value] is not a valid email, null if valid.
  ///
  /// Rules: non-empty, contains '@', has domain part, max 254 chars.
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'validators.required';
    final trimmed = value.trim();
    if (trimmed.length > 254) return 'validators.emailTooLong';
    // RFC-ish: must have exactly one @, non-empty local + domain parts
    final parts = trimmed.split('@');
    if (parts.length != 2) return 'validators.emailFormat';
    if (parts[0].isEmpty || parts[1].isEmpty) return 'validators.emailFormat';
    if (!parts[1].contains('.')) return 'validators.emailFormat';
    return null;
  }

  // ── Username ───────────────────────────────────────────────────────────────

  /// Returns an i18n key if [value] is not a valid username, null if valid.
  ///
  /// Rules: 3-30 chars, only [a-z0-9_], cannot start with '_'.
  static String? username(String? value) {
    if (value == null || value.trim().isEmpty) return 'validators.required';
    final v = value.trim();
    if (v.length < 3 || v.length > 30) return 'validators.usernameFormat';
    if (v.startsWith('_')) return 'validators.usernameStartsWithUnderscore';
    if (!RegExp(r'^[a-z0-9_]+$').hasMatch(v)) {
      return 'validators.usernameFormat';
    }
    return null;
  }

  // ── Password ───────────────────────────────────────────────────────────────

  /// Returns an i18n key if [value] is not a valid password, null if valid.
  ///
  /// Default rules (clean-code §3.3): ≥8 chars, ≥1 letter, ≥1 digit.
  /// Special characters are NOT required to reduce friction.
  ///
  /// Pass [requireSpecial: true] for stricter contexts (e.g. admin).
  static String? password(String? value, {bool requireSpecial = false}) {
    if (value == null || value.isEmpty) return 'validators.required';
    if (value.length < 8) return 'validators.passwordTooShort';
    if (!RegExp(r'[a-zA-Z]').hasMatch(value)) {
      return 'validators.passwordNeedsLetter';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'validators.passwordNeedsNumber';
    }
    if (requireSpecial && !RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return 'validators.passwordNeedsSpecial';
    }
    return null;
  }

  /// Returns password strength score 0.0–1.0 for UI meter.
  static double passwordStrength(String value) {
    double score = 0;
    if (value.length >= 8) score += 0.25;
    if (RegExp(r'[A-Z]').hasMatch(value)) score += 0.25;
    if (RegExp(r'[0-9]').hasMatch(value)) score += 0.25;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) score += 0.25;
    return score;
  }

  // ── URL ────────────────────────────────────────────────────────────────────

  /// Returns an i18n key if [value] is not a valid URL, null if valid.
  static String? url(String? value) {
    if (value == null || value.trim().isEmpty) return null; // optional field
    final uri = Uri.tryParse(value.trim());
    if (uri == null) return 'validators.urlInvalid';
    if (!uri.hasScheme) return 'validators.urlMissingScheme';
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      return 'validators.urlMissingScheme';
    }
    return null;
  }

  // ── Required ───────────────────────────────────────────────────────────────

  /// Returns an i18n key if [value] is empty, null if valid.
  static String? notEmpty(String? value) {
    if (value == null || value.trim().isEmpty) return 'validators.required';
    return null;
  }

  // ── Confirm password ───────────────────────────────────────────────────────

  /// Returns an i18n key if [value] does not match [original], null if valid.
  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) return 'validators.required';
    if (value != original) return 'validators.passwordsDoNotMatch';
    return null;
  }
}
