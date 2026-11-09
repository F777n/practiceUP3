import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ring_shop/data/seed.dart';
import 'package:ring_shop/forms/field_spec.dart';
import 'package:ring_shop/forms/validators.dart';
import 'package:ring_shop/models/brand.dart';
import 'package:ring_shop/models/customer.dart';
import 'package:ring_shop/models/product.dart';
import 'package:ring_shop/repositories/in_memory_product_repository.dart';
import 'package:ring_shop/storage/catalog_store.dart';

void main() {
  test('json переживает пустые и null поля', () {
    final product = Product.fromJson({
      'id': '7',
      'name': null,
      'categoryIds': ['1', 2, null],
      'deletedAt': 'не-дата',
    });
    expect(product.id, 7);
    expect(product.name, isEmpty);
    expect(product.categoryIds, [1, 2]);
    expect(product.deletedAt, isNull);
    final restored = Product.fromJson(product.toJson());
    expect(restored.sku, product.sku);

    final customer = Customer.fromJson({'id': 3, 'email': 'a@b.c'});
    expect(customer.card.number, isEmpty);
    expect(customer.card.active, isTrue);
    expect(Customer.fromJson(customer.toJson()).email, 'a@b.c');
  });

  test('валидаторы ловят пустое, длину, число, почту и уникальность', () {
    expect(requiredText('  '), isNotNull);
    expect(lengthBetween('аб', 3, 10), isNotNull);
    expect(intInRange('0', min: 1, max: 10, positive: true), isNotNull);
    expect(intInRange('4', min: 1, max: 10), isNull);
    expect(emailText('ivan'), isNotNull);
    expect(emailText('ivan.petrov@mail.ru'), isNull);
    expect(skuText('EV-GL-10'), isNull);
    expect(phoneText('+79001110001'), isNull);
    expect(phoneText('+7'), isNotNull);
    expect(phoneText('+790011100011'), isNotNull);
    expect(calendarDate('2024-02-31'), isNotNull);
    expect(calendarDate('2024-02-15'), isNull);
    expect(uniqueValue('EV-GL-10', ['ev-gl-10'], 'Такой артикул уже есть'), 'Такой артикул уже есть');
    expect(linkedDeleteMessage('Everlast', 4), contains('4 товара'));
    expect(linkedDeleteMessage('Everlast', 0), isNull);
  });

  test('телефон клиента начинается с +7 и держит только 10 цифр', () {
    String typed(String raw) {
      final value = TextEditingValue(
        text: raw,
        selection: TextSelection.collapsed(offset: raw.length),
      );
      return const RuPhoneFormatter().formatEditUpdate(TextEditingValue.empty, value).text;
    }

    expect(typed('+7'), '+7');
    expect(typed('9001112233'), '+79001112233');
    expect(typed('+7 (900) 111-22-33'), '+79001112233');
    expect(typed('буквы'), '+7');
    expect(typed('+79001112233999'), '+79001112233');
  });

  test('каскад бренда уже, чем весь список категорий', () {
    final brands = buildSeedBrands();
    final categories = buildSeedCategories().where((item) => !item.isDeleted);
    final winning = brands.singleWhere((item) => item.name == 'Winning');
    expect(winning.categoryIds.length, lessThan(categories.length));
    expect(winning.email, contains('@'));
    for (final product in buildSeedProducts()) {
      final brand = brands.singleWhere((item) => item.id == product.brandId);
      for (final categoryId in product.categoryIds) {
        expect(brand.categoryIds, contains(categoryId), reason: product.name);
      }
      expect(product.disciplineIds, isNotEmpty);
    }
  });

  test('артикул уникален, а бренд с товарами нельзя отвязать молча', () async {
    final products = InMemoryProductRepository(latency: Duration.zero);
    expect(await products.isSkuTaken('EV-GL-10'), isTrue);
    expect(await products.isSkuTaken('EV-GL-10', exceptId: 1), isFalse);
    expect(await products.countLinked(brandId: 1), greaterThan(0));
    expect(await products.countLinked(brandId: 999), 0);
  });

  test('старый или битый формат не роняет разбор', () {
    final fresh = CatalogStore.interpret(null, legacyOnly: false);
    expect(fresh.notice, isNull);
    expect(fresh.snapshot.products, isNotEmpty);

    final legacy = CatalogStore.interpret(null, legacyOnly: true);
    expect(legacy.notice, contains('Формат данных изменился'));

    final broken = CatalogStore.interpret('{', legacyOnly: false);
    expect(broken.notice, contains('повреждены'));
    expect(broken.snapshot.brands, isNotEmpty);

    final oldSchema = CatalogStore.interpret('{"schema":1,"products":[]}', legacyOnly: false);
    expect(oldSchema.notice, contains('устарел'));

    final parsed = CatalogStore.interpret(
      '{"schema":2,"products":[{"id":1,"name":"Лапа","sku":"A-1"}],"brands":[],"categories":[],"disciplines":[],"customers":[]}',
      legacyOnly: false,
    );
    expect(parsed.notice, isNull);
    expect(parsed.snapshot.products.single.name, 'Лапа');
    expect(parsed.snapshot.products.single.disciplineIds, isEmpty);
  });

  test('бренд из json не теряет категории', () {
    const brand = Brand(
      id: 3,
      name: 'Winning',
      country: 'Япония',
      foundedYear: 1937,
      specialization: 'Перчатки',
      email: 'winning@ring.shop',
      categoryIds: [1, 2],
    );
    expect(Brand.fromJson(brand.toJson()).categoryIds, [1, 2]);
  });
}
