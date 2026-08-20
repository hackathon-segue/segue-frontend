import 'package:flutter/material.dart';

import '../providers/providers.dart';
import '../utils/app_config.dart';
import '../widgets/segue_card_shell.dart';

/// Figma node 89:1196 "직원용 웹 홈 -> 고객 조회 이전" — Issue #48's visual
/// rebuild of the Home screen. Uses the shared [SegueCardShell]/
/// [TabletHeader]/[TabletNavSidebar] confirmed in Issue #48's shell pass — no
/// header/menu markup is built here.
///
/// The dashboard summary cards ("현재 진행 중 상담"/"오늘 완료한 내 상담"/"처리
/// 대기") and the "진행 중인 상담" in-progress-consultation card/"상담 이어서
/// 진행" resume flow that used to live here have been dropped — this feature
/// was decided against, so only the title/CTA/footer image remain.
class StaffHomeScreen extends StatelessWidget {
  const StaffHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final LastIntentSessionManager manager = LastIntentSessionScope.of(context);

    return SegueCardShell(
      pageTitle: 'SEGUE HOME',
      activeMenuItem: TabletMenuItem.home,
      sessionCount: manager.activeCount,
      subtitle: '고객이 앱에서 선택한 제품과 조건을 매장 상담으로 연결해 끊김없는 경험을 이어갑니다.',
      bodyTopGap: 40,
      titleTrailing: SegueStartButton(
        label: 'START SEGUE',
        onPressed: () => Navigator.of(context).pushNamed(AppRoutes.customerLookup),
      ),
      body: const _HomeFooterImage(),
    );
  }
}

/// Figma (89:1196) "Footer Image" — a decorative product photo band with a
/// 50% base opacity and a white-to-transparent top fade (`from-white` at
/// the 4.6% gradient stop, `to-transparent` by 100%).
class _HomeFooterImage extends StatelessWidget {
  const _HomeFooterImage();

  @override
  Widget build(BuildContext context) {
    // Figma (89:1196): Footer Image spans left-51/top-558/w-1389/h-347 on
    // the 1440x900 canvas — left-51 sits behind the 265-wide sidebar (so
    // its visible left edge is flush against the sidebar, further left
    // than every other content element's own left inset), its right edge
    // is flush against the card's right edge, and it's bled 5px past the
    // card's bottom edge — all past SegueCardShell's own 31px-left/right
    // and 24px-bottom content padding. `Padding` can't express a negative
    // inset (RenderPadding asserts `padding.isNonNegative`), so this reads
    // the box this widget would normally occupy via LayoutBuilder and uses
    // OverflowBox to paint 31px wider on each side and 24px taller (added
    // at the bottom via `Alignment.topCenter`) than that box, unclipped —
    // the outer ClipRRect still clips the result at the card's rounded
    // corner. OverflowBox itself always sizes to the biggest its OWN
    // incoming constraints allow, so it can't sit directly in this
    // widget's naturally-unbounded-height slot (SingleChildScrollView
    // gives it maxHeight: infinity) — the outer SizedBox pins a concrete
    // height first, exactly like the old `SizedBox(height: 347)` did
    // (BoxConstraints.enforce clamps that 347 up to the real available
    // height here), so OverflowBox's own incoming constraints are finite.
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double height = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : constraints.minHeight;
        return SizedBox(
          width: constraints.maxWidth,
          height: height,
          child: OverflowBox(
            alignment: Alignment.topCenter,
            minWidth: 0,
            maxWidth: double.infinity,
            minHeight: 0,
            maxHeight: double.infinity,
            child: SizedBox(
              width: constraints.maxWidth + 62,
              height: height + 24,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  Opacity(
                    opacity: 0.5,
                    child: Image.asset('assets/images/home_footer.png', fit: BoxFit.cover),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[Colors.white, Colors.white.withValues(alpha: 0)],
                        stops: const <double>[0.046, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
