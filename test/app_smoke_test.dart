import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:segue_frontend/main.dart';

Future<void> _openStaffHome(WidgetTester tester) async {
  await tester.pumpWidget(const SegueApp());
  final Finder staffWebButton = find.widgetWithText(FilledButton, '직원 웹');
  await tester.ensureVisible(staffWebButton);
  await tester.tap(staffWebButton);
  await tester.pumpAndSettle();
}

Future<void> _goToCustomerLookup(WidgetTester tester) async {
  await tester.tap(find.text('고객 조회 시작'));
  await tester.pumpAndSettle();
}

Future<void> _searchCustomer(WidgetTester tester, String phoneNumber) async {
  await tester.enterText(find.byType(TextFormField).at(1), phoneNumber);
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pump();
  // '고객 조회' also labels the sidebar nav link and the page title, so
  // scope the tap to the search Form, which only contains the button.
  await tester.tap(find.descendant(of: find.byType(Form), matching: find.text('고객 조회')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders the initial customer mobile route', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SegueApp());

    expect(find.text('고객 모바일'), findsOneWidget);
    expect(find.text('MCM Last Intent'), findsOneWidget);
  });

  testWidgets('opens the staff route group directly at the home screen (no login gate)', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _openStaffHome(tester);

    expect(find.text('MCM 상담 지원'), findsOneWidget);
    expect(find.text('고객 조회 시작'), findsOneWidget);
  });

  testWidgets(
    'looking up a consented customer shows the cart preview',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _openStaffHome(tester);

      expect(find.text('MCM 상담 지원'), findsOneWidget);
      expect(find.text('고객 조회 시작'), findsOneWidget);

      await _goToCustomerLookup(tester);
      await _searchCustomer(tester, '010-1234-5678');

      expect(find.text('김세계'), findsOneWidget);
      // Already-consented test customer: cart preview should auto-load.
      expect(find.text('MCM 백팩 미디움'), findsOneWidget);
      expect(find.text('MCM 숄더백 미니'), findsOneWidget);
    },
  );

  testWidgets(
    'declining consent for an unconsented customer reaches the declined screen',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _openStaffHome(tester);
      await _goToCustomerLookup(tester);
      await _searchCustomer(tester, '010-9876-5432');

      expect(find.text('이수현'), findsOneWidget);
      expect(find.text('데이터 이용 동의가 필요합니다'), findsOneWidget);

      await tester.tap(find.text('데이터 이용 동의 확인'));
      await tester.pumpAndSettle();

      expect(find.text('상담 데이터 이용 동의'), findsOneWidget);

      await tester.tap(find.text('동의하지 않음'));
      await tester.pumpAndSettle();

      expect(find.text('데이터 이용 동의 거부됨'), findsOneWidget);
    },
  );

  testWidgets('switching to a new customer lookup resets prior cart state', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _openStaffHome(tester);
    await _goToCustomerLookup(tester);
    await _searchCustomer(tester, '010-1234-5678');
    expect(find.text('MCM 백팩 미디움'), findsOneWidget);

    await _searchCustomer(tester, '010-9876-5432');

    expect(find.text('이수현'), findsOneWidget);
    // The previous customer's already-loaded cart items must not leak into
    // the new, unconsented customer's view.
    expect(find.text('MCM 백팩 미디움'), findsNothing);
    expect(find.text('데이터 이용 동의가 필요합니다'), findsOneWidget);
  });
}
