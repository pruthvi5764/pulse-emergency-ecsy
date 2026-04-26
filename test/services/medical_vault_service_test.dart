import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:lifeline_nexus/services/medical_vault_service.dart';
import 'package:lifeline_nexus/models/medical_profile.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mockito/mockito.dart';

// Manual Mock for FlutterSecureStorage
class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {
  final Map<String, String> _storage = {};

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value != null) _storage[key] = value;
  }

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _storage[key];
  }
}

// Simple Mock for FirebaseStorage
class MockFirebaseStorage extends Mock implements FirebaseStorage {}

void main() {
  group('MedicalVaultService Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MockFlutterSecureStorage mockSecureStorage;
    late MockFirebaseStorage mockStorage;
    late MedicalVaultService vaultService;
    
    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      mockSecureStorage = MockFlutterSecureStorage();
      mockStorage = MockFirebaseStorage();
      vaultService = MedicalVaultService(
        firestore: fakeFirestore,
        secureStorage: mockSecureStorage,
        storage: mockStorage,
      );
    });

    test('Task T-81: saveProfile successfully writes to Firestore and SecureStorage', () async {
      final profile = MedicalProfile(
        uid: 'test-user-123',
        lastUpdated: DateTime.now(),
        demographics: Demographics(
          dob: '1990-01-01',
          biologicalSex: 'Male',
          bloodType: 'AB-',
          heightCm: 180,
          weightKg: 75,
          organDonor: true,
        ),
        specialStatus: SpecialStatus(isPregnant: false, mobilityIssues: false),
      );

      // Act
      await vaultService.saveProfile(profile);

      // Assert Firestore
      final snapshot = await fakeFirestore
          .collection('users')
          .doc('test-user-123')
          .collection('medical_profile')
          .doc('latest')
          .get();

      expect(snapshot.exists, isTrue);
      expect(snapshot.data()?['uid'], 'test-user-123');
      expect(snapshot.data()?['base_demographics']['blood_type'], 'AB-');
      
      // Assert SecureStorage cache (T-71 logic)
      final cachedString = await mockSecureStorage.read(key: 'cached_medical_profile');
      expect(cachedString, isNotNull);
      
      final cachedJson = jsonDecode(cachedString!);
      expect(cachedJson['uid'], 'test-user-123');
      expect(cachedJson['base_demographics']['blood_type'], 'AB-');
    });

    test('Task T-81: fetchProfile successfully reads from Firestore', () async {
      // Arrange setup data using the new model structure
      final profile = MedicalProfile(
        uid: 'test-user-456',
        lastUpdated: DateTime.now(),
        demographics: Demographics(
          dob: '1985-01-01',
          biologicalSex: 'Female',
          bloodType: 'O-',
          heightCm: 160,
          weightKg: 55,
          organDonor: false,
        ),
        chronicConditions: ['Asthma'],
        specialStatus: SpecialStatus(isPregnant: false, mobilityIssues: false),
      );

      await fakeFirestore
          .collection('users')
          .doc('test-user-456')
          .collection('medical_profile')
          .doc('latest')
          .set(profile.toMap());

      // Act
      final fetchedProfile = await vaultService.fetchProfile('test-user-456');

      // Assert
      expect(fetchedProfile, isNotNull);
      expect(fetchedProfile!.uid, 'test-user-456');
      expect(fetchedProfile.demographics.bloodType, 'O-');
      expect(fetchedProfile.chronicConditions, contains('Asthma'));
    });
    
    test('Task T-81: fetchProfile returns null if no document exists', () async {
      final fetchedProfile = await vaultService.fetchProfile('non-existent-user');
      expect(fetchedProfile, isNull);
    });
  });
}
