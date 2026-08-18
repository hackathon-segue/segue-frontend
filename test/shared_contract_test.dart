import 'package:flutter_test/flutter_test.dart';
import 'package:segue_frontend/exceptions/app_exception.dart';
import 'package:segue_frontend/models/models.dart';
import 'package:segue_frontend/providers/providers.dart';
import 'package:segue_frontend/repositories/repositories.dart';

void main() {
  test('cart save request uses product option fields, not skuId', () {
    const CartSaveRequest request = CartSaveRequest(
      customerId: 1,
      productId: 1,
      color: '블랙',
      size: '미디움',
    );

    expect(request.toJson(), isNot(contains('skuId')));
    expect(request.toJson(), containsPair('productId', 1));
  });

  test('cart item keeps sku inventory booleans without reliability fields', () {
    final CartItem item = CartItem.fromJson(<String, Object?>{
      'cartItemId': 1,
      'productId': 1,
      'productName': 'MCM 백팩 미디움',
      'imageUrl': 'https://example.com/image.png',
      'category': '백팩',
      'skuId': 1,
      'color': '블랙',
      'size': '미디움',
      'currentStoreInStock': false,
      'otherStoreInStock': true,
      'restockPlanned': false,
      'actionButtonLabel': 'Last Intent 시작',
      'savedAt': '2026-08-16T16:54:29',
    });

    expect(item.productId, 1);
    expect(item.skuId, 1);
    expect(item.inventory.otherStoreInStock, isTrue);
    expect(item.toJson(), isNot(contains('confirmed')));
    expect(item.toJson(), isNot(contains('checked_at')));
  });

  test('mock repository blocks consent-gated cart lookup', () async {
    final MockSegueRepository repository = MockSegueRepository();

    await expectLater(
      repository.fetchCart(customerId: 2, storeId: 1),
      throwsA(
        isA<ApiException>().having(
          (ApiException error) => error.isConsentRequired,
          'isConsentRequired',
          isTrue,
        ),
      ),
    );
  });

  test(
    'mock repository blocks consent-gated consultation result save',
    () async {
      final MockSegueRepository repository = MockSegueRepository();

      await expectLater(
        repository.recordConsultationResult(
          customerId: 2,
          result: ConsultationResult(
            id: 1,
            skuId: 1,
            productName: 'MCM 백팩 미디움',
            imageUrl: 'https://example.com/image.png',
            resultType: DecisionResultType.exactProduct,
            recommendedPath: '타 매장 확인',
            coreConditions: '로고 위치와 각진 형태',
            consultedAt: DateTime(2026, 8, 16),
            executionStatus: ExecutionStatus.requested,
            executionNote: null,
            executionUpdatedAt: DateTime(2026, 8, 16),
          ),
        ),
        throwsA(
          isA<ApiException>().having(
            (ApiException error) => error.isConsentRequired,
            'isConsentRequired',
            isTrue,
          ),
        ),
      );
    },
  );

  test(
    'last intent session carries stateless backend payloads forward',
    () async {
      final MockSegueRepository repository = MockSegueRepository();
      final Customer customer = await repository.lookupCustomerByPhone(
        '010-1234-5678',
      );
      final List<CartItem> cartItems = await repository.fetchCart(
        customerId: customer.id,
        storeId: 1,
      );
      final LastIntentSessionController controller =
          LastIntentSessionController(repository: repository)
            ..start(customer: customer, cartItem: cartItems.first);

      await controller.structureIntent('이 로고 위치와 각진 형태가 좋아요.');
      await controller.decide();
      await controller.execute();

      expect(controller.state.structuredIntent?.needsFollowUp, isFalse);
      expect(controller.state.decisionResult?.actionButtonLabel, '타 매장 확인 요청');
      // Issue #15: MockSegueRepository now hands out a unique id per call
      // (so multiple executed consultations get distinct ConsultationResult
      // records instead of colliding) rather than always returning the
      // same fixed literal — the exact value was never a meaningful
      // contract, just that one is present.
      expect(
        controller.state.executionResponse?.consultationResultId,
        greaterThan(0),
      );
    },
  );
}
