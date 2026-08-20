import '../models/models.dart';

/// API.md "속성 어휘" table — the fixed key/value vocabulary allowed inside
/// StructuredIntent's essentialConditions/preferredConditions/
/// negotiableConditions/physicalCheckAttributes. Centralized here so the
/// summary (display) and edit screens both stay within this contract
/// instead of drifting into arbitrary key/value strings that would break
/// the `/decide` API contract.
///
/// 여기 없는 key 는 화면에 영문 그대로 노출되고(라벨 조회가 key 를 그대로 반환한다),
/// 여기 없는 value 는 조건 수정 화면의 드롭다운에서 빈 선택지로 보인다. 백엔드가
/// 실제로 내려주는 어휘의 원본은 `prompts/intent.txt` 이고 API.md 표가 그 사본이므로,
/// 셋 중 하나가 바뀌면 나머지도 함께 맞춰야 한다.
abstract final class StructuredIntentVocabulary {
  /// Attribute key (wire value, e.g. "colorFamily") -> Korean label.
  static const Map<String, String> attributeLabels = <String, String>{
    'colorFamily': '컬러 계열',
    'colorTone': '컬러 톤',
    'material': '소재',
    'glossLevel': '광택 정도',
    'logoVisibility': '로고 노출도',
    'logoPosition': '로고 위치',
    'patternDensity': '패턴 밀도',
    'silhouette': '실루엣',
    'structure': '구조',
    'sizeGrade': '사이즈',
    'strapType': '스트랩 종류',
    'hardwareColor': '하드웨어 컬러',
    'usageContext': '사용 상황',
    'weightGrade': '무게감',
    'lockType': '잠금 방식',
    'internalStorageLevel': '내부 수납',
    'handleType': '핸들 디자인',
    'laptopCompatible': '노트북 수납 가능 여부',
    'laptopMaxInch': '노트북 최대 인치',
  };

  /// Attribute key -> its allowed wire values, in table order. Matches
  /// API.md's "속성 어휘" table exactly — no keys/values beyond what that
  /// table lists.
  static const Map<String, List<String>> attributeValues = <String, List<String>>{
    'colorFamily': <String>['블랙', '브라운', '베이지', '꼬냑', '오렌지', '그린'],
    'colorTone': <String>['웜', '쿨', '뉴트럴'],
    'material': <String>['가죽', '캔버스', '패브릭'],
    'glossLevel': <String>['높음', '중간', '낮음'],
    'logoVisibility': <String>['높음', '중간', '낮음'],
    'logoPosition': <String>['정면중앙', '정면하단', '스트랩'],
    'patternDensity': <String>['높음', '중간', '낮음'],
    'silhouette': <String>['각진', '라운드', '사각'],
    'structure': <String>['하드', '소프트'],
    'sizeGrade': <String>['미니', '스몰', '미디움', '라지'],
    'strapType': <String>['체인스트랩', '패브릭스트랩', '패브릭+레더콤보', '벨트스트랩'],
    'hardwareColor': <String>['골드', '실버', '건메탈'],
    'usageContext': <String>['데일리', '오피스', '이브닝'],
    'weightGrade': <String>['가벼움', '보통', '무거움'],
    'lockType': <String>['지퍼', '플립', '마그네틱'],
    'internalStorageLevel': <String>['심플', '구획많음'],
    'handleType': <String>['다이아몬드컷아웃', '일반'],
    // API.md: boolean이 아니라 문자열 "true"/"false"로 전달한다.
    'laptopCompatible': <String>['true', 'false'],
    // laptopMaxInch 도 문자열이다. laptopCompatible=false 면 이 key 는 쓰이지 않는다.
    'laptopMaxInch': <String>['13', '16'],
  };

  static String attributeLabel(String key) => attributeLabels[key] ?? key;

  /// Value display label — every attribute's values are already Korean
  /// text except laptopCompatible (literal "true"/"false").
  static String attributeValueLabel(String key, String value) {
    if (key == 'laptopCompatible') {
      return value == 'true' ? '예' : '아니오';
    }
    if (key == 'laptopMaxInch') {
      return '$value인치';
    }
    return value;
  }

  static String purchaseUrgencyLabel(PurchaseUrgency urgency) {
    return switch (urgency) {
      PurchaseUrgency.today => '오늘 구매 희망',
      PurchaseUrgency.thisWeek => '이번 주 내 구매 희망',
      PurchaseUrgency.flexible => '구매 시급성 낮음',
    };
  }

  static String yesNoUnknownLabel(bool? value) {
    if (value == null) return '확인 필요';
    return value ? '예' : '아니오';
  }
}
