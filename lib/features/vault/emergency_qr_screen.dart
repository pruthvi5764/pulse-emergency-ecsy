import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:lifeline_nexus/providers/vault_provider.dart';
import 'package:lifeline_nexus/providers/auth_provider.dart';
import 'dart:convert';
import 'dart:ui';

class EmergencyQRScreen extends ConsumerWidget {
  const EmergencyQRScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final medicalProfile = ref.watch(medicalProfileProvider).value;

    final String qrData = _generateQRData(user, medicalProfile);

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          // Background Aura
          Positioned(
            bottom: -150,
            left: -50,
            child: Container(
              width: 600,
              height: 600,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Colors.white.withValues(alpha: 0.05), Colors.transparent],
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'EMERGENCY\nIDENTITY',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.5,
                        height: 0.9,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'SCAN TO ACCESS MEDICAL VAULT',
                      style: GoogleFonts.inter(
                        color: Colors.white38,
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                        letterSpacing: 2.0,
                      ),
                    ),
                    
                    const SizedBox(height: 48),
                    
                    // QR Container
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.1),
                            blurRadius: 40,
                            spreadRadius: 5,
                          )
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          QrImageView(
                            data: qrData,
                            version: QrVersions.auto,
                            size: 260.0,
                            gapless: false,
                            foregroundColor: Colors.black,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.security_rounded, color: Colors.black38, size: 14),
                              const SizedBox(width: 8),
                              Text(
                                'PULSE ENCRYPTED DATA',
                                style: GoogleFonts.inter(
                                  color: Colors.black38,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 9,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 48),
                    
                    // Summary Card
                    _buildSummaryCard(medicalProfile),
                    
                    const SizedBox(height: 40),
                    
                    Text(
                      'This QR contains your Blood Type, Allergies, and Emergency Contacts. Keep it accessible on your lock screen.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: Colors.white24,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _generateQRData(dynamic user, dynamic profile) {
    if (profile == null) return "Pulse Emergency Profile: Missing Data";
    
    final Map<String, dynamic> data = {
      "n": user?.displayName ?? "Unknown",
      "b": profile.demographics.bloodType,
      "a": profile.allergies.map((a) => a.allergen).toList(),
      "c": profile.chronicConditions,
      "e": profile.emergencyContacts.map((e) => {"n": e.name, "p": e.phone}).toList(),
    };
    
    return jsonEncode(data);
  }

  Widget _buildSummaryCard(dynamic profile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetric('BLOOD TYPE', profile?.demographics.bloodType ?? '??'),
              Container(height: 30, width: 1, color: Colors.white10),
              _buildMetric('ALLERGIES', '${profile?.allergies.length ?? 0}'),
              Container(height: 30, width: 1, color: Colors.white10),
              _buildMetric('CONTACTS', '${profile?.emergencyContacts.length ?? 0}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.0),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}
