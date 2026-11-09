import 'query_codec.dart';

class CategoryQuery {
  const CategoryQuery({
    this.search = '',
    this.kind,
    this.yearFrom,
    this.yearTo,
    this.sortField = 'name',
    this.sortAscending = true,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
  });

  final String search;
  final String? kind;
  final int? yearFrom;
  final int? yearTo;
  final String sortField;
  final bool sortAscending;
  final int page;
  final int size;
  final bool includeDeleted;

  static const allowedSort = {'name', 'introducedYear', 'kind'};

  factory CategoryQuery.fromUri(Uri uri) {
    final params = uri.queryParameters;
    final sort = parseSort(params['sort'], allowed: allowedSort, fallback: 'name');
    final kind = params['kind'];
    return CategoryQuery(
      search: params['search'] ?? '',
      kind: kind == null || kind.isEmpty ? null : kind,
      yearFrom: int.tryParse(params['yearFrom'] ?? ''),
      yearTo: int.tryParse(params['yearTo'] ?? ''),
      sortField: sort.field,
      sortAscending: sort.ascending,
      page: parsePage(params['page']),
      size: parsePageSize(params['size']),
      includeDeleted: params['deleted'] == '1',
    );
  }

  String toLocation() {
    final params = <String, String>{};
    if (search.isNotEmpty) params['search'] = search;
    if (kind != null) params['kind'] = kind!;
    if (yearFrom != null) params['yearFrom'] = '$yearFrom';
    if (yearTo != null) params['yearTo'] = '$yearTo';
    addSort(params, sortField, sortAscending, 'name');
    if (page != 1) params['page'] = '$page';
    if (size != 10) params['size'] = '$size';
    if (includeDeleted) params['deleted'] = '1';
    return buildLocation('/categories', params);
  }

  CategoryQuery copyWith({
    String? search,
    Object? kind = _unset,
    Object? yearFrom = _unset,
    Object? yearTo = _unset,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    return CategoryQuery(
      search: search ?? this.search,
      kind: kind == _unset ? this.kind : kind as String?,
      yearFrom: yearFrom == _unset ? this.yearFrom : yearFrom as int?,
      yearTo: yearTo == _unset ? this.yearTo : yearTo as int?,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
      page: page ?? 1,
      size: size ?? this.size,
      includeDeleted: includeDeleted ?? this.includeDeleted,
    );
  }

  static const _unset = Object();

  @override
  bool operator ==(Object other) {
    return other is CategoryQuery &&
        other.search == search &&
        other.kind == kind &&
        other.yearFrom == yearFrom &&
        other.yearTo == yearTo &&
        other.sortField == sortField &&
        other.sortAscending == sortAscending &&
        other.page == page &&
        other.size == size &&
        other.includeDeleted == includeDeleted;
  }

  @override
  int get hashCode => Object.hash(
        search,
        kind,
        yearFrom,
        yearTo,
        sortField,
        sortAscending,
        page,
        size,
        includeDeleted,
      );

  @override
  String toString() => toLocation();
}
