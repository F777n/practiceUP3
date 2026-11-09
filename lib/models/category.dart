import 'json_values.dart';

class Category {
  const Category({
    required this.id,
    required this.name,
    required this.code,
    required this.description,
    required this.kind,
    required this.introducedYear,
    this.deletedAt,
  });

  final int id;
  final String name;
  final String code;
  final String description;
  final String kind;
  final int introducedYear;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  Category copyWith({
    String? name,
    String? code,
    String? description,
    String? kind,
    int? introducedYear,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Category(
      id: id,
      name: name ?? this.name,
      code: code ?? this.code,
      description: description ?? this.description,
      kind: kind ?? this.kind,
      introducedYear: introducedYear ?? this.introducedYear,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'code': code,
        'description': description,
        'kind': kind,
        'introducedYear': introducedYear,
        'deletedAt': deletedAt?.toIso8601String(),
      };

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: readInt(json['id']),
      name: readString(json['name']),
      code: readString(json['code']),
      description: readString(json['description']),
      kind: readString(json['kind']),
      introducedYear: readInt(json['introducedYear']),
      deletedAt: readDate(json['deletedAt']),
    );
  }
}

const categoryKinds = <String>['Защита', 'Снаряды', 'Одежда'];
