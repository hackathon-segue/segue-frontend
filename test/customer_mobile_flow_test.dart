import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:segue_frontend/main.dart';
import 'package:segue_frontend/models/models.dart';
import 'package:segue_frontend/providers/providers.dart';
import 'package:segue_frontend/repositories/mock_segue_repository.dart';
import 'package:segue_frontend/screens/customer_mobile_entry_screen.dart';
import 'package:segue_frontend/utils/app_theme.dart';

void main() {
  testWidgets('customer mobile login opens home and product list', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const SegueApp());

    await tester.tap(find.text('앱으로 계속하기'));
    await tester.pumpAndSettle();

    expect(find.text('앱 홈 화면'), findsOneWidget);
    expect(find.text('MCM 월드'), findsOneWidget);

    await tester.tap(find.text('제품 전체 보기'));
    await tester.pumpAndSettle();

    expect(find.text('제품 목록 화면'), findsOneWidget);
    expect(find.text('Himmel Large Backpack'), findsOneWidget);
  });

  testWidgets('product detail requires a valid color and size SKU', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const SegueApp());
    await tester.tap(find.text('앱으로 계속하기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('제품 전체 보기'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Himmel Large Backpack').first);
    await tester.pumpAndSettle();

    expect(find.text('제품 상세 화면'), findsOneWidget);
    expect(find.text('컬러 선택'), findsOneWidget);
    expect(find.text('사이즈 선택'), findsOneWidget);

    final Finder cartButton = find.ancestor(
      of: find.text('장바구니 담기', skipOffstage: false),
      matching: find.byType(FilledButton, skipOffstage: false),
    );
    FilledButton button = tester.widget<FilledButton>(cartButton);
    expect(button.onPressed, isNull);

    await tester.ensureVisible(find.text('라지'));
    await tester.tap(find.text('라지'));
    await tester.pumpAndSettle();

    button = tester.widget<FilledButton>(cartButton);
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
    await tester.tap(find.text('앱으로 계속하기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('제품 전체 보기'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Himmel Large Backpack').first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('라지'));
    await tester.tap(find.text('라지'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('장바구니 담기'));
    await tester.pumpAndSettle();

    expect(find.text('장바구니 추가 완료'), findsOneWidget);
    expect(find.text('장바구니에 추가되었습니다'), findsOneWidget);
    expect(find.text('선택 컬러 코냑'), findsOneWidget);
    expect(find.text('선택 사이즈 라지'), findsOneWidget);

    await tester.tap(find.text('장바구니 보기'));
    await tester.pumpAndSettle();

    expect(find.text('앱 장바구니 목록'), findsOneWidget);
    expect(find.text('최근 담은 순서'), findsOneWidget);
    expect(find.text('코냑 · 라지'), findsOneWidget);
    expect(find.text('2026. 08. 16 추가'), findsOneWidget);
  });

  testWidgets('consultation result opens online and store visit guidance', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const SegueApp());
    await tester.tap(find.text('앱으로 계속하기'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('상담 결과').last);
    await tester.pumpAndSettle();

    expect(find.text('앱 상담 결과 확인'), findsOneWidget);
    expect(find.text('MCM 백팩 미디움'), findsOneWidget);
    expect(find.text('정확한 제품 확인'), findsOneWidget);
    expect(find.text('온라인 구매하기'), findsOneWidget);

    await tester.tap(find.text('온라인 구매하기'));
    await tester.pumpAndSettle();

    expect(find.text('온라인 구매 화면'), findsOneWidget);
    expect(find.text('온라인 구매 안내'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('온라인 스토어에서 구매하기'),
      120,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('온라인 스토어에서 구매하기'), findsOneWidget);

    await tester.tap(find.byTooltip('뒤로'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('매장 재방문 안내 보기'),
      80,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.drag(find.byType(ListView).last, const Offset(0, -180));
    await tester.pumpAndSettle();
    await tester.tap(find.text('매장 재방문 안내 보기'));
    await tester.pumpAndSettle();

    expect(find.text('매장 재방문 안내'), findsWidgets);
    expect(find.text('방문 전 준비 사항'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('요청 접수 안내'),
      120,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('요청 접수 안내'), findsOneWidget);
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

    await tester.tap(find.text('앱으로 계속하기'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('상담 결과').last);
    await tester.pumpAndSettle();

    expect(find.text('앱 상담 결과 확인'), findsOneWidget);
    expect(
      find.textContaining('실행이 어렵습니다. 타 매장 보유가 확인되지 않았습니다.'),
      findsWidgets,
    );
    expect(find.text('처리 갱신'), findsOneWidget);
  });
}
