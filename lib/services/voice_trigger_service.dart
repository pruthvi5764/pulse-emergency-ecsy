import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter/foundation.dart';

class VoiceTriggerService {
  final SpeechToText _speech = SpeechToText();
  bool _shouldBeListening = false;
  bool _triggerDetectionEnabled = true; // Flag to stop trigger loops
  final String _triggerPhrase = 'emergency help me';
  
  Function(String)? _lastOnResult;
  VoidCallback? _lastOnTriggerDetected;

  // Initialize the speech-to-text engine
  Future<bool> initialize() async {
    try {
      final bool available = await _speech.initialize(
        onStatus: (status) {
          debugPrint('STT Status: $status');
          if ((status == 'done' || status == 'notListening') && _shouldBeListening) {
            _restartListening();
          }
        },
        onError: (error) {
          debugPrint('STT Error: $error');
          // Only restart on transient errors, not permanent ones
          if (_shouldBeListening && error.errorMsg != 'error_no_match') {
            _restartListening();
          }
        },
      );
      return available;
    } catch (e) {
      debugPrint('STT Initialization failed: $e');
      return false;
    }
  }

  Future<void> _restartListening() async {
    if (!_shouldBeListening || _lastOnResult == null) return;
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (_shouldBeListening) {
      await _startEngine();
    }
  }

  Future<void> _startEngine() async {
    if (!_shouldBeListening) return;
    
    await _speech.listen(
      onResult: (result) {
        final transcription = result.recognizedWords.toLowerCase();
        if (_lastOnResult != null) _lastOnResult!(transcription);

        // ONLY detect triggers if we aren't already in an emergency session
        if (_triggerDetectionEnabled && 
            transcription.contains(_triggerPhrase) && 
            _lastOnTriggerDetected != null) {
          _lastOnTriggerDetected!();
          // We don't stop listening entirely, but we disable trigger detection
          // so it doesn't loop.
          _triggerDetectionEnabled = false; 
        }
      },
      listenFor: const Duration(seconds: 60),
      pauseFor: const Duration(seconds: 30),
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: false,
        listenMode: ListenMode.dictation,
      ),
    );
  }

  // Start listening. triggerDetectionEnabled: false is used for post-trigger context logging.
  Future<void> startListening({
    required Function(String) onResult,
    required VoidCallback onTriggerDetected,
    bool enableTriggerDetection = true,
  }) async {
    _lastOnResult = onResult;
    _lastOnTriggerDetected = onTriggerDetected;
    _shouldBeListening = true;
    _triggerDetectionEnabled = enableTriggerDetection;

    final available = await initialize();
    if (available) {
      await _startEngine();
    }
  }

  Future<void> stopListening() async {
    _shouldBeListening = false;
    _triggerDetectionEnabled = false;
    await _speech.stop();
  }

  bool get isListening => _shouldBeListening && _speech.isListening;
}
