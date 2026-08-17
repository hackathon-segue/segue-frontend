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
    expect(identical(manager.sessionFor(customer: customer, cartItem: itemA), sessionA), isTrue);
    expect(sessionA.state.selectedCartItem?.skuId, 1);
  });

  test('mutating one SKU session does not leak into another SKU session', () async {
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
  });

  test('reset clears every SKU session (new customer lookup)', () {
    manager.sessionFor(customer: customer, cartItem: cartItem(1, 'A'));
    manager.sessionFor(customer: customer, cartItem: cartItem(2, 'B'));
    expect(manager.isStarted(1), isTrue);
    expect(manager.isStarted(2), isTrue);

    manager.reset();

    expect(manager.isStarted(1), isFalse);
    expect(manager.isStarted(2), isFalse);
  });

  test('StaffWebSessionController.onNewLookup resets the manager on a new lookup', () async {
    final StaffWebSessionController staffController = StaffWebSessionController(
      repository: repository,
    );
    staffController.onNewLookup = manager.reset;

    manager.sessionFor(customer: customer, cartItem: cartItem(1, 'A'));
    expect(manager.isStarted(1), isTrue);

    await staffController.lookupCustomer('010-1234-5678');

    expect(manager.isStarted(1), isFalse);
  });
}
