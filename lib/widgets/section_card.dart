import 'package:flutter/material.dart';

import '../utils/staff_design_tokens.dart';

/// Matches the Figma "Frame" info-box pattern that repeats throughout
/// every staff screen: #F9FAFB fill, #E5E7EB border, 6px radius, 12px
/// padding.
class SectionCard extends StatelessWidget {
  const SectionCard({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: StaffColors.cardBg,
        border: Border.all(color: StaffColors.cardBorder),
        borderRadius: BorderRadius.circular(StaffRadii.button),
      ),
      child: child,
    );
  }
}
