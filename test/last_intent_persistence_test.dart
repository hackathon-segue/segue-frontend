import 'package:flutter_test/flutter_test.dart';
import 'package:segue_frontend/models/models.dart';
import 'package:segue_frontend/providers/providers.dart';
import 'package:segue_frontend/repositories/mock_segue_repository.dart';

/// "고객/상담 상태 관리" — active-consultation persistence (localStorage,
/// via LocalStorage's in-memory test fallback) and step-based resume.
/// flutter_test_config.dart clears that storage before every test here, so
/// these tests only ever see what they themselves persist.
void main() {
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

  test('a session survives a fresh LastIntentSessionManager (simulating a page '
      'refresh), including its currentStep and structuredIntent', () async {
    final MockSegueRepository repository = MockSegueRepository();
    final LastIntentSessionManager before = LastIntentSessionManager(
      repository: repository,
    );
    final LastIntentSessionController session = before.sessionFor(
      customer: customer,
      cartItem: cartItem(1, 'MCM 백팩'),
    );
    await session.structureIntent('편한 느낌이면 좋겠어요');
    // structureIntent() alone leaves currentStep at its default
    // (utterance) — only the screen's own navigation sets it forward, so
    // set it explicitly here the same way LastIntentUtteranceScreen does
    // right before pushing the next screen.
    session.setCurrentStep(LastIntentStep.confirm);
    before.dispose();

    // A brand new manager, same repository — mirrors what actually
    // happens on browser refresh (main.dart constructs a fresh
    // LastIntentSessionManager from scratch).
    final LastIntentSessionManager after = LastIntentSessionManager(
      repository: repository,
    );
    addTearDown(after.dispose);

    expect(after.activeCount, 1);
    final LastIntentSessionState? restored = after.firstActiveSession;
    expect(restored, isNotNull);
    expect(restored!.currentStep, LastIntentStep.confirm);
    expect(restored.customer?.id, 1);
    expect(restored.customer?.name, '김세계');
    expect(restored.selectedCartItem?.skuId, 1);
    expect(restored.selectedCartItem?.productName, 'MCM 백팩');
    expect(restored.structuredIntent, isNotNull);
    expect(restored.utterance, '편한 느낌이면 좋겠어요');
  });

  test('a completed session (execute() ran) is never restored — only '
      'still-in-progress sessions persist', () async {
    final MockSegueRepository repository = MockSegueRepository();
    final LastIntentSessionManager before = LastIntentSessionManager(
      repository: repository,
    );
    final LastIntentSessionController session = before.sessionFor(
      customer: customer,
      cartItem: cartItem(1, 'MCM 백팩'),
    );
    await session.structureIntent('편한 느낌이면 좋겠어요');
    await session.decide();
    await session.execute();
    expect(session.state.executionResponse, isNotNull);
    before.dispose();

    final LastIntentSessionManager after = LastIntentSessionManager(
      repository: repository,
    );
    addTearDown(after.dispose);

    expect(after.activeCount, 0);
    expect(after.firstActiveSession, isNull);
    expect(after.isStarted(customer.id, 1), isFalse);
  });

  test('two independent SKU sessions both survive a refresh, each with its own '
      'currentStep', () async {
    final MockSegueRepository repository = MockSegueRepository();
    final LastIntentSessionManager before = LastIntentSessionManager(
      repository: repository,
    );
    final LastIntentSessionController sessionA = before.sessionFor(
      customer: customer,
      cartItem: cartItem(1, 'A'),
    );
    sessionA.setCurrentStep(LastIntentStep.followUp);
    final LastIntentSessionController sessionB = before.sessionFor(
      customer: customer,
      cartItem: cartItem(2, 'B'),
    );
    sessionB.setCurrentStep(LastIntentStep.card);
    before.dispose();

    final LastIntentSessionManager after = LastIntentSessionManager(
      repository: repository,
    );
    addTearDown(after.dispose);

    expect(after.activeCount, 2);
    final LastIntentSessionController restoredA = after.sessionFor(
      customer: customer,
      cartItem: cartItem(1, 'A'),
    );
    final LastIntentSessionController restoredB = after.sessionFor(
      customer: customer,
      cartItem: cartItem(2, 'B'),
    );
    expect(restoredA.state.currentStep, LastIntentStep.followUp);
    expect(restoredB.state.currentStep, LastIntentStep.card);
  });

  test('resetForCustomer() drops the persisted copy too, not just the '
      'in-memory one', () async {
    final MockSegueRepository repository = MockSegueRepository();
    final LastIntentSessionManager before = LastIntentSessionManager(
      repository: repository,
    );
    before.sessionFor(customer: customer, cartItem: cartItem(1, 'A'));
    before.resetForCustomer(customer.id);
    before.dispose();

    final LastIntentSessionManager after = LastIntentSessionManager(
      repository: repository,
    );
    addTearDown(after.dispose);

    expect(after.activeCount, 0);
    expect(after.firstActiveSession, isNull);
  });

  test('StaffWebSessionController restores currentCustomer and re-fetches the '
      'cart via the existing API after a simulated refresh — never replays a '
      'copy of cart items from localStorage', () async {
    final MockSegueRepository repository = MockSegueRepository();
    final StaffWebSessionController before = StaffWebSessionController(
      repository: repository,
    );
    await before.lookupCustomer('010-1234-5678');
    expect(before.state.currentCustomer?.name, '김세계');
    before.dispose();

    final StaffWebSessionController after = StaffWebSessionController(
      repository: repository,
    );
    addTearDown(after.dispose);

    // Restoration sets currentCustomer synchronously (no await needed)...
    expect(after.state.currentCustomer?.id, 1);
    expect(after.state.currentCustomer?.name, '김세계');
    // ...and kicks off the real loadCart() in the background, hitting the
    // same GET /api/cart the app already uses — not a localStorage copy.
    expect(after.state.cartState.isLoading, isTrue);
    await Future<void>.delayed(Duration.zero);
    expect(after.state.cartState.hasData, isTrue);
    expect(after.state.cartItems, isNotEmpty);
  });

  test(
    'StaffWebSessionController.reset() clears the persisted currentCustomer',
    () async {
      final MockSegueRepository repository = MockSegueRepository();
      final StaffWebSessionController before = StaffWebSessionController(
        repository: repository,
      );
      await before.lookupCustomer('010-1234-5678');
      before.reset();
      before.dispose();

      final StaffWebSessionController after = StaffWebSessionController(
        repository: repository,
      );
      addTearDown(after.dispose);

      expect(after.state.currentCustomer, isNull);
    },
  );

  test(
    'in-stock completion survives clearing the session and looking up the same customer again',
    () async {
      final MockSegueRepository repository = MockSegueRepository();
      final StaffWebSessionController controller = StaffWebSessionController(
        repository: repository,
      );
      addTearDown(controller.dispose);

      await controller.lookupCustomer('010-1234-5678');
      controller.markProductChecked(4);
      controller.reset();

      await controller.lookupCustomer('010-1234-5678');

      expect(controller.state.currentCustomer?.id, 1);
      expect(controller.state.checkedInStockSkuIds, contains(4));
    },
  );

  test('clearLookupResult() resets only the lookup-screen result, leaving '
      'currentCustomer/cart untouched', () async {
    final MockSegueRepository repository = MockSegueRepository();
    final StaffWebSessionController controller = StaffWebSessionController(
      repository: repository,
    );
    addTearDown(controller.dispose);
    await controller.lookupCustomer('010-1234-5678');
    await controller.loadCart();
    expect(controller.state.lookupState.hasData, isTrue);
    expect(controller.state.cartState.hasData, isTrue);

    controller.clearLookupResult();

    expect(controller.state.lookupState.isIdle, isTrue);
    expect(controller.state.currentCustomer?.name, '김세계');
    expect(controller.state.cartState.hasData, isTrue);
    expect(controller.state.cartItems, isNotEmpty);
  });
}
