import 'package:flutter/material.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../utils/app_config.dart';
import '../utils/staff_design_tokens.dart';
import '../widgets/section_card.dart';
import '../widgets/staff_app_shell.dart';
import '../widgets/staff_button.dart';
import '../widgets/staff_image_placeholder.dart';

/// Figma node 14:1785 "Last Intent Card". Matches Figma's two-column card
/// layout/copy where real data exists (product summary + live inventory
/// booleans from [CartItem.inventory], and [DecisionResult]'s own
/// coreConditions/reason/difference/nextAction fields). Figma's "재고 및
/// 입고 정보" chips read live inventory instead of the wireframe's canned
/// "확인 필요"/"정보 없음" placeholders, since that data already exists.
///
/// Per Issue #12's own scope note, the alternate-path buttons ("정확한 제품
/// 확인"/"오늘 구매 가능"/"추가 상담") and the primary action button are kept as
/// inert stubs — switching result types or wiring the execute request is a
/// later issue's scope.
class LastIntentCardScreen extends StatelessWidget {
  const LastIntentCardScreen({required this.customer, required this.cartItem, super.key});

  final Customer customer;
  final CartItem cartItem;

  static String _resultTypeLabel(DecisionResultType type) {
    return switch (type) {
      DecisionResultType.exactProduct => '정확한 제품 확인',
      DecisionResultType.comparisonExperience => '비교 체험 제품',
      DecisionResultType.todayPurchase => '오늘 구매 가능한 제품',
      DecisionResultType.additionalConsultation => '추가 상담 필요',
    };
  }

  static const double _twoColumnBreakpoint = 900;

  @override
  Widget build(BuildContext context) {
    final LastIntentSessionController session = LastIntentSessionScope.of(
      context,
    ).sessionFor(customer: customer, cartItem: cartItem);
    final DecisionResult? result = session.state.decisionResult;

    return StaffAppShell(
      currentRoute: AppRoutes.lastIntentIntro,
      body: result == null
          ? const Text('생성된 Last Intent Card가 없습니다.', style: StaffText.body12)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 16,
              children: <Widget>[
                // Wrap (not a spaceBetween Row) — a plain Row has no
                // fallback and overflows once "Last Intent Card" (20px
                // bold) plus the stage label no longer fit one line, e.g.
                // narrow tablet portrait widths.
                const Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    Text('Last Intent Card', style: StaffText.title20Bold),
                    Text('상담 단계 4 / 4', style: StaffText.body12),
                  ],
                ),
                LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final List<Widget> left = _leftColumn(result);
                    final List<Widget> right = _rightColumn(context, result);
                    if (constraints.maxWidth >= _twoColumnBreakpoint) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 24,
                        children: <Widget>[
                          Expanded(child: Column(spacing: 16, children: left)),
                          Expanded(child: Column(spacing: 16, children: right)),
                        ],
                      );
                    }
                    return Column(spacing: 16, children: <Widget>[...left, ...right]);
                  },
                ),
                StaffButton(
                  label: '상담 홈으로',
                  variant: StaffButtonVariant.secondary,
                  onPressed: () {
                    Navigator.of(context).popUntil(ModalRoute.withName(AppRoutes.staffHome));
                  },
                ),
              ],
            ),
    );
  }

  List<Widget> _leftColumn(DecisionResult result) {
    return <Widget>[
      SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: <Widget>[
            const Text('상담 제품 요약', style: StaffText.header16SemiBold),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 16,
              children: <Widget>[
                const StaffImagePlaceholder.square(size: 80),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 4,
                    children: <Widget>[
                      Text(cartItem.productName, style: StaffText.body12),
                      Text(
                        '컬러: ${cartItem.color} · SKU: ${cartItem.skuId}',
                        style: StaffText.meta11,
                      ),
                      StaffButton(
                        label: cartItem.inventory.currentStoreInStock ? '현재 매장 보유' : '현재 매장 미보유',
                        variant: StaffButtonVariant.chip,
                        onPressed: null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            _LabeledLine(label: '원제품', value: '${cartItem.productName} — ${cartItem.color}'),
            _LabeledLine(label: '제안 경로', value: result.pathDescription),
          ],
        ),
      ),
      SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: <Widget>[
            const Text('고객 핵심 조건', style: StaffText.header16SemiBold),
            _LabeledLine(label: '핵심 조건', value: result.coreConditions),
          ],
        ),
      ),
      SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: <Widget>[
            const Text('판단 근거', style: StaffText.header16SemiBold),
            Text(result.reason, style: StaffText.body12),
          ],
        ),
      ),
      SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: <Widget>[
            const Text('원제품과 제안 제품 차이', style: StaffText.header16SemiBold),
            Text(result.difference, style: StaffText.body12),
          ],
        ),
      ),
    ];
  }

  List<Widget> _rightColumn(BuildContext context, DecisionResult result) {
    final InventoryStatus inventory = cartItem.inventory;
    return <Widget>[
      SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: <Widget>[
            const Text('재고 및 입고 정보', style: StaffText.header16SemiBold),
            _InventoryRow(
              label: '현재 매장 재고 (${cartItem.color})',
              chipLabel: inventory.currentStoreInStock ? '보유 확인됨' : '미보유 확인됨',
            ),
            _InventoryRow(
              label: '타 매장 보유',
              chipLabel: inventory.otherStoreInStock ? '보유' : '미보유',
            ),
            _InventoryRow(
              label: '입고 예정',
              chipLabel: inventory.restockPlanned ? '입고 예정 있음' : '입고 예정 없음',
            ),
            const Text(
              '재고 기준 시점: 오늘 업데이트 / 타 매장 및 입고 정보는 직접 확인이 필요합니다.',
              style: StaffText.meta11,
            ),
          ],
        ),
      ),
      SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: <Widget>[
            const Text('다음 행동', style: StaffText.header16SemiBold),
            Text(result.nextAction, style: StaffText.body12),
            const Text(
              '이 요청은 실제 예약 또는 제품 이동 완료가 아니라 Client Advisor 후속 확인 요청 접수 상태입니다.',
              style: StaffText.meta11,
            ),
            StaffButton(
              label: result.actionButtonLabel,
              variant: StaffButtonVariant.primary,
              // 실행 요청(execute) 연결은 별도 이슈 범위라 아직 연결하지 않는다.
              onPressed: null,
            ),
            const Text('결과 유형이 다르다면 해당 경로를 선택하세요.', style: StaffText.meta11),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final DecisionResultType type in DecisionResultType.values)
                  if (type != result.resultType)
                    StaffButton(
                      label: _resultTypeLabel(type),
                      variant: StaffButtonVariant.secondary,
                      // 다른 결과 유형으로의 전환은 별도 이슈 범위라 아직 연결하지 않는다.
                      onPressed: null,
                    ),
              ],
            ),
          ],
        ),
      ),
    ];
  }
}

class _LabeledLine extends StatelessWidget {
  const _LabeledLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        Text(label, style: StaffText.meta11),
        Text(value, style: StaffText.body12),
      ],
    );
  }
}

class _InventoryRow extends StatelessWidget {
  const _InventoryRow({required this.label, required this.chipLabel});

  final String label;
  final String chipLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Expanded(child: Text(label, style: StaffText.body12)),
        StaffButton(label: chipLabel, variant: StaffButtonVariant.chip, onPressed: null),
      ],
    );
  }
}
