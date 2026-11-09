import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/catalog.dart';
import '../forms/field_spec.dart';
import '../forms/spec_form_screen.dart';
import '../forms/validators.dart';
import '../models/brand.dart';
import '../models/category.dart';
import '../navigation.dart';
import '../repositories/brand_repository.dart';
import '../repositories/directory_repositories.dart';
import '../state/brand_list_notifier.dart';

class BrandFormScreen extends StatelessWidget {
  const BrandFormScreen({super.key, this.id});

  final int? id;

  @override
  Widget build(BuildContext context) {
    final brands = context.read<BrandRepository>();
    final categories = context.read<CategoryRepository>();
    final back = context.read<ListLocationMemory>().brands;
    return SpecFormScreen(
      fallback: back,
      locationFor: (savedId) => '/brands/$savedId',
      onSaved: () => context.read<BrandListNotifier>().load(),
      load: () => _load(brands, categories),
      save: (values) => _save(brands, values),
    );
  }

  Future<FormBlueprint> _load(BrandRepository brands, CategoryRepository categories) async {
    final brand = id == null ? null : await brands.findById(id!);
    if (id != null && brand == null) throw StateError('Бренд с номером $id не найден.');
    final categoryList = await categories.all();
    return FormBlueprint(
      title: id == null ? 'Новый бренд' : 'Изменение бренда',
      submitLabel: id == null ? 'Создать' : 'Сохранить',
      values: {
        'name': brand?.name ?? '',
        'country': brand?.country,
        'foundedYear': brand == null ? '' : '${brand.foundedYear}',
        'specialization': brand?.specialization ?? '',
        'email': brand?.email ?? '',
        'categoryIds': brand?.categoryIds ?? <int>[],
      },
      fields: (values) => _fields(values, categoryList),
    );
  }

  Future<int> _save(BrandRepository brands, Map<String, Object?> values) async {
    final draft = Brand(
      id: id ?? 0,
      name: textValue(values, 'name'),
      country: stringValue(values, 'country') ?? '',
      foundedYear: int.parse(textValue(values, 'foundedYear')),
      specialization: textValue(values, 'specialization'),
      email: textValue(values, 'email'),
      categoryIds: idValue(values, 'categoryIds'),
    );
    if (draft.country.isEmpty) throw StateError('Выберите страну.');
    if (id == null) return (await brands.create(draft)).id;
    final current = await brands.findById(id!);
    if (current == null) throw StateError('Бренд уже удалён.');
    final saved = await brands.update(
      Brand(
        id: current.id,
        name: draft.name,
        country: draft.country,
        foundedYear: draft.foundedYear,
        specialization: draft.specialization,
        email: draft.email,
        categoryIds: draft.categoryIds,
        deletedAt: current.deletedAt,
      ),
    );
    return saved.id;
  }
}

List<FieldSpec> _fields(Map<String, Object?> values, List<Category> categories) {
  return [
    TextFieldSpec(
      id: 'name',
      label: 'Название',
      initialValue: textValue(values, 'name'),
      validator: (value, _) =>
          requiredText(value, message: 'Укажите название') ?? lengthBetween(value, 2, 80),
    ),
    StringChoiceSpec(
      id: 'country',
      label: 'Страна',
      value: stringValue(values, 'country'),
      options: [for (final country in brandCountries) ChoiceOption(country, country)],
      validator: (value) => value == null || value.isEmpty ? 'Выберите страну' : null,
    ),
    TextFieldSpec(
      id: 'foundedYear',
      label: 'Год основания',
      initialValue: textValue(values, 'foundedYear'),
      digitsOnly: true,
      keyboardType: TextInputType.number,
      validator: (value, _) => intInRange(value, min: 1800, max: 2026, empty: 'Укажите год'),
    ),
    TextFieldSpec(
      id: 'specialization',
      label: 'Специализация',
      initialValue: textValue(values, 'specialization'),
      validator: (value, _) =>
          requiredText(value, message: 'Опишите специализацию') ?? lengthBetween(value, 2, 80),
    ),
    TextFieldSpec(
      id: 'email',
      label: 'Почта',
      initialValue: textValue(values, 'email'),
      keyboardType: TextInputType.emailAddress,
      validator: (value, _) => emailText(value),
    ),
    MultiSpec(
      id: 'categoryIds',
      label: 'Категории бренда',
      values: idValue(values, 'categoryIds'),
      hint: 'От них зависит, какие категории можно выбрать у товара',
      options: [
        for (final category in categories)
          if (!category.isDeleted) ChoiceOption(category.id, category.name),
      ],
      validator: (value) => requiredIds(value, 'Выберите хотя бы одну категорию'),
    ),
  ];
}
