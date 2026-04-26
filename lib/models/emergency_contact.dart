import 'package:flutter/foundation.dart';

@immutable
class EmergencyContact {
  final String name;
  final String phone;
  final String relation;

  const EmergencyContact({
    required this.name,
    required this.phone,
    required this.relation,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'relation': relation,
    };
  }

  // Added safe type casting
  factory EmergencyContact.fromMap(Map<String, dynamic> map) {
    return EmergencyContact(
      name: map['name']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      relation: map['relation']?.toString() ?? '',
    );
  }

  // Added copyWith for state management
  EmergencyContact copyWith({
    String? name,
    String? phone,
    String? relation,
  }) {
    return EmergencyContact(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      relation: relation ?? this.relation,
    );
  }
}
