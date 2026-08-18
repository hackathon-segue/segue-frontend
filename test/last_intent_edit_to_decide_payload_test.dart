import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:segue_frontend/models/models.dart';
import 'package:segue_frontend/providers/providers.dart';
import 'package:segue_frontend/repositories/mock_segue_repository.dart';
import 'package:segue_frontend/screens/last_intent_confirm_screen.dart';

/// Issue #12's most important guarantee: an edit made on
/// [LastIntentEditScreen] must be the exact StructuredIntent that ends up
/// inside the `/api/consultations/decide` request payload when the CA
/// presses "맞아요, 다음 단계로" — not the original AI-generated one. This spies
/// on the repository boundary (the same `DecisionRequest.toJson()` shape
/// the real API will receive) rather than trusting internal state alone.
class _SpyRepository extends MockSegueRepository {
  DecisionRequest? lastDecisionRequest;

  @override
  Future<DecisionResult> decide(DecisionRequest request) async {
    lastDecisionRequest = request;
    return super.decide(request);
  }
}

void main() {
  testWidgets(
    'editing purchaseUrgency to TODAY and saving actually reaches the decide() request payload',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final _SpyRepository repository = _SpyRepository();
      final LastIntentSessionManager manager = LastIntentSessionManager(repository: repository);

      const Customer customer = Customer(
        id: 1,
        name: '김세계',
        phoneNumber: '010-1234-5678',
        hasConsented: true,
      );
      final CartItem cartItem = CartItem.fromJson(<String, Object?>{
        'cartItemId': 1,
        'productId': 1,
        'productName': 'MCM 백팩 미디움',
        'imageUrl': 'https://example.com/mcm-backpack.png',
        'category': '백팩',
        'skuId': 1,
        'color': '블랙',
        'size': '미디움',
        'currentStoreInStock': false,
        'otherStoreInStock': true,
        'restockPlanned': false,
        'actionButtonLabel': 'Last Intent 시작',
        'savedAt': DateTime(2026, 8, 16).toIso8601String(),
      });

      // Seed a real structureIntent() result first — this is what Issue
      // #10/#11 already put in the session before the CA ever reaches the
      // summary/edit screens. Mock's default purchaseUrgency is FLEXIBLE.
      final LastIntentSessionController session = manager.sessionFor(
        customer: customer,
        cartItem: cartItem,
      );
      await session.structureIntent('편한 느낌이면 좋겠어요');
      expect(session.state.structuredIntent!.purchaseUrgency, PurchaseUrgency.flexible);

      // LastIntentSessionScope must wrap MaterialApp (not sit inside
      // `home:`), matching main.dart's real widget tree — it needs to be
      // an ancestor of the Navigator itself so routes pushed later (the
      // edit screen) still inherit it, not just the initial route.
      await tester.pumpWidget(
        LastIntentSessionScope(
          manager: manager,
          child: MaterialApp(
            home: LastIntentConfirmScreen(customer: customer, cartItem: cartItem),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('구매 시급성 낮음'), findsOneWidget);

      // CA edits the intent: open the edit screen and change 구매 시급성 to
      // "오늘 구매 희망" (PurchaseUrgency.today).
      final Finder editButton = find.text('수정할게요');
      await tester.ensureVisible(editButton);
      await tester.tap(editButton);
      await tester.pumpAndSettle();

      final Finder urgencyDropdown = find.byType(DropdownButtonFormField<PurchaseUrgency>);
      await tester.ensureVisible(urgencyDropdown);
      await tester.tap(urgencyDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('오늘 구매 희망').last);
      await tester.pumpAndSettle();

      final Finder saveButton = find.text('저장');
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Back on the summary screen, the edit is already reflected.
      expect(find.text('오늘 구매 희망'), findsOneWidget);
      expect(session.state.structuredIntent!.purchaseUrgency, PurchaseUrgency.today);

      // "맞아요" -> decide() -> capture exactly what the repository/API
      // boundary receives.
      await tester.tap(find.text('맞아요, 다음 단계로'));
      await tester.pumpAndSettle();

      final DecisionRequest? sent = repository.lastDecisionRequest;
      expect(sent, isNotNull, reason: 'decide() must actually have been called');
      expect(sent!.storeId, session.state.storeId);
      expect(sent.skuId, cartItem.skuId);
      expect(
        sent.structuredIntent.purchaseUrgency,
        PurchaseUrgency.today,
        reason: 'the EDITED value must be what is sent, not the original FLEXIBLE from the mock AI',
      );

      // Print the exact wire payload so it's visible, matching the real
      // `POST /api/consultations/decide` body shape (storeId/skuId/
      // structuredIntent) once the backend is wired up.
      // ignore: avoid_print
      print('DecisionRequest payload sent to decide():\n${const JsonEncoder.withIndent('  ').convert(sent.toJson())}');
    },
  );
}
