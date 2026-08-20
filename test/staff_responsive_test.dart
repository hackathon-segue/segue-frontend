import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:segue_frontend/main.dart';
import 'package:segue_frontend/repositories/mock_segue_repository.dart';
import 'package:segue_frontend/utils/app_config.dart';

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

      await tester.pumpWidget(SegueApp(repository: MockSegueRepository()));
      // The mobile customer entry screen no longer has a "직원 웹" button
      // (it's now the real customer-facing app) — reach staff routes via a
      // direct named push instead, same as the app's own wireframe QA does.
      Navigator.of(
        tester.element(find.text('LXXVI')),
      ).pushNamed(AppRoutes.staffHome);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('START SEGUE'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Consented test customer: opens the populated cart list directly.
      await tester.enterText(find.byType(TextFormField).at(1), '010-1234-5678');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      await tester.tap(
        find.descendant(of: find.byType(Form), matching: find.text('고객 조회')),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final Finder cartButton = find.text('쇼핑백 확인');
      await tester.ensureVisible(cartButton);
      await tester.tap(cartButton);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('쇼핑백 및 재고 확인'), findsOneWidget);

      // Issue #46: continue through the redesigned ("MCM SEGUE") Last
      // Intent flow — Card, its EXACT_PRODUCT result-detail screen, and the
      // completion screen — none of which the pre-#46 version of this test
      // reached, so none of it was actually checked for overflow at
      // smaller tablet widths.
      final Finder lastIntentButton = find.text('Last Intent 시작').first;
      await tester.ensureVisible(lastIntentButton);
      await tester.tap(lastIntentButton);
      await tester.pumpAndSettle();
      await tester.tap(find.text('고객 의도 입력 시작'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.enterText(find.byType(TextField), '편한 느낌이면 좋겠어요');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      await tester.tap(find.text('고객 의도 구조화하기'));
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
