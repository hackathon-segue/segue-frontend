import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:segue_frontend/models/models.dart';
import 'package:segue_frontend/providers/providers.dart';
import 'package:segue_frontend/repositories/mock_segue_repository.dart';
import 'package:segue_frontend/screens/last_intent_edit_screen.dart';
import 'package:segue_frontend/utils/structured_intent_vocabulary.dart';

/// The new condition row editor (조건 선택 → 값 선택 [삭제], + 조건 추가) —
/// vocabulary correctness (the full API.md 속성 어휘 table, including the
/// handleType/laptopMaxInch/컬러 keys the decision engine actually matches on)
/// and initial-value/save round-tripping.
void main() {
  // Pure vocabulary checks — no widget interaction needed, and more
  // precise than driving the screen's dropdowns: the screen only ever
  // reflects whatever StructuredIntentVocabulary declares.
  group('StructuredIntentVocabulary matches API.md exactly', () {
    // 페르소나 1·4 의 handleType, 페르소나 3 의 laptopMaxInch 는 백엔드가 실제로
    // 내려주는 필수 조건 key 다. 빠져 있으면 조건 확인 화면에 영문 key 가 그대로 뜬다.
    test('handleType/laptopMaxInch exist with Korean labels', () {
      expect(
        StructuredIntentVocabulary.attributeLabels['handleType'],
        '핸들 디자인',
      );
      expect(
        StructuredIntentVocabulary.attributeLabels['laptopMaxInch'],
        '노트북 최대 인치',
      );
      expect(
        StructuredIntentVocabulary.attributeValues['handleType'],
        <String>['다이아몬드컷아웃', '일반'],
      );
      expect(
        StructuredIntentVocabulary.attributeValues['laptopMaxInch'],
        <String>['13', '16'],
      );
      expect(
        StructuredIntentVocabulary.attributeValueLabel('laptopMaxInch', '16'),
        '16인치',
      );
    });

    test('colorFamily covers the MCM product colors the backend emits', () {
      expect(StructuredIntentVocabulary.attributeValues['colorFamily'], <
        String
      >['블랙', '브라운', '베이지', '꼬냑', '오렌지', '그린']);
    });

    test('laptopCompatible values are the literal strings "true"/"false"', () {
      expect(
        StructuredIntentVocabulary.attributeValues['laptopCompatible'],
        <String>['true', 'false'],
      );
      expect(
        StructuredIntentVocabulary.attributeValueLabel(
          'laptopCompatible',
          'true',
        ),
        '예',
      );
    });

    test('exactly the 19 API.md attribute keys exist, nothing extra', () {
      expect(StructuredIntentVocabulary.attributeLabels.keys.toSet(), <
        String
      >{
        'colorFamily',
        'colorTone',
        'material',
        'glossLevel',
        'logoVisibility',
        'logoPosition',
        'patternDensity',
        'silhouette',
        'structure',
        'sizeGrade',
        'strapType',
        'hardwareColor',
        'usageContext',
        'weightGrade',
        'lockType',
        'internalStorageLevel',
        'handleType',
        'laptopCompatible',
        'laptopMaxInch',
      });
    });

    test('every labelled key also declares its allowed values', () {
      expect(
        StructuredIntentVocabulary.attributeValues.keys.toSet(),
        StructuredIntentVocabulary.attributeLabels.keys.toSet(),
      );
    });
  });

  Future<LastIntentSessionController> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final MockSegueRepository repository = MockSegueRepository();
    final LastIntentSessionManager manager = LastIntentSessionManager(
      repository: repository,
    );
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
    final LastIntentSessionController session = manager.sessionFor(
      customer: customer,
      cartItem: cartItem,
    );
    await session.structureIntent('편한 느낌이면 좋겠어요');

    await tester.pumpWidget(
      LastIntentSessionScope(
        manager: manager,
        child: MaterialApp(
          home: LastIntentEditScreen(customer: customer, cartItem: cartItem),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return session;
  }

  testWidgets('existing essentialConditions seed one row each on entry', (
    WidgetTester tester,
  ) async {
    await pump(tester);
    // Mock's structureIntent('편한 느낌이면 좋겠어요') seeds
    // essentialConditions {logoPosition: 정면중앙, silhouette: 각진}. Their
    // labels also appear as physicalCheckAttributes chips further down, so
    // this only checks the values (unique to the condition rows) plus at
    // least one label instance.
    expect(find.text('로고 위치'), findsWidgets);
    expect(find.text('정면중앙'), findsOneWidget);
    expect(find.text('실루엣'), findsWidgets);
    expect(find.text('각진'), findsOneWidget);
  });

  testWidgets('handleType/laptopMaxInch are offered as condition keys', (
    WidgetTester tester,
  ) async {
    await pump(tester);
    // 조건 선택 드롭다운은 선택되지 않은 항목도 위젯 트리에 만들어 두므로,
    // 라벨이 보이면 그 key 를 CA 가 고를 수 있다는 뜻이다.
    expect(find.text('핸들 디자인'), findsWidgets);
    expect(find.text('노트북 최대 인치'), findsWidgets);
  });

  testWidgets('deleting a row removes its key from the underlying map on save', (
    WidgetTester tester,
  ) async {
    final LastIntentSessionController session = await pump(tester);

    // Delete the seeded essentialConditions.logoPosition row.
    final Finder deleteButtons = find.byIcon(Icons.delete_outline);
    await tester.ensureVisible(deleteButtons.first);
    await tester.tap(deleteButtons.first);
    await tester.pumpAndSettle();

    final Finder nextButton = find.text('다음 단계로');
    await tester.ensureVisible(nextButton);
    await tester.tap(nextButton);
    await tester.pumpAndSettle();

    expect(
      session.state.structuredIntent!.essentialConditions.containsKey(
        'logoPosition',
      ),
      isFalse,
    );
    expect(
      session.state.structuredIntent!.essentialConditions['silhouette'],
      '각진',
    );
  });

  testWidgets('needsFollowUp/followUpReason are preserved untouched through a save', (
    WidgetTester tester,
  ) async {
    final LastIntentSessionController session = await pump(tester);
    final bool originalNeedsFollowUp =
        session.state.structuredIntent!.needsFollowUp;
    final String originalReason = session.state.structuredIntent!.followUpReason;

    final Finder nextButton = find.text('다음 단계로');
    await tester.ensureVisible(nextButton);
    await tester.tap(nextButton);
    await tester.pumpAndSettle();

    expect(
      session.state.structuredIntent!.needsFollowUp,
      originalNeedsFollowUp,
    );
    expect(session.state.structuredIntent!.followUpReason, originalReason);
  });
}
