import 'package:flutter/foundation.dart';

import '../models/load_status.dart';
import '../models/page_result.dart';

class SimpleListNotifier<T, Q> extends ChangeNotifier {
  SimpleListNotifier({
    required this.find,
    required this.softDeleteById,
    required this.hardDeleteById,
    required this.restoreById,
    required this.deleteManyById,
    required Q initialQuery,
    required this.failureText,
  }) : _query = initialQuery;

  final Future<PageResult<T>> Function(Q query) find;
  final Future<void> Function(int id) softDeleteById;
  final Future<void> Function(int id) hardDeleteById;
  final Future<void> Function(int id) restoreById;
  final Future<int> Function(List<int> ids) deleteManyById;
  final String failureText;

  Q _query;
  PageResult<T> _result = PageResult<T>.empty();
  LoadStatus _status = LoadStatus.idle;
  String? _error;
  final Set<int> _selected = {};
  bool _failNext = false;
  int _ticket = 0;

  Q get query => _query;
  PageResult<T> get result => _result;
  LoadStatus get status => _status;
  String? get error => _error;
  Set<int> get selected => Set.unmodifiable(_selected);
  bool get hasSelection => _selected.isNotEmpty;

  Future<void> load() async {
    final ticket = ++_ticket;
    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();
    try {
      if (_failNext) {
        _failNext = false;
        throw StateError(failureText);
      }
      final result = await find(_query);
      if (ticket != _ticket) return;
      _result = result;
      _status = LoadStatus.success;
    } on StateError catch (error) {
      if (ticket != _ticket) return;
      _error = error.message;
      _status = LoadStatus.error;
    } catch (error) {
      if (ticket != _ticket) return;
      _error = 'Не удалось загрузить список: $error';
      _status = LoadStatus.error;
    }
    notifyListeners();
  }

  Future<void> applyQuery(Q next) async {
    final changed = _query != next;
    if (!changed && _status == LoadStatus.success) return;
    _query = next;
    if (changed) _selected.clear();
    await load();
  }

  Future<void> demonstrateError() async {
    _failNext = true;
    await load();
  }

  void toggleSelection(int id) {
    if (_selected.contains(id)) {
      _selected.remove(id);
    } else {
      _selected.add(id);
    }
    notifyListeners();
  }

  void clearSelection() {
    if (_selected.isEmpty) return;
    _selected.clear();
    notifyListeners();
  }

  Future<void> deleteSelected() async {
    final ids = _selected.toList();
    if (ids.isEmpty) return;
    await _mutate(() async {
      await deleteManyById(ids);
      _selected.clear();
    });
  }

  Future<void> softDelete(int id) {
    _selected.remove(id);
    return _mutate(() => softDeleteById(id));
  }

  Future<void> hardDelete(int id) {
    _selected.remove(id);
    return _mutate(() => hardDeleteById(id));
  }

  Future<void> restore(int id) => _mutate(() => restoreById(id));

  Future<void> _mutate(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      _error = 'Не удалось изменить запись: $error';
      _status = LoadStatus.error;
      notifyListeners();
      return;
    }
    await load();
  }
}
