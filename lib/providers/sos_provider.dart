import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeline_nexus/providers/auth_provider.dart';
import 'package:lifeline_nexus/providers/location_provider.dart';
import 'package:lifeline_nexus/providers/vault_provider.dart';
import 'package:lifeline_nexus/services/voice_trigger_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';

class SOSState {
  final bool isTriggered;
  final bool isListening;
  final bool isCountdownActive;
  final int countdownSeconds;
  final String reason;
  final String context;
  final String alertId;
  final bool isUserSpeaking;
  final bool isMicActive;

  SOSState({
    this.isTriggered = false,
    this.isListening = false,
    this.isCountdownActive = false,
    this.countdownSeconds = 10,
    this.reason = '',
    this.context = '',
    this.alertId = '',
    this.isUserSpeaking = false,
    this.isMicActive = false,
  });

  SOSState copyWith({
    bool? isTriggered,
    bool? isListening,
    bool? isCountdownActive,
    int? countdownSeconds,
    String? reason,
    String? context,
    String? alertId,
    bool? isUserSpeaking,
    bool? isMicActive,
  }) {
    return SOSState(
      isTriggered: isTriggered ?? this.isTriggered,
      isListening: isListening ?? this.isListening,
      isCountdownActive: isCountdownActive ?? this.isCountdownActive,
      countdownSeconds: countdownSeconds ?? this.countdownSeconds,
      reason: reason ?? this.reason,
      context: context ?? this.context,
      alertId: alertId ?? this.alertId,
      isUserSpeaking: isUserSpeaking ?? this.isUserSpeaking,
      isMicActive: isMicActive ?? this.isMicActive,
    );
  }

  static SOSState idle() => SOSState();
}

class SOSNotifier extends Notifier<SOSState> {
  final VoiceTriggerService _voiceService = VoiceTriggerService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _countdownTimer;
  Timer? _silenceTimer;

  @override
  SOSState build() {
    // Moved side effects out of build for stability
    return SOSState.idle();
  }

  Future<void> startBufferedTrigger() async {
    if (state.isTriggered || state.isCountdownActive) return;

    state = state.copyWith(
      isCountdownActive: true,
      countdownSeconds: 10,
      isListening: true,
      isUserSpeaking: false,
      isMicActive: true,
      context: '', 
    );

    await _voiceService.startListening(
      enableTriggerDetection: true,
      onResult: (text) {
        if (text.trim().isNotEmpty) {
          if (!state.isUserSpeaking) {
            _stopCountdown();
            state = state.copyWith(isUserSpeaking: true, isListening: true);
          }
          
          state = state.copyWith(context: text);

          _silenceTimer?.cancel();
          _silenceTimer = Timer(const Duration(seconds: 30), () {
            if (state.isUserSpeaking && !state.isTriggered) {
              triggerSOS('User Explanation: ${state.context}');
            }
          });
        }
      },
      onTriggerDetected: () {
         if (!state.isTriggered) {
           triggerSOS('Voice Command Detected');
         }
      },
    );

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.countdownSeconds <= 1) {
        _stopCountdown();
        triggerSOS('Automatic Timed Trigger');
      } else {
        state = state.copyWith(countdownSeconds: state.countdownSeconds - 1);
      }
    });
  }

  void _stopCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    state = state.copyWith(isCountdownActive: false);
  }

  Future<void> triggerSOS(String reason) async {
    if (state.isTriggered) return;

    _silenceTimer?.cancel();
    _stopCountdown();

    // 1. Capture Point-in-Time Data
    final user = ref.read(authStateProvider).value;
    final location = ref.read(locationProvider).value;
    final medicalProfile = ref.read(medicalProfileProvider).value;

    state = state.copyWith(
      isTriggered: true,
      reason: reason,
      isListening: false, 
      isUserSpeaking: false,
      isMicActive: false,
    );

    await _voiceService.stopListening();
    _playEmergencyFeedback();

    if (user == null) return;

    try {
      // 2. Embed Medical Snapshot (T-16/T-17 Integration)
      final Map<String, dynamic> medicalSnapshot = medicalProfile != null ? {
        'bloodType': medicalProfile.demographics.bloodType,
        'allergies': medicalProfile.allergies.map((a) => a.allergen).toList(),
        'chronicIllnesses': medicalProfile.chronicConditions,
        'medications': medicalProfile.activeMedications.map((m) => m.name).toList(),
        'emergencyContacts': medicalProfile.emergencyContacts.map((e) => e.toMap()).toList(),
      } : {};

      final docRef = await FirebaseFirestore.instance.collection('emergency_alerts').add({
        'userId': user.uid,
        'userName': user.displayName,
        'timestamp': FieldValue.serverTimestamp(),
        'reason': reason,
        'latitude': location?.latitude,
        'longitude': location?.longitude,
        'status': 'active',
        'context': state.context ?? '',
        'medicalSnapshot': medicalSnapshot, // The snapshot implementation
      });
      
      state = state.copyWith(alertId: docRef.id);
    } catch (e) {
      debugPrint('SOS Broadcast Error: $e');
    }
  }

  Future<void> _playEmergencyFeedback() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(pattern: [500, 1000, 500, 1000], repeat: 0);
    }

    try {
      await _audioPlayer.play(UrlSource('https://assets.mixkit.co/active_storage/sfx/2568/2568-preview.mp3'));
    } catch (e) {
      debugPrint('Audio playback failed: $e');
    }
  }

  void cancelFeedback() {
    _audioPlayer.stop();
    Vibration.cancel();
  }

  Future<void> _updateFirestoreContext(String context) async {
    if (state.alertId == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('emergency_alerts')
          .doc(state.alertId)
          .update({'context': context});
    } catch (_) {}
  }

  Future<void> cancelSOS() async {
    _stopCountdown();
    _silenceTimer?.cancel();
    await _voiceService.stopListening();
    cancelFeedback();
    state = SOSState.idle().copyWith(isMicActive: false);
  }
}

final sosProvider = NotifierProvider<SOSNotifier, SOSState>(() {
  return SOSNotifier();
});
