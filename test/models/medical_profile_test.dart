import 'package:flutter_test/flutter_test.dart';
import 'package:lifeline_nexus/models/medical_profile.dart';

void main() {
  group('MedicalProfile Tests', () {
    test('Task T-82: successfully deserializes from Firestore map', () {
      final mapData = {
        'uid': 'user123',
        'last_updated': '2023-10-27T10:00:00.000',
        'base_demographics': {
          'dob': '1990-01-01',
          'biological_sex': 'Male',
          'blood_type': 'O+',
          'height_cm': 180.0,
          'weight_kg': 75.0,
          'organ_donor': true,
        },
        'critical_alerts': [
          {'type': 'Device', 'detail': 'Pacemaker', 'ai_routing_tag': 'CARDIAC'}
        ],
        'allergies': [
          {'allergen': 'Peanuts', 'reaction': 'Anaphylaxis', 'severity': 'CRITICAL'}
        ],
        'active_medications': [
          {'name': 'Insulin', 'dosage': '10 units', 'frequency': 'Daily'}
        ],
        'chronic_conditions': ['Type 1 Diabetes'],
        'special_status': {
          'is_pregnant': false,
          'mobility_issues': false,
        },
        'emergency_contacts': [
          {'name': 'Jane Doe', 'phone': '555-0100', 'relation': 'Mother'}
        ],
        'document_urls': ['https://example.com/doc.pdf']
      };

      final profile = MedicalProfile.fromMap(mapData);

      expect(profile.uid, 'user123');
      expect(profile.demographics.bloodType, 'O+');
      expect(profile.activeMedications.first.name, 'Insulin');
      expect(profile.allergies.first.allergen, 'Peanuts');
      expect(profile.chronicConditions, contains('Type 1 Diabetes'));
      expect(profile.specialStatus.isPregnant, isFalse);
      expect(profile.emergencyContacts.length, 1);
      expect(profile.documentUrls.length, 1);
    });

    test('Task T-82: handles missing fields safely with defaults', () {
      final mapData = {
        'uid': 'user456',
        // Minimal data
      };

      final profile = MedicalProfile.fromMap(mapData);

      expect(profile.uid, 'user456');
      expect(profile.demographics.bloodType, 'Unknown');
      expect(profile.activeMedications, isEmpty);
      expect(profile.allergies, isEmpty);
      expect(profile.emergencyContacts, isEmpty);
      expect(profile.specialStatus.isPregnant, isFalse);
    });
    
    test('Task T-82: successfully serializes to map', () {
       final profile = MedicalProfile(
          uid: 'user789',
          lastUpdated: DateTime.now(),
          demographics: Demographics(
            dob: '1985-05-05',
            biologicalSex: 'Female',
            bloodType: 'A-',
            heightCm: 165,
            weightKg: 60,
            organDonor: false,
          ),
          specialStatus: SpecialStatus(isPregnant: true, mobilityIssues: false),
          allergies: [
            Allergy(allergen: 'Latex', reaction: 'Rash', severity: 'LOW')
          ],
       );
       
       final toMapResult = profile.toMap();
       
       expect(toMapResult['uid'], 'user789');
       expect(toMapResult['base_demographics']['blood_type'], 'A-');
       expect(toMapResult['allergies'].first['allergen'], 'Latex');
       expect(toMapResult['special_status']['is_pregnant'], isTrue);
    });
  });
}
