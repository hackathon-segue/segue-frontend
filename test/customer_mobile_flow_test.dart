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

  testWidgets('product detail requires a valid color and size SKU', (
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

    expect(find.text('제품 상세 화면'), findsOneWidget);
    expect(find.text('컬러 선택'), findsOneWidget);
    expect(find.text('사이즈 선택'), findsOneWidget);

    final Finder cartButton = find.ancestor(
      of: find.text('장바구니 담기', skipOffstage: false),
      matching: find.byType(FilledButton, skipOffstage: false),
    );
    FilledButton button = tester.widget<FilledButton>(cartButton);
    expect(button.onPressed, isNull);

    await tester.ensureVisible(find.text('스몰'));
    await tester.tap(find.text('스몰'));
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

    await tester.pumpWidget(SegueApp(repository: MockSegueRepository()));
    await _openNewProducts(tester);

    await tester.tap(find.text('Diamond 3D 카프스킨 숄더백').first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('스몰'));
    await tester.tap(find.text('스몰'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('장바구니 담기'));
    await tester.pumpAndSettle();

    expect(find.text('장바구니 추가 완료'), findsOneWidget);
    expect(find.text('장바구니에 추가되었습니다'), findsOneWidget);
    expect(find.text('선택 컬러 오렌지'), findsOneWidget);
    expect(find.text('선택 사이즈 스몰'), findsOneWidget);

    await tester.tap(find.text('장바구니 보기'));
    await tester.pumpAndSettle();

    expect(find.text('앱 장바구니 목록'), findsOneWidget);
    expect(find.text('최근 담은 순서'), findsOneWidget);
    expect(find.text('오렌지 · 스몰'), findsOneWidget);
    expect(find.text('2026. 08. 16 추가'), findsWidgets);
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
    await tester.ensureVisible(find.text('스몰'));
    await tester.tap(find.text('스몰'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('장바구니 담기'));
    await tester.pumpAndSettle();

    expect(repository.lastSaveRequest?.customerId, 1);
    expect(repository.lastSaveRequest?.productId, 6);
    expect(repository.lastSaveRequest?.color, '오렌지');
    expect(repository.lastSaveRequest?.size, '스몰');
    expect(repository.lastSaveRequest?.toJson(), isNot(contains('skuId')));

    await tester.tap(find.text('장바구니 보기'));
    await tester.pumpAndSettle();

    expect(repository.lastFetchCustomerId, 1);
    expect(repository.lastFetchStoreId, 1);
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

  testWidgets('consultation result opens online and store visit guidance', (
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
    expect(find.text('앱 상담 결과 확인'), findsOneWidget);
    expect(find.text('최신 서버 결과'), findsOneWidget);
    expect(find.text('서버 저장 경로'), findsOneWidget);

    await tester.tap(find.text('온라인 구매하기').first);
    await tester.pumpAndSettle();

    expect(find.text('온라인 구매 화면'), findsOneWidget);
    expect(find.text('최신 서버 결과'), findsOneWidget);
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

    expect(find.text('앱 상담 결과 확인'), findsOneWidget);
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
