import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:segue_frontend/main.dart';
import 'package:segue_frontend/repositories/mock_segue_repository.dart';
import 'package:segue_frontend/utils/app_config.dart';
import 'package:segue_frontend/widgets/segue_card_shell.dart';

/// "진행 중인 상담 없음" popup (Figma 500:3902) — CURRENT SESSION's sidebar row
/// shows this instead of navigating when there's no active consultation.
void main() {
  const String popupTitle = '현재 진행 중인 상담이 없습니다.';

  Future<void> reachStaffHome(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(SegueApp(repository: MockSegueRepository()));
    Navigator.of(
      tester.element(find.text('LXXVI')),
    ).pushNamed(AppRoutes.staffHome);
    await tester.pumpAndSettle();
  }

  Future<void> lookupAndConsent(WidgetTester tester) async {
    await tester.tap(find.text('START SEGUE'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(1), '010-1234-5678');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    await tester.tap(
      find.descendant(of: find.byType(Form), matching: find.text('고객 조회')),
    );
    await tester.pumpAndSettle();

    final Finder cartButton = find.text('쇼핑백 확인');
    await tester.ensureVisible(cartButton);
    await tester.tap(cartButton);
    await tester.pumpAndSettle();
  }

  Future<void> completeLastIntentSession(WidgetTester tester) async {
    final Finder lastIntentButtons = find.widgetWithText(
      SegueLargeButton,
      'Last Intent 시작',
    );
    final List<SegueLargeButton> buttons = tester
        .widgetList<SegueLargeButton>(lastIntentButtons)
        .toList();
    final int enabledIndex = buttons.indexWhere(
      (SegueLargeButton button) => button.onPressed != null,
    );
    expect(enabledIndex, greaterThanOrEqualTo(0));
    await tester.ensureVisible(lastIntentButtons.at(enabledIndex));
    await tester.tap(lastIntentButtons.at(enabledIndex));
    await tester.pumpAndSettle();
    await tester.tap(find.text('고객 의도 입력 시작'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextField),
      '이 직사각형 형태와 다이아몬드 모양 핸들이 가장 좋아요. 색이나 소재는 달라도 괜찮아요.',
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    await tester.tap(find.text('고객 의도 구조화하기'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('맞아요, 다음 단계로'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('이 제품 확인하기'));
    await tester.pumpAndSettle();

    final Finder detailCta = find.text('해당 제품 상담 완료');
    await tester.ensureVisible(detailCta);
    await tester.tap(detailCta);
    await tester.pumpAndSettle();
  }

  Future<void> completeInStockSession(WidgetTester tester) async {
    await tester.tap(find.text('제품 확인하기'));
    await tester.pumpAndSettle();
    final Finder completeButton = find.text('해당 제품 상담 완료');
    await tester.ensureVisible(completeButton);
    await tester.tap(completeButton);
    await tester.pumpAndSettle();
  }

  testWidgets('조회된 고객이 없을 때 CURRENT SESSION을 누르면 팝업이 뜨고, '
      '"SEGUE 진행하기"를 누르면 고객 조회 페이지로 이동한다', (WidgetTester tester) async {
    await reachStaffHome(tester);

    await tester.tap(find.text('CURRENT SESSION').first);
    await tester.pumpAndSettle();

    expect(find.text(popupTitle), findsOneWidget);
    expect(find.text('SEGUE 진행하기'), findsOneWidget);

    await tester.tap(find.text('SEGUE 진행하기'));
    await tester.pumpAndSettle();

    expect(find.text(popupTitle), findsNothing);
    expect(find.text('CUSTOMER SEARCH'), findsWidgets);
    expect(find.text('고객 검색'), findsOneWidget);
  });

  testWidgets('이미 조회된 고객이 있어도 CURRENT SESSION의 SEGUE 진행하기는 '
      '항상 새 고객 조회부터 시작한다', (WidgetTester tester) async {
    await reachStaffHome(tester);
    await lookupAndConsent(tester);

    // lookupAndConsent lands on the cart (sidebar-less
    // SegueHeaderOnlyShell) — back to a sidebar-bearing screen first.
    Navigator.of(
      tester.element(find.text('쇼핑백 및 재고 확인')),
    ).popUntil(ModalRoute.withName(AppRoutes.staffHome));
    await tester.pumpAndSettle();

    await tester.tap(find.text('CURRENT SESSION').first);
    await tester.pumpAndSettle();
    expect(find.text(popupTitle), findsOneWidget);

    await tester.tap(find.text('SEGUE 진행하기'));
    await tester.pumpAndSettle();

    expect(find.text(popupTitle), findsNothing);
    expect(find.text('CUSTOMER SEARCH'), findsWidgets);
    expect(find.text('고객 검색'), findsOneWidget);
  });

  testWidgets('진행 중인 상담이 모두 완료된 뒤 CURRENT SESSION 팝업의 '
      '"SEGUE 진행하기"를 누르면 고객 조회부터 다시 시작한다', (WidgetTester tester) async {
    await reachStaffHome(tester);
    await lookupAndConsent(tester);
    await completeInStockSession(tester);
    await completeLastIntentSession(tester);
    await completeLastIntentSession(tester);

    expect(find.text('쇼핑백 및 재고 확인'), findsOneWidget);
    // The completed cart remains visible; only the next CURRENT SESSION
    // action starts from a fresh customer lookup.
    expect(find.textContaining('김세계 님의 쇼핑백'), findsOneWidget);

    Navigator.of(
      tester.element(find.textContaining('김세계 님의 쇼핑백')),
    ).pushNamed(AppRoutes.staffHome);
    await tester.pumpAndSettle();

    await tester.tap(find.text('CURRENT SESSION').first);
    await tester.pumpAndSettle();
    expect(find.text(popupTitle), findsOneWidget);

    await tester.tap(find.text('SEGUE 진행하기'));
    await tester.pumpAndSettle();

    expect(find.text(popupTitle), findsNothing);
    expect(find.text('CUSTOMER SEARCH'), findsWidgets);
    expect(find.text('고객 검색'), findsOneWidget);
  });

  testWidgets('X를 누르면 팝업만 닫히고 현재 페이지에 그대로 남는다', (WidgetTester tester) async {
    await reachStaffHome(tester);

    await tester.tap(find.text('CURRENT SESSION').first);
    await tester.pumpAndSettle();
    expect(find.text(popupTitle), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.text(popupTitle), findsNothing);
    expect(find.text('SEGUE HOME'), findsOneWidget);
  });
}
