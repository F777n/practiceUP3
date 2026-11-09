import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../forms/field_spec.dart';
import '../forms/spec_form_screen.dart';
import '../forms/validators.dart';
import '../models/brand.dart';
import '../models/category.dart';
import '../models/discipline.dart';
import '../models/product.dart';
import '../navigation.dart';
import '../repositories/brand_repository.dart';
import '../repositories/directory_repositories.dart';
import '../repositories/product_repository.dart';
import '../state/product_list_notifier.dart';
import '../theme.dart';

class ProductFormScreen extends StatelessWidget {
  const ProductFormScreen({super.key, this.id});

  final int? id;

  @override
  Widget build(BuildContext context) {
    final products = context.read<ProductRepository>();
    final brands = context.read<BrandRepository>();
    final categories = context.read<CategoryRepository>();
    final disciplines = context.read<DisciplineRepository>();
    final back = context.read<ListLocationMemory>().products;
    return SpecFormScreen(
      fallback: back,
      locationFor: (savedId) => '/products/$savedId',
      onSaved: () => context.read<ProductListNotifier>().load(),
      load: () => _load(products, brands, categories, disciplines),
      save: (values) => _save(products, values),
    );
  }

  Future<FormBlueprint> _load(
    ProductRepository products,
    BrandRepository brands,
    CategoryRepository categories,
    DisciplineRepository disciplines,
  ) async {
    final product = id == null ? null : await products.findById(id!);
    if (id != null && product == null) {
      throw StateError('Товар с номером $id не найден.');
    }
    final brandList = await brands.all();
    final categoryList = await categories.all();
    final disciplineList = await disciplines.all();
    final taken = (await products.all())
        .where((item) => item.id != id)
        .map((item) => item.sku)
        .toList();
    final values = <String, Object?>{
      'name': product?.name ?? '',
      'sku': product?.sku ?? '',
      'year': product == null ? '' : '${product.year}',
      'priceRub': product == null ? '' : '${product.priceRub}',
      'weightGrams': product == null ? '' : '${product.weightGrams}',
      'stockTotal': product == null ? '' : '${product.stockTotal}',
      'stockAvailable': product == null ? '' : '${product.stockAvailable}',
      'brandId': product?.brandId,
      'categoryIds': product?.categoryIds ?? <int>[],
      'disciplineIds': product?.disciplineIds ?? <int>[],
    };
    return FormBlueprint(
      title: id == null ? 'Новый товар' : 'Изменение товара',
      submitLabel: id == null ? 'Создать' : 'Сохранить',
      values: values,
      fields: (current) => _fields(current, brandList, categoryList, disciplineList, taken),
    );
  }

  Future<int> _save(ProductRepository products, Map<String, Object?> values) async {
    final draft = Product(
      id: id ?? 0,
      name: textValue(values, 'name'),
      sku: textValue(values, 'sku'),
      year: int.parse(textValue(values, 'year')),
      priceRub: int.parse(textValue(values, 'priceRub')),
      weightGrams: int.parse(textValue(values, 'weightGrams')),
      brandId: intValue(values, 'brandId') ?? 0,
      categoryIds: idValue(values, 'categoryIds'),
      disciplineIds: idValue(values, 'disciplineIds'),
      stockTotal: int.parse(textValue(values, 'stockTotal')),
      stockAvailable: int.parse(textValue(values, 'stockAvailable')),
    );
    if (await products.isSkuTaken(draft.sku, exceptId: id)) {
      throw StateError('Такой артикул уже есть.');
    }
    if (id == null) {
      final created = await products.create(draft);
      return created.id;
    }
    final current = await products.findById(id!);
    if (current == null) throw StateError('Товар уже удалён.');
    final saved = await products.update(
      Product(
        id: current.id,
        name: draft.name,
        sku: draft.sku,
        year: draft.year,
        priceRub: draft.priceRub,
        weightGrams: draft.weightGrams,
        brandId: draft.brandId,
        categoryIds: draft.categoryIds,
        disciplineIds: draft.disciplineIds,
        stockTotal: draft.stockTotal,
        stockAvailable: draft.stockAvailable,
        deletedAt: current.deletedAt,
      ),
    );
    return saved.id;
  }
}

Set<int> _brandCategories(int? brandId, List<Brand> brands) {
  for (final brand in brands) {
    if (brand.id == brandId) return brand.categoryIds.toSet();
  }
  return const {};
}

List<FieldSpec> _fields(
  Map<String, Object?> values,
  List<Brand> brands,
  List<Category> categories,
  List<Discipline> disciplines,
  List<String> takenSkus,
) {
  final brandId = intValue(values, 'brandId');
  final allowed = _brandCategories(brandId, brands);
  final selectedCategories = idValue(values, 'categoryIds');
  final categoryOptions = <ChoiceOption<int>>[
    for (final category in categories)
      if (brandId != null && !category.isDeleted && allowed.contains(category.id))
        ChoiceOption(category.id, category.name),
  ];
  final visibleBrands = [
    for (final brand in brands)
      if (!brand.isDeleted || brand.id == brandId)
        ChoiceOption(brand.id, brand.isDeleted ? '${brand.name} (удалён)' : brand.name),
  ];
  final disciplineOptions = [
    for (final discipline in disciplines)
      if (!discipline.isDeleted || idValue(values, 'disciplineIds').contains(discipline.id))
        ChoiceOption(discipline.id, discipline.name),
  ];
  return [
    TextFieldSpec(
      id: 'name',
      label: 'Название',
      initialValue: textValue(values, 'name'),
      validator: (value, _) =>
          requiredText(value, message: 'Укажите название') ?? lengthBetween(value, 2, 120),
    ),
    TextFieldSpec(
      id: 'sku',
      label: 'Артикул',
      hint: 'EV-GL-10',
      initialValue: textValue(values, 'sku'),
      style: skuTextStyle,
      validator: (value, _) => skuText(value) ?? uniqueValue(value, takenSkus, 'Такой артикул уже есть'),
    ),
    TextFieldSpec(
      id: 'year',
      label: 'Год выпуска',
      initialValue: textValue(values, 'year'),
      digitsOnly: true,
      keyboardType: TextInputType.number,
      validator: (value, _) => intInRange(value, min: 1950, max: 2026, empty: 'Укажите год'),
    ),
    TextFieldSpec(
      id: 'priceRub',
      label: 'Цена, ₽',
      initialValue: textValue(values, 'priceRub'),
      digitsOnly: true,
      keyboardType: TextInputType.number,
      validator: (value, _) => intInRange(value, min: 1, max: 1000000, positive: true, empty: 'Укажите цену'),
    ),
    TextFieldSpec(
      id: 'weightGrams',
      label: 'Вес, г',
      initialValue: textValue(values, 'weightGrams'),
      digitsOnly: true,
      keyboardType: TextInputType.number,
      validator: (value, _) => intInRange(value, min: 1, max: 100000, positive: true, empty: 'Укажите вес'),
    ),
    TextFieldSpec(
      id: 'stockTotal',
      label: 'Всего на складе',
      initialValue: textValue(values, 'stockTotal'),
      digitsOnly: true,
      keyboardType: TextInputType.number,
      validator: (value, _) =>
          intInRange(value, min: 1, max: 100000, positive: true, empty: 'Укажите количество'),
    ),
    TextFieldSpec(
      id: 'stockAvailable',
      label: 'Доступно',
      initialValue: textValue(values, 'stockAvailable'),
      digitsOnly: true,
      keyboardType: TextInputType.number,
      validator: (value, texts) {
        final error = intInRange(value, min: 0, max: 100000, empty: 'Укажите остаток');
        if (error != null) return error;
        final total = int.tryParse((texts['stockTotal'] ?? '').trim());
        final available = int.tryParse((value ?? '').trim());
        if (total != null && available != null && available > total) {
          return 'Не больше, чем всего на складе';
        }
        return null;
      },
    ),
    IntChoiceSpec(
      id: 'brandId',
      label: 'Бренд',
      value: brandId,
      options: visibleBrands,
      validator: (value) => value == null ? 'Выберите бренд' : null,
    ),
    MultiSpec(
      id: 'categoryIds',
      label: 'Категории',
      values: selectedCategories.where(allowed.contains).toList(),
      options: categoryOptions,
      hint: 'Сначала выберите бренд: список сузится до его категорий',
      validator: (value) {
        if (brandId == null) return 'Сначала выберите бренд';
        return requiredIds(value, 'Выберите хотя бы одну категорию');
      },
    ),
    MultiSpec(
      id: 'disciplineIds',
      label: 'Дисциплины',
      values: idValue(values, 'disciplineIds'),
      options: disciplineOptions,
      hint: 'Отметьте, для каких единоборств подходит товар',
      validator: (value) => requiredIds(value, 'Выберите хотя бы одну дисциплину'),
    ),
  ];
}
