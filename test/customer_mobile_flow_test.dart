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

Future<void> _loginMobileCustomer(WidgetTester tester) async {
  await tester.tap(find.byTooltip('메뉴 열기'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('로그인'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('로그인').last);
  await tester.pumpAndSettle();
}

Future<void> _openSegueHistoryFromMenu(WidgetTester tester) async {
  await tester.tap(find.byTooltip('메뉴 열기'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('SEGUE 내역 확인').last);
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

  testWidgets('customer mobile menu opens the login screen', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(SegueApp(repository: MockSegueRepository()));

    await tester.tap(find.byTooltip('메뉴 열기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('로그인'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('로그인 닫기'), findsOneWidget);
    expect(find.text('회원으로 가입하시면 빠르고 편리하게 이용하실 수 있습니다.'), findsOneWidget);
    expect(find.text('이메일 주소*'), findsOneWidget);
    expect(find.text('비밀번호*'), findsOneWidget);
    expect(find.text('계정이 없으신가요? 회원가입하기'), findsOneWidget);
  });

  testWidgets('menu login row changes to my account after login', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(SegueApp(repository: MockSegueRepository()));

    await tester.tap(find.byTooltip('메뉴 열기'));
    await tester.pumpAndSettle();
    expect(find.text('로그인'), findsOneWidget);

    await tester.tap(find.text('로그인'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('로그인').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('메뉴 열기'));
    await tester.pumpAndSettle();

    expect(find.text('내 계정'), findsOneWidget);
    expect(find.text('로그인'), findsNothing);

    await tester.tap(find.text('내 계정'));
    await tester.pumpAndSettle();

    expect(find.text('계정 상세정보'), findsOneWidget);
    expect(find.text('1234@1234.com'), findsOneWidget);
  });

  testWidgets('top profile icon opens my account from product detail', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(SegueApp(repository: MockSegueRepository()));
    await _loginMobileCustomer(tester);
    await _openNewProducts(tester);

    await tester.tap(find.text('Diamond 3D 카프스킨 숄더백').first);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('내 계정'));
    await tester.pumpAndSettle();

    expect(find.text('내 계정'), findsOneWidget);
    expect(find.text('계정 상세정보'), findsOneWidget);
  });

  testWidgets('shopping bag requires login before opening', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(SegueApp(repository: MockSegueRepository()));

    await tester.tap(find.byTooltip('메뉴 열기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('쇼핑백'));
    await tester.pumpAndSettle();

    expect(find.text('해당 기능은 로그인 이후에 가능합니다.'), findsOneWidget);
    expect(find.text('회원가입!'), findsOneWidget);
    expect(find.text('로그인'), findsWidgets);
    expect(
      tester
          .getSize(
            find.byKey(const ValueKey<String>('login-required-dialog-panel')),
          )
          .width,
      lessThanOrEqualTo(390 - 44),
    );

    await tester.tap(find.text('로그인').last);
    await tester.pumpAndSettle();

    expect(find.byTooltip('로그인 닫기'), findsOneWidget);
  });

  testWidgets('SEGUE history requires login before opening', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      SegueApp(
        repository: MockSegueRepository(seedDemoConsultationResults: true),
      ),
    );

    await tester.tap(find.byTooltip('메뉴 열기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('SEGUE 내역 확인'));
    await tester.pumpAndSettle();

    expect(find.text('해당 기능은 로그인 이후에 가능합니다.'), findsOneWidget);
    expect(find.text('SEGUE 내역'), findsNothing);

    await tester.tap(find.byTooltip('팝업 닫기'));
    await tester.pumpAndSettle();

    expect(find.text('해당 기능은 로그인 이후에 가능합니다.'), findsNothing);
  });

  testWidgets('customer mobile new-season menu item opens product list', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(SegueApp(repository: MockSegueRepository()));

    await tester.tap(find.byTooltip('메뉴 열기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('신상품').first);
    await tester.pumpAndSettle();

    expect(find.text('AUTUMN WINTER 2026'), findsOneWidget);
    final Text seasonMenuItem = tester.widget<Text>(
      find.text('AUTUMN WINTER 2026'),
    );
    expect(seasonMenuItem.style?.fontFamily, 'Montserrat');

    await tester.tap(find.text('AUTUMN WINTER 2026'));
    await tester.pumpAndSettle();

    expect(find.text('Diamond 3D 카프스킨 숄더백'), findsOneWidget);
  });

  testWidgets('product category selector stays fixed while list scrolls', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(SegueApp(repository: MockSegueRepository()));
    await _openNewProducts(tester);

    final Finder categoryTrail = find.byKey(
      const ValueKey<String>('mobile-product-category-trail'),
    );
    final Finder scrollBody = find.byKey(
      const ValueKey<String>('mobile-product-scroll-body'),
    );

    final double beforeTop = tester.getTopLeft(categoryTrail).dy;

    await tester.drag(scrollBody, const Offset(0, -420));
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(categoryTrail).dy, beforeTop);
  });

  testWidgets(
    'backend products without season metadata appear in new products',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        SegueApp(repository: _BackendStyleProductRepository()),
      );

      await _openNewProducts(tester);

      expect(find.text('M Diamond 비세토스 레더 믹스'), findsOneWidget);
    },
  );

  testWidgets('backend handbag category appears in top-handle products', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      SegueApp(repository: _BackendStyleProductRepository()),
    );

    await tester.tap(find.byTooltip('메뉴 열기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('탑 핸들백').last);
    await tester.pumpAndSettle();

    expect(find.text('M Diamond 비세토스 레더 믹스'), findsOneWidget);
  });

  testWidgets('product detail shows the new shopping bag CTA', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(SegueApp(repository: MockSegueRepository()));
    await _loginMobileCustomer(tester);
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
    await _loginMobileCustomer(tester);
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

  testWidgets('mobile detail only allows existing color and size SKU pairs', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final _NonCartesianProductRepository repository =
        _NonCartesianProductRepository();

    await tester.pumpWidget(
      RepositoryScope(
        repository: repository,
        child: MaterialApp(
          theme: SegueTheme.light(),
          home: const CustomerMobileEntryScreen(),
        ),
      ),
    );
    await _loginMobileCustomer(tester);
    await _openNewProducts(tester);

    await tester.tap(find.text('조합 제한 토트').first);
    await tester.pumpAndSettle();

    expect(find.text('색상: 코냑'), findsOneWidget);
    expect(find.text('사이즈: 미디움'), findsOneWidget);
    expect(find.text('소재 및 상세 정보'), findsOneWidget);
    expect(find.text('비세토스 캔버스'), findsOneWidget);
    expect(find.text('내부 포켓 2개'), findsOneWidget);
    expect(find.text('토트'), findsOneWidget);
    expect(find.text('620g'), findsOneWidget);
    expect(find.text('수납 불가'), findsOneWidget);
    expect(find.text('라지'), findsNothing);

    await tester.tap(find.text('블랙'));
    await tester.pumpAndSettle();

    expect(find.text('색상: 블랙'), findsOneWidget);
    expect(find.text('사이즈: 라지'), findsOneWidget);
    expect(find.text('미디움'), findsNothing);

    await tester.tap(find.text('쇼핑백에 추가'));
    await tester.pumpAndSettle();

    expect(repository.lastSaveRequest?.productId, 99);
    expect(repository.lastSaveRequest?.color, '블랙');
    expect(repository.lastSaveRequest?.size, '라지');
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
    await _loginMobileCustomer(tester);
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
    await _loginMobileCustomer(tester);

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
      SegueApp(
        repository: MockSegueRepository(seedDemoConsultationResults: true),
      ),
    );
    await _loginMobileCustomer(tester);
    await _openSegueHistoryFromMenu(tester);

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
    await _loginMobileCustomer(tester);

    await _openSegueHistoryFromMenu(tester);

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
    await _loginMobileCustomer(tester);

    await _openSegueHistoryFromMenu(tester);

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

class _BackendStyleProductRepository extends MockSegueRepository {
  @override
  Future<List<MobileProduct>> fetchMobileProducts() async {
    return const <MobileProduct>[
      MobileProduct(
        id: 1,
        name: 'M Diamond 비세토스 레더 믹스',
        collection: '',
        category: '핸드백',
        price: 1590000,
        material: '비세토스 모노그램 캔버스 + 나파 송아지 가죽 트림',
        dimensions: '',
        origin: '',
        season: '',
        visualValue: 0xFFB87945,
        accentValue: 0xFF111827,
        options: <MobileSkuOption>[
          MobileSkuOption(
            skuId: 1,
            color: '꼬냑',
            size: 'M',
            swatchValue: 0xFFB87945,
            material: '비세토스 모노그램 캔버스 + 나파 송아지 가죽 트림',
            weightGrams: 480,
            storageStructure: '지퍼 클로저 + 내부 포켓',
            wearStyle: '핸드백/크로스바디 겸용',
            laptopCompatible: false,
          ),
        ],
      ),
    ];
  }
}

class _NonCartesianProductRepository extends MockSegueRepository {
  CartSaveRequest? lastSaveRequest;

  @override
  Future<List<MobileProduct>> fetchMobileProducts() async {
    return const <MobileProduct>[
      MobileProduct(
        id: 99,
        name: '조합 제한 토트',
        collection: '신상품',
        category: '가방',
        price: 1090000,
        material: '비세토스 캔버스',
        dimensions: 'W 35 x H 29 x D 14 cm',
        origin: 'Made in Korea',
        season: '2026 AW',
        visualValue: 0xFFB87945,
        accentValue: 0xFF111827,
        options: <MobileSkuOption>[
          MobileSkuOption(
            skuId: 991,
            color: '코냑',
            size: '미디움',
            swatchValue: 0xFFB87945,
            material: '비세토스 캔버스',
            weightGrams: 620,
            storageStructure: '내부 포켓 2개',
            wearStyle: '토트',
            laptopCompatible: false,
            sizeGrade: '미디움',
          ),
          MobileSkuOption(
            skuId: 992,
            color: '블랙',
            size: '라지',
            swatchValue: 0xFF111827,
          ),
        ],
      ),
    ];
  }

  @override
  Future<CartItem> saveCartItem(CartSaveRequest request) async {
    lastSaveRequest = request;
    return CartItem.fromJson(<String, Object?>{
      'cartItemId': 99,
      'productId': request.productId,
      'productName': '조합 제한 토트',
      'imageUrl': '/images/products/non-cartesian.png',
      'category': '가방',
      'skuId': request.color == '블랙' ? 992 : 991,
      'color': request.color,
      'size': request.size,
      'currentStoreInStock': false,
      'otherStoreInStock': false,
      'restockPlanned': false,
      'actionButtonLabel': 'Last Intent 시작',
      'savedAt': DateTime(2026, 8, 19, 12).toIso8601String(),
    });
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
