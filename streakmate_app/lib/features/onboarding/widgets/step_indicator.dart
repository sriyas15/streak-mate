import 'package:flutter/material.dart';

/// step_indicator.dart
/// The "1/4" / "2/4" pill shown top-left in every onboarding screenshot.
class StepIndicator extends StatelessWidget {
  const StepIndicator({
    super.key,
    required this.current,
    required this.total,
    this.darkText = true,
  });

  final int current;
  final int total;
  final bool darkText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$current/$total',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: darkText ? Colors.black87 : Colors.white,
        ),
      ),
    );
  }
}
