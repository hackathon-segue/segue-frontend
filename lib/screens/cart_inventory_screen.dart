import 'package:flutter/material.dart';

import '../exceptions/app_exception.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../utils/app_config.dart';
import '../utils/staff_design_tokens.dart';
import '../widgets/app_state_view.dart';
import '../widgets/section_card.dart';
import '../widgets/staff_app_shell.dart';
import '../widgets/staff_button.dart';
import '../widgets/staff_image_placeholder.dart';

/// Figma node 14:1051 "장바구니·재고 확인 화면".
///
/// Not part of Issue #7's original scope (that only required the cart
/// *preview* inside [CustomerLookupScreen]) — added because the user
/// explicitly provided this Figma node and asked for an exact match.
/// Reuses the already-loaded customer/cart/consent state from
/// [StaffWebSessionController] rather than re-fetching, since the CA
/// reaches this screen right after consenting on [ConsentScreen].
class CartInventoryScreen extends StatelessWidget {
  const CartInventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final StaffWebSessionController controller = StaffSessionScope.of(context);

    return StaffAppShell(
      currentRoute: AppRoutes.cartInventory,
      body: ListenableBuilder(
        listenable: controller,
        builder: (BuildContext context, Widget? _) {
          final StaffWebSessionState state = controller.state;
          final Customer? customer = state.customer;

          if (customer == null) {
            return const AppStateView.empty(
              title: '조회된 고객이 없습니다',
              message: '고객 조회 화면에서 먼저 고객을 조회해 주세요.',
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 16,
            children: <Widget>[
              // The meta text is long enough that, as a plain non-flex Row
              // sibling, it reports its unwrapped single-line intrinsic
              // width and overflows on narrow viewports (Figma's 1440
              // reference never needs it to wrap). Flexible lets it wrap
              // within its share instead of demanding full-line width.
              const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(child: Text('장바구니 · 재고 확인', style: StaffText.title20Bold)),
                  Flexible(
                    child: Text(
                      '재고 기준 시점: 오늘 업데이트 · 현재 매장 재고는 실시간 동기화가 아닙니다',
                      style: StaffText.meta11,
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
              _CustomerSummaryCard(customer: customer, state: state),
              const Text('장바구니 목록', style: StaffText.header16SemiBold),
              _CartList(customer: customer, cartState: state.cartState),
              const SectionCard(
                child: Wrap(
                  spacing: 8,
                  children: <Widget>[
                    Text('재고 안내', style: StaffText.meta11),
                    Text(
                      '현재 매장 재고 정보는 확인 기준 시점 이후 변동될 수 있습니다. '
                      '재고 없음 제품은 Last Intent 상담을 통해 타 매장 확인 또는 입고 경로를 안내할 수 있습니다.',
                      style: StaffText.meta11,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CustomerSummaryCard extends StatelessWidget {
  const _CustomerSummaryCard({required this.customer, required this.state});

  final Customer customer;
  final StaffWebSessionState state;

  static const double _equalColumnsBreakpoint = 760;

  @override
  Widget build(BuildContext context) {
    final CustomerConsent? consent = state.consentState.data;
    final String consentDate = consent != null ? _formatDateTime(consent.consentedAt) : '-';
    final int itemCount = state.cartState.data?.length ?? 0;

    // Figma (14:1051 metadata) lays this out as 6 EQUAL-width flex columns
    // (5 info columns + 1 invisible spacer between "휴대전화" and "상담 동의
    // 완료"), not a left-flowing Wrap — so the last two columns must land
    // flush against the card's right edge, not directly after "휴대전화".
    final List<Widget> columns = <Widget>[
      _InfoColumn(label: '고객', value: customer.name, valueStyle: StaffText.header16SemiBold),
      _InfoColumn(label: '회원번호', value: 'MCM-${customer.id.toString().padLeft(5, '0')}'),
      _InfoColumn(label: '휴대전화', value: customer.phoneNumber),
      const SizedBox.shrink(),
      _InfoColumn(label: '상담 동의 완료', value: consentDate, alignEnd: true),
      _InfoColumn(
        label: '장바구니 제품',
        value: '$itemCount개',
        valueStyle: StaffText.header16SemiBold,
        alignEnd: true,
      ),
    ];

    return SectionCard(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          if (constraints.maxWidth >= _equalColumnsBreakpoint) {
            return Row(
              spacing: 24,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[for (final Widget column in columns) Expanded(child: column)],
            );
          }
          // Narrow-viewport fallback (this app's own responsive addition,
          // not present in the 1440px Figma reference): drop the equal-flex
          // grid and just flow the 5 real columns, skipping the invisible
          // spacer which has no purpose without the flex distribution.
          return Wrap(
            spacing: 24,
            runSpacing: 12,
            children: <Widget>[for (final Widget column in columns) if (column is! SizedBox) column],
          );
        },
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}년 ${dt.month}월 ${dt.day}일 '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _InfoColumn extends StatelessWidget {
  const _InfoColumn({
    required this.label,
    required this.value,
    this.valueStyle = StaffText.body12,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final TextStyle valueStyle;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      spacing: 4,
      children: <Widget>[
        Text(label, style: StaffText.meta11),
        Text(value, style: valueStyle),
      ],
    );
  }
}

class _CartList extends StatelessWidget {
  const _CartList({required this.customer, required this.cartState});

  final Customer customer;
  final AsyncValue<List<CartItem>> cartState;

  @override
  Widget build(BuildContext context) {
    if (!customer.hasConsented) {
      return const AppStateView.empty(
        title: '데이터 이용 동의가 필요합니다',
        message: '동의 확인 후 장바구니 목록을 볼 수 있습니다.',
      );
    }
    if (cartState.isLoading || cartState.isIdle) {
      return const AppStateView.loading(title: '장바구니를 불러오고 있습니다');
    }
    if (cartState.hasError) {
      final Object? error = cartState.error;
      final String message = error is AppException ? error.message : '장바구니를 불러오지 못했습니다.';
      return AppStateView.error(message: message);
    }
    final List<CartItem> items = cartState.data ?? const <CartItem>[];
    if (items.isEmpty) {
      return const AppStateView.empty(title: '장바구니가 비어 있습니다');
    }

    return Column(
      spacing: 16,
      children: <Widget>[for (final CartItem item in items) _CartInventoryRow(item: item)],
    );
  }
}

class _CartInventoryRow extends StatelessWidget {
  const _CartInventoryRow({required this.item});

  final CartItem item;

  // Same reasoning as CustomerLookupScreen's cart row: image + status
  // column + primary button together need more width than a narrow
  // viewport leaves once the name column is squeezed to nothing. No
  // narrower Figma variant exists, so this app stacks the trailing group
  // under the leading content below this width as its own responsive
  // addition.
  static const double _rowBreakpoint = 480;

  @override
  Widget build(BuildContext context) {
    final bool inStock = item.inventory.currentStoreInStock;
    final String statusLabel = inStock ? '현재 매장 보유' : '선택 컬러 미보유';
    final String chipLabel = inStock ? '재고 확인됨' : '재고 없음';
    final String actionLabel = inStock ? '제품 확인하기' : item.actionButtonLabel;

    final Widget leading = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: 16,
      children: <Widget>[
        const StaffImagePlaceholder.square(size: 72),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4,
            children: <Widget>[
              Text(item.productName, style: StaffText.body12, overflow: TextOverflow.ellipsis),
              Text(
                '컬러: ${item.color} · SKU: ${item.skuId}',
                style: StaffText.meta11,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );

    final Widget trailing = Wrap(
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 8,
      children: <Widget>[
        Column(
          spacing: 4,
          children: <Widget>[
            Text(statusLabel, style: StaffText.meta11),
            StaffButton(label: chipLabel, variant: StaffButtonVariant.chip, onPressed: null),
          ],
        ),
        StaffButton(label: actionLabel, variant: StaffButtonVariant.primary, onPressed: () {}),
      ],
    );

    return SectionCard(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          if (constraints.maxWidth >= _rowBreakpoint) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              spacing: 16,
              children: <Widget>[Expanded(child: leading), trailing],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 8,
            children: <Widget>[leading, Align(alignment: Alignment.centerRight, child: trailing)],
          );
        },
      ),
    );
  }
}
