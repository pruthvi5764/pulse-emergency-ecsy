import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class OfflineFallbackService {
  static const String _nationalEmergencyNumber = "911"; // Placeholder, can be localized later

  /// Task T-68/T-71: Fallback method to send an SMS with cached critical medical info and GPS.
  Future<bool> sendSOS({
    required double lat,
    required double lng,
  }) async {
    try {
      const secureStorage = FlutterSecureStorage();
      final cachedProfileString = await secureStorage.read(key: 'cached_medical_profile');
      
      String bloodType = "Unknown";
      String criticalConditions = "None listed";

      if (cachedProfileString != null) {
        try {
          final profileMap = jsonDecode(cachedProfileString);
          bloodType = profileMap['bloodType']?.toString() ?? 'Unknown';
          
          final conditions = (profileMap['specialConditions'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
          final allergies = (profileMap['allergies'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
          
          List<String> combined = [...conditions, ...allergies];
          if (combined.isNotEmpty) {
            criticalConditions = combined.join(", ");
          }
        } catch (e) {
          debugPrint('Error parsing cached profile: $e');
        }
      }

      final smsBody = "🚨 LIFELINE NEXUS OFFLINE SOS 🚨\n"
          "Location: https://www.google.com/maps?q=$lat,$lng\n"
          "Blood Type: $bloodType\n"
          "Critical/Allergies: $criticalConditions\n"
          "Immediate assistance required.";

      // URL encode the body
      final encodedBody = Uri.encodeComponent(smsBody);
      
      final String uriString;
      if (Platform.isAndroid) {
        uriString = 'sms:$_nationalEmergencyNumber?body=$encodedBody';
      } else if (Platform.isIOS) {
        uriString = 'sms:$_nationalEmergencyNumber&body=$encodedBody';
      } else {
        uriString = 'sms:$_nationalEmergencyNumber?body=$encodedBody';
      }

      final Uri smsUri = Uri.parse(uriString);

      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
        return true;
      } else {
        debugPrint('Could not launch SMS URI');
        return false;
      }
    } catch (e) {
      debugPrint('Failed offline SMS fallback: $e');
      return false;
    }
  }
}
