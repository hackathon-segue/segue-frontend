import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:segue_frontend/main.dart';
import 'package:segue_frontend/repositories/mock_segue_repository.dart';
import 'package:segue_frontend/utils/app_config.dart';

/// API.md: 고객 조회는 `GET /api/customers/lookup?phoneNumber=` 하나뿐이고
/// 회원번호로 조회하는 API는 없다. 예전 검증 로직은 회원번호 필드만 채워도
/// 통과시켜, 실제로는 빈 전화번호로 조회를 시도해 항상 "조회 결과가
/// 없습니다"로 실패했다 — 원인을 알 수 없는 "회원번호로 조회가 안 되는
/// 문제"로 보였다. 전화번호를 항상 필수로 만들어 명확한 안내로 바꾼다.
void main() {
  Future<void> reachCustomerLookupScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(SegueApp(repository: MockSegueRepository()));
    Navigator.of(
      tester.element(
        find.byKey(const ValueKey<String>('customer-mobile-start-logo')),
      ),
    ).pushNamed(AppRoutes.customerLookup);
    await tester.pumpAndSettle();
  }

  testWidgets('회원번호만 입력하고 전화번호를 비운 채 조회하면 명확한 검증 에러가 뜨고 조회를 시도하지 않는다', (
    WidgetTester tester,
  ) async {
    await reachCustomerLookupScreen(tester);

    final Finder fields = find.byType(TextFormField);
    expect(fields, findsNWidgets(2));
    // Column order: 회원번호 (index 0), 전화번호 (index 1).
    await tester.enterText(fields.at(0), '12345');
    await tester.pump();

    await tester.tap(find.text('고객 조회'));
    await tester.pump();

    expect(find.text('휴대전화 번호를 입력해 주세요.'), findsOneWidget);
    // Never reached a lookup result/error state — the request was never
    // sent because the form failed to validate.
    expect(find.text('조회 결과가 없습니다'), findsNothing);
    expect(find.text('고객 정보를 조회하고 있습니다'), findsNothing);
  });

  testWidgets('전화번호를 올바르게 입력하면 회원번호 입력 여부와 무관하게 조회된다', (
    WidgetTester tester,
  ) async {
    await reachCustomerLookupScreen(tester);

    final Finder fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '12345');
    await tester.enterText(fields.at(1), '010-1234-5678');
    await tester.pump();

    await tester.tap(find.text('고객 조회'));
    await tester.pumpAndSettle();

    expect(find.text('휴대전화 번호를 입력해 주세요.'), findsNothing);
    expect(find.text('김세계'), findsOneWidget);
  });
}
