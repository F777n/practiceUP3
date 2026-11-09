import 'json_values.dart';

class Discipline {
  const Discipline({
    required this.id,
    required this.name,
    required this.country,
    required this.establishedYear,
    required this.summary,
    this.deletedAt,
  });

  final int id;
  final String name;
  final String country;
  final int establishedYear;
  final String summary;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  Discipline copyWith({
    String? name,
    String? country,
    int? establishedYear,
    String? summary,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Discipline(
      id: id,
      name: name ?? this.name,
      country: country ?? this.country,
      establishedYear: establishedYear ?? this.establishedYear,
      summary: summary ?? this.summary,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'country': country,
        'establishedYear': establishedYear,
        'summary': summary,
        'deletedAt': deletedAt?.toIso8601String(),
      };

  factory Discipline.fromJson(Map<String, dynamic> json) {
    return Discipline(
      id: readInt(json['id']),
      name: readString(json['name']),
      country: readString(json['country']),
      establishedYear: readInt(json['establishedYear']),
      summary: readString(json['summary']),
      deletedAt: readDate(json['deletedAt']),
    );
  }
}
