import '../models/category.dart';
import 'seed.dart';

const brandCountries = <String>[
  'США',
  'Канада',
  'Япония',
  'Мексика',
  'Германия',
  'Франция',
  'Россия',
  'Таиланд',
  'Италия',
];

List<Category> get productCategories => buildSeedCategories();

String categoryName(int id) {
  for (final category in productCategories) {
    if (category.id == id) return category.name;
  }
  return 'Категория #$id';
}

String categoryLabel(List<int> ids) {
  if (ids.isEmpty) return '—';
  return ids.map(categoryName).join(', ');
}

String namesById(List<int> ids, String Function(int id) nameOf) {
  if (ids.isEmpty) return '—';
  return ids.map(nameOf).join(', ');
}
