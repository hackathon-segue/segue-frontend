import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:segue_frontend/main.dart';
import 'package:segue_frontend/utils/app_config.dart';

/// Regression coverage for a bug where trailing "chip"/status groups (e.g.
/// "Last Intent 시작" on the customer lookup cart preview) were wrapped in a
/// `Flexible` that competed 50/50 with the leading `Expanded` name column,
/// so the group right-aligned inside only its own half instead of the
/// row's true right edge. These tests assert the trailing content's right
/// edge actually reaches the card's right edge (within rounding).
void main() {
  testWidgets('cart preview action chip is flush with the card right edge', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const SegueApp());
    Navigator.of(
      tester.element(find.text('LXXVI')),
    ).pushNamed(AppRoutes.staffHome);
    await tester.pumpAndSettle();

    await tester.tap(find.text('고객 조회 시작'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(1), '010-1234-5678');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    await tester.tap(
      find.descendant(of: find.byType(Form), matching: find.text('고객 조회')),
    );
    await tester.pumpAndSettle();

    final Rect chipRect = tester.getRect(find.text('Last Intent 시작').first);
    final Rect cardRect = tester.getRect(find.text('장바구니 제품 목록'));
    // The result card spans from its own left edge out to
    // (left + full card width); use the card title's ancestor Container
    // instead so we measure the actual card bounds, not just the title text.
    final Finder cardFinder = find
        .ancestor(of: find.text('장바구니 제품 목록'), matching: find.byType(Container))
        .first;
    final Rect fullCardRect = tester.getRect(cardFinder);

    // SectionCard has 12px padding + 1px border on the right, so the chip's
    // right edge should sit ~13px inside the card's outer right edge. Before
    // the fix this gap was in the hundreds of pixels (stranded at the
    // midpoint of the row); allow generous slack for that inset plus the
    // button's own internal padding, while still catching the regression.
    expect(
      fullCardRect.right - chipRect.right,
      lessThan(40),
      reason:
          'action chip right edge ($chipRect) should be near the card right '
          'edge ($fullCardRect), not stranded mid-row',
    );
    // Sanity: cardRect itself is non-empty (title actually found).
    expect(cardRect.width, greaterThan(0));
  });
}
