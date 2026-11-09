import 'json_values.dart';

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.sku,
    required this.year,
    required this.priceRub,
    required this.weightGrams,
    required this.brandId,
    required this.categoryIds,
    required this.stockTotal,
    required this.stockAvailable,
    this.disciplineIds = const [],
    this.deletedAt,
  });

  final int id;
  final String name;
  final String sku;
  final int year;
  final int priceRub;
  final int weightGrams;
  final int brandId;
  final List<int> categoryIds;
  final List<int> disciplineIds;
  final int stockTotal;
  final int stockAvailable;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  Product copyWith({
    String? name,
    String? sku,
    int? year,
    int? priceRub,
    int? weightGrams,
    int? brandId,
    List<int>? categoryIds,
    List<int>? disciplineIds,
    int? stockTotal,
    int? stockAvailable,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Product(
      id: id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      year: year ?? this.year,
      priceRub: priceRub ?? this.priceRub,
      weightGrams: weightGrams ?? this.weightGrams,
      brandId: brandId ?? this.brandId,
      categoryIds: categoryIds ?? this.categoryIds,
      disciplineIds: disciplineIds ?? this.disciplineIds,
      stockTotal: stockTotal ?? this.stockTotal,
      stockAvailable: stockAvailable ?? this.stockAvailable,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'sku': sku,
        'year': year,
        'priceRub': priceRub,
        'weightGrams': weightGrams,
        'brandId': brandId,
        'categoryIds': categoryIds,
        'disciplineIds': disciplineIds,
        'stockTotal': stockTotal,
        'stockAvailable': stockAvailable,
        'deletedAt': deletedAt?.toIso8601String(),
      };

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: readInt(json['id']),
      name: readString(json['name']),
      sku: readString(json['sku']),
      year: readInt(json['year']),
      priceRub: readInt(json['priceRub']),
      weightGrams: readInt(json['weightGrams']),
      brandId: readInt(json['brandId']),
      categoryIds: readIntList(json['categoryIds']),
      disciplineIds: readIntList(json['disciplineIds']),
      stockTotal: readInt(json['stockTotal']),
      stockAvailable: readInt(json['stockAvailable']),
      deletedAt: readDate(json['deletedAt']),
    );
  }
}
