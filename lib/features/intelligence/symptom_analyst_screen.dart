import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lifeline_nexus/providers/gemini_provider.dart';
import 'package:lifeline_nexus/ui/theme/app_theme.dart';
import 'dart:ui';

class SymptomAnalystScreen extends ConsumerStatefulWidget {
  const SymptomAnalystScreen({super.key});

  @override
  ConsumerState<SymptomAnalystScreen> createState() => _SymptomAnalystScreenState();
}

class _SymptomAnalystScreenState extends ConsumerState<SymptomAnalystScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _symptomController = TextEditingController();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
    
    // Clear previous analysis when entering
    Future.microtask(() => ref.read(geminiProvider.notifier).clearAnalysis());
  }

  @override
  void dispose() {
    _symptomController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _analyze() {
    if (_symptomController.text.trim().isEmpty) return;
    FocusScope.of(context).unfocus();
    ref.read(geminiProvider.notifier).conductSymptomAnalysis(_symptomController.text);
  }

  @override
  Widget build(BuildContext context) {
    final aiState = ref.watch(geminiProvider);

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
          'DIAGNOSTIC CORE',
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
            top: -100,
            right: -50,
            child: _buildAuraCircle(AppTheme.accentCyan.withValues(alpha: 0.15), 500),
          ),
          
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI SYMPTOM\nANALYST',
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
                      'Cross-referencing symptoms with your Pulse Medical Vault for rapid intelligence.',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: Colors.white54,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 40),
                    
                    // Input Section
                    _buildSectionLabel('INPUT OBSERVATIONS'),
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
                            controller: _symptomController,
                            maxLines: 4,
                            style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                            decoration: InputDecoration(
                              hintText: 'e.g., Sharp chest pain, dizziness, and mild nausea for 20 minutes...',
                              hintStyle: GoogleFonts.inter(color: Colors.white12, fontSize: 14, fontWeight: FontWeight.w400),
                              contentPadding: const EdgeInsets.all(24),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    _buildAnalyzeButton(aiState.isLoading),
                    
                    const SizedBox(height: 40),
                    
                    // Result Section
                    if (aiState.isLoading || aiState.advice != null)
                      _buildResultSection(aiState),
                      
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

  Widget _buildAnalyzeButton(bool isLoading) {
    return GestureDetector(
      onTap: isLoading ? null : _analyze,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isLoading ? Colors.white10 : AppTheme.accentCyan,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isLoading ? [] : [
            BoxShadow(
              color: AppTheme.accentCyan.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Center(
          child: isLoading 
            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(
                'INITIALIZE ANALYSIS',
                style: GoogleFonts.inter(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  fontSize: 12,
                ),
              ),
        ),
      ),
    );
  }

  Widget _buildResultSection(EmergencyAIState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('AI DIAGNOSTIC OUTPUT'),
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.accentCyan.withValues(alpha: 0.1)),
              ),
              child: state.isLoading 
                ? Column(
                    children: [
                      const LinearProgressIndicator(backgroundColor: Colors.white10, color: AppTheme.accentCyan),
                      const SizedBox(height: 16),
                      Text(
                        'PULSE NEURAL PROCESSING...',
                        style: GoogleFonts.inter(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2.0),
                      ),
                    ],
                  )
                : Text(
                    state.advice ?? '',
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.9),
                      height: 1.6,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
            ),
          ),
        ),
      ],
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
