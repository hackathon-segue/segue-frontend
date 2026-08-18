import 'package:flutter/material.dart';

import '../providers/providers.dart';
import '../utils/app_config.dart';
import '../utils/segue_card_tokens.dart';
import '../widgets/segue_card_shell.dart';

/// Figma node 98:1810 "비동의 안내 화면" (Issue #48 — this screen's own visual
/// rebuild, superseding the previous 14:1197-based build). Uses the shared
/// [SegueHeaderOnlyShell] (same sidebar-less family as [ConsentScreen]'s
/// 89:1386) — no header markup is built here.
///
/// "비회원 상담 진행" still has no defined screen or API anywhere in
/// API.md/SCHEMA.md/TASK.md, so its button stays intentionally inert, same
/// as the previous build — see the Issue #7 implementation report for
/// follow-up.
class ConsentDeclinedScreen extends StatelessWidget {
  const ConsentDeclinedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final StaffWebSessionController controller = StaffSessionScope.of(context);

    return SegueHeaderOnlyShell(
      heading: '데이터 이용 동의 거부됨',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: double.infinity,
            // Minimum, not fixed — matches Figma exactly at the 1440
            // reference width but grows instead of clipping once the
            // bullet lines wrap at narrower widths.
            constraints: const BoxConstraints(minHeight: 169),
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: SegueCardColors.border, width: 2),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text('제한된 기능', style: SegueCardText.boxHeading26),
                SizedBox(height: 19),
                _BulletLine('회원 장바구니 조회'),
                _BulletLine('상담 결과 저장'),
                _BulletLine('고객 모바일 재확인'),
              ],
            ),
          ),
          // Figma: box1 bottom 177+169=346 → box2 top 365 = 19px.
          const SizedBox(height: 19),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 295),
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: SegueCardColors.border, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text('다음 단계', style: SegueCardText.boxHeading26),
                // Figma: title bottom 381+36=417 → row1 top 433 = 16px.
                const SizedBox(height: 16),
                const _NextStepOption(
                  height: 99,
                  title: '비회원 일반 상담 진행',
                  description: '비회원으로 상담을 진행합니다. 선택한 제품 정보와 고객 의도를 수동으로 입력해 '
                      '상담을 계속 진행할 수 있습니다.',
                  button: const SegueLargeButton(
                    label: '비회원 상담 진행',
                    filled: true,
                    // No defined screen/API for this action anywhere in
                    // API.md/SCHEMA.md/TASK.md — left inert rather than
                    // guessing a destination.
                    onPressed: null,
                  ),
                ),
                // Figma: row1 bottom 433+99=532 → row2 top 543 = 11px.
                const SizedBox(height: 11),
                _NextStepOption(
                  height: 95,
                  title: '고객 조회 화면으로 돌아가기',
                  description: '현재 상담을 취소하고 다른 고객을 조회하거나 새로운 상담을 시작합니다.',
                  button: SegueLargeButton(
                    label: '고객 조회로 돌아가기',
                    filled: false,
                    onPressed: () {
                      controller.reset();
                      Navigator.of(context).popUntil(ModalRoute.withName(AppRoutes.customerLookup));
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BulletLine extends StatelessWidget {
  const _BulletLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text('•', style: SegueCardText.bulletBody18),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: SegueCardText.bulletBody18)),
      ],
    );
  }
}

class _NextStepOption extends StatelessWidget {
  const _NextStepOption({
    required this.height,
    required this.title,
    required this.description,
    required this.button,
  });

  final double height;
  final String title;
  final String description;
  final Widget button;

  @override
  Widget build(BuildContext context) {
    final Widget textColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(title, style: SegueCardText.optionTitle20),
        // Figma: title top 16 → description top 52 (row-relative) = 36px
        // total from top, ~8px gap after the title's own line box.
        const SizedBox(height: 8),
        Text(description, style: SegueCardText.bulletBody18),
      ],
    );

    return Container(
      width: double.infinity,
      // Minimum, not fixed — the description can wrap to more lines at
      // narrower widths than the 1440 reference.
      constraints: BoxConstraints(minHeight: height),
      color: SegueCardColors.scopeBoxBg,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          // The button has no narrower Figma variant, so this app's own
          // responsive fallback drops it below the text instead of
          // overflowing.
          if (constraints.maxWidth >= 500) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Expanded(child: textColumn),
                const SizedBox(width: 24),
                button,
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[textColumn, const SizedBox(height: 12), button],
          );
        },
      ),
    );
  }
}
