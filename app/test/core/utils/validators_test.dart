import 'package:flutter_test/flutter_test.dart';

import 'package:devconnect/core/utils/validators.dart';

void main() {
  group('Validators.email', () {
    test('returns null for valid email', () {
      expect(Validators.email('user@example.com'), isNull);
      expect(Validators.email('user+tag@sub.domain.com'), isNull);
    });

    test('returns required key for empty input', () {
      expect(Validators.email(null), 'validators.required');
      expect(Validators.email(''), 'validators.required');
      expect(Validators.email('   '), 'validators.required');
    });

    test('returns emailFormat key for missing @', () {
      expect(Validators.email('notanemail'), 'validators.emailFormat');
    });

    test('returns emailFormat key for missing domain', () {
      expect(Validators.email('user@'), 'validators.emailFormat');
    });

    test('returns emailFormat key for missing dot in domain', () {
      expect(Validators.email('user@nodot'), 'validators.emailFormat');
    });

    test('returns emailTooLong for email > 254 chars', () {
      final longEmail = '${'a' * 250}@b.com';
      expect(Validators.email(longEmail), 'validators.emailTooLong');
    });
  });

  group('Validators.password', () {
    test('returns null for valid password', () {
      expect(Validators.password('Password1'), isNull);
      expect(Validators.password('abc12345'), isNull);
    });

    test('returns required key for empty input', () {
      expect(Validators.password(null), 'validators.required');
      expect(Validators.password(''), 'validators.required');
    });

    test('returns passwordTooShort for < 8 chars', () {
      expect(Validators.password('abc123'), 'validators.passwordTooShort');
    });

    test('returns passwordNeedsLetter when no letter', () {
      expect(Validators.password('12345678'), 'validators.passwordNeedsLetter');
    });

    test('returns passwordNeedsNumber when no digit', () {
      expect(Validators.password('abcdefgh'), 'validators.passwordNeedsNumber');
    });
  });

  group('Validators.passwordStrength', () {
    test('returns 0.25 for length only', () {
      expect(Validators.passwordStrength('abcdefgh'), 0.25);
    });

    test('returns 1.0 for all criteria met', () {
      expect(Validators.passwordStrength('Abcdef1!'), 1.0);
    });
  });

  group('Validators.username', () {
    test('returns null for valid username', () {
      expect(Validators.username('john_dev'), isNull);
      expect(Validators.username('abc'), isNull);
    });

    test('returns required key for empty input', () {
      expect(Validators.username(null), 'validators.required');
      expect(Validators.username(''), 'validators.required');
    });

    test('returns usernameFormat for too short', () {
      expect(Validators.username('ab'), 'validators.usernameFormat');
    });

    test('returns usernameFormat for invalid chars', () {
      expect(Validators.username('John Doe'), 'validators.usernameFormat');
      expect(Validators.username('UPPER'), 'validators.usernameFormat');
    });

    test('returns usernameStartsWithUnderscore', () {
      expect(
        Validators.username('_john'),
        'validators.usernameStartsWithUnderscore',
      );
    });
  });

  group('Validators.url', () {
    test('returns null for valid URL', () {
      expect(Validators.url('https://example.com'), isNull);
      expect(Validators.url('http://localhost:8080'), isNull);
    });

    test('returns null for empty (optional field)', () {
      expect(Validators.url(null), isNull);
      expect(Validators.url(''), isNull);
    });

    test('returns urlMissingScheme for missing scheme', () {
      expect(Validators.url('example.com'), 'validators.urlMissingScheme');
    });

    test('returns urlMissingScheme for non-http scheme', () {
      expect(
        Validators.url('ftp://example.com'),
        'validators.urlMissingScheme',
      );
    });
  });

  group('Validators.confirmPassword', () {
    test('returns null when passwords match', () {
      expect(Validators.confirmPassword('abc12345', 'abc12345'), isNull);
    });

    test('returns passwordsDoNotMatch when different', () {
      expect(
        Validators.confirmPassword('abc12345', 'different'),
        'validators.passwordsDoNotMatch',
      );
    });
  });
}
