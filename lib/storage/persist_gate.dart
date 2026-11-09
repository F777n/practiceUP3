class PersistGate {
  Future<void> Function()? save;
  Future<void>? _pending;

  void touch() {
    final previous = _pending;
    _pending = () async {
      if (previous != null) {
        try {
          await previous;
        } catch (_) {}
      }
      final action = save;
      if (action == null) return;
      await action();
    }();
  }
}
