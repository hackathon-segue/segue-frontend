import 'package:flutter_test/flutter_test.dart';
import 'package:segue_frontend/models/models.dart';
import 'package:segue_frontend/providers/providers.dart';
import 'package:segue_frontend/repositories/mock_segue_repository.dart';

/// Issue #9: LastIntentSessionManager keeps one independent session per SKU
/// so several out-of-stock cart items never share or overwrite each
/// other's Last Intent progress.
void main() {
  late MockSegueRepository repository;
  late LastIntentSessionManager manager;

  setUp(() {
    repository = MockSegueRepository();
    manager = LastIntentSessionManager(repository: repository);
  });

  const Customer customer = Customer(
    id: 1,
    name: '김세계',
    phoneNumber: '010-1234-5678',
    hasConsented: true,
  );

  CartItem cartItem(int skuId, String name) {
    return CartItem.fromJson(<String, Object?>{
      'cartItemId': skuId,
      'productId': skuId,
      'productName': name,
      'imageUrl': 'https://example.com/x.png',
      'category': '백팩',
      'skuId': skuId,
      'color': '블랙',
      'size': '미디움',
      'currentStoreInStock': false,
      'otherStoreInStock': false,
      'restockPlanned': false,
      'actionButtonLabel': 'Last Intent 시작',
      'savedAt': DateTime(2026, 8, 16).toIso8601String(),
    });
  }

  test('each SKU gets its own controller instance, not a shared one', () {
    final CartItem itemA = cartItem(1, 'A');
    final CartItem itemB = cartItem(2, 'B');

    final LastIntentSessionController sessionA = manager.sessionFor(
      customer: customer,
      cartItem: itemA,
    );
    final LastIntentSessionController sessionB = manager.sessionFor(
      customer: customer,
      cartItem: itemB,
    );

    expect(sessionA.state.selectedCartItem?.skuId, 1);
    expect(sessionB.state.selectedCartItem?.skuId, 2);
    expect(identical(sessionA, sessionB), isFalse);

    // Re-visiting SKU A returns the SAME instance with unchanged state —
    // starting SKU B did not reset or replace it.
    expect(
      identical(
        manager.sessionFor(customer: customer, cartItem: itemA),
        sessionA,
      ),
      isTrue,
    );
    expect(sessionA.state.selectedCartItem?.skuId, 1);
  });

  test(
    'mutating one SKU session does not leak into another SKU session',
    () async {
      final CartItem itemA = cartItem(1, 'A');
      final CartItem itemB = cartItem(2, 'B');

      final LastIntentSessionController sessionA = manager.sessionFor(
        customer: customer,
        cartItem: itemA,
      );
      await sessionA.structureIntent('편한 느낌이면 좋겠어요');
      expect(sessionA.state.structuredIntent, isNotNull);

      final LastIntentSessionController sessionB = manager.sessionFor(
        customer: customer,
        cartItem: itemB,
      );
      expect(sessionB.state.utterance, isEmpty);
      expect(sessionB.state.structuredIntent, isNull);
    },
  );

  test('reset clears every SKU session (new customer lookup)', () {
    manager.sessionFor(customer: customer, cartItem: cartItem(1, 'A'));
    manager.sessionFor(customer: customer, cartItem: cartItem(2, 'B'));
    expect(manager.isStarted(1), isTrue);
    expect(manager.isStarted(2), isTrue);

    manager.reset();

    expect(manager.isStarted(1), isFalse);
    expect(manager.isStarted(2), isFalse);
  });

  test(
    'StaffWebSessionController.onNewLookup resets the manager on a new lookup',
    () async {
      final StaffWebSessionController staffController =
          StaffWebSessionController(repository: repository);
      staffController.onNewLookup = manager.reset;

      manager.sessionFor(customer: customer, cartItem: cartItem(1, 'A'));
      expect(manager.isStarted(1), isTrue);

      await staffController.lookupCustomer('010-1234-5678');

      expect(manager.isStarted(1), isFalse);
    },
  );

  test(
    'StaffWebSessionController.onConsentChanged resets in-progress sessions',
    () async {
      final StaffWebSessionController staffController =
          StaffWebSessionController(repository: repository);
      staffController.onConsentChanged = manager.reset;

      await staffController.lookupCustomer('010-1234-5678');
      await staffController.loadCart();
      manager.sessionFor(customer: customer, cartItem: cartItem(1, 'A'));
      expect(manager.isStarted(1), isTrue);
      expect(staffController.state.cartState.hasData, isTrue);

      await staffController.submitConsent(false);

      expect(manager.isStarted(1), isFalse);
      expect(staffController.state.customer?.hasConsented, isFalse);
      expect(staffController.state.cartItems, isEmpty);
      expect(staffController.state.cartState.isIdle, isTrue);
    },
  );

  group('Issue #64: declineAdditionalConsultation / activeCount interplay', () {
    test(
      'a session stays active until execute() runs, regardless of decline',
      () {
        final CartItem itemA = cartItem(1, 'A');
        final LastIntentSessionController sessionA = manager.sessionFor(
          customer: customer,
          cartItem: itemA,
        );

        expect(manager.activeCount, 1);
        expect(manager.isCompleted(1), isFalse);
        expect(manager.isDeclined(1), isFalse);

        // declineAdditionalConsultation() alone (no execute() yet) is not a
        // real usage of the method — this only proves it doesn't fabricate
        // completion on its own, execute() is still what flips isCompleted.
        sessionA.declineAdditionalConsultation();
        expect(manager.isDeclined(1), isTrue);
        expect(manager.isCompleted(1), isFalse);
        expect(manager.activeCount, 1);
      },
    );

    test(
      'once execute() runs, a declined SKU counts as completed (not active) '
      'exactly like a normally-completed one, and only the badge flag differs',
      () async {
        final CartItem itemA = cartItem(1, 'A');
        final CartItem itemB = cartItem(2, 'B');
        final LastIntentSessionController sessionA = manager.sessionFor(
          customer: customer,
          cartItem: itemA,
        );
        final LastIntentSessionController sessionB = manager.sessionFor(
          customer: customer,
          cartItem: itemB,
        );
        await sessionA.structureIntent('편한 느낌이면 좋겠어요');
        await sessionA.decide();
        await sessionB.structureIntent('편한 느낌이면 좋겠어요');
        await sessionB.decide();

        expect(manager.activeCount, 2);

        // SKU A: "추가 상담 미진행" — execute() runs, then declined.
        await sessionA.execute();
        sessionA.declineAdditionalConsultation();

        expect(manager.isCompleted(1), isTrue);
        expect(manager.isDeclined(1), isTrue);
        // SKU B is untouched — still active, not declined.
        expect(manager.isCompleted(2), isFalse);
        expect(manager.isDeclined(2), isFalse);
        // Only SKU B is left active now that A completed (declined or not).
        expect(manager.activeCount, 1);
        expect(manager.firstActiveSession?.selectedCartItem?.skuId, 2);

        // SKU B: normal completion — execute() runs, never declined.
        await sessionB.execute();

        expect(manager.isCompleted(2), isTrue);
        expect(manager.isDeclined(2), isFalse);
        // Both SKUs done (one declined, one normal) → no active sessions
        // left, matching "모든 상담 대상 상품이 상담 완료 또는 상담 중단이면
        // 고객 진행 중 상담 종료" (Issue #64).
        expect(manager.activeCount, 0);
        expect(manager.firstActiveSession, isNull);
      },
    );
  });
}
