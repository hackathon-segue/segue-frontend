import 'package:flutter/material.dart';

/// Design tokens for the "MCM SEGUE" Last Intent flow (Issue #46), matching
/// Figma nodes 164:3213 / 159:2295 / 159:2173 / 159:3053 / 169:3683 /
/// 169:3821 / 169:3891 exactly.
///
/// Deliberately separate from [StaffColors]/[StaffText]
/// (`staff_design_tokens.dart`): those still back every other staff screen
/// (login/home/customer lookup/consent/cart), which per this issue's scope
/// keep their current "MCM 상담" look for now and will be migrated to this
/// same SEGUE system in a later, separate pass. Isolating these tokens here
/// means this rebuild cannot bleed into those screens.
abstract final class SegueCardColors {
  static const Color ink = Color(0xFF222222);
  static const Color secondaryText = Color(0xFF515151);
  static const Color muted = Color(0xFF7C7C7C);
  static const Color subtitleMuted = Color(0xFF6B6B6B);
  static const Color placeholderMuted = Color(0xFF909090);
  static const Color sidebarBg = Color(0xFFF7F7F7);
  static const Color panelBg = Color(0xFFF7F7F7);
  static const Color previewPanelBg = Color(0xFFEDEDED);
  static const Color border = Color(0xFFDBDCE0);
  static const Color chipBg = Color(0xFFBFBFBF);
  static const Color ctaBg = Color(0xFF222222);
  static const Color avatarBg = Color(0xFF7C7C7C);
  static const Color badgeBg = Color(0xFF222222);
}

abstract final class SegueCardSizes {
  static const double sidebarWidth = 265;
  static const double headerHeight = 71;
}

/// Figma uses two font families throughout this flow:
///
/// - **Montserrat** (Bold/SemiBold/Medium) — the English-only chrome (logo,
///   sidebar labels, "CURRENT SESSION" title, step badge). Bundled here as
///   the real Google Fonts (OFL-licensed) variable font — `assets/fonts/
///   Montserrat-Variable.ttf`, registered in pubspec.yaml as family
///   "Montserrat".
/// - **Apple SD Gothic Neo** (weight tiers B00=Bold/EB00=ExtraBold/
///   SB00=SemiBold/M00=Medium) — every Korean text node. This is a macOS
///   system font with no redistribution license, so per user decision it is
///   substituted with **Pretendard** (SIL OFL, near-identical shape/weight
///   coverage, the standard open-source substitute for this exact font in
///   Korean UI work) — bundled as `assets/fonts/Pretendard-*.otf`,
///   registered as family "Pretendard" with weights 400/500/600/700/800
///   matching Apple SD Gothic Neo's Regular/M00/SB00/B00/EB00 tiers exactly.
///
/// Any text that can contain real product/customer data (Korean color
/// names, product names) uses Pretendard even where Figma's own example
/// content happened to be English (e.g. "COGNAC") — Montserrat has no
/// Hangul glyphs, so using it for a field that can legitimately contain
/// Korean text would silently fall back to a mismatched system font.
abstract final class SegueCardText {
  static const String _montserrat = 'Montserrat';
  static const String _pretendard = 'Pretendard';

  static const TextStyle brandLogo20 = TextStyle(
    fontFamily: _montserrat,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: SegueCardColors.ink,
  );
  static const TextStyle menuLabel14 = TextStyle(
    fontFamily: _montserrat,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: SegueCardColors.muted,
  );
  static const TextStyle menuItem16 = TextStyle(
    fontFamily: _montserrat,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: SegueCardColors.secondaryText,
  );
  static const TextStyle menuItemActive16 = TextStyle(
    fontFamily: _montserrat,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: SegueCardColors.ink,
  );
  static const TextStyle pageTitle28 = TextStyle(
    fontFamily: _montserrat,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: SegueCardColors.ink,
  );
  static const TextStyle stepBadge20 = TextStyle(
    fontFamily: _montserrat,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );
  // Screen titles ("정확한 제품 확인" 등) — AppleSDGothicNeoB00 = Bold(700).
  static const TextStyle screenTitle22 = TextStyle(
    fontFamily: _pretendard,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: SegueCardColors.ink,
  );
  static const TextStyle screenTitle24 = TextStyle(
    fontFamily: _pretendard,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: SegueCardColors.ink,
  );
  // Subtitle — AppleSDGothicNeoM00 = Medium(500).
  static const TextStyle subtitle16 = TextStyle(
    fontFamily: _pretendard,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: SegueCardColors.subtitleMuted,
    letterSpacing: -0.32,
  );
  // Card titles ("고객 핵심 조건" 등) — AppleSDGothicNeoEB00 = ExtraBold(800).
  static const TextStyle sectionTitle20 = TextStyle(
    fontFamily: _pretendard,
    fontSize: 20,
    fontWeight: FontWeight.w800,
    color: SegueCardColors.ink,
  );
  // Figma's Latin run is Montserrat Bold, its Korean run is
  // AppleSDGothicNeoEB00 — since product names mix scripts and Montserrat
  // has no Hangul glyphs, the whole string uses Pretendard Bold (closest
  // single-family match covering both scripts).
  // Figma (159:2295): name text box height 43 / 30px font ≈ 1.43.
  static const TextStyle productName30 = TextStyle(
    fontFamily: _pretendard,
    fontSize: 30,
    fontWeight: FontWeight.w700,
    color: SegueCardColors.ink,
    height: 43 / 30,
  );
  // Figma's example (COGNAC/Medium) is Montserrat Medium, but real
  // color/size values are Korean (블랙/미디움 등) — Pretendard Medium(500).
  // Figma: 3-line block height 72 / 3 lines / 20px font = 1.2.
  static const TextStyle productMeta20 = TextStyle(
    fontFamily: _pretendard,
    fontSize: 20,
    fontWeight: FontWeight.w500,
    color: SegueCardColors.ink,
    height: 1.2,
  );
  // Body paragraphs — AppleSDGothicNeoM00 = Medium(500).
  static const TextStyle body18 = TextStyle(
    fontFamily: _pretendard,
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: SegueCardColors.secondaryText,
    height: 26 / 18,
  );
  // Bold label prefix in label/value rows — AppleSDGothicNeoB00 = Bold(700).
  static const TextStyle bodyLabel18Bold = TextStyle(
    fontFamily: _pretendard,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: SegueCardColors.secondaryText,
    height: 26 / 18,
  );
  // Chip label — AppleSDGothicNeoSB00 = SemiBold(600).
  static const TextStyle chipLabel16White = TextStyle(
    fontFamily: _pretendard,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
  // "처음으로 돌아가기" — AppleSDGothicNeoB00 = Bold(700).
  static const TextStyle link18Underline = TextStyle(
    fontFamily: _pretendard,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: SegueCardColors.muted,
    decoration: TextDecoration.underline,
  );
  // CTA button label — AppleSDGothicNeoB00 = Bold(700).
  static const TextStyle ctaLabel18White = TextStyle(
    fontFamily: _pretendard,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );
  // CA footer — 김셀러(AppleSDGothicNeoB00=Bold), Client Advisor(Montserrat
  // Medium), 강남 플래그십 스토어(AppleSDGothicNeoB00=Bold).
  static const TextStyle caName14 = TextStyle(
    fontFamily: _pretendard,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: SegueCardColors.ink,
  );
  static const TextStyle caRole12 = TextStyle(
    fontFamily: _montserrat,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: SegueCardColors.muted,
  );
  static const TextStyle caStore10 = TextStyle(
    fontFamily: _pretendard,
    fontSize: 10,
    fontWeight: FontWeight.w700,
    color: SegueCardColors.muted,
  );
  // Not a Figma value — this app's own placeholder-image label (no bundled
  // product photos), kept visually neutral.
  static const TextStyle placeholder14 = TextStyle(
    fontFamily: _pretendard,
    fontSize: 14,
    color: SegueCardColors.placeholderMuted,
  );
}
