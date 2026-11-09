import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../models/brand.dart';
import '../models/category.dart';
import '../models/load_status.dart';
import '../models/page_result.dart';
import '../models/product.dart';
import '../models/product_query.dart';
import '../repositories/brand_repository.dart';
import '../repositories/directory_repositories.dart';
import '../repositories/product_repository.dart';

class ProductListNotifier extends ChangeNotifier {
  ProductListNotifier(this._repository, this._brands, this._categories);

  final ProductRepository _repository;
  final BrandRepository _brands;
  final CategoryRepository _categories;

  ProductQuery _query = const ProductQuery();
  PageResult<Product> _result = PageResult<Product>.empty();
  LoadStatus _status = LoadStatus.idle;
  String? _error;
  final Set<int> _selected = {};
  List<Brand> _brandOptions = const [];
  List<Category> _categoryOptions = const [];
  bool _brandsReady = false;
  bool _failNext = false;
  int _ticket = 0;

  ProductQuery get query => _query;
  PageResult<Product> get result => _result;
  LoadStatus get status => _status;
  String? get error => _error;
  Set<int> get selected => Set.unmodifiable(_selected);
  bool get hasSelection => _selected.isNotEmpty;
  List<Brand> get brandOptions => _brandOptions;
  List<Category> get categories =>
      _categoryOptions.where((item) => !item.isDeleted).toList(growable: false);

  String brandName(int id) {
    for (final brand in _brandOptions) {
      if (brand.id == id) return brand.name;
    }
    return 'Бренд #$id';
  }

  String categoryTitle(int id) {
    for (final category in _categoryOptions) {
      if (category.id == id) return category.name;
    }
    return categoryName(id);
  }

  String categoryNames(List<int> ids) {
    if (ids.isEmpty) return '—';
    return ids.map(categoryTitle).join(', ');
  }

  Future<void> load() async {
    final ticket = ++_ticket;
    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();
    try {
      if (_failNext) {
        _failNext = false;
        throw StateError('Учебная имитация: каталог не ответил');
      }
      if (!_brandsReady) {
        _brandOptions = await _brands.all();
        _brandsReady = true;
      }
      _categoryOptions = await _categories.all();
      if (ticket != _ticket) return;
      final result = await _repository.find(_query);
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

  Future<void> applyQuery(ProductQuery next) async {
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
      await _repository.deleteMany(ids);
      _selected.clear();
    }, 'Не удалось скрыть выбранные товары.');
  }

  Future<void> softDelete(int id) {
    _selected.remove(id);
    return _mutate(() => _repository.softDelete(id), 'Не удалось скрыть товар.');
  }

  Future<void> hardDelete(int id) {
    _selected.remove(id);
    return _mutate(() => _repository.hardDelete(id), 'Не удалось удалить товар.');
  }

  Future<void> restore(int id) {
    return _mutate(() => _repository.restore(id), 'Не удалось восстановить товар.');
  }

  Future<void> _mutate(
    Future<void> Function() action,
    String failMessage,
  ) async {
    try {
      await action();
    } catch (error) {
      _error = '$failMessage $error';
      _status = LoadStatus.error;
      notifyListeners();
      return;
    }
    await load();
  }
}
