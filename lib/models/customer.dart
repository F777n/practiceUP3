import 'json_values.dart';

class LoyaltyCard {
  const LoyaltyCard({
    this.number = '',
    this.issuedOn = '',
    this.discountPercent = 0,
    this.active = true,
  });

  final String number;
  final String issuedOn;
  final int discountPercent;
  final bool active;

  LoyaltyCard copyWith({
    String? number,
    String? issuedOn,
    int? discountPercent,
    bool? active,
  }) {
    return LoyaltyCard(
      number: number ?? this.number,
      issuedOn: issuedOn ?? this.issuedOn,
      discountPercent: discountPercent ?? this.discountPercent,
      active: active ?? this.active,
    );
  }

  Map<String, dynamic> toJson() => {
        'number': number,
        'issuedOn': issuedOn,
        'discountPercent': discountPercent,
        'active': active,
      };

  factory LoyaltyCard.fromJson(Map<String, dynamic> json) {
    return LoyaltyCard(
      number: readString(json['number']),
      issuedOn: readString(json['issuedOn']),
      discountPercent: readInt(json['discountPercent']),
      active: readBool(json['active'], true),
    );
  }
}

class Customer {
  const Customer({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.city,
    required this.birthYear,
    required this.card,
    this.deletedAt,
  });

  final int id;
  final String fullName;
  final String email;
  final String phone;
  final String city;
  final int birthYear;
  final LoyaltyCard card;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  Customer copyWith({
    String? fullName,
    String? email,
    String? phone,
    String? city,
    int? birthYear,
    LoyaltyCard? card,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Customer(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      city: city ?? this.city,
      birthYear: birthYear ?? this.birthYear,
      card: card ?? this.card,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'city': city,
        'birthYear': birthYear,
        'card': card.toJson(),
        'deletedAt': deletedAt?.toIso8601String(),
      };

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: readInt(json['id']),
      fullName: readString(json['fullName']),
      email: readString(json['email']),
      phone: readString(json['phone']),
      city: readString(json['city']),
      birthYear: readInt(json['birthYear']),
      card: LoyaltyCard.fromJson(readMap(json['card']) ?? const {}),
      deletedAt: readDate(json['deletedAt']),
    );
  }
}
