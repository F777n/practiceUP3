import 'dart:convert';

import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:shared_preferences/shared_preferences.dart';

import '../data/seed.dart';
import '../models/brand.dart';
import '../models/category.dart';
import '../models/customer.dart';
import '../models/discipline.dart';
import '../models/json_values.dart';
import '../models/product.dart';
import '../repositories/directory_repositories.dart';
import '../repositories/in_memory_brand_repository.dart';
import '../repositories/in_memory_product_repository.dart';
import 'persist_gate.dart';

class CatalogSnapshot {
  const CatalogSnapshot({
    required this.products,
    required this.brands,
    required this.categories,
    required this.disciplines,
    required this.customers,
  });

  final List<Product> products;
  final List<Brand> brands;
  final List<Category> categories;
  final List<Discipline> disciplines;
  final List<Customer> customers;

  static CatalogSnapshot seed() {
    return CatalogSnapshot(
      products: buildSeedProducts(),
      brands: buildSeedBrands(),
      categories: buildSeedCategories(),
      disciplines: buildSeedDisciplines(),
      customers: buildSeedCustomers(),
    );
  }

  Map<String, dynamic> toJson() => {
        'schema': CatalogStore.schema,
        'products': products.map((item) => item.toJson()).toList(),
        'brands': brands.map((item) => item.toJson()).toList(),
        'categories': categories.map((item) => item.toJson()).toList(),
        'disciplines': disciplines.map((item) => item.toJson()).toList(),
        'customers': customers.map((item) => item.toJson()).toList(),
      };

  factory CatalogSnapshot.fromJson(Map<String, dynamic> json) {
    List<T> kept<T>(Object? raw, T Function(Map<String, dynamic>) decode, int Function(T) idOf) {
      return readModels(raw, decode).where((item) => idOf(item) > 0).toList();
    }

    return CatalogSnapshot(
      products: kept(json['products'], Product.fromJson, (item) => item.id),
      brands: kept(json['brands'], Brand.fromJson, (item) => item.id),
      categories: kept(json['categories'], Category.fromJson, (item) => item.id),
      disciplines: kept(json['disciplines'], Discipline.fromJson, (item) => item.id),
      customers: kept(json['customers'], Customer.fromJson, (item) => item.id),
    );
  }
}

class CatalogRestore {
  const CatalogRestore({required this.snapshot, this.notice});

  final CatalogSnapshot snapshot;
  final String? notice;
}

class CatalogStore {
  static const schema = 2;
  static const currentKey = 'ring_catalog_v2';
  static const legacyKey = 'ring_catalog_v1';

  static CatalogRestore interpret(String? raw, {required bool legacyOnly}) {
    if (raw == null) {
      return CatalogRestore(
        snapshot: CatalogSnapshot.seed(),
        notice: legacyOnly
            ? 'Формат данных изменился. Старый ключ $legacyKey больше не читается, каталог загружен заново.'
            : null,
      );
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map || readInt(decoded['schema'], -1) != schema) {
        return CatalogRestore(
          snapshot: CatalogSnapshot.seed(),
          notice: 'Формат сохранённых данных устарел. Каталог загружен заново.',
        );
      }
      return CatalogRestore(
        snapshot: CatalogSnapshot.fromJson(Map<String, dynamic>.from(decoded)),
      );
    } catch (_) {
      return CatalogRestore(
        snapshot: CatalogSnapshot.seed(),
        notice: 'Сохранённые данные повреждены. Каталог загружен заново.',
      );
    }
  }
}

class StorageNotice extends ChangeNotifier {
  StorageNotice(this.message);

  String? message;

  void dismiss() {
    if (message == null) return;
    message = null;
    notifyListeners();
  }
}

class CatalogSession {
  CatalogSession({
    required this.products,
    required this.brands,
    required this.categories,
    required this.disciplines,
    required this.customers,
    required this.notice,
  });

  final InMemoryProductRepository products;
  final InMemoryBrandRepository brands;
  final InMemoryCategoryRepository categories;
  final InMemoryDisciplineRepository disciplines;
  final InMemoryCustomerRepository customers;
  final StorageNotice notice;

  Map<String, dynamic> toJson() {
    return CatalogSnapshot(
      products: products.snapshot(),
      brands: brands.snapshot(),
      categories: categories.snapshot(),
      disciplines: disciplines.snapshot(),
      customers: customers.snapshot(),
    ).toJson();
  }

  static Future<CatalogSession> open() async {
    final prefs = await SharedPreferences.getInstance();
    final hasCurrent = prefs.containsKey(CatalogStore.currentKey);
    final legacyOnly = prefs.containsKey(CatalogStore.legacyKey) && !hasCurrent;
    final restored = CatalogStore.interpret(
      hasCurrent ? prefs.getString(CatalogStore.currentKey) : null,
      legacyOnly: legacyOnly,
    );
    final gate = PersistGate();
    final session = CatalogSession(
      products: InMemoryProductRepository(products: restored.snapshot.products, gate: gate),
      brands: InMemoryBrandRepository(brands: restored.snapshot.brands, gate: gate),
      categories: InMemoryCategoryRepository(categories: restored.snapshot.categories, gate: gate),
      disciplines: InMemoryDisciplineRepository(
        disciplines: restored.snapshot.disciplines,
        gate: gate,
      ),
      customers: InMemoryCustomerRepository(customers: restored.snapshot.customers, gate: gate),
      notice: StorageNotice(restored.notice),
    );
    gate.save = () => _write(prefs, session);
    if (!hasCurrent || restored.notice != null) {
      await _write(prefs, session);
    }
    return session;
  }

  static Future<void> _write(SharedPreferences prefs, CatalogSession session) async {
    try {
      await prefs.setString(CatalogStore.currentKey, jsonEncode(session.toJson()));
    } catch (_) {}
  }
}
