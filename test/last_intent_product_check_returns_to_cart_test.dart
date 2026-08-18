import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:segue_frontend/main.dart';
import 'package:segue_frontend/utils/app_config.dart';
import 'package:segue_frontend/widgets/staff_check_row.dart';

/// "해당 제품 상담 완료" (COMPARISON_EXPERIENCE/TODAY_PURCHASE's
/// productCheckRequest CTA) must skip the "요청 접수 완료" hand-off screen and
/// return straight to the cart, with that item's row now showing "요청 접수" —
/// as opposed to the "타 매장 확인 요청 접수" CTA (EXACT_PRODUCT,
/// otherStoreCheckRequest), which still goes to the "요청 접수 완료" screen.
void main() {
  testWidgets(
    '해당 제품 상담 완료 tap executes then returns to the cart with 요청 접수 shown',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const SegueApp());
      Navigator.of(
        tester.element(find.text('앱 로그인 화면')),
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

      final Finder consentButton = find.text('데이터 이용 동의 확인');
      await tester.ensureVisible(consentButton);
      await tester.tap(consentButton);
      await tester.pumpAndSettle();
      final Finder checkRows = find.byType(StaffCheckRow);
      for (int i = 0; i < tester.widgetList(checkRows).length; i++) {
        await tester.tap(checkRows.at(i));
        await tester.pump();
      }
      final Finder agreeButton = find.text('동의하고 장바구니 확인');
      await tester.ensureVisible(agreeButton);
      await tester.tap(agreeButton);
      await tester.pumpAndSettle();
      expect(find.text('장바구니 · 재고 확인'), findsOneWidget);
      expect(find.text('요청 접수'), findsNothing);

      await tester.tap(find.text('Last Intent 시작').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('고객 의도 입력 시작'));
      await tester.pumpAndSettle();

      // Persona 1 keyword (mock_segue_repository.dart) → COMPARISON_EXPERIENCE,
      // whose actionType is productCheckRequest / CTA "해당 제품 상담 완료".
      await tester.enterText(
        find.byType(TextFormField),
        '이 직사각형 형태와 다이아몬드 모양 핸들이 가장 좋아요. 색이나 소재는 달라도 괜찮아요.',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      await tester.tap(find.text('제출'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('맞아요, 다음 단계로'));
      await tester.pumpAndSettle();
      expect(find.text('SEGUE CARD'), findsOneWidget);

      final Finder cardCta = find.text('이 제품 확인하기');
      await tester.ensureVisible(cardCta);
      await tester.tap(cardCta);
      await tester.pumpAndSettle();
      expect(find.text('비교 체험 제품'), findsOneWidget);

      final Finder detailCta = find.text('해당 제품 상담 완료');
      await tester.ensureVisible(detailCta);
      await tester.tap(detailCta);
      await tester.pumpAndSettle();

      // Never shows the "요청 접수 완료" hand-off screen for this actionType.
      expect(find.text('요청 접수 완료'), findsNothing);
      // Lands back on the cart, with this SKU's row now marked request-accepted.
      expect(find.text('장바구니 · 재고 확인'), findsOneWidget);
      expect(find.text('요청 접수'), findsOneWidget);
    },
  );
}
