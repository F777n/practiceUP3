import '../storage/persist_gate.dart';

class MemoryTable<T> {
  MemoryTable({
    required List<T> items,
    required this.idOf,
    required this.withId,
    this.latency = const Duration(milliseconds: 250),
    this.gate,
  }) : _items = List<T>.of(items) {
    _nextId = _items.fold<int>(0, (max, item) {
      final id = idOf(item);
      return id > max ? id : max;
    }) + 1;
  }

  final int Function(T item) idOf;
  final T Function(T draft, int id) withId;
  final Duration latency;
  final PersistGate? gate;
  final List<T> _items;
  late int _nextId;

  List<T> get items => _items;

  List<T> snapshot() => List<T>.unmodifiable(_items);

  Future<void> pause() => Future<void>.delayed(latency);

  Future<List<T>> all() async => snapshot();

  Future<T?> findById(int id) async {
    await pause();
    for (final item in _items) {
      if (idOf(item) == id) return item;
    }
    return null;
  }

  Future<T> create(T draft) async {
    await pause();
    final created = withId(draft, _nextId++);
    _items.add(created);
    gate?.touch();
    return created;
  }

  Future<T> update(T item, String missing) async {
    await pause();
    final index = _items.indexWhere((row) => idOf(row) == idOf(item));
    if (index < 0) throw StateError(missing);
    _items[index] = item;
    gate?.touch();
    return item;
  }

  Future<void> softDelete(int id, T Function(T item) hide, String missing) async {
    await pause();
    final index = _items.indexWhere((row) => idOf(row) == id);
    if (index < 0) throw StateError(missing);
    _items[index] = hide(_items[index]);
    gate?.touch();
  }

  Future<void> hardDelete(int id, String missing) async {
    await pause();
    final before = _items.length;
    _items.removeWhere((item) => idOf(item) == id);
    if (_items.length == before) throw StateError(missing);
    gate?.touch();
  }

  Future<void> restore(int id, T Function(T item) show, String missing) async {
    await pause();
    final index = _items.indexWhere((row) => idOf(row) == id);
    if (index < 0) throw StateError(missing);
    _items[index] = show(_items[index]);
    gate?.touch();
  }

  Future<int> deleteMany(
    List<int> ids,
    T Function(T item) hide,
    bool Function(T item) isDeleted,
  ) async {
    await pause();
    var count = 0;
    for (final id in ids) {
      final index = _items.indexWhere((item) => idOf(item) == id && !isDeleted(item));
      if (index < 0) continue;
      _items[index] = hide(_items[index]);
      count++;
    }
    if (count > 0) gate?.touch();
    return count;
  }
}
