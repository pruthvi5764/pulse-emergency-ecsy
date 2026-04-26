import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeline_nexus/providers/vault_provider.dart';
import 'package:lifeline_nexus/providers/gemini_provider.dart';
import 'package:lifeline_nexus/ui/theme/app_theme.dart';
import 'dart:ui';

class FirstAidKitScreen extends ConsumerStatefulWidget {
  const FirstAidKitScreen({super.key});

  @override
  ConsumerState<FirstAidKitScreen> createState() => _FirstAidKitScreenState();
}

class _FirstAidKitScreenState extends ConsumerState<FirstAidKitScreen> {
  final List<Map<String, dynamic>> _guides = [
    {
      'title': 'CPR (ADULT)',
      'icon': Icons.favorite_rounded,
      'color': const Color(0xFFFF5252),
      'steps': [
        'Push hard and fast in the center of the chest.',
        'Rate: 100-120 compressions per minute.',
        'Depth: At least 2 inches.',
        'Allow chest to recoil completely between compressions.'
      ]
    },
    {
      'title': 'CHOKING',
      'icon': Icons.air_rounded,
      'color': Colors.orangeAccent,
      'steps': [
        'Stand behind the person.',
        'Wrap your arms around their waist.',
        'Make a fist and place it just above the navel.',
        'Perform quick, upward thrusts (Heimlich maneuver).'
      ]
    },
    {
      'title': 'SEVERE BLEEDING',
      'icon': Icons.bloodtype_rounded,
      'color': Colors.red,
      'steps': [
        'Apply direct pressure to the wound with a clean cloth.',
        'Maintain pressure until bleeding stops.',
        'If blood soaks through, add more cloth (do not remove original).',
        'If bleeding is life-threatening, use a tourniquet.'
      ]
    },
    {
      'title': 'BURNS',
      'icon': Icons.whatshot_rounded,
      'color': Colors.orange,
      'steps': [
        'Cool the burn with cool (not cold) running water for 10-20 mins.',
        'Remove jewelry or tight clothing near the burn.',
        'Cover the burn loosely with sterile dressing or cling film.',
        'Do not pop blisters or apply ice/ointments.'
      ]
    },
    {
      'title': 'SEIZURES',
      'icon': Icons.bolt_rounded,
      'color': Colors.yellowAccent,
      'steps': [
        'Clear the area of hard or sharp objects.',
        'Place something soft under their head.',
        'Do not restrain the person or put anything in their mouth.',
        'Turn them on their side once the shaking stops.'
      ]
    },
  ];

  @override
  Widget build(BuildContext context) {
    final medicalProfile = ref.watch(medicalProfileProvider).value;
    final aiState = ref.watch(geminiProvider);
    
    // Dynamically add personalized guides based on Medical Valet
    final List<Map<String, dynamic>> personalizedGuides = List.from(_guides);
    
    if (medicalProfile != null) {
      if (medicalProfile.chronicConditions.any((c) => c.toLowerCase().contains('asthma'))) {
        personalizedGuides.insert(0, {
          'title': 'ASTHMA ATTACK',
          'icon': Icons.air_rounded,
          'color': Colors.cyanAccent,
          'steps': [
            'Sit the person upright and keep them calm.',
            'Help them use their inhaler (usually blue).',
            'Take 4 separate puffs, with 4 breaths after each.',
            'Wait 4 minutes; if no improvement, give 4 more puffs.',
            'If breathing is still difficult, call emergency services.'
          ]
        });
      }
      if (medicalProfile.chronicConditions.any((c) => c.toLowerCase().contains('diabet'))) {
        personalizedGuides.insert(0, {
          'title': 'DIABETIC EMERGENCY',
          'icon': Icons.monitor_heart_rounded,
          'color': Colors.amberAccent,
          'steps': [
            'If conscious, give sugary food or drink (e.g., fruit juice, candy).',
            'Do not give insulin during an acute low-sugar episode.',
            'If unconscious, do not put anything in their mouth.',
            'Place in recovery position and call emergency services.'
          ]
        });
      }
    }

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
          'OFFLINE PROTOCOL',
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
          // Background Aura
          Positioned(
            top: -100,
            left: -50,
            child: _buildAuraCircle(const Color(0xFFFF5252).withValues(alpha: 0.1), 500),
          ),
          
          SafeArea(
            child: ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: personalizedGuides.length + (medicalProfile != null ? 2 : 1),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24, top: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'FIRST AID\nPROTOCOLS',
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
                          'Vital life-saving instructions cached locally for zero-latency response.',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: Colors.white54,
                            fontWeight: FontWeight.w500,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Inject Medical Valet Context Alert
                if (medicalProfile != null && index == 1) {
                  return Column(
                    children: [
                      _buildMedicalContextCard(medicalProfile),
                      if (aiState.optimizedActionPlan != null)
                        _buildAIActionPlanCard(aiState.optimizedActionPlan!),
                    ],
                  );
                }
                
                final guideIndex = medicalProfile != null ? index - 2 : index - 1;
                final guide = personalizedGuides[guideIndex];
                return _buildGuideCard(guide);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalContextCard(dynamic profile) {
    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFF5252).withValues(alpha: 0.15),
            Colors.transparent,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFF5252).withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF5252), size: 20),
              const SizedBox(width: 12),
              Text(
                'PERSONAL MEDICAL ALERT',
                style: GoogleFonts.inter(
                  color: const Color(0xFFFF5252),
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  letterSpacing: 2.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildAlertItem('BLOOD TYPE', profile.demographics.bloodType, Icons.water_drop_rounded),
          if (profile.allergies.isNotEmpty)
            _buildAlertItem(
              'ALLERGIES', 
              profile.allergies.map((a) => a.allergen).join(', '), 
              Icons.warning_rounded
            ),
          if (profile.chronicConditions.isNotEmpty)
            _buildAlertItem(
              'CHRONIC CONDITIONS', 
              profile.chronicConditions.join(', '), 
              Icons.history_edu_rounded
            ),
        ],
      ),
    );
  }

  Widget _buildAlertItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.white24, size: 16),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  color: Colors.white38,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAIActionPlanCard(String plan) {
    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1F1F),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.cyan.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology_rounded, color: Colors.cyan, size: 20),
              const SizedBox(width: 12),
              Text(
                'PULSE AI ACTION PLAN',
                style: GoogleFonts.inter(
                  color: Colors.cyan,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  letterSpacing: 2.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            plan,
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 13,
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '• PRE-OPTIMIZED BASED ON VALET',
            style: GoogleFonts.inter(
              color: Colors.cyan.withValues(alpha: 0.5),
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideCard(Map<String, dynamic> guide) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (guide['color'] as Color).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(guide['icon'], color: guide['color'], size: 20),
          ),
          title: Text(
            guide['title'],
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 13,
              letterSpacing: 1.0,
            ),
          ),
          iconColor: Colors.white24,
          collapsedIconColor: Colors.white24,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: (guide['steps'] as List<String>).asMap().entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${entry.key + 1}. ',
                          style: GoogleFonts.inter(
                            color: guide['color'],
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontSize: 13,
                              height: 1.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
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
