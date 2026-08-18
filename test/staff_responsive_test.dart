import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:segue_frontend/main.dart';
import 'package:segue_frontend/widgets/staff_check_row.dart';

/// Issue #7 requires the staff/tablet shell to avoid overflow across a
/// small tablet, a regular tablet, tablet landscape, and a desktop web
/// width. This pumps the full login → home → customer lookup (consented
/// and unconsented) → consent flow at each width and asserts no rendering
/// exception (e.g. RenderFlex overflow) was thrown.
void main() {
  const List<(String, Size)> sizes = <(String, Size)>[
    ('small tablet portrait', Size(600, 960)),
    ('regular tablet portrait', Size(820, 1180)),
    ('tablet landscape', Size(1180, 820)),
    ('desktop web', Size(1440, 900)),
  ];

  for (final (String label, Size size) in sizes) {
    testWidgets('no overflow at $label ($size)', (WidgetTester tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const SegueApp());
      await tester.tap(find.widgetWithText(FilledButton, '직원 웹'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('고객 조회 시작'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Consented test customer: exercises the populated cart preview list.
      await tester.enterText(find.byType(TextFormField).at(1), '010-1234-5678');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      await tester.tap(find.descendant(of: find.byType(Form), matching: find.text('고객 조회')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final Finder consentButton = find.text('데이터 이용 동의 확인');
      await tester.ensureVisible(consentButton);
      await tester.tap(consentButton);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // "동의하고 장바구니 확인" stays disabled until all three 동의 범위
      // checkboxes are confirmed.
      final Finder checkRows = find.byType(StaffCheckRow);
      expect(checkRows, findsNWidgets(3));
      for (int i = 0; i < 3; i++) {
        await tester.tap(checkRows.at(i));
        await tester.pump();
      }

      // Continue through to the dedicated cart/inventory screen (Figma
      // 14:1051), which has its own item-row layout distinct from the
      // lookup screen's cart preview.
      final Finder agreeButton = find.text('동의하고 장바구니 확인');
      await tester.ensureVisible(agreeButton);
      await tester.tap(agreeButton);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('장바구니 · 재고 확인'), findsOneWidget);

      // Issue #46: continue through the redesigned ("MCM SEGUE") Last
      // Intent flow — Card, its EXACT_PRODUCT result-detail screen, and the
      // completion screen — none of which the pre-#46 version of this test
      // reached, so none of it was actually checked for overflow at
      // smaller tablet widths.
      await tester.tap(find.text('Last Intent 시작').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('고객 의도 입력 시작'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.enterText(find.byType(TextFormField), '편한 느낌이면 좋겠어요');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      await tester.tap(find.text('제출'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('맞아요, 다음 단계로'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('SEGUE CARD'), findsOneWidget);

      Finder cta = find.text('타 매장 확인 요청');
      await tester.ensureVisible(cta);
      await tester.pumpAndSettle();
      await tester.tap(cta);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('정확한 제품 확인'), findsOneWidget);

      // Detail screen (159:2295) CTA label is a Figma-literal override, not
      // the same real actionButtonLabel text the Card screen's CTA uses.
      cta = find.text('타 매장 확인 요청 접수');
      await tester.ensureVisible(cta);
      await tester.pumpAndSettle();
      await tester.tap(cta);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('요청 접수 완료'), findsOneWidget);
    });
  }
}
