import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:lifeline_nexus/models/medical_profile.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class MedicalVaultService {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final FlutterSecureStorage _secureStorage;

  MedicalVaultService({
    FirebaseFirestore? firestore, 
    FirebaseStorage? storage,
    FlutterSecureStorage? secureStorage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  // Save or update the user's medical profile (Task T-20)
  Future<void> saveProfile(MedicalProfile profile) async {
    try {
      await _firestore
          .collection('users')
          .doc(profile.uid)
          .collection('medical_profile')
          .doc('latest') // Storing as 'latest' for single-profile consistency
          .set(profile.toMap());
          
      // Cache locally for offline fallback securely (Task T-71, Security Fix)
      await _secureStorage.write(
        key: 'cached_medical_profile', 
        value: jsonEncode(profile.toMap())
      );
      
      debugPrint('Medical profile saved successfully to Firestore and securely locally.');
    } catch (e) {
      debugPrint('Error saving medical profile: $e');
      rethrow; // Ensure UI can catch and handle
    }
  }

  // Fetch the user's medical profile (Task T-20)
  Future<MedicalProfile?> fetchProfile(String uid) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('medical_profile')
          .doc('latest')
          .get();
          
      if (doc.exists && doc.data() != null) {
        return MedicalProfile.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching medical profile: $e');
      return null;
    }
  }

  // Stream of the medical profile for real-time updates (Task T-21)
  Stream<MedicalProfile?> profileStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('medical_profile')
        .doc('latest')
        .snapshots()
        .map((snapshot) {
          if (snapshot.exists && snapshot.data() != null) {
            return MedicalProfile.fromMap(snapshot.data()!);
          }
          return null;
        })
        .handleError((error) {
          debugPrint('Error streaming medical profile: $error');
        });
  }

  // Upload a medical document to storage (Task T-25)
  Future<String?> uploadDocument(String uid, File file) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final ref = _storage.ref().child('users/$uid/documents/$fileName');
      
      final uploadTask = await ref.putFile(file);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading document to Storage: $e');
      return null;
    }
  }
}
