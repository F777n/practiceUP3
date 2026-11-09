import 'package:flutter/foundation.dart';

class FormGuard extends ChangeNotifier {
  bool dirty = false;
  bool force = false;

  void setDirty(bool value) {
    if (dirty == value) return;
    dirty = value;
    if (value) force = false;
    notifyListeners();
  }

  void reset() {
    dirty = false;
    force = false;
    notifyListeners();
  }

  void allowProgrammaticLeave() {
    dirty = false;
    force = true;
    notifyListeners();
  }
}
