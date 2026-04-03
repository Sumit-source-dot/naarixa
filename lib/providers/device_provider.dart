import 'package:flutter/foundation.dart';

class DeviceProvider extends ChangeNotifier {
  int _deviceCount = 0;

  int get deviceCount => _deviceCount;

  void setDeviceCount(int count) {
    _deviceCount = count;
    notifyListeners();
  }
}
