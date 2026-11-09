import '../models/brand.dart';
import '../models/category.dart';
import '../models/customer.dart';
import '../models/discipline.dart';
import '../models/product.dart';

const seedBrandCategoryIds = <int, List<int>>{
  1: [1, 5, 8],
  2: [1, 4],
  3: [1, 2],
  4: [1, 3],
  5: [1, 7],
  6: [1, 2, 4],
  7: [3, 5],
  8: [1, 6],
  9: [1, 2, 5],
  10: [1, 6],
  11: [1, 4],
  12: [1, 7],
};

String seedBrandEmail(int id) {
  const slugs = <int, String>{
    1: 'everlast',
    2: 'rival',
    3: 'winning',
    4: 'cleto',
    5: 'adidas',
    6: 'venum',
    7: 'title',
    8: 'greenhill',
    9: 'fairtex',
    10: 'twins',
    11: 'hayabusa',
    12: 'leone',
  };
  return '${slugs[id] ?? 'brand$id'}@ring.shop';
}

List<int> seedDisciplineIds(Product product) {
  final ids = <int>{1};
  if (product.categoryIds.contains(5) || product.categoryIds.contains(6)) ids.add(7);
  if (product.brandId == 9 || product.brandId == 10) ids.add(3);
  if (product.brandId == 6) ids.add(4);
  if (product.categoryIds.contains(7)) ids.add(2);
  return ids.toList()..sort();
}

List<Brand> buildSeedBrands() {
  return [
    for (final brand in _rawSeedBrands())
      brand.copyWith(
        email: seedBrandEmail(brand.id),
        categoryIds: List<int>.of(seedBrandCategoryIds[brand.id] ?? const [1]),
      ),
  ];
}

List<Brand> _rawSeedBrands() {
  return [
    const Brand(
      id: 1,
      name: 'Everlast',
      country: 'США',
      foundedYear: 1910,
      specialization: 'Перчатки и снаряды',
    ),
    const Brand(
      id: 2,
      name: 'Rival',
      country: 'Канада',
      foundedYear: 1987,
      specialization: 'Соревновательная экипировка',
    ),
    const Brand(
      id: 3,
      name: 'Winning',
      country: 'Япония',
      foundedYear: 1937,
      specialization: 'Профессиональные перчатки',
    ),
    const Brand(
      id: 4,
      name: 'Cleto Reyes',
      country: 'Мексика',
      foundedYear: 1973,
      specialization: 'Перчатки и капы',
    ),
    const Brand(
      id: 5,
      name: 'Adidas',
      country: 'Германия',
      foundedYear: 1949,
      specialization: 'Обувь и тренировки',
    ),
    const Brand(
      id: 6,
      name: 'Venum',
      country: 'Франция',
      foundedYear: 2006,
      specialization: 'Экипировка для зала',
    ),
    const Brand(
      id: 7,
      name: 'Title',
      country: 'США',
      foundedYear: 1963,
      specialization: 'Груши и оснащение зала',
    ),
    const Brand(
      id: 8,
      name: 'Green Hill',
      country: 'Россия',
      foundedYear: 1992,
      specialization: 'Тренировочная линейка',
    ),
    const Brand(
      id: 9,
      name: 'Fairtex',
      country: 'Таиланд',
      foundedYear: 1971,
      specialization: 'Тайский бокс и бокс',
    ),
    const Brand(
      id: 10,
      name: 'Twins Special',
      country: 'Таиланд',
      foundedYear: 1991,
      specialization: 'Перчатки и лапы',
    ),
    const Brand(
      id: 11,
      name: 'Hayabusa',
      country: 'Канада',
      foundedYear: 2005,
      specialization: 'Защита и перчатки',
    ),
    Brand(
      id: 12,
      name: 'Leone 1947',
      country: 'Италия',
      foundedYear: 1947,
      specialization: 'Классическая экипировка',
      deletedAt: DateTime.utc(2026, 2, 1),
    ),
  ];
}

List<Product> buildSeedProducts() {
  return [
    for (final product in _rawSeedProducts())
      product.copyWith(disciplineIds: seedDisciplineIds(product)),
  ];
}

List<Product> _rawSeedProducts() {
  return const [
    Product(
      id: 1,
      name: 'Перчатки тренировочные Everlast Powerlock',
      sku: 'EV-GL-10',
      year: 2022,
      priceRub: 8990,
      weightGrams: 397,
      brandId: 1,
      categoryIds: [1],
      stockTotal: 20,
      stockAvailable: 14,
    ),
    Product(
      id: 2,
      name: 'Защита паха Everlast Elite',
      sku: 'EV-GR-01',
      year: 2021,
      priceRub: 4590,
      weightGrams: 280,
      brandId: 1,
      categoryIds: [8],
      stockTotal: 15,
      stockAvailable: 9,
    ),
    Product(
      id: 3,
      name: 'Перчатки Rival RB50',
      sku: 'RV-GL-50',
      year: 2023,
      priceRub: 12490,
      weightGrams: 410,
      brandId: 2,
      categoryIds: [1],
      stockTotal: 12,
      stockAvailable: 7,
    ),
    Product(
      id: 4,
      name: 'Шлем Rival Guerrero',
      sku: 'RV-HL-02',
      year: 2020,
      priceRub: 9990,
      weightGrams: 680,
      brandId: 2,
      categoryIds: [4],
      stockTotal: 10,
      stockAvailable: 4,
    ),
    Product(
      id: 5,
      name: 'Перчатки Winning MS-600',
      sku: 'WN-GL-600',
      year: 2024,
      priceRub: 54900,
      weightGrams: 360,
      brandId: 3,
      categoryIds: [1],
      stockTotal: 6,
      stockAvailable: 2,
    ),
    Product(
      id: 6,
      name: 'Бинты Winning полуэластичные',
      sku: 'WN-WR-290',
      year: 2024,
      priceRub: 3900,
      weightGrams: 90,
      brandId: 3,
      categoryIds: [2],
      stockTotal: 40,
      stockAvailable: 31,
    ),
    Product(
      id: 7,
      name: 'Перчатки Cleto Reyes Extra',
      sku: 'CR-GL-EX',
      year: 2019,
      priceRub: 18990,
      weightGrams: 425,
      brandId: 4,
      categoryIds: [1],
      stockTotal: 8,
      stockAvailable: 3,
    ),
    Product(
      id: 8,
      name: 'Капа Cleto Reyes',
      sku: 'CR-MG-01',
      year: 2022,
      priceRub: 2490,
      weightGrams: 40,
      brandId: 4,
      categoryIds: [3],
      stockTotal: 50,
      stockAvailable: 44,
    ),
    Product(
      id: 9,
      name: 'Перчатки Adidas Speed Tilt 350',
      sku: 'AD-GL-350',
      year: 2023,
      priceRub: 10990,
      weightGrams: 390,
      brandId: 5,
      categoryIds: [1],
      stockTotal: 18,
      stockAvailable: 11,
    ),
    Product(
      id: 10,
      name: 'Боксерки Adidas Box Hog 4',
      sku: 'AD-SH-04',
      year: 2024,
      priceRub: 13990,
      weightGrams: 820,
      brandId: 5,
      categoryIds: [7],
      stockTotal: 14,
      stockAvailable: 8,
    ),
    Product(
      id: 11,
      name: 'Перчатки Venum Challenger 3.0',
      sku: 'VN-GL-C3',
      year: 2021,
      priceRub: 6490,
      weightGrams: 370,
      brandId: 6,
      categoryIds: [1],
      stockTotal: 22,
      stockAvailable: 16,
    ),
    Product(
      id: 12,
      name: 'Шлем Venum Elite',
      sku: 'VN-HL-EL',
      year: 2022,
      priceRub: 7990,
      weightGrams: 640,
      brandId: 6,
      categoryIds: [4],
      stockTotal: 11,
      stockAvailable: 5,
    ),
    Product(
      id: 13,
      name: 'Бинты Venum Kontact 4 м',
      sku: 'VN-WR-4M',
      year: 2020,
      priceRub: 1290,
      weightGrams: 80,
      brandId: 6,
      categoryIds: [2],
      stockTotal: 60,
      stockAvailable: 52,
    ),
    Product(
      id: 14,
      name: 'Груша Title Genuine Leather',
      sku: 'TL-BG-70',
      year: 2018,
      priceRub: 15990,
      weightGrams: 32000,
      brandId: 7,
      categoryIds: [5],
      stockTotal: 5,
      stockAvailable: 2,
    ),
    Product(
      id: 15,
      name: 'Капа Title Gel',
      sku: 'TL-MG-01',
      year: 2023,
      priceRub: 990,
      weightGrams: 35,
      brandId: 7,
      categoryIds: [3],
      stockTotal: 70,
      stockAvailable: 61,
    ),
    Product(
      id: 16,
      name: 'Перчатки Green Hill Tiger',
      sku: 'GH-GL-TG',
      year: 2022,
      priceRub: 3490,
      weightGrams: 380,
      brandId: 8,
      categoryIds: [1],
      stockTotal: 30,
      stockAvailable: 21,
    ),
    Product(
      id: 17,
      name: 'Лапы Green Hill Coach',
      sku: 'GH-LP-01',
      year: 2021,
      priceRub: 4990,
      weightGrams: 900,
      brandId: 8,
      categoryIds: [6],
      stockTotal: 16,
      stockAvailable: 10,
    ),
    Product(
      id: 18,
      name: 'Набор Fairtex: перчатки и бинты',
      sku: 'FX-SET-01',
      year: 2019,
      priceRub: 9190,
      weightGrams: 480,
      brandId: 9,
      categoryIds: [1, 2],
      stockTotal: 13,
      stockAvailable: 6,
    ),
    Product(
      id: 19,
      name: 'Мешок Fairtex HB6',
      sku: 'FX-BG-H6',
      year: 2017,
      priceRub: 21990,
      weightGrams: 28000,
      brandId: 9,
      categoryIds: [5],
      stockTotal: 4,
      stockAvailable: 1,
    ),
    Product(
      id: 20,
      name: 'Перчатки Twins Special BGVL3',
      sku: 'TW-GL-L3',
      year: 2020,
      priceRub: 7490,
      weightGrams: 405,
      brandId: 10,
      categoryIds: [1],
      stockTotal: 17,
      stockAvailable: 9,
    ),
    Product(
      id: 21,
      name: 'Лапы Twins Special',
      sku: 'TW-LP-01',
      year: 2016,
      priceRub: 8690,
      weightGrams: 1100,
      brandId: 10,
      categoryIds: [6],
      stockTotal: 9,
      stockAvailable: 4,
    ),
    Product(
      id: 22,
      name: 'Перчатки Hayabusa T3',
      sku: 'HY-GL-T3',
      year: 2024,
      priceRub: 19990,
      weightGrams: 430,
      brandId: 11,
      categoryIds: [1],
      stockTotal: 10,
      stockAvailable: 6,
    ),
    Product(
      id: 23,
      name: 'Шлем Hayabusa',
      sku: 'HY-HL-01',
      year: 2023,
      priceRub: 11490,
      weightGrams: 700,
      brandId: 11,
      categoryIds: [4],
      stockTotal: 8,
      stockAvailable: 3,
    ),
    Product(
      id: 24,
      name: 'Перчатки Leone 1947 Iconic',
      sku: 'LE-GL-IC',
      year: 2015,
      priceRub: 9690,
      weightGrams: 415,
      brandId: 12,
      categoryIds: [1],
      stockTotal: 7,
      stockAvailable: 0,
    ),
  ].followedBy([
    Product(
      id: 25,
      name: 'Боксерки Leone Premium',
      sku: 'LE-SH-PR',
      year: 2018,
      priceRub: 12990,
      weightGrams: 780,
      brandId: 12,
      categoryIds: const [7],
      stockTotal: 6,
      stockAvailable: 2,
      deletedAt: DateTime.utc(2026, 3, 1),
    ),
    Product(
      id: 26,
      name: 'Груша Everlast Nevatear',
      sku: 'EV-BG-NV',
      year: 2016,
      priceRub: 24990,
      weightGrams: 35000,
      brandId: 1,
      categoryIds: const [5],
      stockTotal: 3,
      stockAvailable: 1,
      deletedAt: DateTime.utc(2026, 1, 15),
    ),
  ]).toList();
}

Category _category(
  int id,
  String name,
  String code,
  String kind,
  int year,
  String description, {
  DateTime? deletedAt,
}) {
  return Category(
    id: id,
    name: name,
    code: code,
    description: description,
    kind: kind,
    introducedYear: year,
    deletedAt: deletedAt,
  );
}

List<Category> buildSeedCategories() {
  return [
    _category(1, 'Перчатки', 'GLV', 'Защита', 1910, 'Снаряжение для ударов руками на тренировке и на ринге.'),
    _category(2, 'Бинты', 'WRP', 'Защита', 1930, 'Фиксируют запястье и костяшки под перчаткой.'),
    _category(3, 'Капы', 'MTH', 'Защита', 1950, 'Защищают зубы и челюсть во время спарринга.'),
    _category(4, 'Шлемы', 'HLM', 'Защита', 1960, 'Закрывают голову на тренировочных боях.'),
    _category(5, 'Груши и мешки', 'BAG', 'Снаряды', 1920, 'Подвесные и напольные снаряды для ударов.'),
    _category(6, 'Лапы', 'PAD', 'Снаряды', 1970, 'Парные лапы для работы с тренером.'),
    _category(7, 'Обувь', 'SHO', 'Одежда', 1980, 'Боксёрки и обувь для зала.'),
    _category(8, 'Защита', 'GRD', 'Защита', 1985, 'Защита корпуса, паха и голени.'),
    _category(9, 'Шорты', 'SRT', 'Одежда', 1990, 'Боксёрские и тайские шорты.'),
    _category(10, 'Футболки', 'TSH', 'Одежда', 1995, 'Тренировочные футболки и рашгарды.'),
    _category(11, 'Скакалки', 'ROP', 'Снаряды', 2001, 'Скоростные скакалки для разминки.'),
    _category(
      12,
      'Нагрудники',
      'CST',
      'Защита',
      1978,
      'Жёсткая защита корпуса. Позиция снята с витрины.',
      deletedAt: DateTime.utc(2026, 4, 1),
    ),
  ];
}

List<Discipline> buildSeedDisciplines() {
  Discipline item(
    int id,
    String name,
    String country,
    int year,
    String summary, {
    DateTime? deletedAt,
  }) {
    return Discipline(
      id: id,
      name: name,
      country: country,
      establishedYear: year,
      summary: summary,
      deletedAt: deletedAt,
    );
  }

  return [
    item(1, 'Бокс', 'Великобритания', 1867, 'Удары руками в перчатках по правилам ринга.'),
    item(2, 'Кикбоксинг', 'США', 1974, 'Удары руками и ногами в полный контакт.'),
    item(3, 'Муай-тай', 'Таиланд', 1930, 'Тайский бокс: локти, колени, клинч и лоу-кик.'),
    item(4, 'ММА', 'США', 1993, 'Смешанные единоборства в клетке и в клетке-октагоне.'),
    item(5, 'Сават', 'Франция', 1832, 'Французский бокс ногами в обуви.'),
    item(6, 'Рукопашный бой', 'Россия', 1979, 'Прикладной раздел с ударами и борьбой.'),
    item(7, 'Общая подготовка', 'Германия', 1950, 'ОФП, мешки, скакалка и работа на снарядах.'),
    item(8, 'Кудо', 'Япония', 1981, 'Контакт в шлеме с ударами и борьбой.'),
    item(9, 'К-1', 'Япония', 1993, 'Стойка кикбоксинга по правилам К-1.'),
    item(10, 'Самбо', 'Россия', 1938, 'Борьба и боевое самбо в куртке.'),
    item(11, 'Бокс олимпийский', 'Франция', 1904, 'Любительский бокс по олимпийской формуле.'),
    item(
      12,
      'Панкратион',
      'Греция',
      1996,
      'Возрождённый античный раздел. Снят с витрины.',
      deletedAt: DateTime.utc(2025, 11, 2),
    ),
  ];
}

List<Customer> buildSeedCustomers() {
  Customer person(
    int id,
    String name,
    String email,
    String phone,
    String city,
    int year,
    String card,
    int discount, {
    bool active = true,
    DateTime? deletedAt,
  }) {
    return Customer(
      id: id,
      fullName: name,
      email: email,
      phone: phone,
      city: city,
      birthYear: year,
      deletedAt: deletedAt,
      card: LoyaltyCard(
        number: card,
        issuedOn: '2024-0${(id % 9) + 1}-15',
        discountPercent: discount,
        active: active,
      ),
    );
  }

  return [
    person(1, 'Иван Петров', 'ivan.petrov@mail.ru', '+79001110001', 'Москва', 1994, '100001', 5),
    person(2, 'Мария Соколова', 'maria.sokolova@mail.ru', '+79001110002', 'Санкт-Петербург', 1998, '100002', 10),
    person(3, 'Артём Кузнецов', 'artem.kuznetsov@mail.ru', '+79001110003', 'Казань', 1991, '100003', 0),
    person(4, 'Елена Орлова', 'elena.orlova@mail.ru', '+79001110004', 'Екатеринбург', 1987, '100004', 15),
    person(5, 'Никита Волков', 'nikita.volkov@mail.ru', '+79001110005', 'Новосибирск', 2001, '100005', 5),
    person(6, 'Ольга Белова', 'olga.belova@mail.ru', '+79001110006', 'Краснодар', 1996, '100006', 10, active: false),
    person(7, 'Павел Морозов', 'pavel.morozov@mail.ru', '+79001110007', 'Москва', 1984, '100007', 20),
    person(8, 'Дарья Лебедева', 'darya.lebedeva@mail.ru', '+79001110008', 'Казань', 2003, '100008', 5),
    person(9, 'Сергей Новиков', 'sergey.novikov@mail.ru', '+79001110009', 'Санкт-Петербург', 1979, '100009', 15),
    person(10, 'Алина Ким', 'alina.kim@mail.ru', '+79001110010', 'Екатеринбург', 1999, '100010', 0),
    person(11, 'Глеб Сафин', 'gleb.safin@mail.ru', '+79001110011', 'Краснодар', 1992, '100011', 10),
    person(
      12,
      'Кирилл Ершов',
      'kirill.ershov@mail.ru',
      '+79001110012',
      'Новосибирск',
      1988,
      '100012',
      5,
      deletedAt: DateTime.utc(2026, 5, 1),
    ),
  ];
}
