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

  Future<LastIntentSessionController> pumpCompletionScreen(
    WidgetTester tester,
    MockSegueRepository repository,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final LastIntentSessionManager manager = LastIntentSessionManager(
      repository: repository,
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
        child: MaterialApp(
          home: LastIntentCompletionScreen(customer: customer, cartItem: item),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return session;
  }

  testWidgets(
    'shows the real completionMessage headline and 요청 내용 sourced from real session data',
    (WidgetTester tester) async {
      final LastIntentSessionController session = await pumpCompletionScreen(
        tester,
        MockSegueRepository(),
      );

      expect(find.text('요청 접수 완료'), findsOneWidget);
      // Real completionMessage from execute()'s response, not Figma's example
      // "타 매장 확인 요청이 접수되었습니다." headline text.
      expect(
        find.text(session.state.executionResponse!.completionMessage),
        findsOneWidget,
      );
      expect(find.text('요청 내용'), findsOneWidget);
      expect(find.text(customer.name), findsOneWidget);
      expect(find.text(customer.phoneNumber), findsOneWidget);
      expect(find.text('타 매장 확인 요청'), findsOneWidget); // real actionButtonLabel
      expect(find.text('요청 접수'), findsWidgets); // REQUESTED status label
      expect(find.text('후속 처리 상태'), findsOneWidget);
      // AC: never implies the real-world action itself is done.
      expect(find.textContaining('구매 완료'), findsNothing);
      expect(find.textContaining('예약 완료'), findsNothing);
      expect(find.textContaining('제품 이동 완료'), findsNothing);
    },
  );

  testWidgets(
    'CA can update execution status and the mock result store reflects it',
    (WidgetTester tester) async {
      final MockSegueRepository repository = MockSegueRepository();
      final LastIntentSessionController session = await pumpCompletionScreen(
        tester,
        repository,
      );

      await tester.tap(find.text('후속 확인 필요'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '타 매장 재고를 다시 확인해야 합니다.');
      final Finder updateButton = find.text('상태 갱신');
      await tester.ensureVisible(updateButton);
      await tester.pumpAndSettle();
      await tester.tap(updateButton);
      await tester.pumpAndSettle();

      expect(session.state.executionStatus, ExecutionStatus.followUpNeeded);
      expect(session.state.executionNote, '타 매장 재고를 다시 확인해야 합니다.');
      expect(find.text('후속 확인 필요 상태로 갱신되었습니다.'), findsOneWidget);

      final List<ConsultationResult> stored = await repository
          .fetchConsultationResults(customer.id);
      expect(stored.single.executionStatus, ExecutionStatus.followUpNeeded);
      expect(stored.single.executionNote, '타 매장 재고를 다시 확인해야 합니다.');
    },
  );
}
