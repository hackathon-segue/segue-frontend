import '../models/models.dart';

enum InventoryCheckState { confirmed, needsCheck, stale, unverified }

class InventoryCheckPresentation {
  const InventoryCheckPresentation({
    required this.label,
    required this.value,
    required this.state,
    required this.referenceTime,
    required this.note,
  });

  final String label;
  final String value;
  final InventoryCheckState state;
  final DateTime? referenceTime;
  final String note;

  String get stateLabel {
    return switch (state) {
      InventoryCheckState.confirmed => '확인 완료',
      InventoryCheckState.needsCheck => '확인 필요',
      InventoryCheckState.stale => '오래된 정보',
      InventoryCheckState.unverified => '미확인',
    };
  }

  String get referenceLabel {
    final DateTime? time = referenceTime;
    if (time == null) {
      return '기준 시점 없음';
    }
    return '기준 ${formatInventoryReferenceTime(time)}';
  }

  bool get needsVerification => state != InventoryCheckState.confirmed;
}

List<InventoryCheckPresentation> inventoryChecksFor(CartItem item) {
  final DateTime cartReference = item.savedAt;
  final DateTime otherStoreReference = cartReference.subtract(
    const Duration(hours: 2),
  );
  final DateTime restockReference = cartReference.subtract(
    const Duration(days: 7),
  );

  return <InventoryCheckPresentation>[
    InventoryCheckPresentation(
      label: '현재 매장 재고',
      value: item.inventory.currentStoreInStock ? '보유 확인' : '미보유 확인',
      state: InventoryCheckState.confirmed,
      referenceTime: cartReference,
      note: '현재 매장 기준으로 확인된 상태입니다.',
    ),
    InventoryCheckPresentation(
      label: '타 매장 보유',
      value: item.inventory.otherStoreInStock ? '보유 가능성 있음' : '확인 필요',
      state: item.inventory.otherStoreInStock
          ? InventoryCheckState.needsCheck
          : InventoryCheckState.unverified,
      referenceTime: item.inventory.otherStoreInStock
          ? otherStoreReference
          : null,
      note: item.inventory.otherStoreInStock
          ? '구매 경로 확정 전 타 매장에 다시 확인해야 합니다.'
          : '아직 확인된 타 매장 보유 정보가 없습니다.',
    ),
    InventoryCheckPresentation(
      label: '입고 예정',
      value: item.inventory.restockPlanned ? '입고 가능성 있음' : '확인 필요',
      state: item.inventory.restockPlanned
          ? InventoryCheckState.stale
          : InventoryCheckState.unverified,
      referenceTime: item.inventory.restockPlanned ? restockReference : null,
      note: item.inventory.restockPlanned
          ? '입고 일정은 오래된 정보로 보고 재확인이 필요합니다.'
          : '아직 확인된 입고 예정 정보가 없습니다.',
    ),
  ];
}

String formatInventoryReferenceTime(DateTime time) {
  return '${time.year}.${time.month.toString().padLeft(2, '0')}.'
      '${time.day.toString().padLeft(2, '0')} '
      '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}';
}
