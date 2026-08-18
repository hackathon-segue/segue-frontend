import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:segue_frontend/models/models.dart';
import 'package:segue_frontend/providers/providers.dart';
import 'package:segue_frontend/repositories/mock_segue_repository.dart';
import 'package:segue_frontend/screens/last_intent_completion_screen.dart';

/// Issue #46: completion screen rebuilt to match Figma node 169:3891
/// (superseding the previous #14/#15 build at node 14:2301).
void main() {
  CartItem cartItem() {
    return CartItem.fromJson(<String, Object?>{
      'cartItemId': 1,
      'productId': 1,
      'productName': 'MCM 백팩 미디움',
      'imageUrl': 'https://example.com/x.png',
      'category': '백팩',
      'skuId': 1,
      'color': '블랙',
      'size': '미디움',
      'currentStoreInStock': false,
      'otherStoreInStock': false,
      'restockPlanned': false,
      'actionButtonLabel': 'Last Intent 시작',
      'savedAt': DateTime(2026, 8, 16).toIso8601String(),
    });
  }

  const Customer customer = Customer(
    id: 1,
    name: '김세계',
    phoneNumber: '010-1234-5678',
    hasConsented: true,
  );

  testWidgets('shows the real completionMessage headline and 요청 내용 sourced from real session data', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final LastIntentSessionManager manager = LastIntentSessionManager(
      repository: MockSegueRepository(),
    );
    final CartItem item = cartItem();
    final LastIntentSessionController session = manager.sessionFor(
      customer: customer,
      cartItem: item,
    );
    await session.structureIntent('편한 느낌이면 좋겠어요');
    await session.decide();
    await session.execute();

    await tester.pumpWidget(
      LastIntentSessionScope(
        manager: manager,
        child: MaterialApp(home: LastIntentCompletionScreen(customer: customer, cartItem: item)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('요청 접수 완료'), findsOneWidget);
    // Real completionMessage from execute()'s response, not Figma's example
    // "타 매장 확인 요청이 접수되었습니다." headline text.
    expect(find.text(session.state.executionResponse!.completionMessage), findsOneWidget);
    expect(find.text('요청 내용'), findsOneWidget);
    expect(find.text(customer.name), findsOneWidget);
    expect(find.text(customer.phoneNumber), findsOneWidget);
    expect(find.text('타 매장 확인 요청'), findsOneWidget); // real actionButtonLabel
    expect(find.text('확인 대기'), findsOneWidget); // REQUESTED status label
    // AC: never implies the real-world action itself is done.
    expect(find.textContaining('구매 완료'), findsNothing);
    expect(find.textContaining('예약 완료'), findsNothing);
    expect(find.textContaining('제품 이동 완료'), findsNothing);
  });
}
