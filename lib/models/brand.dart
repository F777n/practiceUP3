import 'json_values.dart';

class Brand {
  const Brand({
    required this.id,
    required this.name,
    required this.country,
    required this.foundedYear,
    required this.specialization,
    this.email = '',
    this.categoryIds = const [],
    this.deletedAt,
  });

  final int id;
  final String name;
  final String country;
  final int foundedYear;
  final String specialization;
  final String email;
  final List<int> categoryIds;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  Brand copyWith({
    String? name,
    String? country,
    int? foundedYear,
    String? specialization,
    String? email,
    List<int>? categoryIds,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Brand(
      id: id,
      name: name ?? this.name,
      country: country ?? this.country,
      foundedYear: foundedYear ?? this.foundedYear,
      specialization: specialization ?? this.specialization,
      email: email ?? this.email,
      categoryIds: categoryIds ?? this.categoryIds,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'country': country,
        'foundedYear': foundedYear,
        'specialization': specialization,
        'email': email,
        'categoryIds': categoryIds,
        'deletedAt': deletedAt?.toIso8601String(),
      };

  factory Brand.fromJson(Map<String, dynamic> json) {
    return Brand(
      id: readInt(json['id']),
      name: readString(json['name']),
      country: readString(json['country']),
      foundedYear: readInt(json['foundedYear']),
      specialization: readString(json['specialization']),
      email: readString(json['email']),
      categoryIds: readIntList(json['categoryIds']),
      deletedAt: readDate(json['deletedAt']),
    );
  }
}
