import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeline_nexus/models/medical_profile.dart';
import 'package:lifeline_nexus/services/medical_vault_service.dart';
import 'package:lifeline_nexus/providers/auth_provider.dart';

// Provider for the MedicalVaultService instance (keepAlive to avoid recreation)
final medicalVaultServiceProvider = Provider<MedicalVaultService>((ref) {
  return MedicalVaultService();
});

// StreamProvider for the user's medical profile (Task T-21)
final medicalProfileProvider = StreamProvider<MedicalProfile?>((ref) {
  final authState = ref.watch(authStateProvider);
  final vaultService = ref.watch(medicalVaultServiceProvider);

  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      return vaultService.profileStream(user.uid);
    },
    loading: () => const Stream.empty(),
    error: (err, stack) => Stream.value(null),
  );
}, dependencies: [authStateProvider, medicalVaultServiceProvider]);
