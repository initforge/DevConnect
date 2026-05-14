import 'package:flutter/foundation.dart';

class ProfileRefreshBus extends ChangeNotifier {
  ProfileRefreshBus._();

  static final ProfileRefreshBus instance = ProfileRefreshBus._();

  void refresh() => notifyListeners();
}
