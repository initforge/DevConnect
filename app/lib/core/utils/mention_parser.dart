/// Parses @mentions and #hashtags from text.
class MentionParser {
  MentionParser._();

  /// Returns the @mention query at cursor position, or null if not in a mention.
  static String? getMentionQuery(String text, int cursorPos) {
    if (cursorPos <= 0 || cursorPos > text.length) return null;
    final before = text.substring(0, cursorPos);
    final match = RegExp(r'@(\w*)$').firstMatch(before);
    return match?.group(1);
  }

  /// Returns the #hashtag query at cursor position, or null if not in a hashtag.
  static String? getHashtagQuery(String text, int cursorPos) {
    if (cursorPos <= 0 || cursorPos > text.length) return null;
    final before = text.substring(0, cursorPos);
    final match = RegExp(r'#(\w*)$').firstMatch(before);
    return match?.group(1);
  }

  /// Replaces the current @mention with the selected username.
  static String replaceMention(String text, int cursorPos, String username) {
    final before = text.substring(0, cursorPos);
    final after = text.substring(cursorPos);
    final replaced = before.replaceAll(RegExp(r'@\w*$'), '@$username ');
    return replaced + after;
  }

  /// Replaces the current #hashtag with the selected tag.
  static String replaceHashtag(String text, int cursorPos, String tag) {
    final before = text.substring(0, cursorPos);
    final after = text.substring(cursorPos);
    final replaced = before.replaceAll(RegExp(r'#\w*$'), '#$tag ');
    return replaced + after;
  }
}
