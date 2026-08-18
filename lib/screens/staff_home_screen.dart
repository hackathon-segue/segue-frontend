import 'package:flutter/material.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../utils/app_config.dart';
import '../utils/segue_card_tokens.dart';
import '../widgets/segue_card_shell.dart';
import '../widgets/segue_info_card.dart';

/// Figma node 89:1196 "직원용 웹 홈 -> 고객 조회 이전" (empty state) and 80:776
/// "직원용 웹 홈 -> 고객 조회 이후" (active-consultation state) — Issue #48's
/// visual rebuild of the Home screen, superseding the previous 14:765-based
/// build. Uses the shared [SegueCardShell]/[TabletHeader]/[TabletNavSidebar]
/// confirmed in Issue #48's shell pass — no header/menu markup is built here.
///
/// API.md/SCHEMA.md still have no endpoint for consultation stats or an
/// active-consultation list (상담 이력 is TASK.md P1), so the "오늘 완료한 내
/// 상담"/"처리 대기" counters stay the same kind of static placeholder the
/// previous build already used (see git history) — "현재 진행 중 상담" and the
/// "진행 중인 상담" panel below it are wired to the real
/// [LastIntentSessionManager.firstActiveSession] this app already tracks,
/// switching between 89:1196's empty state ("현재 없음") and 80:776's
/// customer/product card the same way the real session count naturally
/// does — never a hardcoded toggle.
///
/// The old 14:765-era "상담 진행 흐름" 4-step guide and "상담 데이터 이용 안내"
/// panel don't exist in either Figma node, so they're dropped rather than
/// kept as leftovers — both were purely decorative static content with no
/// controller/state/API tie of their own.
class StaffHomeScreen extends StatelessWidget {
  const StaffHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final LastIntentSessionManager manager = LastIntentSessionScope.of(context);
    final int activeCount = manager.activeCount;
    final LastIntentSessionState? activeSession = manager.firstActiveSession;

    return SegueCardShell(
      pageTitle: 'SEGUE HOME',
      activeMenuItem: TabletMenuItem.home,
      sessionCount: activeCount,
      subtitle: '고객이 앱에서 선택한 제품과 조건을 매장 상담으로 연결해 끊김없는 경험을 이어갑니다.',
      // Figma (89:1196): subtitle bottom 146+19=165 → summary row top 205 =
      // 40px — NOT the 28px the Last Intent flow screens use.
      bodyTopGap: 40,
      titleTrailing: SegueStartButton(
        label: 'START SEGUE',
        onPressed: () => Navigator.of(context).pushNamed(AppRoutes.customerLookup),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final List<Widget> cards = <Widget>[
                _SummaryCard(
                  label: '현재 진행 중 상담',
                  count: activeCount,
                  backgroundColor: SegueCardColors.previewPanelBg,
                ),
                const _SummaryCard(
                  label: '오늘 완료한 내 상담',
                  count: 3,
                  backgroundColor: SegueCardColors.panelBg,
                ),
                const _SummaryCard(
                  label: '처리 대기',
                  count: 3,
                  backgroundColor: SegueCardColors.panelBg,
                ),
              ];
              // Figma: 3 cards, 340px wide, 46px gaps (340*3+46*2=1112, the
              // full reference content width) — Expanded keeps that ratio at
              // other widths instead of hardcoding 340.
              if (constraints.maxWidth >= 700) {
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      for (int i = 0; i < cards.length; i++) ...<Widget>[
                        if (i > 0) const SizedBox(width: 46),
                        Expanded(child: cards[i]),
                      ],
                    ],
                  ),
                );
              }
              return Column(
                children: <Widget>[
                  for (final Widget c in cards) ...<Widget>[c, const SizedBox(height: 16)],
                ],
              );
            },
          ),
          // Figma: summary row bottom 205+121=326 → "진행 중인 상담" top 362 = 36px.
          const SizedBox(height: 36),
          const Text('진행 중인 상담', style: SegueCardText.screenTitle22),
          // Figma: title bottom 362+31=393 → details box top 405 = 12px.
          const SizedBox(height: 12),
          if (activeSession == null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: SegueCardColors.border, width: 2),
              ),
              child: const Text('현재 없음', style: SegueCardText.emptyState20),
            )
          else
            _InProgressConsultationCard(session: activeSession),
          // Figma: footer image top is a fixed y=558 in both 89:1196 and
          // 80:776 — the empty-state box (68 tall) ends well above that
          // (405+68=473, 85px gap), but the active card (238 tall) ends at
          // 405+238=643, PAST y=558, so in Figma's raw canvas the card
          // actually overlaps/covers the image's top 85px (the card is
          // later in z-order, painted on top). A negative gap isn't
          // representable in normal document flow, so the only faithful
          // conversion is 0 — the card's bottom flows directly into the
          // (still-347px-tall) image, exactly matching what's actually
          // visible once the overlapped portion is accounted for.
          SizedBox(height: activeSession == null ? 85 : 0),
          const _HomeFooterImage(),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.label, required this.count, required this.backgroundColor});

  final String label;
  final int count;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      // Figma: card height 121, no fixed width (Expanded above matches the
      // aspect ratio at the 1440 reference width instead).
      height: 121,
      color: backgroundColor,
      // Figma: label inset (21.1, 15); counter inset (right 21, bottom 14) —
      // both measured directly, not rounded to match each other.
      padding: const EdgeInsets.fromLTRB(21, 15, 21, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: SegueCardText.statLabel13, maxLines: 1, overflow: TextOverflow.ellipsis),
          const Spacer(),
          Align(
            alignment: Alignment.centerRight,
            child: Text('$count', style: SegueCardText.statCounter40),
          ),
        ],
      ),
    );
  }
}

/// Figma (80:776) "Details Container" active-consultation card — customer
/// info + product info + a product photo, replacing 89:1196's "현재 없음"
/// empty state once a Last Intent session exists. All content is sourced
/// from the real [LastIntentSessionState] the manager already tracks
/// (never fabricated example values).
class _InProgressConsultationCard extends StatelessWidget {
  const _InProgressConsultationCard({required this.session});

  final LastIntentSessionState session;

  @override
  Widget build(BuildContext context) {
    final Customer? customer = session.customer;
    final CartItem? cartItem = session.selectedCartItem;
    if (customer == null || cartItem == null) {
      // Cannot happen in practice — start() always sets both — but the
      // fields are nullable on the model, so this stays a safe no-op
      // fallback rather than asserting.
      return const SizedBox.shrink();
    }
    final ProductSkuSummary? recommended = session.decisionResult?.recommendedProduct;
    final String segueProductName = recommended?.productName ?? cartItem.productName;

    return Container(
      width: double.infinity,
      height: 238,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: SegueCardColors.border, width: 2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Padding(
              // Figma: text content inset (23, 19) from the box's top-left —
              // NOT the same top inset the product image uses (0, flush).
              padding: const EdgeInsets.fromLTRB(23, 19, 0, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // Figma: "제품 정보" column starts at box-relative
                      // x=283 regardless of customer content width —
                      // fixed 260 (283-23) column width replicates that.
                      SizedBox(
                        width: 260,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Text('고객 정보', style: SegueCardText.sectionLabel13),
                            // Figma: label bottom 424+18=442 → name top 460 = 18px.
                            const SizedBox(height: 18),
                            // Figma: name left 321 vs label left 317 = 4px indent.
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Text(customer.name, style: SegueCardText.customerName22),
                            ),
                            // Figma: name bottom 460+31=491 → details top 504 = 13px.
                            const SizedBox(height: 13),
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: _DetailRow(
                                label: '회원번호',
                                value: '${customer.id}',
                                gap: '   ',
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: _DetailRow(
                                label: '전화번호',
                                value: customer.phoneNumber,
                                gap: '   ',
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Text('제품 정보', style: SegueCardText.sectionLabel13),
                            const SizedBox(height: 18),
                            _DetailRow(label: '희망 제품', value: cartItem.productName, gap: '  '),
                            _DetailRow(label: 'SEGUE 제품', value: segueProductName, gap: '  '),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Figma: details block bottom 504+48=552 → button row top
                  // 580 = 28px.
                  const SizedBox(height: 28),
                  const Row(
                    children: <Widget>[
                      SegueCompactButton(
                        label: '쇼핑백 확인',
                        backgroundColor: SegueCardColors.compactButtonSecondaryBg,
                        // No resume/deep-link semantics exist yet for this
                        // brand-new interaction (no prior screen ever
                        // needed to jump back into a specific customer's
                        // cart from Home) — left inactive rather than
                        // guessing a navigation target.
                        onPressed: null,
                      ),
                      // Figma: button1 right 321+96=417 → button2 left 429 = 12px.
                      SizedBox(width: 12),
                      SegueCompactButton(
                        label: '상담 이어서 진행',
                        backgroundColor: SegueCardColors.ctaBg,
                        showArrow: true,
                        onPressed: null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Figma: image right edge 986+411=1397 → box right 294+1112=1406 = 9px.
          Padding(
            padding: const EdgeInsets.only(right: 9),
            child: SegueProductImage(
              imageUrl: recommended?.imageUrl ?? cartItem.imageUrl,
              width: 411,
              height: 231,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, required this.gap});

  final String label;
  final String value;
  final String gap;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: <InlineSpan>[
          TextSpan(text: label, style: SegueCardText.detailLabel16),
          TextSpan(text: gap, style: SegueCardText.detailLabel16),
          TextSpan(text: value, style: SegueCardText.detailValue16),
        ],
      ),
    );
  }
}

/// Figma (89:1196) "Footer Image" — a decorative product photo band with a
/// 50% base opacity and a white-to-transparent top fade (`from-white` at
/// the 4.6% gradient stop, `to-transparent` by 100%).
class _HomeFooterImage extends StatelessWidget {
  const _HomeFooterImage();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 347,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Opacity(
            opacity: 0.5,
            child: Image.asset('assets/images/home_footer.png', fit: BoxFit.cover),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[Colors.white, Colors.white.withValues(alpha: 0)],
                stops: const <double>[0.046, 1.0],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
