import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:lifeline_nexus/core/constants.dart';
import 'package:flutter/foundation.dart';

class GeminiService {
  GenerativeModel? _model;
  
  GeminiService() {
    try {
      final key = ApiKeys.geminiApiKey;
      if (key.isNotEmpty) {
        _model = GenerativeModel(
          model: 'gemini-1.5-flash', 
          apiKey: key,
        );
      }
    } catch (e) {
      debugPrint('Gemini Service Init Error: $e');
    }
  }

  // Analyze an emergency situation and provide immediate medical advice
  Future<String?> analyzeEmergency({
    required String context,
    required List<String> allergies,
    required String bloodType,
  }) async {
    try {
      final prompt = '''
        CRITICAL EMERGENCY CONTEXT: $context
        USER MEDICAL DATA:
        - Blood Type: $bloodType
        - Allergies: ${allergies.join(', ')}
        
        TASK:
        1. Provide immediate, step-by-step first aid advice for this specific situation.
        2. Identify any contraindications based on the user's allergies.
        3. Keep instructions concise, high-contrast (use bolding), and calm.
        
        LIMIT: 150 words.
      ''';

      if (_model == null) return 'AI services are currently initializing or misconfigured.';

      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);
      
      return response.text;
    } catch (e) {
      debugPrint('Gemini Analysis Failed: $e');
      return 'System issue detecting AI context. Please follow standard emergency protocols.';
    }
  }

  // Diagnostic Analysis: Analyze symptoms and provide preliminary advice
  Future<String?> analyzeSymptoms({
    required String symptoms,
    required List<String> medications,
  }) async {
    try {
      final prompt = '''
        USER SYMPTOMS: $symptoms
        USER CURRENT MEDICATIONS: ${medications.join(', ')}
        
        TASK:
        1. Analyze potential causes (provide 2-3 most likely possibilities).
        2. Provide immediate non-emergency guidance (Self-care, rest, etc.).
        3. CRITICAL: Identify "Red Flags" that would require immediate SOS or ER visit.
        4. DISCLAIMER: State clearly that this is an AI-generated assessment, not a medical diagnosis.
        
        STYLE: Use a clean, futuristic layout with bullet points.
        LIMIT: 200 words.
      ''';

      if (_model == null) return 'Pulse AI intelligence is currently optimizing.';

      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);
      return response.text;
    } catch (e) {
      debugPrint('Gemini Symptom Analysis Failed: $e');
      return 'Pulse AI intelligence is currently optimizing. If you feel this is an emergency, trigger SOS now.';
    }
  }

  // Pre-process Medical Valet for optimized protocols (Phase 4 Intelligence)
  Future<String?> generatePersonalizedFirstAidPlan({
    required List<String> conditions,
    required List<String> allergies,
    required List<String> medications,
  }) async {
    try {
      final prompt = '''
        MEDICAL VALET PROFILE OPTIMIZATION:
        - Chronic Conditions: ${conditions.join(', ')}
        - Known Allergies: ${allergies.join(', ')}
        - Active Medications: ${medications.join(', ')}
        
        TASK:
        Generate a "PULSE AI MEDICAL ACTION PLAN".
        1. Identify the top 2 most critical risks for this user.
        2. Provide a 3-step concise guide for a bystander to help this specific user.
        3. Mention any critical medication the rescuer should look for (e.g. EpiPen, Inhaler, Glucose).
        
        STYLE: Professional, "Operative" tone. Use Markdown.
        LIMIT: 100 words.
      ''';

      if (_model == null) return null;

      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);
      return response.text;
    } catch (e) {
      return null;
    }
  }

  // Hospital Matching Logic (Placeholder for T-28+)
  Future<String?> matchHospital({
    required double lat,
    required double lng,
    required String emergencyType,
  }) async {
    // This will eventually integrate with Google Places + Gemini 
    return "Analyzing nearest specialized trauma centers...";
  }
}
