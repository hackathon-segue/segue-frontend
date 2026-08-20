import 'package:flutter/material.dart';

abstract final class AppColors {
  static const Color ink = Color(0xFF111827);
  static const Color mutedInk = Color(0xFF475569);
  static const Color subtleInk = Color(0xFF64748B);
  static const Color canvas = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF1F5F9);
  static const Color border = Color(0xFFE2E8F0);
  static const Color brand = Color(0xFF111827);
  static const Color focus = Color(0xFF2563EB);
  static const Color success = Color(0xFF047857);
  static const Color warning = Color(0xFFB45309);
  static const Color danger = Color(0xFFB91C1C);
}

abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
}

abstract final class AppRadii {
  static const double sm = 6;
  static const double md = 8;
}

abstract final class AppSizes {
  static const double minTapTarget = 44;
  static const double iconMedium = 28;
  static const double iconLarge = 32;
  static const double loadingIndicator = 28;
  static const double loadingStroke = 2.6;
  static const double mobileContentMaxWidth = 430;
  static const double staffContentMaxWidth = 960;
  static const double staffGridBreakpoint = 720;
}

abstract final class AppBorders {
  static const BorderSide subtle = BorderSide(color: AppColors.border);
  static const BorderSide focused = BorderSide(
    color: AppColors.focus,
    width: 1.5,
  );
  static const BorderSide danger = BorderSide(color: AppColors.danger);
}
