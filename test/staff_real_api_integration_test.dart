import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:segue_frontend/exceptions/app_exception.dart';
import 'package:segue_frontend/models/models.dart';
import 'package:segue_frontend/providers/providers.dart';
import 'package:segue_frontend/repositories/repositories.dart';
import 'package:segue_frontend/screens/cart_inventory_screen.dart';
import 'package:segue_frontend/screens/consent_declined_screen.dart';
import 'package:segue_frontend/screens/consent_screen.dart';
import 'package:segue_frontend/screens/customer_lookup_screen.dart';
import 'package:segue_frontend/utils/app_config.dart';
import 'package:segue_frontend/utils/app_theme.dart';
import 'package:segue_frontend/widgets/segue_card_shell.dart';

void main() {
  test(
    'staff session fetches cart for the selected store and sorts by savedAt',
    () async {
      final _RecordingStaffRepository repository = _RecordingStaffRepository();
      final StaffWebSessionController controller = StaffWebSessionController(
        repository: repository,
      );
      addTearDown(controller.dispose);

      controller.setStoreId(7);
      await controller.lookupCustomer('010-1234-5678');
      await controller.loadCart();

      expect(repository.lastFetchCustomerId, 1);
      expect(repository.lastFetchStoreId, 7);
      expect(
        controller.state.cartItems.map((CartItem item) => item.skuId),
        <int>[22, 21],
      );
      expect(controller.state.cartItems.first.productId, 1);
      expect(controller.state.cartItems.last.productId, 1);
      expect(
        controller.state.cartItems.first.inventory.currentStoreInStock,
        isTrue,
      );
      expect(
        controller.state.cartItems.last.inventory.currentStoreInStock,
        isFalse,
      );
    },
  );

  testWidgets('staff customer lookup communication failure can be retried', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final _FlakyLookupRepository repository = _FlakyLookupRepository();
    await _pumpStaffLookup(tester, repository);

    await _lookupPhone(tester, '010-1234-5678');

    expect(find.text('고객 조회에 실패했습니다'), findsOneWidget);
    expect(find.text('임시 통신 실패'), findsOneWidget);
    expect(find.text('다시 시도'), findsOneWidget);

    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();

    expect(repository.lookupAttempts, 2);
    expect(find.text('김세계'), findsOneWidget);
  });

  testWidgets('staff cart 403 guides CA to consent and retries the cart API', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final _ConsentRequiredCartRepository repository =
        _ConsentRequiredCartRepository();
    await _pumpStaffLookup(tester, repository);

    await _lookupPhone(tester, '010-1234-5678');

    // Lookup says the customer has already consented, so the CTA opens the
    // cart directly. The backend can still reject the cart with 403 if that
    // consent is stale/revoked server-side.
    final Finder cartButton = find.text('쇼핑백 확인');
    await tester.ensureVisible(cartButton);
    await tester.tap(cartButton);
    await tester.pumpAndSettle();

    final Finder consentRedirectButton = find.text('동의 화면으로 이동');
    await tester.ensureVisible(consentRedirectButton);
    await tester.tap(consentRedirectButton);
    await tester.pumpAndSettle();

    for (int i = 0; i < 3; i++) {
      await tester.tap(find.byType(SegueCheckboxRow).at(i));
      await tester.pump();
    }

    final Finder agreeButton = find.text('동의하고 쇼핑백 확인');
    await tester.ensureVisible(agreeButton);
    await tester.tap(agreeButton);
    await tester.pumpAndSettle();

    // submitConsent() resets cartState to idle on success, and the
    // (still-mounted-underneath) lookup screen's own postFrameCallback
    // re-triggers loadCart() — this time consentSubmitted is true, so the
    // retried fetch succeeds without any explicit "재시도" action needed.
    expect(repository.fetchAttempts, 2);
    expect(repository.lastFetchCustomerId, 1);
    expect(repository.lastFetchStoreId, 1);
    expect(find.text('MCM 백팩 미디움'), findsOneWidget);
  });
}

Future<void> _pumpStaffLookup(
  WidgetTester tester,
  SegueRepository repository,
) async {
  final StaffWebSessionController controller = StaffWebSessionController(
    repository: repository,
  );
  final LastIntentSessionManager manager = LastIntentSessionManager(
    repository: repository,
  );
  addTearDown(controller.dispose);
  addTearDown(manager.dispose);

  await tester.pumpWidget(
    RepositoryScope(
      repository: repository,
      child: StaffSessionScope(
        controller: controller,
        child: LastIntentSessionScope(
          manager: manager,
          child: MaterialApp(
            theme: SegueTheme.light(),
            routes: <String, WidgetBuilder>{
              AppRoutes.customerConsent: (_) => const ConsentScreen(),
              AppRoutes.customerConsentDeclined: (_) =>
                  const ConsentDeclinedScreen(),
              AppRoutes.cartInventory: (_) => const CartInventoryScreen(),
            },
            home: const CustomerLookupScreen(),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _lookupPhone(WidgetTester tester, String phoneNumber) async {
  await tester.enterText(find.byType(TextFormField).at(1), phoneNumber);
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pump();
  await tester.tap(
    find.descendant(of: find.byType(Form), matching: find.text('고객 조회')),
  );
  await tester.pumpAndSettle();
}

class _RecordingStaffRepository extends MockSegueRepository {
  int? lastFetchCustomerId;
  int? lastFetchStoreId;

  @override
  Future<Customer> lookupCustomerByPhone(String phoneNumber) async {
    return const Customer(
      id: 1,
      name: '김세계',
      phoneNumber: '010-1234-5678',
      hasConsented: true,
    );
  }

  @override
  Future<List<CartItem>> fetchCart({
    required int customerId,
    required int storeId,
  }) async {
    lastFetchCustomerId = customerId;
    lastFetchStoreId = storeId;
    return <CartItem>[
      _cartItem(
        skuId: 21,
        size: '미디움',
        currentStoreInStock: false,
        savedAt: DateTime(2026, 8, 16, 12),
      ),
      _cartItem(
        skuId: 22,
        size: '라지',
        currentStoreInStock: true,
        savedAt: DateTime(2026, 8, 16, 14),
      ),
    ];
  }
}

class _FlakyLookupRepository extends MockSegueRepository {
  int lookupAttempts = 0;

  @override
  Future<Customer> lookupCustomerByPhone(String phoneNumber) async {
    lookupAttempts += 1;
    if (lookupAttempts == 1) {
      throw const ApiException(
        '임시 통신 실패',
        statusCode: 0,
        code: 'NETWORK_ERROR',
      );
    }
    return const Customer(
      id: 1,
      name: '김세계',
      phoneNumber: '010-1234-5678',
      hasConsented: false,
    );
  }
}

class _ConsentRequiredCartRepository extends MockSegueRepository {
  bool consentSubmitted = false;
  int fetchAttempts = 0;
  int? lastFetchCustomerId;
  int? lastFetchStoreId;

  @override
  Future<Customer> lookupCustomerByPhone(String phoneNumber) async {
    return const Customer(
      id: 1,
      name: '김세계',
      phoneNumber: '010-1234-5678',
      hasConsented: true,
    );
  }

  @override
  Future<CustomerConsent> submitCustomerConsent({
    required int customerId,
    required bool agreed,
  }) async {
    consentSubmitted = agreed;
    return CustomerConsent(
      customerId: customerId,
      status: agreed ? ConsentStatus.agree : ConsentStatus.disagree,
      scope: MockDemoFixtures.consentScope,
      consentedAt: MockDemoFixtures.demoNow,
    );
  }

  @override
  Future<List<CartItem>> fetchCart({
    required int customerId,
    required int storeId,
  }) async {
    fetchAttempts += 1;
    lastFetchCustomerId = customerId;
    lastFetchStoreId = storeId;
    if (!consentSubmitted) {
      throw const ApiException(
        '고객 동의가 필요합니다. 장바구니 조회·상담 결과 저장 전에 데이터 이용 동의를 먼저 받아 주세요.',
        statusCode: 403,
        code: 'CONSENT_REQUIRED',
      );
    }
    return <CartItem>[
      _cartItem(
        skuId: 1,
        size: '미디움',
        currentStoreInStock: true,
        savedAt: MockDemoFixtures.demoNow,
      ),
    ];
  }
}

CartItem _cartItem({
  required int skuId,
  required String size,
  required bool currentStoreInStock,
  required DateTime savedAt,
}) {
  return CartItem.fromJson(<String, Object?>{
    'cartItemId': skuId,
    'productId': 1,
    'productName': 'MCM 백팩 미디움',
    'imageUrl': 'https://example.com/backpack.png',
    'category': '백팩',
    'skuId': skuId,
    'color': '블랙',
    'size': size,
    'currentStoreInStock': currentStoreInStock,
    'otherStoreInStock': !currentStoreInStock,
    'restockPlanned': false,
    'actionButtonLabel': currentStoreInStock ? '제품 확인하기' : 'Last Intent 시작',
    'savedAt': savedAt.toIso8601String(),
  });
}
