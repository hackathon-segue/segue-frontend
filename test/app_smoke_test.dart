import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:segue_frontend/main.dart';
import 'package:segue_frontend/repositories/mock_segue_repository.dart';
import 'package:segue_frontend/utils/app_config.dart';

Future<void> _openStaffHome(WidgetTester tester) async {
  await tester.pumpWidget(SegueApp(repository: MockSegueRepository()));
  // The mobile customer entry screen no longer has a "직원 웹" button (it's
  // now the real customer-facing app) — reach staff routes via a direct
  // named push instead, same as the app's own wireframe QA does.
  Navigator.of(
    tester.element(
      find.byKey(const ValueKey<String>('customer-mobile-start-logo')),
    ),
  ).pushNamed(AppRoutes.staffHome);
  await tester.pumpAndSettle();
}

Future<void> _goToCustomerLookup(WidgetTester tester) async {
  await tester.tap(find.text('START SEGUE'));
  await tester.pumpAndSettle();
}

Future<void> _searchCustomer(WidgetTester tester, String phoneNumber) async {
  await tester.enterText(find.byType(TextFormField).at(1), phoneNumber);
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pump();
  // '고객 조회' also labels the sidebar nav link and the page title, so
  // scope the tap to the search Form, which only contains the button.
  await tester.tap(
    find.descendant(of: find.byType(Form), matching: find.text('고객 조회')),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders the initial customer mobile route', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(SegueApp(repository: MockSegueRepository()));

    // Root now lands on the real customer-facing mobile app (not the old
    // route-group placeholder screen).
    expect(
      find.byKey(const ValueKey<String>('customer-mobile-start-logo')),
      findsOneWidget,
    );
  });

  testWidgets(
    'opens the staff route group directly at the home screen (no login gate)',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _openStaffHome(tester);

      expect(find.text('SEGUE HOME'), findsOneWidget);
      expect(find.text('START SEGUE'), findsOneWidget);
    },
  );

  testWidgets(
    'looking up a consented customer shows the result card and cart CTA',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _openStaffHome(tester);

      expect(find.text('SEGUE HOME'), findsOneWidget);
      expect(find.text('START SEGUE'), findsOneWidget);

      await _goToCustomerLookup(tester);
      await _searchCustomer(tester, '010-1234-5678');

      // Issue #48 (89:1001): the result card itself has no cart-preview
      // list — that now lives only on CartInventoryScreen — but the
      // customer identity and next CTA are still real, live-looked-up
      // data/state, not fabricated.
      expect(find.text('김세계'), findsOneWidget);
      expect(find.text('쇼핑백 확인'), findsOneWidget);
    },
  );

  testWidgets('customer lookup input fields match the Figma field sizing', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _openStaffHome(tester);
    await _goToCustomerLookup(tester);

    final Rect memberField = tester.getRect(find.byType(TextFormField).at(0));
    final Rect phoneField = tester.getRect(find.byType(TextFormField).at(1));

    expect(memberField.width, 335);
    expect(memberField.height, 42);
    expect(phoneField.width, 335);
    expect(phoneField.height, 42);
    expect(phoneField.top - memberField.bottom, 16);
  });

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

      await tester.tap(find.text('상담 데이터 이용 동의 확인'));
      await tester.pumpAndSettle();

      expect(find.text('상담 데이터 이용 동의'), findsOneWidget);

      await tester.tap(find.text('동의하지 않음'));
      await tester.pumpAndSettle();

      expect(find.text('데이터 이용 동의 거부됨'), findsOneWidget);
    },
  );

  testWidgets(
    'switching to a new customer lookup shows the new customer, not the old one',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _openStaffHome(tester);
      await _goToCustomerLookup(tester);
      await _searchCustomer(tester, '010-1234-5678');
      expect(find.text('김세계'), findsOneWidget);

      await _searchCustomer(tester, '010-9876-5432');

      // StaffWebSessionController.lookupCustomer() resets prior state before
      // looking up the new customer — the previous customer's card must not
      // linger once the new one is found.
      expect(find.text('이수현'), findsOneWidget);
      expect(find.text('김세계'), findsNothing);
    },
  );
}
