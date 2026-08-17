import 'package:flutter/material.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../utils/app_config.dart';
import '../utils/decision_result_validator.dart';
import '../utils/staff_design_tokens.dart';
import '../widgets/app_state_view.dart';
import '../widgets/section_card.dart';
import '../widgets/staff_app_shell.dart';
import '../widgets/staff_button.dart';
import '../widgets/staff_image_placeholder.dart';
import 'last_intent_completion_screen.dart';

/// Figma node 14:1785 "Last Intent Card". Matches Figma's two-column card
/// layout/copy where real data exists (product summary + live inventory
/// booleans from [CartItem.inventory], and [DecisionResult]'s own
/// coreConditions/reason/difference/nextAction fields). Figma's "재고 및
/// 입고 정보" chips read live inventory instead of the wireframe's canned
/// "확인 필요"/"정보 없음" placeholders, since that data already exists.
///
/// Issue #13/#14 AC: exactly ONE next action, ever — no result-type badges,
/// no "BEST MATCH"/적합도/순위, no listing multiple recommended products or
/// paths. `recommendedProduct` decides which ONE of "제안 제품" (product) vs
/// "확보 경로" (`pathDescription`) renders; both never show together, and
/// there is exactly one CTA button (`actionButtonLabel`) that now calls
/// `execute()` (Issue #14) — before any of this renders,
/// [DecisionResultValidator] checks the result for forbidden language.
class LastIntentCardScreen extends StatefulWidget {
  const LastIntentCardScreen({required this.customer, required this.cartItem, super.key});

  final Customer customer;
  final CartItem cartItem;

  @override
  State<LastIntentCardScreen> createState() => _LastIntentCardScreenState();
}

class _LastIntentCardScreenState extends State<LastIntentCardScreen> {
  bool _executing = false;

  // MockSegueRepository resolves near-instantly, so without an artificial
  // floor the loading state would flash by too fast to see — same
  // rationale as every other AI-adapter step in this flow.
  static const Duration _minExecutingDuration = Duration(milliseconds: 600);

  static const double _twoColumnBreakpoint = 900;

  Future<void> _handleExecute(LastIntentSessionController session) {
    return _runAndMaybeNavigate(session, session.execute);
  }

  // Issue #15: retries ONLY the local/mock save (not execute() again) when
  // execute() already succeeded but recordConsultationResult() failed —
  // re-running execute() here would risk a duplicate real-world request.
  Future<void> _handleRetrySave(LastIntentSessionController session) {
    return _runAndMaybeNavigate(session, session.retrySaveConsultationResult);
  }

  Future<void> _runAndMaybeNavigate(
    LastIntentSessionController session,
    Future<void> Function() action,
  ) async {
    if (_executing) {
      return; // AC: CTA/재시도 중복 클릭·중복 요청 금지.
    }
    setState(() => _executing = true);
    final Stopwatch stopwatch = Stopwatch()..start();
    await action();
    final Duration remaining = _minExecutingDuration - stopwatch.elapsed;
    if (remaining > Duration.zero) {
      await Future<void>.delayed(remaining);
    }
    if (!mounted) {
      return;
    }
    setState(() => _executing = false);
    // AC: 요청 접수(execute)와 결과 저장(local store) 둘 다 성공해야 완료
    // 화면으로 이동한다 — 저장이 아직 실패/미완료면 Card 화면에 남아 해당 에러를
    // 보여준다 (완료된 척 다음 단계로 넘어가지 않는다).
    if (session.state.executionResponse != null && session.state.resultSaveState.hasData) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => LastIntentCompletionScreen(
            customer: widget.customer,
            cartItem: widget.cartItem,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final LastIntentSessionController session = LastIntentSessionScope.of(
      context,
    ).sessionFor(customer: widget.customer, cartItem: widget.cartItem);

    return StaffAppShell(
      currentRoute: AppRoutes.lastIntentIntro,
      body: ListenableBuilder(
        listenable: session,
        builder: (BuildContext context, Widget? _) {
          if (_executing || session.state.executionState.isLoading) {
            // Issue #15: two chained mock calls, distinguishable copy for
            // each so the CA sees WHAT is actually in flight.
            final String title = session.state.executionState.isLoading
                ? '요청을 접수하고 있습니다'
                : '상담 결과를 저장하고 있습니다';
            return AppStateView.loading(title: title);
          }

          if (session.state.executionState.hasError) {
            return AppStateView.error(
              message: '요청 접수에 실패했습니다. 다시 시도해 주세요.',
              onAction: () => _handleExecute(session),
            );
          }

          if (session.state.resultSaveState.hasError) {
            // AC: 저장 실패 시 완료된 척 넘어가지 않고, Card/실행 결과는 유지한 채
            // 저장만 재시도한다.
            return AppStateView.error(
              message: '상담 결과 저장에 실패했습니다. 다시 시도해 주세요.',
              onAction: () => _handleRetrySave(session),
            );
          }

          final DecisionResult? result = session.state.decisionResult;
          if (result == null) {
            return const Text('생성된 Last Intent Card가 없습니다.', style: StaffText.body12);
          }

          // AC: 금지 표현(품절/대체품/BEST MATCH/적합도 %)이 포함된 raw 결과를 화면에
          // 그대로 노출하지 않는다 — 렌더링 이전에 검증하고, 걸리면 안전한
          // fallback(에러+재시도)으로 대체한다.
          if (DecisionResultValidator.hasForbiddenLanguage(result)) {
            return AppStateView.error(
              title: '결과를 표시할 수 없습니다',
              message: '이 상담 결과에는 표시할 수 없는 표현이 포함되어 있습니다. 다시 시도해 주세요.',
              onAction: () => _handleExecute(session),
            );
          }

          return Column(
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
                  final List<Widget> right = _rightColumn(session, result);
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
          );
        },
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
            const Text('원제품 정보', style: StaffText.header16SemiBold),
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
                      Text(widget.cartItem.productName, style: StaffText.body12),
                      Text(
                        '컬러: ${widget.cartItem.color} · 사이즈: ${widget.cartItem.size} · SKU: ${widget.cartItem.skuId}',
                        style: StaffText.meta11,
                      ),
                      StaffButton(
                        label: widget.cartItem.inventory.currentStoreInStock ? '현재 매장 보유' : '현재 매장 미보유',
                        variant: StaffButtonVariant.chip,
                        onPressed: null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: <Widget>[
            const Text('고객 핵심 조건', style: StaffText.header16SemiBold),
            Text(result.coreConditions, style: StaffText.body12),
          ],
        ),
      ),
      SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: <Widget>[
            const Text('선정 이유', style: StaffText.header16SemiBold),
            Text(result.reason, style: StaffText.body12),
          ],
        ),
      ),
      SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: <Widget>[
            const Text('원제품과 제안 결과의 차이', style: StaffText.header16SemiBold),
            Text(result.difference, style: StaffText.body12),
          ],
        ),
      ),
    ];
  }

  List<Widget> _rightColumn(LastIntentSessionController session, DecisionResult result) {
    final InventoryStatus inventory = widget.cartItem.inventory;
    final ProductSkuSummary? recommended = result.recommendedProduct;
    return <Widget>[
      SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: <Widget>[
            const Text('재고 및 입고 정보', style: StaffText.header16SemiBold),
            _InventoryRow(
              label: '현재 매장 재고 (${widget.cartItem.color})',
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
      // AC: recommendedProduct가 있으면 제안 "제품"을, 없으면 pathDescription
      // 기반 확보 "경로"를 보여준다 — 절대 둘 다 보여주거나 여러 개를 나열하지 않는다.
      SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: <Widget>[
            Text(recommended != null ? '제안 제품' : '확보 경로', style: StaffText.header16SemiBold),
            if (recommended != null)
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
                        Text(recommended.productName, style: StaffText.body12),
                        Text(
                          '컬러: ${recommended.color} · 사이즈: ${recommended.size} · SKU: ${recommended.skuId}',
                          style: StaffText.meta11,
                        ),
                      ],
                    ),
                  ),
                ],
              )
            else
              Text(result.pathDescription, style: StaffText.body12),
          ],
        ),
      ),
      SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: <Widget>[
            const Text('가장 적합한 다음 행동', style: StaffText.header16SemiBold),
            Text(result.nextAction, style: StaffText.body12),
            const Text(
              '이 요청은 실제 예약 또는 제품 이동 완료가 아니라 Client Advisor 후속 확인 요청 접수 상태입니다.',
              style: StaffText.meta11,
            ),
            // AC: 실행 CTA는 actionButtonLabel 하나만 — 다른 결과 유형으로 전환하는
            // 버튼이나 대체 경로 목록은 만들지 않는다.
            StaffButton(
              label: result.actionButtonLabel,
              variant: StaffButtonVariant.primary,
              onPressed: () => _handleExecute(session),
            ),
          ],
        ),
      ),
    ];
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
