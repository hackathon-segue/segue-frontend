import 'package:flutter_test/flutter_test.dart';
import 'package:segue_frontend/models/models.dart';
import 'package:segue_frontend/utils/decision_result_validator.dart';

DecisionResult _result({
  String coreConditions = '로고 위치와 실루엣을 중요하게 보셨습니다.',
  String nextAction = '강남 신세계점 재고를 확인해 안내해 드릴 수 있습니다.',
  String reason = '지금 보고 계신 제품에서만 확인되는 특징입니다.',
  String difference = '동일 제품을 타 매장에서 확보하는 경로를 우선 제안드립니다.',
  String pathDescription = '강남 신세계점 재고 확인',
  String actionButtonLabel = '타 매장 확인 요청',
}) {
  return DecisionResult(
    resultType: DecisionResultType.exactProduct,
    coreConditions: coreConditions,
    nextAction: nextAction,
    reason: reason,
    difference: difference,
    recommendedProduct: null,
    pathDescription: pathDescription,
    actionType: DecisionActionType.otherStoreCheckRequest,
    actionButtonLabel: actionButtonLabel,
  );
}

void main() {
  test('a normal mock-style result has no forbidden language', () {
    expect(DecisionResultValidator.hasForbiddenLanguage(_result()), isFalse);
  });

  test('품절 is forbidden, regardless of which field it appears in', () {
    expect(
      DecisionResultValidator.hasForbiddenLanguage(_result(nextAction: '해당 제품은 품절입니다.')),
      isTrue,
    );
  });

  test('대체품 is forbidden', () {
    expect(
      DecisionResultValidator.hasForbiddenLanguage(_result(difference: '대체품으로 안내해 드립니다.')),
      isTrue,
    );
  });

  test('BEST MATCH is forbidden (case-insensitive)', () {
    expect(
      DecisionResultValidator.hasForbiddenLanguage(_result(coreConditions: '이 제품이 Best Match 입니다.')),
      isTrue,
    );
  });

  test('a bare match-score percentage is forbidden', () {
    expect(
      DecisionResultValidator.hasForbiddenLanguage(_result(reason: '적합도 92%로 가장 높습니다.')),
      isTrue,
    );
    expect(
      DecisionResultValidator.hasForbiddenLanguage(_result(reason: '매칭률 87% 입니다.')),
      isTrue,
    );
  });

  test('checks actionButtonLabel and pathDescription too, not just the prose fields', () {
    expect(
      DecisionResultValidator.hasForbiddenLanguage(_result(actionButtonLabel: '대체품 확인하기')),
      isTrue,
    );
    expect(
      DecisionResultValidator.hasForbiddenLanguage(_result(pathDescription: '품절 재고 확인')),
      isTrue,
    );
  });
}
