import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeline_nexus/models/medical_profile.dart';
import 'package:lifeline_nexus/services/gemini_service.dart';
import 'package:lifeline_nexus/providers/vault_provider.dart';

// Provider for the GeminiService instance
final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService();
});

// State class for AI-generated emergency advice
class EmergencyAIState {
  final String advice;
  final String optimizedActionPlan;
  final bool isLoading;
  final String error;

  const EmergencyAIState({
    this.advice = '', 
    this.optimizedActionPlan = '',
    this.isLoading = false, 
    this.error = ''
  });

  EmergencyAIState copyWith({
    String? advice, 
    String? optimizedActionPlan,
    bool? isLoading, 
    String? error
  }) {
    return EmergencyAIState(
      advice: advice ?? this.advice,
      optimizedActionPlan: optimizedActionPlan ?? this.optimizedActionPlan,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// Notifier — uses Riverpod 3.x Notifier (replaces deprecated StateNotifier)
class GeminiNotifier extends Notifier<EmergencyAIState> {
  @override
  EmergencyAIState build() {
    // Temporarily disabled to debug ProviderException
    return const EmergencyAIState();
  }

  // Pre-generate optimized first aid based on valet
  Future<void> optimizeProtocols(MedicalProfile profile) async {
    try {
      final geminiService = ref.read(geminiServiceProvider);
      final plan = await geminiService.generatePersonalizedFirstAidPlan(
        conditions: profile.chronicConditions,
        allergies: profile.allergies.map((a) => a.allergen).toList(),
        medications: profile.activeMedications.map((m) => m.name).toList(),
      );
      state = state.copyWith(optimizedActionPlan: plan);
    } catch (e) {
      debugPrint('AI Protocol Optimization Error: $e');
    }
  }

  // Trigger Gemini analysis for an active emergency
  Future<void> conductEmergencyAnalysis(String context) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final geminiService = ref.read(geminiServiceProvider);
      final medicalRecord = ref.read(medicalProfileProvider).value;

      final advice = await geminiService.analyzeEmergency(
        context: context,
        bloodType: medicalRecord?.demographics.bloodType ?? 'Unknown',
        allergies: medicalRecord?.allergies.map((a) => a.allergen).toList() ?? [],
      );

      state = state.copyWith(advice: advice, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Analyze symptoms for the diagnostic module
  Future<void> conductSymptomAnalysis(String symptoms) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final geminiService = ref.read(geminiServiceProvider);
      final medicalRecord = ref.read(medicalProfileProvider).value;

      final result = await geminiService.analyzeSymptoms(
        symptoms: symptoms,
        medications: medicalRecord?.activeMedications.map((m) => m.name).toList() ?? [],
      );

      state = state.copyWith(advice: result, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clearAnalysis() {
    state = const EmergencyAIState();
  }
}

// Global provider for Gemini AI logic — using NotifierProvider (Riverpod 3.x)
final geminiProvider =
    NotifierProvider<GeminiNotifier, EmergencyAIState>(GeminiNotifier.new);
