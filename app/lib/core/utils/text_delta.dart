/// Pure utility for computing text diffs between two strings.
/// Used by live_code_screen to send minimal deltas over the socket.
class TextDelta {
  const TextDelta({
    required this.start,
    required this.deleteCount,
    required this.insertText,
    required this.deletedText,
  });

  final int start;
  final int deleteCount;
  final String insertText;
  final String deletedText;

  factory TextDelta.fromChange(String previous, String next) {
    var start = 0;
    while (start < previous.length &&
        start < next.length &&
        previous.codeUnitAt(start) == next.codeUnitAt(start)) {
      start += 1;
    }

    var previousEnd = previous.length;
    var nextEnd = next.length;
    while (previousEnd > start &&
        nextEnd > start &&
        previous.codeUnitAt(previousEnd - 1) == next.codeUnitAt(nextEnd - 1)) {
      previousEnd -= 1;
      nextEnd -= 1;
    }

    return TextDelta(
      start: start,
      deleteCount: previousEnd - start,
      deletedText: previous.substring(start, previousEnd),
      insertText: next.substring(start, nextEnd),
    );
  }

  Map<String, dynamic> toJson() => {
    'start': start,
    'deleteCount': deleteCount,
    'deletedText': deletedText,
    'insertText': insertText,
  };
}
