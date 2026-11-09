import '../data/seed.dart';
import '../models/brand.dart';
import '../models/brand_query.dart';
import '../models/page_result.dart';
import '../storage/persist_gate.dart';
import 'brand_repository.dart';

class InMemoryBrandRepository implements BrandRepository {
  InMemoryBrandRepository({
    List<Brand>? brands,
    this.latency = const Duration(milliseconds: 250),
    this.gate,
  }) : _items = List<Brand>.of(brands ?? buildSeedBrands()) {
    _nextId = _items.fold<int>(0, (max, item) {
      return item.id > max ? item.id : max;
    }) +
        1;
  }

  final Duration latency;
  final PersistGate? gate;
  final List<Brand> _items;
  late int _nextId;

  List<Brand> snapshot() => List<Brand>.unmodifiable(_items);

  void _touch() => gate?.touch();

  @override
  Future<List<Brand>> all() async => List<Brand>.unmodifiable(_items);

  @override
  Future<PageResult<Brand>> find(BrandQuery q) async {
    await Future.delayed(latency);
    var rows = _items.where((item) => q.includeDeleted || !item.isDeleted).toList();
    final needle = q.search.trim().toLowerCase();
    if (needle.isNotEmpty) {
      rows = rows
          .where(
            (item) =>
                item.name.toLowerCase().contains(needle) ||
                item.country.toLowerCase().contains(needle),
          )
          .toList();
    }
    if (q.country != null) {
      rows = rows.where((item) => item.country == q.country).toList();
    }
    if (q.yearFrom != null) {
      rows = rows.where((item) => item.foundedYear >= q.yearFrom!).toList();
    }
    if (q.yearTo != null) {
      rows = rows.where((item) => item.foundedYear <= q.yearTo!).toList();
    }
    rows.sort((a, b) {
      final result = switch (q.sortField) {
        'country' => a.country.toLowerCase().compareTo(b.country.toLowerCase()),
        'foundedYear' => a.foundedYear.compareTo(b.foundedYear),
        _ => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      };
      return q.sortAscending ? result : -result;
    });
    return pageOf(rows, page: q.page, size: q.size);
  }

  @override
  Future<Brand?> findById(int id) async {
    await Future.delayed(latency);
    for (final item in _items) {
      if (item.id == id) return item;
    }
    return null;
  }

  @override
  Future<Brand> create(Brand draft) async {
    final created = Brand(
      id: _nextId++,
      name: draft.name,
      country: draft.country,
      foundedYear: draft.foundedYear,
      specialization: draft.specialization,
      email: draft.email,
      categoryIds: List<int>.of(draft.categoryIds),
    );
    _items.add(created);
    _touch();
    return created;
  }

  @override
  Future<Brand> update(Brand brand) async {
    final index = _items.indexWhere((item) => item.id == brand.id);
    if (index == -1) throw StateError('Бренд ${brand.id} не найден');
    _items[index] = brand;
    _touch();
    return brand;
  }

  @override
  Future<void> softDelete(int id) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index == -1) throw StateError('Бренд $id не найден');
    _items[index] = _items[index].copyWith(deletedAt: DateTime.now());
    _touch();
  }

  @override
  Future<void> hardDelete(int id) async {
    final before = _items.length;
    _items.removeWhere((item) => item.id == id);
    if (_items.length == before) throw StateError('Бренд $id не найден');
    _touch();
  }

  @override
  Future<void> restore(int id) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index == -1) throw StateError('Бренд $id не найден');
    _items[index] = _items[index].copyWith(clearDeletedAt: true);
    _touch();
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    var count = 0;
    for (final id in ids) {
      final index = _items.indexWhere((item) => item.id == id && !item.isDeleted);
      if (index == -1) continue;
      _items[index] = _items[index].copyWith(deletedAt: DateTime.now());
      count++;
    }
    if (count > 0) _touch();
    return count;
  }
}
