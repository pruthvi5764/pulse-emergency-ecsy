import 'package:flutter/material.dart';
import 'package:lifeline_nexus/ui/theme/app_theme.dart';

class FirstAidStepsScreen extends StatelessWidget {
  final List<String> steps;

  const FirstAidStepsScreen({super.key, required this.steps});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FIRST AID INSTRUCTIONS'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: steps.isEmpty
          ? const Center(child: Text("No instructions available.", style: TextStyle(color: Colors.white)))
          : PageView.builder(
              itemCount: steps.length,
              itemBuilder: (context, index) {
                return _buildStepCard(context, index, steps[index], steps.length);
              },
            ),
    );
  }

  Widget _buildStepCard(BuildContext context, int index, String stepText, int totalSteps) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(26),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.accentCyan, width: 2),
        ),
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.accentCyan,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                'STEP ${index + 1} OF $totalSteps',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 48),
            const Divider(color: Colors.white54, thickness: 1),
            const Spacer(),
            Text(
              stepText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w900,
                height: 1.3,
              ),
            ),
            const Spacer(),
            const Divider(color: Colors.white54, thickness: 1),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (index > 0) const Icon(Icons.arrow_back_ios, color: Colors.white54, size: 16),
                const SizedBox(width: 8),
                Text(
                  index < totalSteps - 1 ? 'SWIPE FOR NEXT STEP' : 'END OF INSTRUCTIONS',
                  style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                if (index < totalSteps - 1) const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
