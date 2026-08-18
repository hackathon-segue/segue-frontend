import 'package:flutter/material.dart';

import '../utils/segue_card_tokens.dart';

/// Shared chrome for the "MCM SEGUE" Last Intent flow (Issue #46) — header,
/// sidebar (with CA footer), "CURRENT SESSION" page title + step badge.
/// Identical across every one of Figma nodes 164:3213 / 159:2295 /
/// 159:2173 / 159:3053 / 169:3683 / 169:3821 / 169:3891 (`get_design_context`
/// on all of them returns the same header/sidebar/footer/step-badge
/// structure byte-for-byte, only the step number and body differ).
///
/// Only used by the Last Intent flow screens for now — the rest of the
/// staff app (login/home/customer lookup/consent/cart) intentionally keeps
/// [StaffAppShell]'s current look; this issue's Figma only covers the
/// Last Intent flow, and migrating the rest is separate, later work.
class SegueCardShell extends StatelessWidget {
  const SegueCardShell({
    required this.step,
    required this.title,
    required this.body,
    this.subtitle,
    this.titleStyle = SegueCardText.screenTitle22,
    this.bottomBar,
    super.key,
  });

  /// e.g. "4/5".
  final String step;
  final String title;
  final TextStyle titleStyle;

  /// Null on the Card screen (164:3213), which has no subtitle line.
  final String? subtitle;

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
              BoxShadow(color: Color(0x14000000), offset: Offset(0, 4), blurRadius: 16),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Column(
              children: <Widget>[
                const _SegueHeader(),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const _SegueSidebar(),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(31, 24, 31, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  const Expanded(
                                    child: Text(
                                      'CURRENT SESSION',
                                      style: SegueCardText.pageTitle28,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    width: 53,
                                    height: 36,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: SegueCardColors.avatarBg,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(step, style: SegueCardText.stepBadge20),
                                  ),
                                ],
                              ),
                              // Figma delta (159:2295): page-title top 105 →
                              // screen-title top 191 = 86px, minus the
                              // 28px-font page title's own ~34px line box =
                              // 52px gap. Same delta on 164:3213/169:3683.
                              const SizedBox(height: 52),
                              Text(title, style: titleStyle),
                              if (subtitle != null) ...<Widget>[
                                // Figma: screen-title top 191 (h31) → subtitle
                                // top 227 = 5px gap.
                                const SizedBox(height: 5),
                                Text(subtitle!, style: SegueCardText.subtitle16),
                              ],
                              // Figma: subtitle top 227 (h21) → product box
                              // top 276 = 28px gap.
                              const SizedBox(height: 28),
                              Expanded(child: SingleChildScrollView(child: body)),
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

class _SegueHeader extends StatelessWidget {
  const _SegueHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: SegueCardSizes.headerHeight,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: SegueCardColors.border, width: 2)),
      ),
      child: const Row(
        children: <Widget>[
          Text('MCM SEGUE', style: SegueCardText.brandLogo20),
          Spacer(),
          Icon(Icons.person_outline, color: SegueCardColors.ink),
        ],
      ),
    );
  }
}

class _SegueSidebar extends StatelessWidget {
  const _SegueSidebar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: SegueCardSizes.sidebarWidth,
      color: SegueCardColors.sidebarBg,
      padding: const EdgeInsets.symmetric(horizontal: 31, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('SEGUE MENU', style: SegueCardText.menuLabel14),
          const SizedBox(height: 18),
          const Text('HOME', style: SegueCardText.menuItem16),
          const SizedBox(height: 8),
          const Text('CUSTOMER SEARCH', style: SegueCardText.menuItem16),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              const Flexible(
                child: Text(
                  'CURRENT SESSION',
                  style: SegueCardText.menuItemActive16,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 20,
                height: 15,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: SegueCardColors.badgeBg,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '1',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('REQUESTS', style: SegueCardText.menuItem16),
          const SizedBox(height: 8),
          const Text('CONSULTATION HISTORY', style: SegueCardText.menuItem16),
          const Spacer(),
          Row(
            children: <Widget>[
              Container(
                width: 41,
                height: 41,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: SegueCardColors.avatarBg,
                  shape: BoxShape.circle,
                ),
                child: const Text(
                  'SL',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white),
                ),
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
              const Icon(Icons.chevron_right, color: SegueCardColors.muted, size: 18),
            ],
          ),
        ],
      ),
    );
  }
}

/// The "처음으로 돌아가기" link + primary CTA row that closes every one of
/// this issue's screens, always at the same relative position (bottom of
/// the scrollable body, link left / CTA right).
class SegueBottomActionRow extends StatelessWidget {
  const SegueBottomActionRow({required this.onBackToStart, this.cta, super.key});

  final VoidCallback onBackToStart;
  final Widget? cta;

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Figma (159:2295): 3-card row bottom 594+177=771 → CTA top 821 = 50px.
      padding: const EdgeInsets.only(top: 50),
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
              child: const Text('처음으로 돌아가기', style: SegueCardText.link18Underline),
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
  const SegueCtaButton({required this.label, required this.onPressed, this.showArrow = true, super.key});

  final String label;
  final VoidCallback? onPressed;
  final bool showArrow;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SegueCardColors.ctaBg,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
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
