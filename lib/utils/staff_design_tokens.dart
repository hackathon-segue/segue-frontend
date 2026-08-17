import 'package:flutter/material.dart';

/// Design tokens for the staff/tablet screens (Issue #7), matching the
/// Figma file exactly (figma.com/design/CjERPUSeG5K9uPxt3kgbYH/Segue,
/// nodes 14:720 / 14:765 / 14:859 / 14:964 / 14:1051 / 14:1197).
///
/// Deliberately kept separate from [AppColors]/[AppRadii] in
/// `app_design_tokens.dart`: those are shared with the customer-mobile
/// screens (via the global [SegueTheme]), and the Figma palette here does
/// not match the mobile palette. Isolating it here means the staff rebuild
/// cannot bleed into mobile screens.
abstract final class StaffColors {
  static const Color ink = Color(0xFF1F2937);
  static const Color muted = Color(0xFF6B7280);
  static const Color placeholder = Color(0xFF9CA3AF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBg = Color(0xFFF9FAFB);
  static const Color sidebarBg = Color(0xFFF5F5F5);
  static const Color chipBg = Color(0xFFF3F4F6);
  static const Color avatarBg = Color(0xFFD1D5DB);
  static const Color cardBorder = Color(0xFFE5E7EB);
  static const Color chromeBorder = Color(0xFFD0D0D0);
  static const Color inputBorder = Color(0xFFD1D5DB);
  static const Color primary = Color(0xFF1F2937);
}

abstract final class StaffRadii {
  static const double input = 4;
  static const double button = 6;
  static const double chip = 999;
  static const double shell = 12;
}

abstract final class StaffSizes {
  static const double sidebarWidth = 240;
  static const double twoPaneBreakpoint = 760;
  static const double avatarSize = 48;
  static const double searchBoxWidth = 140;
  static const double searchBoxHeight = 38;
  static const double inputHeight = 38;
}

abstract final class StaffShadows {
  static const List<BoxShadow> shell = <BoxShadow>[
    BoxShadow(color: Color(0x14000000), offset: Offset(0, 4), blurRadius: 16),
  ];
}

/// Text styles matching Figma's Inter type scale. The project does not
/// bundle the Inter font (adding it would mean touching pubspec.yaml,
/// which is out of scope here), so these intentionally omit `fontFamily`
/// and fall back to the app's default font — sizes/weights/colors still
/// match Figma exactly.
abstract final class StaffText {
  static const TextStyle title20Bold = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: StaffColors.ink,
  );
  static const TextStyle header16SemiBold = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: StaffColors.ink,
  );
  static const TextStyle body14 = TextStyle(fontSize: 14, color: StaffColors.ink);
  static const TextStyle body12 = TextStyle(fontSize: 12, color: StaffColors.ink);
  static const TextStyle meta11 = TextStyle(fontSize: 11, color: StaffColors.ink);
  static const TextStyle link14Muted = TextStyle(
    fontSize: 14,
    color: StaffColors.muted,
    decoration: TextDecoration.underline,
  );
  static const TextStyle placeholder14 = TextStyle(fontSize: 14, color: StaffColors.placeholder);
  static const TextStyle buttonPrimary14 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Colors.white,
  );
  static const TextStyle buttonSecondary14 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: StaffColors.ink,
  );
  static const TextStyle brand16SemiBold = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: StaffColors.ink,
  );
}
