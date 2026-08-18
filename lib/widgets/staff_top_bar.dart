import 'package:flutter/material.dart';

import '../utils/staff_design_tokens.dart';
import 'staff_image_placeholder.dart';

/// Matches Figma's "SharedHeader" component exactly: brand text, a spacer,
/// a static 140x38 search box (icon only — the reference passes no
/// placeholder text) and a 48px avatar circle.
class StaffTopBar extends StatelessWidget {
  const StaffTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: StaffColors.chromeBorder)),
      ),
      child: Row(
        spacing: 16,
        children: <Widget>[
          const Text('MCM 상담', style: StaffText.brand16SemiBold),
          const Expanded(child: SizedBox.shrink()),
          Container(
            width: StaffSizes.searchBoxWidth,
            height: StaffSizes.searchBoxHeight,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: StaffColors.inputBorder),
              borderRadius: BorderRadius.circular(StaffRadii.input),
            ),
            alignment: Alignment.centerLeft,
            child: const Icon(Icons.search, size: 16, color: StaffColors.placeholder),
          ),
          const StaffImagePlaceholder.avatar(),
        ],
      ),
    );
  }
}
