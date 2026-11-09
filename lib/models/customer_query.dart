import 'query_codec.dart';

class CustomerQuery {
  const CustomerQuery({
    this.search = '',
    this.city,
    this.cardActive,
    this.yearFrom,
    this.yearTo,
    this.sortField = 'fullName',
    this.sortAscending = true,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
  });

  final String search;
  final String? city;
  final bool? cardActive;
  final int? yearFrom;
  final int? yearTo;
  final String sortField;
  final bool sortAscending;
  final int page;
  final int size;
  final bool includeDeleted;

  static const allowedSort = {'fullName', 'email', 'birthYear'};

  factory CustomerQuery.fromUri(Uri uri) {
    final params = uri.queryParameters;
    final sort = parseSort(params['sort'], allowed: allowedSort, fallback: 'fullName');
    final city = params['city'];
    return CustomerQuery(
      search: params['search'] ?? '',
      city: city == null || city.isEmpty ? null : city,
      cardActive: params['card'] == '1'
          ? true
          : params['card'] == '0'
              ? false
              : null,
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
    if (city != null) params['city'] = city!;
    if (cardActive != null) params['card'] = cardActive! ? '1' : '0';
    if (yearFrom != null) params['yearFrom'] = '$yearFrom';
    if (yearTo != null) params['yearTo'] = '$yearTo';
    addSort(params, sortField, sortAscending, 'fullName');
    if (page != 1) params['page'] = '$page';
    if (size != 10) params['size'] = '$size';
    if (includeDeleted) params['deleted'] = '1';
    return buildLocation('/customers', params);
  }

  CustomerQuery copyWith({
    String? search,
    Object? city = _unset,
    Object? cardActive = _unset,
    Object? yearFrom = _unset,
    Object? yearTo = _unset,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    return CustomerQuery(
      search: search ?? this.search,
      city: city == _unset ? this.city : city as String?,
      cardActive: cardActive == _unset ? this.cardActive : cardActive as bool?,
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
    return other is CustomerQuery &&
        other.search == search &&
        other.city == city &&
        other.cardActive == cardActive &&
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
        city,
        cardActive,
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
