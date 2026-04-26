import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lifeline_nexus/providers/auth_provider.dart';
import 'package:lifeline_nexus/features/vault/medical_vault_screen.dart';
import 'package:lifeline_nexus/features/home/emergency_dashboard.dart';
import 'package:lifeline_nexus/features/bystander/bystander_mode_screen.dart';
import 'package:lifeline_nexus/features/profile/profile_screen.dart';
import 'package:lifeline_nexus/ui/theme/app_theme.dart';
import 'dart:ui';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const EmergencyDashboard(),
    const BystanderModeScreen(),
    const MedicalVaultScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final isAnonymous = user?.isAnonymous ?? false;

    return Scaffold(
      backgroundColor: Colors.black,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          const EmergencyDashboard(),
          const BystanderModeScreen(),
          isAnonymous ? _buildGuestVaultRestriction() : MedicalVaultScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(isAnonymous),
    );
  }

  Widget _buildBottomNav(bool isAnonymous) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 80,
          padding: const EdgeInsets.only(top: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.7),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.08), width: 0.5),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.emergency_rounded, 'SOS'),
                _buildNavItem(1, Icons.people_outline_rounded, 'BYSTANDER'),
                _buildNavItem(2, Icons.health_and_safety_rounded, 'VALET', disabled: isAnonymous),
                _buildNavItem(3, Icons.person_outline_rounded, 'PROFILE'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, {bool disabled = false}) {
    final isSelected = _selectedIndex == index;
    final color = isSelected 
        ? (index == 0 ? const Color(0xFFFF5252) : AppTheme.accentCyan) 
        : Colors.white24;

    return GestureDetector(
      onTap: () {
        if (disabled) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Vault restricted in Emergency Bypass mode.'),
              backgroundColor: Colors.white10,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
          return;
        }
        _onItemTapped(index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                color: color,
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestVaultRestriction() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_person_rounded, size: 64, color: Colors.white10),
              const SizedBox(height: 24),
              Text(
                'VAULT RESTRICTED',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Personal medical records are not accessible during an anonymous emergency bypass session.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Colors.white24, fontSize: 13, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
