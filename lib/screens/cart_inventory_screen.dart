import 'package:flutter/material.dart';

import '../exceptions/app_exception.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../utils/app_config.dart';
import '../utils/inventory_display.dart';
import '../utils/staff_design_tokens.dart';
import '../widgets/app_state_view.dart';
import '../widgets/section_card.dart';
import '../widgets/staff_app_shell.dart';
import '../widgets/staff_button.dart';
import '../widgets/staff_image_placeholder.dart';
import 'last_intent_intro_screen.dart';

/// Figma node 14:1051 "장바구니·재고 확인 화면" — Issue #8's main screen.
///
/// The shell/consent plumbing was built ahead of schedule in Issue #7
/// (this screen was already reachable from [ConsentScreen]); Issue #8 adds
/// the actual SKU-status action wiring: "제품 확인하기" navigates to
/// [GeneralProductCheckScreen], "Last Intent 시작" hands the selected
/// cart item/SKU off to [LastIntentSessionController]. Reuses the
/// already-loaded customer/cart/consent state from
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
                  Expanded(
                    child: Text('장바구니 · 재고 확인', style: StaffText.title20Bold),
                  ),
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
              _AllLastIntentCompleteBanner(cartState: state.cartState),
              const SectionCard(
                child: Wrap(
                  spacing: 8,
                  children: <Widget>[
                    Text('재고 안내', style: StaffText.meta11),
                    Text(
                      '현재 매장 재고 정보는 확인 기준 시점 이후 변동될 수 있습니다. '
                      '타 매장 보유와 입고 예정은 확인 필요 상태일 때 구매 가능 경로로 확정하지 않습니다.',
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
    final String consentDate = consent != null
        ? formatDateTime(consent.consentedAt)
        : '-';
    final int itemCount = state.cartState.data?.length ?? 0;

    // Figma (14:1051 metadata) lays this out as 6 EQUAL-width flex columns
    // (5 info columns + 1 invisible spacer between "휴대전화" and "상담 동의
    // 완료"), not a left-flowing Wrap — so the last two columns must land
    // flush against the card's right edge, not directly after "휴대전화".
    final List<Widget> columns = <Widget>[
      _InfoColumn(
        label: '고객',
        value: customer.name,
        valueStyle: StaffText.header16SemiBold,
      ),
      _InfoColumn(
        label: '회원번호',
        value: 'MCM-${customer.id.toString().padLeft(5, '0')}',
      ),
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
              children: <Widget>[
                for (final Widget column in columns) Expanded(child: column),
              ],
            );
          }
          // Narrow-viewport fallback (this app's own responsive addition,
          // not present in the 1440px Figma reference): drop the equal-flex
          // grid and just flow the 5 real columns, skipping the invisible
          // spacer which has no purpose without the flex distribution.
          return Wrap(
            spacing: 24,
            runSpacing: 12,
            children: <Widget>[
              for (final Widget column in columns)
                if (column is! SizedBox) column,
            ],
          );
        },
      ),
    );
  }
}

String formatDateTime(DateTime dt) {
  return '${dt.year}년 ${dt.month}월 ${dt.day}일 '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
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
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      spacing: 4,
      children: <Widget>[
        Text(label, style: StaffText.meta11),
        Text(value, style: valueStyle),
      ],
    );
  }
}

class _InventoryCheckPanel extends StatelessWidget {
  const _InventoryCheckPanel({required this.checks});

  final List<InventoryCheckPresentation> checks;

  @override
  Widget build(BuildContext context) {
    final bool hasUnconfirmed = checks.any(
      (InventoryCheckPresentation check) => check.needsVerification,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: <Widget>[
        const Divider(height: 1, color: StaffColors.cardBorder),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            const Text('재고/입고 확인 상태', style: StaffText.meta11),
            if (hasUnconfirmed)
              const Text('확인 필요 정보 포함', style: StaffText.meta11),
          ],
        ),
        for (final InventoryCheckPresentation check in checks)
          _InventoryCheckLine(check: check),
        if (hasUnconfirmed)
          const Text(
            '확인 필요 또는 오래된 정보는 구매 가능 경로로 확정하지 않고 CA가 다시 확인합니다.',
            style: StaffText.meta11,
          ),
      ],
    );
  }
}

class _InventoryCheckLine extends StatelessWidget {
  const _InventoryCheckLine({required this.check});

  final InventoryCheckPresentation check;

  @override
  Widget build(BuildContext context) {
    final Widget meta = Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        _InventoryStateBadge(state: check.state, label: check.stateLabel),
        Text(check.referenceLabel, style: StaffText.meta11),
      ],
    );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxWidth < 620) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4,
            children: <Widget>[
              Text(check.label, style: StaffText.meta11),
              Text(check.value, style: StaffText.body12),
              meta,
              Text(check.note, style: StaffText.meta11),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              width: 96,
              child: Text(check.label, style: StaffText.meta11),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 4,
                children: <Widget>[
                  Text(check.value, style: StaffText.body12),
                  Text(check.note, style: StaffText.meta11),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(width: 180, child: meta),
          ],
        );
      },
    );
  }
}

class _InventoryStateBadge extends StatelessWidget {
  const _InventoryStateBadge({required this.state, required this.label});

  final InventoryCheckState state;
  final String label;

  @override
  Widget build(BuildContext context) {
    final Color color = switch (state) {
      InventoryCheckState.confirmed => const Color(0xFF15803D),
      InventoryCheckState.needsCheck => const Color(0xFFB45309),
      InventoryCheckState.stale => const Color(0xFF92400E),
      InventoryCheckState.unverified => StaffColors.muted,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(StaffRadii.chip),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(label, style: StaffText.meta11.copyWith(color: color)),
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
      final String message = error is AppException
          ? error.message
          : '장바구니를 불러오지 못했습니다.';
      return AppStateView.error(message: message);
    }
    final List<CartItem> items = cartState.data ?? const <CartItem>[];
    if (items.isEmpty) {
      return const AppStateView.empty(title: '장바구니가 비어 있습니다');
    }

    return Column(
      spacing: 16,
      children: <Widget>[
        for (final CartItem item in items)
          _CartInventoryRow(customer: customer, item: item),
      ],
    );
  }
}

/// Issue #9 AC: "상담 완료 여부 표시" — a small colored badge distinguishing
/// in-progress vs. request-accepted Last Intent sessions. No Figma design exists
/// for this yet; colors here are a functional placeholder only.
class _SessionStatusBadge extends StatelessWidget {
  const _SessionStatusBadge({required this.label, required this.completed});

  final String label;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final Color color = completed
        ? const Color(0xFF15803D)
        : const Color(0xFFB45309);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(StaffRadii.chip),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label, style: StaffText.meta11.copyWith(color: color)),
    );
  }
}

/// Issue #9 작업 범위: "모든 상담 완료 상태 표시" — once every out-of-stock item's
/// own independent Last Intent request is accepted, surface that as one
/// aggregate banner rather than requiring the CA to check each row.
class _AllLastIntentCompleteBanner extends StatelessWidget {
  const _AllLastIntentCompleteBanner({required this.cartState});

  final AsyncValue<List<CartItem>> cartState;

  @override
  Widget build(BuildContext context) {
    final LastIntentSessionManager manager = LastIntentSessionScope.of(context);
    return ListenableBuilder(
      listenable: manager,
      builder: (BuildContext context, Widget? _) {
        final List<CartItem> outOfStockItems =
            (cartState.data ?? const <CartItem>[])
                .where((CartItem item) => !item.inventory.currentStoreInStock)
                .toList();
        final bool allComplete =
            outOfStockItems.isNotEmpty &&
            outOfStockItems.every(
              (CartItem item) => manager.isCompleted(item.skuId),
            );
        if (!allComplete) {
          return const SizedBox.shrink();
        }
        return const SectionCard(
          child: Text(
            '미보유 제품의 Last Intent 요청이 모두 접수되었습니다.',
            style: StaffText.body12,
          ),
        );
      },
    );
  }
}

class _CartInventoryRow extends StatelessWidget {
  const _CartInventoryRow({required this.customer, required this.item});

  final Customer customer;
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
    final LastIntentSessionManager lastIntentManager =
        LastIntentSessionScope.of(context);

    return ListenableBuilder(
      listenable: lastIntentManager,
      builder: (BuildContext context, Widget? _) {
        return _buildCard(context, lastIntentManager);
      },
    );
  }

  Widget _buildCard(
    BuildContext context,
    LastIntentSessionManager lastIntentManager,
  ) {
    final bool inStock = item.inventory.currentStoreInStock;
    final List<InventoryCheckPresentation> inventoryChecks = inventoryChecksFor(
      item,
    );
    // API.md/SCHEMA.md only expose a per-SKU currentStoreInStock boolean —
    // there is no field distinguishing "this color/size unavailable" from
    // "the whole product unavailable" (CLAUDE.md F2's two non-stock
    // sub-cases), so this label intentionally stays generic rather than
    // guessing which sub-case applies.
    final String statusLabel = inStock ? '현재 매장 보유' : '현재 매장 미보유';
    final String chipLabel = inStock ? '재고 확인됨' : '재고 없음';
    final String actionLabel = inStock ? '제품 확인하기' : item.actionButtonLabel;

    // Issue #9: each SKU's Last Intent session is tracked independently by
    // LastIntentSessionManager, so this row's badge only ever reflects THIS
    // item's own skuId — never a different row's in-progress/completed
    // session.
    final bool sessionStarted =
        !inStock && lastIntentManager.isStarted(item.skuId);
    final bool sessionCompleted =
        !inStock && lastIntentManager.isCompleted(item.skuId);
    final String? sessionStatusLabel = sessionCompleted
        ? '요청 접수'
        : sessionStarted
        ? '상담 진행 중'
        : null;

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
              Text(
                item.productName,
                style: StaffText.body12,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '컬러: ${item.color} · 사이즈: ${item.size}',
                style: StaffText.meta11,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'SKU: ${item.skuId} · 담은 시각: ${formatDateTime(item.savedAt)}',
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
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Text(statusLabel, style: StaffText.meta11),
            StaffButton(
              label: chipLabel,
              variant: StaffButtonVariant.chip,
              onPressed: null,
            ),
            // Issue #9 AC: "상담 완료 여부 표시" — only ever reflects this row's
            // own SKU, never another out-of-stock row's session. No Figma
            // spec exists for this badge yet, so the colors here are a
            // placeholder pending final design.
            if (sessionStatusLabel != null)
              _SessionStatusBadge(
                label: sessionStatusLabel,
                completed: sessionCompleted,
              ),
          ],
        ),
        StaffButton(
          label: actionLabel,
          variant: StaffButtonVariant.primary,
          onPressed: () {
            if (inStock) {
              Navigator.of(context).pushNamed(AppRoutes.generalProductCheck);
            } else {
              // AC: "선택된 cart item/SKU context가 상담 플로우로 전달된다" — start
              // (or resume) THIS SKU's own session here, before navigating,
              // so LastIntentIntroScreen never creates a session mid-build
              // (sessionFor() notifies listeners on creation, which is only
              // safe outside the widget build phase).
              lastIntentManager.sessionFor(customer: customer, cartItem: item);
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      LastIntentIntroScreen(customer: customer, cartItem: item),
                  settings: const RouteSettings(
                    name: AppRoutes.lastIntentIntro,
                  ),
                ),
              );
            }
          },
        ),
      ],
    );

    return SectionCard(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final Widget summary;
          if (constraints.maxWidth >= _rowBreakpoint) {
            summary = Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              spacing: 16,
              children: <Widget>[
                Expanded(child: leading),
                trailing,
              ],
            );
          } else {
            summary = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 8,
              children: <Widget>[
                leading,
                Align(alignment: Alignment.centerRight, child: trailing),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: <Widget>[
              summary,
              _InventoryCheckPanel(checks: inventoryChecks),
            ],
          );
        },
      ),
    );
  }
}
