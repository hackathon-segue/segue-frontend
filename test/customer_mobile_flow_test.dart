import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:segue_frontend/exceptions/app_exception.dart';
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

    await tester.pumpWidget(SegueApp(repository: MockSegueRepository()));

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

    await tester.pumpWidget(SegueApp(repository: MockSegueRepository()));
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

    await tester.pumpWidget(SegueApp(repository: MockSegueRepository()));
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

    expect(find.textContaining('나의 쇼핑백('), findsOneWidget);
    expect(find.text('Diamond 3D 카프스킨 숄더백'), findsOneWidget);
    expect(find.text('예상 합계'), findsWidgets);
  });

  testWidgets('mobile cart save and cart tab use the repository API contract', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final _RecordingMobileRepository repository = _RecordingMobileRepository();

    await tester.pumpWidget(
      RepositoryScope(
        repository: repository,
        child: MaterialApp(
          theme: SegueTheme.light(),
          home: const CustomerMobileEntryScreen(),
        ),
      ),
    );
    await _openNewProducts(tester);

    await tester.tap(find.text('Diamond 3D 카프스킨 숄더백').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('쇼핑백에 추가'));
    await tester.pumpAndSettle();

    expect(repository.lastSaveRequest?.customerId, 1);
    expect(repository.lastSaveRequest?.productId, 6);
    expect(repository.lastSaveRequest?.color, '오렌지');
    expect(repository.lastSaveRequest?.size, '스몰');
    expect(repository.lastSaveRequest?.toJson(), isNot(contains('skuId')));

    await tester.tap(find.text('쇼핑백 확인하기'));
    await tester.pumpAndSettle();

    expect(repository.lastFetchCustomerId, 1);
    expect(repository.lastFetchStoreId, 1);
    expect(find.textContaining('나의 쇼핑백('), findsOneWidget);
    expect(find.text('Diamond 3D 카프스킨 숄더백'), findsOneWidget);
  });

  testWidgets('mobile cart fetch failure can be retried in place', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final _FlakyCartRepository repository = _FlakyCartRepository();

    await tester.pumpWidget(
      RepositoryScope(
        repository: repository,
        child: MaterialApp(
          theme: SegueTheme.light(),
          home: const CustomerMobileEntryScreen(),
        ),
      ),
    );

    await tester.tap(find.byTooltip('메뉴 열기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('쇼핑백'));
    await tester.pumpAndSettle();

    expect(find.text('장바구니를 불러오지 못했습니다'), findsOneWidget);
    expect(find.text('임시 네트워크 오류'), findsOneWidget);

    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();

    expect(repository.fetchAttempts, 2);
    expect(repository.lastFetchCustomerId, 1);
    expect(repository.lastFetchStoreId, 1);
    expect(find.text('MCM 백팩 미디움'), findsOneWidget);
  });

  testWidgets('consultation result list opens the SEGUE result detail', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      SegueApp(repository: MockSegueRepository(seedDemoConsultationResults: true)),
    );
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

  testWidgets('mobile consultation results use the fetched server payload', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final _RecordingResultsRepository repository =
        _RecordingResultsRepository();

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

    expect(repository.lastResultsCustomerId, 1);
    expect(find.text('SEGUE 내역'), findsOneWidget);
    expect(find.text('최신 서버 결과'), findsWidgets);

    await tester.tap(find.text('최신 서버 결과').first);
    await tester.pumpAndSettle();

    expect(find.text('SEGUE 결과'), findsWidgets);
    expect(find.text('최신 서버 결과'), findsWidgets);
    expect(find.text('서버 저장 경로'), findsOneWidget);
    expect(find.text('서버 저장 핵심 조건'), findsOneWidget);
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

    await tester.tap(find.text('MCM 백팩 미디움').first);
    await tester.pumpAndSettle();

    expect(find.text('처리 상태'), findsOneWidget);
    expect(
      find.textContaining('실행이 어렵습니다. 타 매장 보유가 확인되지 않았습니다.'),
      findsWidgets,
    );
    expect(find.text('처리 갱신'), findsOneWidget);
  });
}

class _RecordingMobileRepository extends MockSegueRepository {
  CartSaveRequest? lastSaveRequest;
  int? lastFetchCustomerId;
  int? lastFetchStoreId;

  @override
  Future<CartItem> saveCartItem(CartSaveRequest request) {
    lastSaveRequest = request;
    return super.saveCartItem(request);
  }

  @override
  Future<List<CartItem>> fetchCart({
    required int customerId,
    required int storeId,
  }) {
    lastFetchCustomerId = customerId;
    lastFetchStoreId = storeId;
    return super.fetchCart(customerId: customerId, storeId: storeId);
  }
}

class _FlakyCartRepository extends MockSegueRepository {
  int fetchAttempts = 0;
  int? lastFetchCustomerId;
  int? lastFetchStoreId;

  @override
  Future<List<CartItem>> fetchCart({
    required int customerId,
    required int storeId,
  }) {
    fetchAttempts += 1;
    lastFetchCustomerId = customerId;
    lastFetchStoreId = storeId;
    if (fetchAttempts == 1) {
      throw const ApiException(
        '임시 네트워크 오류',
        statusCode: 0,
        code: 'NETWORK_ERROR',
      );
    }
    return super.fetchCart(customerId: customerId, storeId: storeId);
  }
}

class _RecordingResultsRepository extends MockSegueRepository {
  int? lastResultsCustomerId;

  @override
  Future<List<ConsultationResult>> fetchConsultationResults(
    int customerId,
  ) async {
    lastResultsCustomerId = customerId;
    return <ConsultationResult>[
      ConsultationResult(
        id: 11,
        skuId: 1,
        productName: '이전 서버 결과',
        imageUrl: 'https://example.com/previous.png',
        resultType: DecisionResultType.exactProduct,
        recommendedPath: '이전 저장 경로',
        coreConditions: '이전 핵심 조건',
        consultedAt: DateTime(2026, 8, 16, 12),
        executionStatus: ExecutionStatus.requested,
        executionNote: null,
        executionUpdatedAt: DateTime(2026, 8, 16, 12),
      ),
      ConsultationResult(
        id: 12,
        skuId: 1,
        productName: '최신 서버 결과',
        imageUrl: 'https://example.com/latest.png',
        resultType: DecisionResultType.exactProduct,
        recommendedPath: '서버 저장 경로',
        coreConditions: '서버 저장 핵심 조건',
        consultedAt: DateTime(2026, 8, 16, 15),
        executionStatus: ExecutionStatus.requested,
        executionNote: null,
        executionUpdatedAt: DateTime(2026, 8, 16, 15),
      ),
    ];
  }
}
