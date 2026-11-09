import 'package:flutter/material.dart';

import '../models/brand.dart';
import '../models/load_status.dart';
import '../models/product_query.dart';
import '../repositories/brand_repository.dart';
import '../repositories/directory_repositories.dart';
import '../repositories/product_repository.dart';

class BrandDetailsNotifier extends ChangeNotifier {
  BrandDetailsNotifier(this._brands, this._products, this._categories);

  final BrandRepository _brands;
  final ProductRepository _products;
  final CategoryRepository _categories;

  Brand? brand;
  int productCount = 0;
  String categories = '';
  LoadStatus status = LoadStatus.idle;
  String? error;
  bool permanentlyDeleted = false;

  Future<void> load(int id) async {
    status = LoadStatus.loading;
    error = null;
    permanentlyDeleted = false;
    notifyListeners();
    try {
      final found = await _brands.findById(id);
      if (found == null) {
        brand = null;
        error = 'Бренд с номером $id не найден.';
        status = LoadStatus.error;
        notifyListeners();
        return;
      }
      final products = await _products.find(
        ProductQuery(brandId: id, size: 1, includeDeleted: true),
      );
      final categoryList = await _categories.all();
      brand = found;
      productCount = products.total;
      categories = found.categoryIds.map((categoryId) {
        for (final category in categoryList) {
          if (category.id == categoryId) return category.name;
        }
        return 'Категория #$categoryId';
      }).join(', ');
      if (categories.isEmpty) categories = '—';
      status = LoadStatus.success;
    } catch (error) {
      this.error = 'Не удалось открыть карточку: $error';
      status = LoadStatus.error;
    }
    notifyListeners();
  }

  Future<bool> softDelete() async {
    final current = brand;
    if (current == null) return false;
    try {
      await _brands.softDelete(current.id);
    } catch (error) {
      this.error = 'Не удалось скрыть бренд: $error';
      status = LoadStatus.error;
      notifyListeners();
      return false;
    }
    await load(current.id);
    return status == LoadStatus.success;
  }

  Future<bool> restore() async {
    final current = brand;
    if (current == null) return false;
    try {
      await _brands.restore(current.id);
    } catch (error) {
      this.error = 'Не удалось восстановить бренд: $error';
      status = LoadStatus.error;
      notifyListeners();
      return false;
    }
    await load(current.id);
    return status == LoadStatus.success;
  }

  Future<bool> hardDelete() async {
    final current = brand;
    if (current == null) return false;
    try {
      await _brands.hardDelete(current.id);
    } catch (error) {
      this.error = 'Не удалось удалить бренд: $error';
      status = LoadStatus.error;
      notifyListeners();
      return false;
    }
    brand = null;
    permanentlyDeleted = true;
    status = LoadStatus.success;
    notifyListeners();
    return true;
  }
}
