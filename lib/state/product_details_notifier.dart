import 'package:flutter/material.dart';

import '../models/load_status.dart';
import '../models/product.dart';
import '../repositories/brand_repository.dart';
import '../repositories/directory_repositories.dart';
import '../repositories/product_repository.dart';

class ProductDetailsNotifier extends ChangeNotifier {
  ProductDetailsNotifier(this._products, this._brands, this._categories, this._disciplines);

  final ProductRepository _products;
  final BrandRepository _brands;
  final CategoryRepository _categories;
  final DisciplineRepository _disciplines;

  Product? product;
  String brandName = '';
  String categories = '';
  String disciplines = '';
  LoadStatus status = LoadStatus.idle;
  String? error;
  bool permanentlyDeleted = false;

  Future<void> load(int id) async {
    status = LoadStatus.loading;
    error = null;
    permanentlyDeleted = false;
    notifyListeners();
    try {
      final found = await _products.findById(id);
      if (found == null) {
        product = null;
        error = 'Товар с номером $id не найден.';
        status = LoadStatus.error;
        notifyListeners();
        return;
      }
      final brand = await _brands.findById(found.brandId);
      final categoryList = await _categories.all();
      final disciplineList = await _disciplines.all();
      product = found;
      brandName = brand?.name ?? 'Бренд #${found.brandId}';
      categories = _names(found.categoryIds, categoryList.map((item) => (item.id, item.name)));
      disciplines = _names(found.disciplineIds, disciplineList.map((item) => (item.id, item.name)));
      status = LoadStatus.success;
    } catch (error) {
      this.error = 'Не удалось открыть карточку: $error';
      status = LoadStatus.error;
    }
    notifyListeners();
  }

  Future<bool> softDelete() async {
    final current = product;
    if (current == null) return false;
    try {
      await _products.softDelete(current.id);
    } catch (error) {
      this.error = 'Не удалось скрыть товар: $error';
      status = LoadStatus.error;
      notifyListeners();
      return false;
    }
    await load(current.id);
    return status == LoadStatus.success;
  }

  Future<bool> restore() async {
    final current = product;
    if (current == null) return false;
    try {
      await _products.restore(current.id);
    } catch (error) {
      this.error = 'Не удалось восстановить товар: $error';
      status = LoadStatus.error;
      notifyListeners();
      return false;
    }
    await load(current.id);
    return status == LoadStatus.success;
  }

  Future<bool> hardDelete() async {
    final current = product;
    if (current == null) return false;
    try {
      await _products.hardDelete(current.id);
    } catch (error) {
      this.error = 'Не удалось удалить товар: $error';
      status = LoadStatus.error;
      notifyListeners();
      return false;
    }
    product = null;
    permanentlyDeleted = true;
    status = LoadStatus.success;
    notifyListeners();
    return true;
  }

  String _names(List<int> ids, Iterable<(int, String)> options) {
    if (ids.isEmpty) return '—';
    return ids.map((id) {
      for (final option in options) {
        if (option.$1 == id) return option.$2;
      }
      return '#$id';
    }).join(', ');
  }
}
