import 'package:flutter/material.dart';

import '../providers/providers.dart';
import '../utils/app_config.dart';
import '../utils/segue_card_tokens.dart';
import '../widgets/segue_card_shell.dart';

/// Figma node 89:1386 "동의 안내 화면" (Issue #48 — this screen's own visual
/// rebuild, superseding the previous 14:964-based build). Uses the shared
/// [SegueHeaderOnlyShell] confirmed for this sidebar-less screen family
/// (89:1386/98:1810 both lack the usual [TabletNavSidebar]) — no header
/// markup is built here.
///
/// The three "동의 범위" rows start unchecked and the CA must tap each one
/// to confirm it before "동의하고 쇼핑백 확인" switches from outline to filled
/// (89:1482 confirms the filled/checked-state color) — unchanged from the
/// previous build's gating logic. SCHEMA.md's `customer_consent` still only
/// stores one overall status/scope per customer — these three checks are a
/// client-side confirmation gate, not three separate persisted fields.
class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key});

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  final List<bool> _scopeChecked = <bool>[false, false, false];

  bool get _allScopeChecked => _scopeChecked.every((bool checked) => checked);

  @override
  Widget build(BuildContext context) {
    final StaffWebSessionController controller = StaffSessionScope.of(context);

    return SegueHeaderOnlyShell(
      heading: '상담 데이터 이용 동의',
      body: ListenableBuilder(
        listenable: controller,
        builder: (BuildContext context, Widget? _) {
          final bool isSubmitting = controller.state.consentState.isLoading;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const _ConsentBox(
                height: 199,
                title: '수집 및 이용 목적',
                child: _BulletList(<String>[
                  '고객 앱 쇼핑백 제품, 컬러 정보 조회 및 매장 재고 확인',
                  'AI 기반 구매 조건 분석 및 다음 행동 추천',
                  '상담 결과(추천 제품, 경로, 핵심 조건, 결과 유형) 고객 계정에 저장',
                  '저장된 상담 결과 고객 모바일 앱 재확인 제공',
                ]),
              ),
              // Figma: box1 bottom 177+199=376 → box2 top 395 = 19px.
              const SizedBox(height: 19),
              _ConsentBox(
                height: 186,
                title: '동의 범위',
                backgroundColor: SegueCardColors.scopeBoxBg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SegueCheckboxRow(
                      label: '회원 쇼핑백 조회',
                      description: '고객 앱에 담긴 제품, 컬러 목록을 이번 상담에서 불러옵니다.',
                      checked: _scopeChecked[0],
                      onChanged: (bool value) => setState(() => _scopeChecked[0] = value),
                    ),
                    // Figma: row1 text top 465 → row2 text top 499 = 34px.
                    const SizedBox(height: 4),
                    SegueCheckboxRow(
                      label: '상담 결과 저장',
                      description: '상담 종료 후 결과를 고객 계정에 저장합니다.',
                      checked: _scopeChecked[1],
                      onChanged: (bool value) => setState(() => _scopeChecked[1] = value),
                    ),
                    const SizedBox(height: 4),
                    SegueCheckboxRow(
                      label: '고객 모바일 재확인',
                      description: '저장된 결과를 고객 앱에서 다시 확인할 수 있도록 제공합니다.',
                      checked: _scopeChecked[2],
                      onChanged: (bool value) => setState(() => _scopeChecked[2] = value),
                    ),
                  ],
                ),
              ),
              // Figma: box2 bottom 395+186=581 → box3 top 600 = 19px.
              const SizedBox(height: 19),
              const _ConsentBox(
                height: 141,
                title: '유의사항',
                child: _BulletList(<String>[
                  '동의하지 않을 시 회원 정보 기반 조회 및 상담 결과 저장이 제공되지 않습니다.',
                  '수집된 정보는 이번 상담 목적으로만 사용되며 제3자에게 제공되지 않습니다.',
                ]),
              ),
              // Figma: box3 bottom 600+141=741 → buttons top 769 = 28px.
              const SizedBox(height: 28),
              Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 13,
                runSpacing: 8,
                children: <Widget>[
                  SegueLargeButton(
                    label: '동의하지 않음',
                    filled: false,
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            await controller.submitConsent(false);
                            if (context.mounted) {
                              Navigator.of(context).pushNamed(AppRoutes.customerConsentDeclined);
                            }
                          },
                  ),
                  SegueLargeButton(
                    label: '동의하고 쇼핑백 확인',
                    // Figma (89:1386 outline / 89:1482 filled): outline
                    // until all three 동의 범위 rows are checked, filled once
                    // they are.
                    filled: _allScopeChecked,
                    onPressed: (!_allScopeChecked || isSubmitting)
                        ? null
                        : () async {
                            await controller.submitConsent(true);
                            if (context.mounted) {
                              Navigator.of(context).pushNamed(AppRoutes.cartInventory);
                            }
                          },
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ConsentBox extends StatelessWidget {
  const _ConsentBox({
    required this.height,
    required this.title,
    required this.child,
    this.backgroundColor = Colors.white,
  });

  final double height;
  final String title;
  final Widget child;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      // A hard-fixed height matching Figma exactly overflows once the
      // bullet text wraps to more lines at narrower widths than the 1440
      // reference — minHeight keeps the exact reference-width height while
      // letting the box grow instead of clipping when content needs more
      // room.
      constraints: BoxConstraints(minHeight: height),
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 20),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: backgroundColor == Colors.white
            ? Border.all(color: SegueCardColors.border, width: 2)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(title, style: SegueCardText.boxHeading26),
          // Figma: title bottom ~+36 → content top = 19px gap on every box.
          const SizedBox(height: 19),
          child,
        ],
      ),
    );
  }
}

class _BulletList extends StatelessWidget {
  const _BulletList(this.items);

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (final String item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('•', style: SegueCardText.bulletBody18),
                const SizedBox(width: 12),
                Expanded(child: Text(item, style: SegueCardText.bulletBody18)),
              ],
            ),
          ),
      ],
    );
  }
}
