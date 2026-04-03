import 'package:flutter/foundation.dart';

class AppStateProvider extends ChangeNotifier {
  int _tabIndex = 0;

  int get tabIndex => _tabIndex;

  void setTab(int index) {
    _tabIndex = index;
    notifyListeners();
  }
}
