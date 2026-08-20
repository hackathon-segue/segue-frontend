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
  // Figma (89:1196) "Rectangle 9" step badge background — distinct from the
  // CA avatar circle below, which was wrongly sharing this same token.
  static const Color stepBadgeBg = Color(0xFF7C7C7C);
  // Figma 98:1740's "상담 중단" pill (node 98:1803) — same 123×48 badge as
  // "상담 완료" (stepBadgeBg) but a deliberately darker fill to read as a
  // distinct, more final state.
  static const Color consultationAbortedBg = Color(0xFF535353);
  // Figma (89:1196) "Ellipse 1" fill — confirmed via the raw SVG asset
  // (#D9D9D9), NOT the muted/step-badge gray this token used to alias.
  static const Color avatarCircleBg = Color(0xFFD9D9D9);
  // Figma (89:1196) "CURRENT SESSION" sidebar count badge: muted gray at 0,
  // solid ink once a session actually exists (confirmed by cross-referencing
  // 89:1196's "0" badge against 159:2173/159:3053's "1" badge, which use
  // these two exact colors respectively).
  static const Color sessionBadgeZero = Color(0xFF515151);
  static const Color sessionBadgeActive = Color(0xFF222222);
  static const Color badgeBg = Color(0xFF222222);
  // Figma (89:1196) "START SEGUE" button text — an off-white, NOT pure
  // white like every other CTA in this flow.
  static const Color ctaTextMuted = Color(0xFFF1F1F1);
  // Figma (89:1196) summary-card label/counter text — distinct from every
  // other gray token already defined here (#515151/#6B6B6B/#7C7C7C).
  static const Color statText = Color(0xFF545454);
  // Figma (80:776) "진행 중인 상담" card's customer/product detail rows —
  // distinct from #515151/#545454.
  static const Color detailText = Color(0xFF3D3D3D);
  // Figma (80:776) "쇼핑백 확인" compact button background — distinct from
  // ctaBg (#222222) used by "상담 이어서 진행" right next to it.
  static const Color compactButtonSecondaryBg = Color(0xFF707070);
  // Figma (89:1386) "동의 범위" box fill / (98:1810) "다음 단계" option row
  // fill — same #F1F1F1 value as ctaTextMuted but a distinct semantic use
  // (a background, not text color).
  static const Color scopeBoxBg = Color(0xFFF1F1F1);
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
  // Korean run of the product name (159:2295 etc.) — AppleSDGothicNeoEB00,
  // substituted with Pretendard Bold per this file's documented rule.
  // Figma (159:2295): name text box height 43 / 30px font ≈ 1.43.
  static const TextStyle productName30 = TextStyle(
    fontFamily: _pretendard,
    fontSize: 30,
    fontWeight: FontWeight.w700,
    color: SegueCardColors.ink,
    height: 43 / 30,
  );
  // Latin brand-word run of the product name (159:2295's "Diamond") —
  // Montserrat Bold, 30px, ink, matching [productName30]'s box metrics.
  // Real CartItem.productName values are consistently
  // "<Latin brand> <Korean description>" (e.g. "MCM 백팩 미디움"), so
  // splitting on the first space reflects real data, not a guess.
  static const TextStyle productNameLatin30 = TextStyle(
    fontFamily: _montserrat,
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
    // Without an explicit decorationColor, Flutter paints the underline in
    // the default black rather than following this style's own `color`.
    decorationColor: SegueCardColors.muted,
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
  // "SL" avatar initials — Montserrat SemiBold, muted (NOT white — the
  // avatar circle itself is light gray #D9D9D9, not a dark fill).
  static const TextStyle caInitials17 = TextStyle(
    fontFamily: _montserrat,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: SegueCardColors.muted,
  );
  // Not a Figma value — this app's own placeholder-image label (no bundled
  // product photos), kept visually neutral.
  static const TextStyle placeholder14 = TextStyle(
    fontFamily: _pretendard,
    fontSize: 14,
    color: SegueCardColors.placeholderMuted,
  );
  // "START SEGUE" — Montserrat Bold, off-white (89:1196).
  static const TextStyle ctaLabel18Muted = TextStyle(
    fontFamily: _montserrat,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: SegueCardColors.ctaTextMuted,
  );
  // Summary-card label ("현재 진행 중 상담" 등) — AppleSDGothicNeoB00 = Bold.
  static const TextStyle statLabel13 = TextStyle(
    fontFamily: _pretendard,
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: SegueCardColors.statText,
    letterSpacing: -0.26,
  );
  // Summary-card counter ("0"/"3") — Montserrat SemiBold 40px.
  static const TextStyle statCounter40 = TextStyle(
    fontFamily: _montserrat,
    fontSize: 40,
    fontWeight: FontWeight.w600,
    color: SegueCardColors.statText,
    letterSpacing: -0.8,
  );
  // "현재 없음" empty-state text — AppleSDGothicNeoM00 = Medium(500).
  static const TextStyle emptyState20 = TextStyle(
    fontFamily: _pretendard,
    fontSize: 20,
    fontWeight: FontWeight.w500,
    color: SegueCardColors.statText,
  );
  // "고객 정보"/"제품 정보" section labels (80:776) — AppleSDGothicNeoB00 =
  // Bold(700). Same size/weight/color as statLabel13 but NO letterSpacing
  // (confirmed: 80:776's label nodes carry no tracking value, unlike
  // 89:1196's summary cards).
  static const TextStyle sectionLabel13 = TextStyle(
    fontFamily: _pretendard,
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: SegueCardColors.statText,
  );
  // Customer name ("윤서진") — AppleSDGothicNeoB00 = Bold(700), identical to
  // screenTitle22 in every value; kept as its own named token since the two
  // represent different Figma elements that happen to share a style.
  static const TextStyle customerName22 = TextStyle(
    fontFamily: _pretendard,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: SegueCardColors.ink,
  );
  // Customer/product detail row label prefix ("회원번호", "희망 제품" 등) —
  // AppleSDGothicNeoSB00 = SemiBold(600), 16px, line-height 24.
  static const TextStyle detailLabel16 = TextStyle(
    fontFamily: _pretendard,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: SegueCardColors.detailText,
    height: 24 / 16,
  );
  // Customer/product detail row value ("TEST-MCM-01" 등) —
  // AppleSDGothicNeoM00 = Medium(500), 16px, line-height 24.
  static const TextStyle detailValue16 = TextStyle(
    fontFamily: _pretendard,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: SegueCardColors.detailText,
    height: 24 / 16,
  );
  // "제품 정보" section label (98:1933) — AppleSDGothicNeoB00 = Bold(700),
  // 15px, statText (#545454).
  static const TextStyle productInfoLabel15 = TextStyle(
    fontFamily: _pretendard,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: SegueCardColors.statText,
  );
  // "쇼핑백 제품" label prefix (98:1933) — AppleSDGothicNeoSB00 =
  // SemiBold(600), 20px, detailText (#3D3D3D), line-height 24.
  static const TextStyle cartProductLabel20 = TextStyle(
    fontFamily: _pretendard,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: SegueCardColors.detailText,
    height: 24 / 20,
  );
  // "쇼핑백 제품" row value (98:1933) — AppleSDGothicNeoM00 = Medium(500),
  // 20px, detailText (#3D3D3D), line-height 24.
  static const TextStyle cartProductValue20 = TextStyle(
    fontFamily: _pretendard,
    fontSize: 20,
    fontWeight: FontWeight.w500,
    color: SegueCardColors.detailText,
    height: 24 / 20,
  );
  // "쇼핑백 제품" row value's Latin brand-word run (89:1559's "M Diamond") —
  // Montserrat Medium(500), 20px, detailText (#3D3D3D), line-height 24.
  static const TextStyle cartProductValueLatin20 = TextStyle(
    fontFamily: _montserrat,
    fontSize: 20,
    fontWeight: FontWeight.w500,
    color: SegueCardColors.detailText,
    height: 24 / 20,
  );
  // Compact button label ("쇼핑백 확인"/"상담 이어서 진행", 80:776) —
  // AppleSDGothicNeoB00 = Bold(700), 15px, white.
  static const TextStyle compactButtonLabel15 = TextStyle(
    fontFamily: _pretendard,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );
  // "상담 데이터 이용 동의 확인" (89:1001) — same button shape as
  // compactButtonLabel15 but measured at 16px, not 15.
  static const TextStyle compactButtonLabel16 = TextStyle(
    fontFamily: _pretendard,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );
  // "고객 검색" section heading (89:928/89:1001) — AppleSDGothicNeoB00 =
  // Bold(700), 20px, ink.
  static const TextStyle sectionHeading20 = TextStyle(
    fontFamily: _pretendard,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: SegueCardColors.ink,
  );
  // Text-field placeholder ("회원번호"/"전화번호" hint, 89:928/89:1001) —
  // AppleSDGothicNeoM00 = Medium(500), 14px, placeholderMuted (#909090).
  static const TextStyle inputPlaceholder14 = TextStyle(
    fontFamily: _pretendard,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: SegueCardColors.placeholderMuted,
  );
  // Page heading on the sidebar-less consent screens (89:1386/98:1810) —
  // AppleSDGothicNeoB00 = Bold(700), 36px, ink. Distinct from pageTitle28 —
  // these screens have no sidebar/subtitle row at all, just this one line.
  static const TextStyle pageHeading36 = TextStyle(
    fontFamily: _pretendard,
    fontSize: 36,
    fontWeight: FontWeight.w700,
    color: SegueCardColors.ink,
  );
  // Bordered-box section heading ("수집 및 이용 목적"/"동의 범위"/"유의사항"/
  // "제한된 기능"/"다음 단계") — AppleSDGothicNeoB00 = Bold(700), 26px, ink.
  static const TextStyle boxHeading26 = TextStyle(
    fontFamily: _pretendard,
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: SegueCardColors.ink,
  );
  // Bullet-list body text (89:1386/98:1810) — AppleSDGothicNeoM00 =
  // Medium(500), 18px, line-height 27, ink.
  static const TextStyle bulletBody18 = TextStyle(
    fontFamily: _pretendard,
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: SegueCardColors.ink,
    height: 27 / 18,
  );
  // "동의 범위" checkbox row label prefix ("회원 쇼핑백 조회" 등) —
  // AppleSDGothicNeoB00 = Bold(700), 19px, line-height 30, ink.
  static const TextStyle checkRowLabel19 = TextStyle(
    fontFamily: _pretendard,
    fontSize: 19,
    fontWeight: FontWeight.w700,
    color: SegueCardColors.ink,
    height: 30 / 19,
  );
  // "추가 상담 진행/미진행" toggle checkbox label (169:3817/169:3878) —
  // AppleSDGothicNeoSB00 = SemiBold(600), 18px, line-height 30, ink. Distinct
  // from checkRowLabel19 (19px Bold) — that's the consent screen's own
  // measured spec, this one measures SemiBold/18px instead.
  static const TextStyle toggleCheckLabel18 = TextStyle(
    fontFamily: _pretendard,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: SegueCardColors.ink,
    height: 30 / 18,
  );
  // "동의 범위" checkbox row description — AppleSDGothicNeoM00 =
  // Medium(500), 19px, line-height 30, ink.
  static const TextStyle checkRowBody19 = TextStyle(
    fontFamily: _pretendard,
    fontSize: 19,
    fontWeight: FontWeight.w500,
    color: SegueCardColors.ink,
    height: 30 / 19,
  );
  // "다음 단계" option title (98:1810's "비회원 일반 상담 진행" 등) —
  // AppleSDGothicNeoB00 = Bold(700), 20px, ink.
  static const TextStyle optionTitle20 = TextStyle(
    fontFamily: _pretendard,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: SegueCardColors.ink,
  );
  // 48px button label (89:1386/98:1810's Continue Buttons) —
  // AppleSDGothicNeoB00 = Bold(700), 20px — color varies (filled=white,
  // outline=ink), passed at the call site.
  static const TextStyle largeButtonLabel20 = TextStyle(
    fontFamily: _pretendard,
    fontSize: 20,
    fontWeight: FontWeight.w700,
  );
  // 89:1498's page heading ("쇼핑백 및 재고 확인") — AppleSDGothicNeoB00 =
  // Bold(700), 32px, ink. A third sidebar-less heading size, distinct from
  // pageHeading36 (89:1386/98:1810).
  static const TextStyle pageHeading32 = TextStyle(
    fontFamily: _pretendard,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: SegueCardColors.ink,
  );
  // Customer info bar value ("TEST-MCM-01"/"010-****-1234"/"2026.08.17(월)"
  // 등) — Montserrat Medium, 20px, ink.
  static const TextStyle customerInfoValue20 = TextStyle(
    fontFamily: _montserrat,
    fontSize: 20,
    fontWeight: FontWeight.w500,
    color: SegueCardColors.ink,
  );
  // Item table column headers ("품목"/"설명"/"재고"/"상담"/"다음 행동") —
  // AppleSDGothicNeoM00 = Medium(500), 20px, ink.
  static const TextStyle tableHeader20 = TextStyle(
    fontFamily: _pretendard,
    fontSize: 20,
    fontWeight: FontWeight.w500,
    color: SegueCardColors.ink,
  );
  // Item name (216:484's "Diamond 비세토스 레더 믹스") — Korean run: Pretendard
  // Bold, 24px, ink. The Latin brand-word run uses [itemNameLatin24]
  // instead (real CartItem.productName values are consistently
  // "<Latin brand> <Korean description>", e.g. "MCM 백팩 미디움" — see
  // mock_segue_repository.dart — so splitting on the first space is safe
  // for this field specifically).
  static const TextStyle itemName24 = TextStyle(
    fontFamily: _pretendard,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: SegueCardColors.ink,
  );
  // Item name Latin-brand-word run (216:484's "Diamond") — Montserrat
  // Bold, 24px, ink.
  static const TextStyle itemNameLatin24 = TextStyle(
    fontFamily: _montserrat,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: SegueCardColors.ink,
  );
  // Item price/color/size block — Montserrat Medium, 22px, ink.
  static const TextStyle itemMeta22 = TextStyle(
    fontFamily: _montserrat,
    fontSize: 22,
    fontWeight: FontWeight.w500,
    color: SegueCardColors.ink,
  );
  // "재고 없음"/"재고 확인"/"상담 미진행" plain status text —
  // AppleSDGothicNeoSB00 = SemiBold(600), 22px, ink.
  static const TextStyle rowStatus22 = TextStyle(
    fontFamily: _pretendard,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: SegueCardColors.ink,
  );
  // "쇼핑백의 모든 품목이 상담 완료되었습니다." banner text (98:1740/98:1806) —
  // AppleSDGothicNeoSB00 = SemiBold(600), 22px, ink.
  static const TextStyle allCompleteBanner22 = TextStyle(
    fontFamily: _pretendard,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: SegueCardColors.ink,
  );
  // "상담 완료" badge / large-button white-label variant, 20px Bold
  // (98:1780/98:1737's disabled-state pill reuses this on a gray fill).
  // Figma's own text node is literally tagged "Montserrat:Bold", but the
  // content is Korean-only ("상담 완료") — Montserrat has no Hangul glyphs,
  // so (per this file's own documented rule) real Korean text uses
  // Pretendard Bold instead, which is what Figma's own renderer actually
  // substitutes in to draw those glyphs.
  static const TextStyle largeButtonLabel20White = TextStyle(
    fontFamily: _pretendard,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );
  // "쇼핑백 품목" card's Korean product-name/color/size run (110:2038) —
  // AppleSDGothicNeoB00 = Bold(700) per Figma, 18px, secondaryText
  // (#515151), line-height 26. Figma's own "COGNAC"/"M" example values are
  // literal Latin placeholders; real CartItem.color/size are Korean, so
  // (per this file's documented rule) they render in Pretendard, not
  // Montserrat.
  static const TextStyle itemSummaryName18 = TextStyle(
    fontFamily: _pretendard,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: SegueCardColors.secondaryText,
    height: 26 / 18,
  );
  // Same run's Latin brand-word span (110:2038's "Diamond") — Montserrat
  // SemiBold(600), 18px, secondaryText, line-height 26.
  static const TextStyle itemSummaryNameLatin18 = TextStyle(
    fontFamily: _montserrat,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: SegueCardColors.secondaryText,
    height: 26 / 18,
  );
  // Follow-up question text (98:1981's question box, 110:2027) —
  // AppleSDGothicNeoSB00 = SemiBold(600), 20px, ink.
  static const TextStyle followUpQuestion20 = TextStyle(
    fontFamily: _pretendard,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: SegueCardColors.ink,
  );
}
