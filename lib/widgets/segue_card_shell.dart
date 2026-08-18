import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../utils/segue_card_tokens.dart';

/// The 5 sidebar sections shared across every tablet screen (Figma 89:1196,
/// 164:3213, 159:2295/2173/3053, 169:3683/3821/3891 all show the exact same
/// list). Exactly one is ever "active" (leading arrow + bold) per screen —
/// which one varies per screen, so callers pass it in rather than this shell
/// assuming a fixed value.
enum TabletMenuItem {
  home('HOME'),
  customerSearch('CUSTOMER SEARCH'),
  currentSession('CURRENT SESSION'),
  requests('REQUESTS'),
  consultationHistory('CONSULTATION HISTORY');

  const TabletMenuItem(this.label);
  final String label;
}

/// Shared chrome for every tablet ("MCM SEGUE") screen — header, sidebar
/// (menu + CA footer), and the page-title/step-badge row. Rebuilt against
/// Figma 89:1196 (Issue #48's "최신 Figma" global-shell reference) to fix
/// several inaccuracies the earlier Issue #46-only version had (see
/// TabletMenuItem doc, header logo, avatar/badge colors below) — those
/// fixes apply to every screen using this shell, not just the ones the
/// 89:1196 mockup itself shows.
///
/// GLOBAL UI LOCK: no screen may copy this header/sidebar/footer markup
/// into its own body — they must use this shell so every tablet screen
/// stays visually identical by construction.
class SegueCardShell extends StatelessWidget {
  const SegueCardShell({
    required this.pageTitle,
    required this.activeMenuItem,
    required this.body,
    this.stepBadge,
    this.titleTrailing,
    this.screenTitle,
    this.screenTitleStyle = SegueCardText.screenTitle22,
    this.subtitle,
    this.sessionCount = 0,
    this.bodyTopGap = 28,
    this.bottomBar,
    super.key,
  });

  /// The 28px section heading — e.g. "SEGUE HOME" (89:1196), "CURRENT
  /// SESSION" (164:3213 and the Last Intent result screens). NOT hardcoded
  /// to "CURRENT SESSION" anymore — Home's own mockup proves this varies.
  final String pageTitle;

  /// Which of the 5 sidebar sections this screen belongs to.
  final TabletMenuItem activeMenuItem;

  /// e.g. "4/5". Null on screens with no step indicator (89:1196 Home has
  /// none — this only applies within the Last Intent flow).
  final String? stepBadge;

  /// Arbitrary trailing content in the [pageTitle] row, next to (or instead
  /// of) [stepBadge] — e.g. 89:1196's "START SEGUE" button, which is a
  /// different Figma component ("Start Segue Button") from the small
  /// step-count box, not a parameterization of it.
  final Widget? titleTrailing;

  /// The smaller per-screen title below [pageTitle] (e.g. "정확한 제품 확인").
  /// Null on screens that only have a [pageTitle] (89:1196 Home goes
  /// straight from "SEGUE HOME" to its subtitle with no middle title).
  final String? screenTitle;
  final TextStyle screenTitleStyle;

  final String? subtitle;

  /// Count shown in the "CURRENT SESSION" sidebar badge — shown next to
  /// that menu item regardless of which item is actually [activeMenuItem]
  /// (89:1196 shows "0" there while HOME is active, proving the badge is
  /// independent of the active-item state).
  final int sessionCount;

  /// Gap between the subtitle (or title row, if no subtitle) and [body].
  /// NOT a universal constant — confirmed via Figma that this is 28px on
  /// the Last Intent flow screens (159:2295 etc.) but 40px on 89:1196 Home,
  /// so callers pass their own measured value instead of this shell
  /// guessing one number fits every screen.
  final double bodyTopGap;

  /// Scrollable content below the title/subtitle — each screen supplies its
  /// own cards here.
  final Widget body;

  /// The link + CTA row (usually a [SegueBottomActionRow]). Figma pins this
  /// to a fixed position at the bottom-right of the content column (e.g.
  /// 159:2295's Continue Button sits at a fixed y=821 regardless of how
  /// tall the cards above it are) — kept outside the scrollable [body] so
  /// it never scrolls away or drifts up on short-content screens.
  final Widget? bottomBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: SegueCardColors.border),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x14000000),
                offset: Offset(0, 4),
                blurRadius: 16,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Column(
              children: <Widget>[
                const TabletHeader(),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      TabletNavSidebar(
                        activeMenuItem: activeMenuItem,
                        sessionCount: sessionCount,
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(31, 24, 31, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              LayoutBuilder(
                                builder:
                                    (
                                      BuildContext context,
                                      BoxConstraints constraints,
                                    ) {
                                      final Widget title = Text(
                                        pageTitle,
                                        style: SegueCardText.pageTitle28,
                                        overflow: TextOverflow.ellipsis,
                                      );
                                      final List<Widget> trailing = <Widget>[
                                        if (stepBadge != null)
                                          Container(
                                            width: 53,
                                            height: 36,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color:
                                                  SegueCardColors.stepBadgeBg,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              stepBadge!,
                                              style: SegueCardText.stepBadge20,
                                            ),
                                          ),
                                        if (titleTrailing != null)
                                          titleTrailing!,
                                      ];
                                      // A fixed-width titleTrailing widget (e.g.
                                      // 89:1196's 173px-wide Start Segue Button)
                                      // has no narrower Figma variant, so this
                                      // app's own responsive fallback drops it
                                      // below the title instead of overflowing.
                                      if (trailing.isEmpty ||
                                          constraints.maxWidth >= 360) {
                                        return Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: <Widget>[
                                            Expanded(child: title),
                                            for (final Widget t
                                                in trailing) ...<Widget>[
                                              const SizedBox(width: 12),
                                              t,
                                            ],
                                          ],
                                        );
                                      }
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          title,
                                          const SizedBox(height: 12),
                                          Wrap(
                                            spacing: 12,
                                            runSpacing: 8,
                                            children: trailing,
                                          ),
                                        ],
                                      );
                                    },
                              ),
                              if (screenTitle != null) ...<Widget>[
                                // Figma delta (159:2295): page-title top 105 →
                                // screen-title top 191 = 86px, minus the
                                // 28px-font page title's own ~34px line box =
                                // 52px gap. Same delta on 164:3213/169:3683.
                                const SizedBox(height: 52),
                                Text(screenTitle!, style: screenTitleStyle),
                              ],
                              if (subtitle != null) ...<Widget>[
                                // Figma: screen-title top 191 (h31) → subtitle
                                // top 227 = 5px gap on the Last Intent flow
                                // screens; 89:1196 Home (no screenTitle) uses
                                // a 7px gap from the page-title instead.
                                SizedBox(height: screenTitle != null ? 5 : 7),
                                Text(
                                  subtitle!,
                                  style: SegueCardText.subtitle16,
                                ),
                              ],
                              SizedBox(height: bodyTopGap),
                              Expanded(
                                child: SingleChildScrollView(child: body),
                              ),
                              if (bottomBar != null) bottomBar!,
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shared chrome for the sidebar-less "동의" flow screens (Figma 89:1386
/// "동의 안내 화면" / 98:1810 "비동의 안내 화면") — [TabletHeader] only, no
/// [TabletNavSidebar]: confirmed via Figma metadata that neither node has a
/// "Menu Background"/menu list at all, unlike every other tablet screen.
/// Content spans the full frame width minus a ~65-69px symmetric inset
/// instead of the usual 265px sidebar + 31px content padding.
class SegueHeaderOnlyShell extends StatelessWidget {
  const SegueHeaderOnlyShell({
    required this.heading,
    required this.body,
    this.headingStyle = SegueCardText.pageHeading36,
    this.headingTrailing,
    this.headingGap = 22,
    this.horizontalPadding = 65,
    super.key,
  });

  /// The page heading (e.g. "상담 데이터 이용 동의").
  final String heading;
  final TextStyle headingStyle;

  /// Content sharing the heading's own row (89:1498's customer-info bar
  /// sits to the right of "쇼핑백 및 재고 확인" on the same line, unlike
  /// 89:1386/98:1810 where the heading has the row to itself).
  final Widget? headingTrailing;

  /// Gap between the heading row and [body] — 22px on 89:1386/98:1810, but
  /// not re-verified for every sidebar-less screen, so callers measure
  /// their own.
  final double headingGap;

  /// 65px on 89:1386/98:1810; 89:1498 measures 50px instead — not a shared
  /// constant across every sidebar-less screen.
  final double horizontalPadding;

  /// Scrollable content below the heading.
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: SegueCardColors.border),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x14000000),
                offset: Offset(0, 4),
                blurRadius: 16,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Column(
              children: <Widget>[
                const TabletHeader(),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      24,
                      horizontalPadding,
                      24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        if (headingTrailing == null)
                          Text(heading, style: headingStyle)
                        else
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              // The heading text is short and never wraps
                              // (89:1498), so it takes its own natural
                              // width — the trailing content (a wide
                              // customer-info bar) is the one that needs
                              // Expanded's bounded width to lay out its own
                              // Row of columns.
                              Text(heading, style: headingStyle),
                              const SizedBox(width: 16),
                              Expanded(child: headingTrailing!),
                            ],
                          ),
                        SizedBox(height: headingGap),
                        Expanded(child: SingleChildScrollView(child: body)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The top bar — MCM logo mark + "SEGUE" wordmark on the left, account icon
/// on the right. Figma (89:1196): both icons are real exported SVG assets
/// ("MCM" is custom brand lettering, not a system font — bundled as
/// `assets/icons/mcm_logo.svg`/`account_icon.svg`, not approximated with
/// text or a generic Material icon).
class TabletHeader extends StatelessWidget {
  const TabletHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: SegueCardSizes.headerHeight,
      // Figma: MCM icon left edge x=32; account icon right edge
      // 1381.73+25.27=1407, frame width 1440 → 33px right inset. ~32-33px
      // symmetric, not the 24px this header used before.
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: SegueCardColors.border, width: 2),
        ),
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 48,
            height: 15.2,
            child: SvgPicture.asset(
              'assets/icons/mcm_logo.svg',
              fit: BoxFit.contain,
            ),
          ),
          // Figma: icon right edge 32+48=80 → "SEGUE" text left 87 = 7px.
          const SizedBox(width: 7),
          const Text('SEGUE', style: SegueCardText.brandLogo20),
          const Spacer(),
          SizedBox(
            width: 25.27,
            height: 25.2,
            child: SvgPicture.asset(
              'assets/icons/account_icon.svg',
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}

/// The left nav — "SEGUE MENU" label, divider, 5 menu sections (one active),
/// and the CA footer. Figma (89:1196) confirmed several things the older
/// Issue #46-only sidebar got wrong:
/// - the active item gets a LEADING arrow icon, not a trailing badge;
/// - the "CURRENT SESSION" count badge is a separate element that always
///   shows regardless of which item is active, colored gray at 0 / black
///   once nonzero;
/// - the CA avatar circle is light gray (#D9D9D9) with muted-gray initials,
///   not a dark filled circle with white initials.
class TabletNavSidebar extends StatelessWidget {
  const TabletNavSidebar({
    required this.activeMenuItem,
    this.sessionCount = 0,
    super.key,
  });

  final TabletMenuItem activeMenuItem;
  final int sessionCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: SegueCardSizes.sidebarWidth,
      color: SegueCardColors.sidebarBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Figma: sidebar top 69 → "SEGUE MENU" top 112 = 43px.
          const SizedBox(height: 43),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 31),
            child: Text('SEGUE MENU', style: SegueCardText.menuLabel14),
          ),
          const SizedBox(height: 1),
          // Figma "Line 1" deliberately bleeds past the 31px content inset
          // to the sidebar's true left edge (x=0), 131px wide — not the
          // sidebar's full 265px width.
          Container(width: 131, height: 1, color: SegueCardColors.muted),
          // Figma: divider bottom 131 → Menu Container top 182 = 51px.
          const SizedBox(height: 51),
          Padding(
            // Figma "Menu Container": left 31, width 210 → right inset
            // 265-31-210=24, NOT symmetric 31 — measured because "CONSULTATION
            // HISTORY" (the widest label) truncated to an ellipsis at a
            // symmetric 31px inset when checked against the real render.
            padding: const EdgeInsets.fromLTRB(31, 0, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                for (
                  int i = 0;
                  i < TabletMenuItem.values.length;
                  i++
                ) ...<Widget>[
                  if (i > 0) const SizedBox(height: 8),
                  _SidebarMenuRow(
                    item: TabletMenuItem.values[i],
                    active: TabletMenuItem.values[i] == activeMenuItem,
                    sessionCount:
                        TabletMenuItem.values[i] ==
                            TabletMenuItem.currentSession
                        ? sessionCount
                        : null,
                  ),
                ],
              ],
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(31, 0, 31, 24),
            child: Row(
              children: <Widget>[
                Container(
                  width: 41,
                  height: 41,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: SegueCardColors.avatarCircleBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Text('SL', style: SegueCardText.caInitials17),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Client Advisor', style: SegueCardText.caRole12),
                      Text('김셀러', style: SegueCardText.caName14),
                      Text('강남 플래그십 스토어', style: SegueCardText.caStore10),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: SegueCardColors.muted,
                  size: 18,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarMenuRow extends StatelessWidget {
  const _SidebarMenuRow({
    required this.item,
    required this.active,
    this.sessionCount,
  });

  final TabletMenuItem item;
  final bool active;

  /// Non-null only for [TabletMenuItem.currentSession].
  final int? sessionCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        if (active) ...<Widget>[
          // Figma applies a 90° rotation to this arrow asset (drawn
          // pointing up, rotated to point right for the active-item marker).
          Transform.rotate(
            angle: math.pi / 2,
            child: SizedBox(
              width: 14,
              height: 14,
              child: SvgPicture.asset(
                'assets/icons/nav_active_arrow.svg',
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(width: 6),
        ],
        Flexible(
          child: Text(
            item.label,
            style: active
                ? SegueCardText.menuItemActive16
                : SegueCardText.menuItem16,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        // The "CURRENT SESSION" count badge is intentionally removed here
        // (per explicit design direction) even though Figma still shows it
        // — [sessionCount] is kept as a param (screens still pass it) but
        // no longer rendered, so re-adding it later needs no call-site
        // changes.
      ],
    );
  }
}

/// The "처음으로 돌아가기" link + primary CTA row that closes every one of
/// this issue's screens, always at the same relative position (bottom of
/// the scrollable body, link left / CTA right).
class SegueBottomActionRow extends StatelessWidget {
  const SegueBottomActionRow({
    required this.onBackToStart,
    this.cta,
    this.topPadding = 50,
    super.key,
  });

  final VoidCallback onBackToStart;
  final Widget? cta;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Figma (159:2295): 3-card row bottom 594+177=771 → CTA top 821 = 50px.
      padding: EdgeInsets.only(top: topPadding),
      // Wrap sizes itself to its children by default, which left
      // WrapAlignment.spaceBetween with no extra width to distribute (both
      // items rendered bunched on the left instead of link-left/CTA-right).
      // Forcing the Wrap to the full row width first gives it room to work.
      child: SizedBox(
        width: double.infinity,
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 12,
          children: <Widget>[
            InkWell(
              onTap: onBackToStart,
              child: const Text(
                '처음으로 돌아가기',
                style: SegueCardText.link18Underline,
              ),
            ),
            if (cta != null) cta!,
          ],
        ),
      ),
    );
  }
}

/// The black CTA button matching every "Continue Button" instance in
/// Figma (bg #222, white 18px bold text, 43px tall, auto width from label).
///
/// The trailing arrow is NOT universal — confirmed via Figma metadata that
/// 159:2295 (EXACT_PRODUCT, "타 매장 확인 요청 접수") and 169:3683
/// (ADDITIONAL_CONSULTATION, "조건 다시 확인하기") both have a Vector child next
/// to the button text, but 159:2213/169:4101 (COMPARISON_EXPERIENCE/
/// TODAY_PURCHASE's "해당 제품 상담 완료") do not.
class SegueCtaButton extends StatelessWidget {
  const SegueCtaButton({
    required this.label,
    required this.onPressed,
    this.showArrow = true,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool showArrow;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SegueCardColors.ctaBg,
      // Every "Continue Button" instance checked in Figma (89:1196,
      // 98:1725/1734/1737/1870/1873/1974, 159:2295 etc.) has no corner
      // radius at all — square, not the 6px this used to hardcode.
      borderRadius: BorderRadius.zero,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Flexible(
                child: Text(
                  label,
                  style: SegueCardText.ctaLabel18White,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              if (showArrow) ...<Widget>[
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward, color: Colors.white, size: 17),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The fixed-size title-row CTA matching Figma's "Start Segue Button"
/// component (89:1196) — distinct from [SegueCtaButton]'s "Continue Button"
/// (fixed 173x47 vs auto-width, off-white #F1F1F1 text vs pure white,
/// Montserrat vs Pretendard, no icon).
class SegueStartButton extends StatelessWidget {
  const SegueStartButton({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SegueCardColors.ctaBg,
      // Figma's "Start Segue Button" component (89:1196) has no corner
      // radius — square, not the 6px this used to hardcode.
      borderRadius: BorderRadius.zero,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.zero,
        child: SizedBox(
          width: 173,
          height: 47,
          child: Center(
            child: Text(
              label,
              style: SegueCardText.ctaLabel18Muted,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ),
      ),
    );
  }
}

/// The small 34px-tall action button matching Figma's "Continue Button"
/// instances on 80:776's "진행 중인 상담" card ("쇼핑백 확인"/"상담 이어서 진행") —
/// a third size/weight variant distinct from both [SegueCtaButton] (43px,
/// 18px text) and [SegueStartButton] (47px fixed, 18px text): 34px tall,
/// 15px text, auto width, background color varies per instance.
class SegueCompactButton extends StatelessWidget {
  const SegueCompactButton({
    required this.label,
    required this.backgroundColor,
    required this.onPressed,
    this.showArrow = false,
    this.height = 34,
    this.width,
    this.horizontalPadding = 16,
    this.borderRadius = BorderRadius.zero,
    this.textStyle = SegueCardText.compactButtonLabel15,
    super.key,
  });

  final String label;
  final Color backgroundColor;
  final VoidCallback? onPressed;
  final bool showArrow;

  /// 34px on 80:776's buttons; 89:928/89:1001's "고객 조회" submit button
  /// measures 32px instead — not a shared constant across every instance.
  final double height;

  /// Fixed width (e.g. 123 for 98:1780's "상담 완료" cart-row badge). Null
  /// keeps the auto-width-from-label behavior every other instance uses.
  final double? width;

  /// 16px on 80:776's buttons; 98:1780's "상담 완료" badge measures a much
  /// tighter 4px (123px box around ~115px-wide text) instead.
  final double horizontalPadding;

  /// Every "Continue Button" instance checked in Figma (80:776, 98:1737
  /// etc.) has no corner radius — defaults to square (`BorderRadius.zero`).
  final BorderRadius borderRadius;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: borderRadius,
      child: InkWell(
        onTap: onPressed,
        borderRadius: borderRadius,
        child: Container(
          height: height,
          width: width,
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Flexible(
                child: Text(
                  label,
                  style: textStyle,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              if (showArrow) ...<Widget>[
                const SizedBox(width: 6),
                Transform.rotate(
                  angle: math.pi / 2,
                  child: SizedBox(
                    width: 14,
                    height: 14,
                    child: SvgPicture.asset(
                      'assets/icons/nav_active_arrow.svg',
                      fit: BoxFit.contain,
                      colorFilter: const ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The filled, borderless text input matching Figma's "Rectangle 4" input
/// boxes (89:928/89:1001 "회원번호"/"전화번호") — background #EDEDED, no
/// border, square corners, placeholder-style hint text, 42px tall.
class SegueTextField extends StatelessWidget {
  const SegueTextField({
    required this.hintText,
    required this.controller,
    this.keyboardType,
    this.validator,
    super.key,
  });

  final String hintText;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: SegueCardText.inputPlaceholder14.copyWith(
        color: SegueCardColors.ink,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: SegueCardText.inputPlaceholder14,
        filled: true,
        fillColor: SegueCardColors.previewPanelBg,
        isDense: true,
        constraints: const BoxConstraints.tightFor(height: 42),
        contentPadding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide.none,
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide.none,
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: SegueCardColors.ink, width: 1.5),
        ),
      ),
    );
  }
}

/// The 48px-tall Continue Button matching 89:1386/98:1810's larger CTAs —
/// a fourth size variant (48px/20px, vs 43px/18px [SegueCtaButton],
/// 47px-fixed/18px [SegueStartButton], 34px-or-32px/15-16px
/// [SegueCompactButton]) that additionally switches between an OUTLINE
/// style (border #222, ink text, no fill — 89:1386's default "동의하고
/// 쇼핑백 확인"/always-outline "동의하지 않음"/98:1810's "고객 조회로 돌아가기")
/// and a FILLED style (bg #222, white text — confirmed via 89:1482's
/// checked-state snippet and 98:1810's "비회원 상담 진행"/"비회원 상담 시작").
class SegueLargeButton extends StatelessWidget {
  const SegueLargeButton({
    required this.label,
    required this.filled,
    required this.onPressed,
    this.borderWidth = 1,
    super.key,
  });

  final String label;
  final bool filled;
  final VoidCallback? onPressed;

  /// 1px by default (unverified pre-existing value on the consent screens'
  /// outline buttons); 98:1725's "SEGUE 진행" cart-row button measures a
  /// confirmed 2px border instead.
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    final Color textColor = filled ? Colors.white : SegueCardColors.ink;
    return Material(
      color: filled ? SegueCardColors.ctaBg : Colors.white,
      child: InkWell(
        onTap: onPressed,
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: filled
              ? null
              : BoxDecoration(
                  border: Border.all(
                    color: SegueCardColors.ink,
                    width: borderWidth,
                  ),
                ),
          // Container(alignment: center) expands to fill any available
          // width (Align's default behavior when unconstrained) instead of
          // shrink-wrapping the label — Row(mainAxisSize.min), the pattern
          // every other button in this file uses, avoids that. Flexible
          // around the Text is what actually lets it ellipsize instead of
          // overflowing once a caller (e.g. an Expanded column) gives this
          // button a tight width narrower than the label's natural size.
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Flexible(
                child: Text(
                  label,
                  style: SegueCardText.largeButtonLabel20.copyWith(
                    color: textColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The "동의 범위" checkbox row (Figma 89:1386) — a 15x15 square (2px #222
/// border, unchecked; filled #222 with a white check mark once checked,
/// inferred from 89:1482's checked-state button treatment since Figma gave
/// no separate checked-checkbox reference) + a Bold label prefix and a
/// Medium description on the same line.
class SegueCheckboxRow extends StatelessWidget {
  const SegueCheckboxRow({
    required this.label,
    required this.description,
    required this.checked,
    required this.onChanged,
    super.key,
  });

  final String label;
  final String description;
  final bool checked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!checked),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            // Figma: text top 465 → checkbox top 473 = 8px, aligning the
            // checkbox with the label's cap-height rather than the row top.
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              width: 15,
              height: 15,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: checked ? SegueCardColors.ink : Colors.white,
                border: Border.all(color: SegueCardColors.ink, width: 2),
              ),
              child: checked
                  ? const Icon(Icons.check, size: 11, color: Colors.white)
                  : null,
            ),
          ),
          // Figma: checkbox left 95 → text left 123 = 28px.
          const SizedBox(width: 28),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: <InlineSpan>[
                  TextSpan(text: label, style: SegueCardText.checkRowLabel19),
                  TextSpan(
                    text: '  $description',
                    style: SegueCardText.checkRowBody19,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
