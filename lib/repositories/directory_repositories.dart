import '../data/seed.dart';
import '../models/category.dart';
import '../models/category_query.dart';
import '../models/customer.dart';
import '../models/customer_query.dart';
import '../models/discipline.dart';
import '../models/discipline_query.dart';
import '../models/page_result.dart';
import '../storage/persist_gate.dart';
import 'memory_table.dart';

abstract interface class CategoryRepository {
  Future<PageResult<Category>> find(CategoryQuery query);
  Future<List<Category>> all();
  Future<Category?> findById(int id);
  Future<bool> isCodeTaken(String code, {int? exceptId});
  Future<Category> create(Category category);
  Future<Category> update(Category category);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> deleteMany(List<int> ids);
}

abstract interface class DisciplineRepository {
  Future<PageResult<Discipline>> find(DisciplineQuery query);
  Future<List<Discipline>> all();
  Future<Discipline?> findById(int id);
  Future<Discipline> create(Discipline discipline);
  Future<Discipline> update(Discipline discipline);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> deleteMany(List<int> ids);
}

abstract interface class CustomerRepository {
  Future<PageResult<Customer>> find(CustomerQuery query);
  Future<List<Customer>> all();
  Future<Customer?> findById(int id);
  Future<bool> isEmailTaken(String email, {int? exceptId});
  Future<Customer> create(Customer customer);
  Future<Customer> update(Customer customer);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> deleteMany(List<int> ids);
}

class InMemoryCategoryRepository implements CategoryRepository {
  InMemoryCategoryRepository({
    List<Category>? categories,
    Duration latency = const Duration(milliseconds: 250),
    PersistGate? gate,
  }) : _table = MemoryTable<Category>(
          items: categories ?? buildSeedCategories(),
          idOf: (item) => item.id,
          withId: (draft, id) => Category(
            id: id,
            name: draft.name,
            code: draft.code,
            description: draft.description,
            kind: draft.kind,
            introducedYear: draft.introducedYear,
          ),
          latency: latency,
          gate: gate,
        );

  final MemoryTable<Category> _table;

  List<Category> snapshot() => _table.snapshot();

  @override
  Future<List<Category>> all() => _table.all();

  @override
  Future<Category?> findById(int id) => _table.findById(id);

  @override
  Future<bool> isCodeTaken(String code, {int? exceptId}) async {
    final needle = code.trim().toLowerCase();
    if (needle.isEmpty) return false;
    return _table.items.any(
      (item) => item.id != exceptId && item.code.trim().toLowerCase() == needle,
    );
  }

  @override
  Future<PageResult<Category>> find(CategoryQuery q) async {
    await _table.pause();
    var rows = _table.items.where((item) => q.includeDeleted || !item.isDeleted).toList();
    final needle = q.search.trim().toLowerCase();
    if (needle.isNotEmpty) {
      rows = rows
          .where(
            (item) =>
                item.name.toLowerCase().contains(needle) ||
                item.code.toLowerCase().contains(needle),
          )
          .toList();
    }
    if (q.kind != null) rows = rows.where((item) => item.kind == q.kind).toList();
    if (q.yearFrom != null) {
      rows = rows.where((item) => item.introducedYear >= q.yearFrom!).toList();
    }
    if (q.yearTo != null) {
      rows = rows.where((item) => item.introducedYear <= q.yearTo!).toList();
    }
    rows.sort((a, b) {
      final result = switch (q.sortField) {
        'introducedYear' => a.introducedYear.compareTo(b.introducedYear),
        'kind' => a.kind.toLowerCase().compareTo(b.kind.toLowerCase()),
        _ => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      };
      return q.sortAscending ? result : -result;
    });
    return pageOf(rows, page: q.page, size: q.size);
  }

  @override
  Future<Category> create(Category category) => _table.create(category);

  @override
  Future<Category> update(Category category) => _table.update(category, 'Категория ${category.id} не найдена');

  @override
  Future<void> softDelete(int id) {
    return _table.softDelete(
      id,
      (item) => item.copyWith(deletedAt: DateTime.now()),
      'Категория $id не найдена',
    );
  }

  @override
  Future<void> hardDelete(int id) => _table.hardDelete(id, 'Категория $id не найдена');

  @override
  Future<void> restore(int id) {
    return _table.restore(id, (item) => item.copyWith(clearDeletedAt: true), 'Категория $id не найдена');
  }

  @override
  Future<int> deleteMany(List<int> ids) {
    return _table.deleteMany(
      ids,
      (item) => item.copyWith(deletedAt: DateTime.now()),
      (item) => item.isDeleted,
    );
  }
}

class InMemoryDisciplineRepository implements DisciplineRepository {
  InMemoryDisciplineRepository({
    List<Discipline>? disciplines,
    Duration latency = const Duration(milliseconds: 250),
    PersistGate? gate,
  }) : _table = MemoryTable<Discipline>(
          items: disciplines ?? buildSeedDisciplines(),
          idOf: (item) => item.id,
          withId: (draft, id) => Discipline(
            id: id,
            name: draft.name,
            country: draft.country,
            establishedYear: draft.establishedYear,
            summary: draft.summary,
          ),
          latency: latency,
          gate: gate,
        );

  final MemoryTable<Discipline> _table;

  List<Discipline> snapshot() => _table.snapshot();

  @override
  Future<List<Discipline>> all() => _table.all();

  @override
  Future<Discipline?> findById(int id) => _table.findById(id);

  @override
  Future<PageResult<Discipline>> find(DisciplineQuery q) async {
    await _table.pause();
    var rows = _table.items.where((item) => q.includeDeleted || !item.isDeleted).toList();
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
    if (q.country != null) rows = rows.where((item) => item.country == q.country).toList();
    if (q.yearFrom != null) {
      rows = rows.where((item) => item.establishedYear >= q.yearFrom!).toList();
    }
    if (q.yearTo != null) {
      rows = rows.where((item) => item.establishedYear <= q.yearTo!).toList();
    }
    rows.sort((a, b) {
      final result = switch (q.sortField) {
        'country' => a.country.toLowerCase().compareTo(b.country.toLowerCase()),
        'establishedYear' => a.establishedYear.compareTo(b.establishedYear),
        _ => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      };
      return q.sortAscending ? result : -result;
    });
    return pageOf(rows, page: q.page, size: q.size);
  }

  @override
  Future<Discipline> create(Discipline discipline) => _table.create(discipline);

  @override
  Future<Discipline> update(Discipline discipline) {
    return _table.update(discipline, 'Дисциплина ${discipline.id} не найдена');
  }

  @override
  Future<void> softDelete(int id) {
    return _table.softDelete(
      id,
      (item) => item.copyWith(deletedAt: DateTime.now()),
      'Дисциплина $id не найдена',
    );
  }

  @override
  Future<void> hardDelete(int id) => _table.hardDelete(id, 'Дисциплина $id не найдена');

  @override
  Future<void> restore(int id) {
    return _table.restore(id, (item) => item.copyWith(clearDeletedAt: true), 'Дисциплина $id не найдена');
  }

  @override
  Future<int> deleteMany(List<int> ids) {
    return _table.deleteMany(
      ids,
      (item) => item.copyWith(deletedAt: DateTime.now()),
      (item) => item.isDeleted,
    );
  }
}

class InMemoryCustomerRepository implements CustomerRepository {
  InMemoryCustomerRepository({
    List<Customer>? customers,
    Duration latency = const Duration(milliseconds: 250),
    PersistGate? gate,
  }) : _table = MemoryTable<Customer>(
          items: customers ?? buildSeedCustomers(),
          idOf: (item) => item.id,
          withId: (draft, id) => Customer(
            id: id,
            fullName: draft.fullName,
            email: draft.email,
            phone: draft.phone,
            city: draft.city,
            birthYear: draft.birthYear,
            card: draft.card,
          ),
          latency: latency,
          gate: gate,
        );

  final MemoryTable<Customer> _table;

  List<Customer> snapshot() => _table.snapshot();

  @override
  Future<List<Customer>> all() => _table.all();

  @override
  Future<Customer?> findById(int id) => _table.findById(id);

  @override
  Future<bool> isEmailTaken(String email, {int? exceptId}) async {
    final needle = email.trim().toLowerCase();
    if (needle.isEmpty) return false;
    return _table.items.any(
      (item) => item.id != exceptId && item.email.trim().toLowerCase() == needle,
    );
  }

  @override
  Future<PageResult<Customer>> find(CustomerQuery q) async {
    await _table.pause();
    var rows = _table.items.where((item) => q.includeDeleted || !item.isDeleted).toList();
    final needle = q.search.trim().toLowerCase();
    if (needle.isNotEmpty) {
      rows = rows
          .where(
            (item) =>
                item.fullName.toLowerCase().contains(needle) ||
                item.email.toLowerCase().contains(needle) ||
                item.card.number.toLowerCase().contains(needle),
          )
          .toList();
    }
    if (q.city != null) rows = rows.where((item) => item.city == q.city).toList();
    if (q.cardActive != null) {
      rows = rows.where((item) => item.card.active == q.cardActive).toList();
    }
    if (q.yearFrom != null) rows = rows.where((item) => item.birthYear >= q.yearFrom!).toList();
    if (q.yearTo != null) rows = rows.where((item) => item.birthYear <= q.yearTo!).toList();
    rows.sort((a, b) {
      final result = switch (q.sortField) {
        'email' => a.email.toLowerCase().compareTo(b.email.toLowerCase()),
        'birthYear' => a.birthYear.compareTo(b.birthYear),
        _ => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
      };
      return q.sortAscending ? result : -result;
    });
    return pageOf(rows, page: q.page, size: q.size);
  }

  @override
  Future<Customer> create(Customer customer) => _table.create(customer);

  @override
  Future<Customer> update(Customer customer) => _table.update(customer, 'Клиент ${customer.id} не найден');

  @override
  Future<void> softDelete(int id) {
    return _table.softDelete(
      id,
      (item) => item.copyWith(deletedAt: DateTime.now()),
      'Клиент $id не найден',
    );
  }

  @override
  Future<void> hardDelete(int id) => _table.hardDelete(id, 'Клиент $id не найден');

  @override
  Future<void> restore(int id) {
    return _table.restore(id, (item) => item.copyWith(clearDeletedAt: true), 'Клиент $id не найден');
  }

  @override
  Future<int> deleteMany(List<int> ids) {
    return _table.deleteMany(
      ids,
      (item) => item.copyWith(deletedAt: DateTime.now()),
      (item) => item.isDeleted,
    );
  }
}
