import 'dart:convert';

class MedicalProfile {
  final String uid;
  final DateTime lastUpdated;
  final Demographics demographics;
  final List<CriticalAlert> criticalAlerts;
  final List<Allergy> allergies;
  final List<Medication> activeMedications;
  final List<String> chronicConditions;
  final SpecialStatus specialStatus;
  final List<EmergencyContact> emergencyContacts;
  final List<String> documentUrls;

  MedicalProfile({
    required this.uid,
    required this.lastUpdated,
    required this.demographics,
    this.criticalAlerts = const [],
    this.allergies = const [],
    this.activeMedications = const [],
    this.chronicConditions = const [],
    required this.specialStatus,
    this.emergencyContacts = const [],
    this.documentUrls = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'last_updated': lastUpdated.toIso8601String(),
      'base_demographics': demographics.toMap(),
      'critical_alerts': criticalAlerts.map((x) => x.toMap()).toList(),
      'allergies': allergies.map((x) => x.toMap()).toList(),
      'active_medications': activeMedications.map((x) => x.toMap()).toList(),
      'chronic_conditions': chronicConditions,
      'special_status': specialStatus.toMap(),
      'emergency_contacts': emergencyContacts.map((x) => x.toMap()).toList(),
      'document_urls': documentUrls,
    };
  }

  factory MedicalProfile.fromMap(Map<String, dynamic> map) {
    return MedicalProfile(
      uid: map['uid'] ?? '',
      lastUpdated: map['last_updated'] != null ? DateTime.parse(map['last_updated']) : DateTime.now(),
      demographics: Demographics.fromMap(map['base_demographics'] ?? {}),
      criticalAlerts: List<CriticalAlert>.from((map['critical_alerts'] ?? []).map((x) => CriticalAlert.fromMap(x))),
      allergies: List<Allergy>.from((map['allergies'] ?? []).map((x) => Allergy.fromMap(x))),
      activeMedications: List<Medication>.from((map['active_medications'] ?? []).map((x) => Medication.fromMap(x))),
      chronicConditions: List<String>.from(map['chronic_conditions'] ?? []),
      specialStatus: SpecialStatus.fromMap(map['special_status'] ?? {}),
      emergencyContacts: List<EmergencyContact>.from((map['emergency_contacts'] ?? []).map((x) => EmergencyContact.fromMap(x))),
      documentUrls: List<String>.from(map['document_urls'] ?? []),
    );
  }

  String toJson() => json.encode(toMap());
  factory MedicalProfile.fromJson(String source) => MedicalProfile.fromMap(json.decode(source));

  // Added copyWith for state management consistency
  MedicalProfile copyWith({
    String? uid,
    DateTime? lastUpdated,
    Demographics? demographics,
    List<CriticalAlert>? criticalAlerts,
    List<Allergy>? allergies,
    List<Medication>? activeMedications,
    List<String>? chronicConditions,
    SpecialStatus? specialStatus,
    List<EmergencyContact>? emergencyContacts,
    List<String>? documentUrls,
  }) {
    return MedicalProfile(
      uid: uid ?? this.uid,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      demographics: demographics ?? this.demographics,
      criticalAlerts: criticalAlerts ?? this.criticalAlerts,
      allergies: allergies ?? this.allergies,
      activeMedications: activeMedications ?? this.activeMedications,
      chronicConditions: chronicConditions ?? this.chronicConditions,
      specialStatus: specialStatus ?? this.specialStatus,
      emergencyContacts: emergencyContacts ?? this.emergencyContacts,
      documentUrls: documentUrls ?? this.documentUrls,
    );
  }
}

class Demographics {
  final String dob; // Format: YYYY-MM-DD
  final String biologicalSex;
  final String bloodType;
  final double heightCm;
  final double weightKg;
  final bool organDonor;

  Demographics({
    required this.dob,
    required this.biologicalSex,
    required this.bloodType,
    required this.heightCm,
    required this.weightKg,
    required this.organDonor,
  });

  Map<String, dynamic> toMap() {
    return {
      'dob': dob,
      'biological_sex': biologicalSex,
      'blood_type': bloodType,
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'organ_donor': organDonor,
    };
  }

  factory Demographics.fromMap(Map<String, dynamic> map) {
    return Demographics(
      dob: map['dob'] ?? '',
      biologicalSex: map['biological_sex'] ?? 'Unknown',
      bloodType: map['blood_type'] ?? 'Unknown',
      heightCm: (map['height_cm'] ?? 0).toDouble(),
      weightKg: (map['weight_kg'] ?? 0).toDouble(),
      organDonor: map['organ_donor'] ?? false,
    );
  }
}

class CriticalAlert {
  final String type; // e.g., "Implanted_Device", "Missing_Organ"
  final String detail; // e.g., "Pacemaker (Medtronic)"
  final String aiRoutingTag; // e.g., "CARDIAC_CAPABILITY_REQUIRED"

  CriticalAlert({required this.type, required this.detail, required this.aiRoutingTag});

  Map<String, dynamic> toMap() => {'type': type, 'detail': detail, 'ai_routing_tag': aiRoutingTag};
  factory CriticalAlert.fromMap(Map<String, dynamic> map) => CriticalAlert(
    type: map['type'] ?? '', detail: map['detail'] ?? '', aiRoutingTag: map['ai_routing_tag'] ?? ''
  );
}

class Allergy {
  final String allergen;
  final String reaction;
  final String severity; // "LOW", "MEDIUM", "CRITICAL"

  Allergy({required this.allergen, required this.reaction, required this.severity});

  Map<String, dynamic> toMap() => {'allergen': allergen, 'reaction': reaction, 'severity': severity};
  factory Allergy.fromMap(Map<String, dynamic> map) => Allergy(
    allergen: map['allergen'] ?? '', reaction: map['reaction'] ?? '', severity: map['severity'] ?? 'LOW'
  );
}

class Medication {
  final String name;
  final String dosage;
  final String frequency;

  Medication({required this.name, required this.dosage, required this.frequency});

  Map<String, dynamic> toMap() => {'name': name, 'dosage': dosage, 'frequency': frequency};
  factory Medication.fromMap(Map<String, dynamic> map) => Medication(
    name: map['name'] ?? '', dosage: map['dosage'] ?? '', frequency: map['frequency'] ?? ''
  );
}

class SpecialStatus {
  final bool isPregnant;
  final String? estimatedDueDate;
  final bool mobilityIssues;

  SpecialStatus({required this.isPregnant, this.estimatedDueDate, required this.mobilityIssues});

  Map<String, dynamic> toMap() => {'is_pregnant': isPregnant, 'estimated_due_date': estimatedDueDate, 'mobility_issues': mobilityIssues};
  factory SpecialStatus.fromMap(Map<String, dynamic> map) => SpecialStatus(
    isPregnant: map['is_pregnant'] ?? false, estimatedDueDate: map['estimated_due_date'], mobilityIssues: map['mobility_issues'] ?? false
  );
}

class EmergencyContact {
  final String name;
  final String phone;
  final String relation;

  EmergencyContact({required this.name, required this.phone, required this.relation});

  Map<String, dynamic> toMap() => {'name': name, 'phone': phone, 'relation': relation};
  factory EmergencyContact.fromMap(Map<String, dynamic> map) => EmergencyContact(
    name: map['name'] ?? '', phone: map['phone'] ?? '', relation: map['relation'] ?? ''
  );
}
