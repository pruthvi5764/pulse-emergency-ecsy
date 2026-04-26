import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lifeline_nexus/providers/sos_provider.dart';
import 'package:lifeline_nexus/ui/theme/app_theme.dart';
import 'package:lifeline_nexus/providers/gemini_provider.dart';
import 'package:lifeline_nexus/features/bystander/bystander_mode_screen.dart';
import 'package:lifeline_nexus/features/intelligence/symptom_analyst_screen.dart';
import 'package:lifeline_nexus/features/vault/emergency_qr_screen.dart';
import 'package:lifeline_nexus/features/maps/community_map_screen.dart';
import 'package:lifeline_nexus/features/education/first_aid_kit_screen.dart';
import 'package:lifeline_nexus/features/vault/medical_vault_screen.dart';
import 'dart:math' as math;

class EmergencyDashboard extends ConsumerWidget {
  const EmergencyDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sosState = ref.watch(sosProvider);
    final aiState = ref.watch(geminiProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          const SliverPadding(padding: EdgeInsets.only(top: 80)),
          
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Little Bar-Like Trigger with Overflow Protection
                  _buildBarTrigger(
                    context,
                    ref: ref,
                    sosState: sosState,
                    onTap: () {
                      if (!sosState.isTriggered && !sosState.isCountdownActive && !sosState.isUserSpeaking) {
                        ref.read(sosProvider.notifier).startBufferedTrigger();
                      }
                    },
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // Intelligence Panel
                  if (sosState.isTriggered) ...[
                    _buildSectionHeader('AI INTELLIGENCE'),
                    _buildAIIntelligenceTile(aiState),
                    const SizedBox(height: 24),
                  ],
                  
                  // Resources
                  _buildSectionHeader('CORE RESOURCES'),
                  _buildUtilityTile(
                    icon: Icons.auto_awesome_rounded,
                    title: 'AI SYMPTOM ANALYST',
                    subtitle: 'Neural diagnostic intelligence',
                    accentColor: AppTheme.accentCyan,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SymptomAnalystScreen())),
                  ),
                  const SizedBox(height: 16),
                  _buildUtilityTile(
                    icon: Icons.health_and_safety_rounded,
                    title: 'PULSE MEDICAL VALET',
                    subtitle: 'Secure health identity vault',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MedicalVaultScreen())),
                  ),
                  const SizedBox(height: 16),
                  _buildUtilityTile(
                    icon: Icons.qr_code_2_rounded,
                    title: 'EMERGENCY QR IDENTITY',
                    subtitle: 'Rapid scan medical access',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencyQRScreen())),
                  ),
                  const SizedBox(height: 16),
                  _buildUtilityTile(
                    icon: Icons.map_outlined,
                    title: 'COMMUNITY RESPONDER MAP',
                    subtitle: 'Hospitals, Blood & Oxygen',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CommunityMapScreen())),
                  ),
                  const SizedBox(height: 16),
                  _buildUtilityTile(
                    icon: Icons.medical_services_outlined,
                    title: 'OFFLINE FIRST AID KIT',
                    subtitle: 'Zero-latency rescue guides',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FirstAidKitScreen())),
                  ),
                  const SizedBox(height: 16),
                  _buildUtilityTile(
                    icon: Icons.people_outline_rounded,
                    title: 'BYSTANDER ASSISTANCE',
                    subtitle: 'AI-guided rescue instructions',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BystanderModeScreen())),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Footer Branding
                  Center(
                    child: Text(
                      'PULSE SECURE • ONLINE',
                      style: GoogleFonts.inter(
                        color: Colors.white10, 
                        fontWeight: FontWeight.w900, 
                        fontSize: 10, 
                        letterSpacing: 3.0
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarTrigger(BuildContext context, {required WidgetRef ref, required SOSState sosState, required VoidCallback onTap}) {
    final bool active = sosState.isTriggered;
    final bool countdown = sosState.isCountdownActive;
    final bool micOn = sosState.isMicActive;
    final bool isEngaged = active || countdown || micOn;
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.fastOutSlowIn,
        width: double.infinity,
        height: isEngaged ? 360 : 84,
        decoration: BoxDecoration(
          color: isEngaged ? Colors.transparent : Colors.white,
          borderRadius: BorderRadius.circular(isEngaged ? 40 : 20),
          border: null,
          boxShadow: isEngaged ? [] : [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.1),
              blurRadius: 20,
              spreadRadius: 2,
            )
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (isEngaged)
              PulseWaveform(color: const Color(0xFFFF5252).withValues(alpha: 0.7)),
            
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isEngaged ? 0 : 24),
              child: isEngaged 
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      active ? Icons.emergency_rounded : (micOn ? Icons.mic_rounded : Icons.timer_outlined),
                      size: 40,
                      color: const Color(0xFFFF5252),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      active ? 'SOS ACTIVE' : (micOn ? 'PULSE LISTENING...' : 'AUTO-TRIGGER: ${sosState.countdownSeconds}s'),
                      style: GoogleFonts.inter(
                        color: const Color(0xFFFF5252), 
                        fontWeight: FontWeight.w900, 
                        letterSpacing: 3.0, 
                        fontSize: 12
                      ),
                    ),
                    if (active || countdown || micOn) ...[
                      const SizedBox(height: 80),
                      GestureDetector(
                        onTap: () {
                          ref.read(sosProvider.notifier).cancelSOS();
                          ref.read(geminiProvider.notifier).clearAnalysis();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          child: Text(
                            'CANCEL EMERGENCY',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.radio_button_checked_rounded, color: Colors.black, size: 24),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        'ACTIVATE PULSE SOS',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: Colors.black, 
                          fontWeight: FontWeight.w900, 
                          letterSpacing: 0.5, 
                          fontSize: 15
                        ),
                      ),
                    ),
                  ],
                ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUtilityTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? accentColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF0F0F0F),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Icon(icon, color: accentColor ?? Colors.white, size: 24),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      color: accentColor ?? Colors.white, 
                      fontWeight: FontWeight.w900, 
                      letterSpacing: 0.5, 
                      fontSize: 13
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(color: Colors.white24, fontSize: 11, fontWeight: FontWeight.w500),
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

  Widget _buildAIIntelligenceTile(EmergencyAIState aiState) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.accentCyan.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: AppTheme.accentCyan, size: 16),
              const SizedBox(width: 10),
              Text(
                'INTELLIGENCE', 
                style: GoogleFonts.inter(
                  color: AppTheme.accentCyan, 
                  fontWeight: FontWeight.w900, 
                  letterSpacing: 1.0, 
                  fontSize: 11
                )
              ),
            ],
          ),
          const SizedBox(height: 20),
          aiState.isLoading
              ? const LinearProgressIndicator(backgroundColor: Colors.white10, color: AppTheme.accentCyan)
              : Text(
                  aiState.advice ?? 'Monitoring environmental context...',
                  style: GoogleFonts.inter(color: Colors.white70, height: 1.6, fontSize: 14, fontWeight: FontWeight.w500),
                ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 16, left: 4),
      child: Text(
        title,
        textAlign: TextAlign.left,
        style: GoogleFonts.inter(
          color: Colors.white24,
          fontWeight: FontWeight.w900,
          letterSpacing: 2.0,
          fontSize: 10,
        ),
      ),
    );
  }
}

class PulseWaveform extends StatefulWidget {
  final Color color;
  const PulseWaveform({super.key, required this.color});

  @override
  State<PulseWaveform> createState() => _PulseWaveformState();
}

class _PulseWaveformState extends State<PulseWaveform> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(double.infinity, 300),
          painter: PulsePainter(color: widget.color, progress: _controller.value),
        );
      },
    );
  }
}

class PulsePainter extends CustomPainter {
  final Color color;
  final double progress;

  PulsePainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final double midY = size.height / 2;
    final double width = size.width;
    
    const int points = 100;
    
    for (int i = 0; i <= points; i++) {
      final double x = (i / points) * width;
      final double wavePos = (i / points + progress) % 1.0;
      
      double y = midY;
      
      if (wavePos > 0.4 && wavePos < 0.6) {
        final double t = (wavePos - 0.5) * 20; 
        y = midY - (math.exp(-t * t * 10) * 80 * math.sin(t * 10));
      } else if (wavePos > 0.7 && wavePos < 0.9) {
        final double t = (wavePos - 0.8) * 10;
        y = midY - (math.exp(-t * t) * 15);
      } else {
        y = midY + math.sin(i * 0.5 + progress * 10) * 2;
      }

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
    canvas.drawPath(path, Paint()
      ..color = color.withValues(alpha: 0.1)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
  }

  @override
  bool shouldRepaint(covariant PulsePainter oldDelegate) => true;
}
