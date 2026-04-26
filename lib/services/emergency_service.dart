import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

class EmergencyService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Task T-41: triggerEmergency.
  /// Calls the 'initiateEmergency' Cloud Function and returns the dispatch details.
  Future<Map<String, dynamic>?> triggerEmergency({
    required String uid,
    required double lat,
    required double lng,
    String? emergencyType,
  }) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('initiateEmergency');
      
      final result = await callable.call({
        'uid': uid,
        'lat': lat,
        'lng': lng,
        'emergencyType': emergencyType ?? 'medical',
      });

      return result.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Cloud Function Error: $e');
      return null;
    }
  }

  /// Task T-55: Placeholder for Phase 9 dispatch trigger.
  Future<void> triggerDispatch(String emergencyId) async {
     try {
      final HttpsCallable callable = _functions.httpsCallable('dispatchEmergency');
      await callable.call({'emergencyId': emergencyId});
    } catch (e) {
      debugPrint('Dispatch Error: $e');
    }
  }

  /// Task T-64: getBystanderInstructions.
  /// Calls the 'getFirstAidInstructions' Cloud Function and returns the steps.
  Future<List<String>?> getBystanderInstructions({
    required String description,
  }) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('getFirstAidInstructions');
      final result = await callable.call({'emergencyDescription': description});
      final data = result.data as Map<String, dynamic>;
      final steps = data['steps'] as List<dynamic>?;
      return steps?.map((e) => e.toString()).toList();
    } catch (e) {
      debugPrint('Cloud Function Error (First Aid): $e');
      return null;
    }
  }
}
