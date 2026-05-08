import 'package:flutter/foundation.dart';

class FeedRefreshBus extends ChangeNotifier {
  FeedRefreshBus._();

  static final FeedRefreshBus instance = FeedRefreshBus._();

  void refresh() => notifyListeners();
}
