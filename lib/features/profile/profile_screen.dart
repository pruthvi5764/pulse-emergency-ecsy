import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lifeline_nexus/providers/auth_provider.dart';
import 'package:lifeline_nexus/features/vault/emergency_qr_screen.dart';
import 'dart:ui';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final isAnonymous = user?.isAnonymous ?? false;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Dynamic Aura Background
          Positioned(
            top: -100,
            right: -50,
            child: _buildAuraCircle(const Color(0xFF2979FF).withValues(alpha: 0.1), 500),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Text(
                    'PROFILE',
                    style: GoogleFonts.inter(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -2.0,
                      height: 0.9,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Profile Card
                  _buildProfileCard(user),
                  
                  const SizedBox(height: 40),
                  
                  _buildSectionLabel('SECURITY SETTINGS'),
                  _buildMenuTile(
                    Icons.qr_code_2_rounded, 
                    'EMERGENCY QR IDENTITY', 
                    'Scan for rapid medical access',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencyQRScreen())),
                  ),
                  _buildMenuTile(Icons.shield_outlined, 'BIOMETRIC LOCK', 'Secured with FaceID/TouchID'),
                  _buildMenuTile(Icons.key_outlined, 'ENCRYPTION KEYS', 'End-to-end medical data security'),
                  
                  const SizedBox(height: 24),
                  
                  _buildSectionLabel('ACCOUNT'),
                  _buildMenuTile(
                    Icons.logout_rounded, 
                    'SIGN OUT', 
                    'Securely terminate session',
                    onTap: () => ref.read(authServiceProvider).signOut(),
                    isDestructive: true,
                  ),
                  
                  const SizedBox(height: 40),
                  
                  Center(
                    child: Text(
                      'PULSE v1.0.4 • ENCRYPTED',
                      style: GoogleFonts.inter(
                        color: Colors.white10,
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(dynamic user) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white.withValues(alpha: 0.05),
            backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
            child: user?.photoURL == null 
              ? const Icon(Icons.person_outline_rounded, color: Colors.white24, size: 32) 
              : null,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (user?.displayName ?? 'Anonymous User').toUpperCase(),
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? 'Emergency Bypass Mode',
                  style: GoogleFonts.inter(color: Colors.white24, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile(IconData icon, String title, String subtitle, {VoidCallback? onTap, bool isDestructive = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF0F0F0F),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
        ),
        child: Row(
          children: [
            Icon(icon, color: isDestructive ? const Color(0xFFFF5252) : Colors.white70, size: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      color: isDestructive ? const Color(0xFFFF5252) : Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(color: Colors.white24, fontSize: 11),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.white.withValues(alpha: 0.05), size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: Colors.white24,
          fontWeight: FontWeight.w900,
          letterSpacing: 2.0,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildAuraCircle(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0.0)],
        ),
      ),
    );
  }
}
