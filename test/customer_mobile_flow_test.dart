import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:segue_frontend/main.dart';
import 'package:segue_frontend/models/models.dart';
import 'package:segue_frontend/providers/providers.dart';
import 'package:segue_frontend/repositories/mock_segue_repository.dart';
import 'package:segue_frontend/screens/customer_mobile_entry_screen.dart';
import 'package:segue_frontend/utils/app_theme.dart';

Future<void> _openNewProducts(WidgetTester tester) async {
  await tester.tap(find.byTooltip('메뉴 열기'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('신상품').last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('customer mobile start opens menu and product list', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const SegueApp());

    expect(find.text('LXXVI'), findsOneWidget);

    await tester.tap(find.byTooltip('메뉴 열기'));
    await tester.pumpAndSettle();

    expect(find.text('쇼핑백'), findsOneWidget);
    expect(find.text('토트백 & 쇼퍼백'), findsWidgets);

    await tester.tap(find.text('모두보기'));
    await tester.pumpAndSettle();

    expect(find.text('AUTUMN WINTER 2026'), findsOneWidget);
    expect(find.text('Diamond 3D 카프스킨 숄더백'), findsOneWidget);
  });

  testWidgets('product detail shows the new shopping bag CTA', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const SegueApp());
    await _openNewProducts(tester);

    await tester.tap(find.text('Diamond 3D 카프스킨 숄더백').first);
    await tester.pumpAndSettle();

    expect(find.text('신규 컬렉션'), findsOneWidget);
    expect(find.text('색상: 오렌지'), findsOneWidget);
    expect(find.text('사이즈: 스몰'), findsOneWidget);

    final Finder cartButton = find.ancestor(
      of: find.text('쇼핑백에 추가', skipOffstage: false),
      matching: find.byType(FilledButton, skipOffstage: false),
    );
    final FilledButton button = tester.widget<FilledButton>(cartButton);
    expect(button.onPressed, isNotNull);
  });

  testWidgets('selected SKU is saved and shown in the mobile cart', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const SegueApp());
    await _openNewProducts(tester);

    await tester.tap(find.text('Diamond 3D 카프스킨 숄더백').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('쇼핑백에 추가'));
    await tester.pumpAndSettle();

    expect(find.text('새로운 상품이 쇼핑백에 추가되었습니다!'), findsOneWidget);
    expect(find.text('(1개 품목)'), findsOneWidget);
    expect(find.text('오렌지'), findsOneWidget);
    expect(find.text('스몰'), findsOneWidget);

    await tester.tap(find.text('쇼핑백 확인하기'));
    await tester.pumpAndSettle();

    expect(find.text('나의 쇼핑백(1개 품목)'), findsOneWidget);
    expect(find.text('Diamond 3D 카프스킨 숄더백'), findsOneWidget);
    expect(find.text('예상 합계'), findsWidgets);
  });

  testWidgets('consultation result list opens the SEGUE result detail', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const SegueApp());
    await tester.tap(find.byTooltip('SEGUE 내역 확인'));
    await tester.pumpAndSettle();

    expect(find.text('SEGUE 내역'), findsOneWidget);
    expect(find.text('MCM 백팩 미디움'), findsOneWidget);
    expect(find.textContaining('총 '), findsOneWidget);

    await tester.tap(find.text('MCM 백팩 미디움').first);
    await tester.pumpAndSettle();

    expect(find.text('SEGUE 결과'), findsWidgets);
    expect(find.text('핵심 조건'), findsOneWidget);
    expect(find.text('추천 경로'), findsOneWidget);
    expect(find.text('상담 완료'), findsOneWidget);
  });

  testWidgets('consultation results show updated execution status on mobile', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final MockSegueRepository repository = MockSegueRepository(
      seedDemoConsultationResults: true,
    );
    await repository.updateExecutionStatus(
      consultationResultId: 5,
      request: const ExecutionStatusUpdateRequest(
        status: ExecutionStatus.unable,
        note: '타 매장 보유가 확인되지 않았습니다.',
      ),
    );

    await tester.pumpWidget(
      RepositoryScope(
        repository: repository,
        child: MaterialApp(
          theme: SegueTheme.light(),
          home: const CustomerMobileEntryScreen(),
        ),
      ),
    );

    await tester.tap(find.byTooltip('SEGUE 내역 확인'));
    await tester.pumpAndSettle();

    expect(find.text('SEGUE 내역'), findsOneWidget);
    expect(find.text('MCM 백팩 미디움'), findsOneWidget);
  });
}
