import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lifeline_nexus/ui/theme/app_theme.dart';
import 'package:lifeline_nexus/services/emergency_service.dart';
import 'package:lifeline_nexus/providers/location_provider.dart';
import 'package:lifeline_nexus/providers/auth_provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'first_aid_steps_screen.dart';
import 'dart:math' as math;
import 'dart:ui';

class BystanderModeScreen extends ConsumerStatefulWidget {
  const BystanderModeScreen({super.key});

  @override
  ConsumerState<BystanderModeScreen> createState() => _BystanderModeScreenState();
}

class _BystanderModeScreenState extends ConsumerState<BystanderModeScreen> with TickerProviderStateMixin {
  final TextEditingController _descriptionController = TextEditingController();
  final EmergencyService _emergencyService = EmergencyService();
  final SpeechToText _speech = SpeechToText();
  
  bool _isListening = false;
  bool _isLoadingSteps = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _speech.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    await _speech.initialize(
       onStatus: (status) {
         if (status == 'done' || status == 'notListening') {
           if (mounted) setState(() => _isListening = false);
         }
       },
       onError: (error) {
         if (mounted) setState(() => _isListening = false);
       },
    );
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) {
            if (mounted) {
              setState(() {
                _descriptionController.text = val.recognizedWords;
              });
            }
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  Future<void> _getInstructions() async {
    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please describe the situation.'),
          backgroundColor: Colors.white10,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isLoadingSteps = true);
    _triggerSilentEmergency();

    final steps = await _emergencyService.getBystanderInstructions(
      description: _descriptionController.text,
    );

    if (!mounted) return;
    setState(() => _isLoadingSteps = false);

    if (steps != null && steps.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => FirstAidStepsScreen(steps: steps)),
      );
    }
  }

  Future<void> _triggerSilentEmergency() async {
    final locationService = ref.read(locationServiceProvider);
    final user = ref.read(authStateProvider).value;

    if (user != null) {
      try {
        final position = await locationService.getCurrentLocation();
        if (position != null) {
          await _emergencyService.triggerEmergency(
            uid: user.uid,
            lat: position.latitude,
            lng: position.longitude,
            emergencyType: 'bystander',
          );
        }
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
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
        title: Text(
          'BYSTANDER PROTOCOL',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w900,
            letterSpacing: 3.0,
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Dynamic Aura Background
          Positioned(
            top: -150,
            left: -100,
            child: _buildAuraCircle(const Color(0xFF00E5FF).withValues(alpha: 0.12), 600),
          ),
          
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    
                    // Instruction Header
                    Text(
                      'ASSESS THE\nSITUATION',
                      style: GoogleFonts.inter(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -2.0,
                        height: 0.9,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Describe the patient\'s condition or behavior.\nPulse AI will coordinate rescue steps.',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: Colors.white54,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 48),
                    
                    // Advanced Interaction Hub
                    Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (_isListening)
                            const _BystanderPulseVisualizer(),
                          GestureDetector(
                            onTap: _listen,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              height: 160,
                              width: 160,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isListening ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                                border: Border.all(
                                  color: _isListening ? const Color(0xFFFF5252).withValues(alpha: 0.3) : Colors.transparent,
                                  width: 2,
                                ),
                                boxShadow: _isListening 
                                  ? [BoxShadow(color: const Color(0xFFFF5252).withValues(alpha: 0.2), blurRadius: 40, spreadRadius: 10)]
                                  : [BoxShadow(color: Colors.white.withValues(alpha: 0.1), blurRadius: 30)],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _isListening ? Icons.graphic_eq_rounded : Icons.hearing_rounded,
                                    size: 40,
                                    color: _isListening ? const Color(0xFFFF5252) : Colors.black,
                                  ),
                                  if (!_isListening) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      'ACTIVATE AI',
                                      style: GoogleFonts.inter(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 10,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ]
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 48),
                    
                    // Input Field Area
                    _buildSectionLabel('REAL-TIME OBSERVATION'),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                          ),
                          child: TextField(
                            controller: _descriptionController,
                            maxLines: 5,
                            style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                            decoration: InputDecoration(
                              hintText: 'Signs of life, visible wounds, pulse strength...',
                              hintStyle: GoogleFonts.inter(color: Colors.white12, fontSize: 14, fontWeight: FontWeight.w400),
                              contentPadding: const EdgeInsets.all(24),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Action Button
                    if (_isLoadingSteps)
                      const Center(child: CircularProgressIndicator(color: AppTheme.accentCyan, strokeWidth: 2))
                    else
                      _buildActionBtn(),
                      
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn() {
    return GestureDetector(
      onTap: _getInstructions,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 22),
        decoration: BoxDecoration(
          color: AppTheme.accentCyan,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accentCyan.withValues(alpha: 0.3),
              blurRadius: 30,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Center(
          child: Text(
            'SYNCHRONIZE RESCUE STEPS',
            style: GoogleFonts.inter(
              color: Colors.black,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              fontSize: 13,
            ),
          ),
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

class _BystanderPulseVisualizer extends StatefulWidget {
  const _BystanderPulseVisualizer();

  @override
  State<_BystanderPulseVisualizer> createState() => _BystanderPulseVisualizerState();
}

class _BystanderPulseVisualizerState extends State<_BystanderPulseVisualizer> with SingleTickerProviderStateMixin {
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
          size: const Size(280, 280),
          painter: _CircularPulsePainter(progress: _controller.value),
        );
      },
    );
  }
}

class _CircularPulsePainter extends CustomPainter {
  final double progress;

  _CircularPulsePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;
    
    final paint = Paint()
      ..color = const Color(0xFFFF5252).withValues(alpha: 0.6)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    const int points = 180;
    
    for (int i = 0; i <= points; i++) {
      final double angle = (i / points) * 2 * math.pi;
      final double noise = math.sin(angle * 12 + progress * 8) * 15;
      final double r = radius + noise;
      
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(path, paint);
    
    canvas.drawPath(path, Paint()
      ..color = const Color(0xFFFF5252).withValues(alpha: 0.15)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12));
  }

  @override
  bool shouldRepaint(covariant _CircularPulsePainter oldDelegate) => true;
}
