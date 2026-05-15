import 'package:flutter_test/flutter_test.dart';
import 'package:devconnect/core/utils/mention_parser.dart';

void main() {
  group('MentionParser.getMentionQuery', () {
    test('returns partial username when cursor is after @', () {
      const text = 'Hello @joh';
      expect(MentionParser.getMentionQuery(text, text.length), equals('joh'));
    });

    test('returns empty string when cursor is right after @', () {
      const text = 'Hello @';
      expect(MentionParser.getMentionQuery(text, text.length), equals(''));
    });

    test('returns null when cursor is not in a mention', () {
      const text = 'Hello world';
      expect(MentionParser.getMentionQuery(text, text.length), isNull);
    });

    test('returns null when cursorPos is 0', () {
      expect(MentionParser.getMentionQuery('@user', 0), isNull);
    });

    test('returns null when cursorPos exceeds text length', () {
      expect(MentionParser.getMentionQuery('hi', 99), isNull);
    });

    test('returns correct query mid-text', () {
      const text = 'Hey @ali how are you';
      // cursor right after 'ali' (position 8 = after '@ali')
      expect(MentionParser.getMentionQuery(text, 8), equals('ali'));
    });
  });

  group('MentionParser.getHashtagQuery', () {
    test('returns partial tag when cursor is after #', () {
      const text = 'Post about #flu';
      expect(MentionParser.getHashtagQuery(text, text.length), equals('flu'));
    });

    test('returns empty string when cursor is right after #', () {
      const text = 'Post #';
      expect(MentionParser.getHashtagQuery(text, text.length), equals(''));
    });

    test('returns null when no hashtag at cursor', () {
      const text = 'No hashtag here';
      expect(MentionParser.getHashtagQuery(text, text.length), isNull);
    });

    test('returns null when cursorPos is 0', () {
      expect(MentionParser.getHashtagQuery('#flutter', 0), isNull);
    });

    test('does not confuse @ with #', () {
      const text = 'Hello @user';
      expect(MentionParser.getHashtagQuery(text, text.length), isNull);
    });
  });

  group('MentionParser.replaceMention', () {
    test('replaces partial mention with full username', () {
      const text = 'Hello @joh';
      final result = MentionParser.replaceMention(text, text.length, 'john');
      expect(result, equals('Hello @john '));
    });

    test('replaces empty mention with username', () {
      const text = 'Hello @';
      final result = MentionParser.replaceMention(text, text.length, 'alice');
      expect(result, equals('Hello @alice '));
    });

    test('preserves text after cursor position', () {
      const text = 'Say @joh and more';
      // cursor at position 8 (right after '@joh', before space)
      final result = MentionParser.replaceMention(text, 8, 'john');
      expect(result, equals('Say @john  and more'));
    });
  });

  group('MentionParser.replaceHashtag', () {
    test('replaces partial hashtag with full tag', () {
      const text = 'Post #flu';
      final result = MentionParser.replaceHashtag(text, text.length, 'flutter');
      expect(result, equals('Post #flutter '));
    });

    test('replaces empty hashtag with tag', () {
      const text = 'Post #';
      final result = MentionParser.replaceHashtag(text, text.length, 'dart');
      expect(result, equals('Post #dart '));
    });

    test('preserves text after cursor position', () {
      const text = 'Tag #flu done';
      // cursor at position 8 (right after '#flu', before space)
      final result = MentionParser.replaceHashtag(text, 8, 'flutter');
      expect(result, equals('Tag #flutter  done'));
    });
  });
}
