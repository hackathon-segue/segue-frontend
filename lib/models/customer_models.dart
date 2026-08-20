import 'json_utils.dart';

enum ConsentStatus {
  agree('AGREE'),
  disagree('DISAGREE');

  const ConsentStatus(this.wireName);

  final String wireName;

  static ConsentStatus fromWire(String value) {
    return ConsentStatus.values.firstWhere(
      (ConsentStatus status) => status.wireName == value,
      orElse: () => ConsentStatus.disagree,
    );
  }
}

class Customer {
  const Customer({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.hasConsented,
    this.email = '',
  });

  factory Customer.fromJson(JsonMap json) {
    return Customer(
      id: intValue(json, 'id', defaultValue: intValue(json, 'customerId')),
      name: stringValue(json, 'name'),
      phoneNumber: stringValue(
        json,
        'phoneNumber',
        defaultValue: stringValue(json, 'phone'),
      ),
      hasConsented: boolValue(json, 'hasConsented'),
      email: stringValue(json, 'email'),
    );
  }

  final int id;
  final String name;
  final String phoneNumber;
  final bool hasConsented;
  final String email;

  Customer copyWith({bool? hasConsented, String? email}) {
    return Customer(
      id: id,
      name: name,
      phoneNumber: phoneNumber,
      hasConsented: hasConsented ?? this.hasConsented,
      email: email ?? this.email,
    );
  }

  JsonMap toJson() {
    return <String, Object?>{
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'hasConsented': hasConsented,
      'email': email,
    };
  }
}

class CustomerConsent {
  const CustomerConsent({
    required this.customerId,
    required this.status,
    required this.scope,
    required this.consentedAt,
  });

  factory CustomerConsent.fromJson(JsonMap json) {
    return CustomerConsent(
      customerId: intValue(json, 'customerId'),
      status: ConsentStatus.fromWire(stringValue(json, 'status')),
      scope: stringValue(json, 'scope'),
      consentedAt: dateTimeValue(json, 'consentedAt') ?? DateTime(1970),
    );
  }

  final int customerId;
  final ConsentStatus status;
  final String scope;
  final DateTime consentedAt;

  bool get hasAgreed => status == ConsentStatus.agree;

  JsonMap toJson() {
    return <String, Object?>{
      'customerId': customerId,
      'status': status.wireName,
      'scope': scope,
      'consentedAt': consentedAt.toIso8601String(),
    };
  }
}
