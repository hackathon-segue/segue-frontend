import 'package:flutter/material.dart';

import '../utils/app_config.dart';
import '../utils/staff_design_tokens.dart';
import '../widgets/section_card.dart';
import '../widgets/staff_app_shell.dart';
import '../widgets/staff_button.dart';

/// Figma node 14:765 "직원용 웹 홈".
///
/// API.md/SCHEMA.md have no endpoint for consultation stats or an active
/// consultation list (상담 이력 is explicitly TASK.md P1), so the stat
/// numbers, "진행 중인 상담" tiles and their labels are static placeholders
/// copied verbatim from the Figma reference rather than live data.
class StaffHomeScreen extends StatelessWidget {
  const StaffHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StaffAppShell(
      currentRoute: AppRoutes.staffHome,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 16,
        children: <Widget>[
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final Widget titleColumn = const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 4,
                children: <Widget>[
                  Text('MCM 상담 지원', style: StaffText.title20Bold),
                  Text('고객이 앱에서 선택한 제품과 조건을 매장 상담으로 연결합니다.', style: StaffText.body12),
                ],
              );
              final Widget button = StaffButton(
                label: '고객 조회 시작',
                variant: StaffButtonVariant.primary,
                onPressed: () => Navigator.of(context).pushNamed(AppRoutes.customerLookup),
              );
              // A plain Row here overflows once the title/description column
              // and the button no longer both fit on one line (e.g. narrow
              // tablet portrait widths) — the button drops below the title
              // instead of forcing an overflow.
              if (constraints.maxWidth < 360) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 12,
                  children: <Widget>[titleColumn, button],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[Expanded(child: titleColumn), button],
              );
            },
          ),
          // IntrinsicHeight gives the stretch-aligned Row a bounded height to
          // stretch to (it would otherwise be infinite inside the shell's
          // scrollable content column) so the three stat cards render at
          // equal height.
          const IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 20,
              children: <Widget>[
                Expanded(child: _StatCard(value: '8', label: '오늘 상담', description: '완료된 상담')),
                Expanded(child: _StatCard(value: '2', label: '진행 중', description: '현재 상담 세션')),
                Expanded(child: _StatCard(value: '5', label: '요청 접수', description: '후속 확인 대기')),
              ],
            ),
          ),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: <Widget>[
              Text('진행 중인 상담', style: StaffText.header16SemiBold),
              SectionCard(
                child: _ActiveConsultationRow(
                  customer: '김지은 고객',
                  product: 'Himmel 백팩 · 블랙',
                  status: '고객 의도 확인 중',
                ),
              ),
              SectionCard(
                child: _ActiveConsultationRow(
                  customer: '박민준 고객',
                  product: 'Stark 클러치 · 오그넘',
                  status: '다음 행동 제안 완료',
                ),
              ),
            ],
          ),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: <Widget>[
              Text('상담 진행 흐름', style: StaffText.header16SemiBold),
              _ConsultationFlowRow(
                steps: <_FlowStep>[
                  _FlowStep(number: '1', title: '고객 조회', description: '회원 정보 또는 휴대전화 번호 입력'),
                  _FlowStep(
                    number: '2',
                    title: '장바구니·재고 확인',
                    description: '앱 선택 제품과 현재 매장 재고 비교',
                  ),
                  _FlowStep(number: '3', title: '고객 의도 확인', description: '핵심 구매 조건 구조화'),
                  _FlowStep(number: '4', title: '다음 행동 제안', description: '검증된 결과 유형 확인'),
                ],
              ),
            ],
          ),
          const SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 6,
              children: <Widget>[
                Text('상담 데이터 이용 안내', style: StaffText.header16SemiBold),
                Text('고객 장바구니 조회 및 상담 결과 저장 전 데이터 이용 목적과 범위를 안내하고 동의 여부를 기록합니다.',
                    style: StaffText.body12),
                Text(
                  '동의한 고객에게만 장바구니 조회, 상담 결과 저장, 고객 앱 재확인이 제공됩니다. '
                  '모든 상담 결과는 검증된 재고·제품 정보만 사용하며, 확인되지 않은 재고는 확정 제안에서 제외됩니다.',
                  style: StaffText.meta11,
                ),
              ],
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label, required this.description});

  final String value;
  final String label;
  final String description;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: <Widget>[
          Text(label, style: StaffText.meta11),
          Text(value, style: StaffText.title20Bold),
          Text(description, style: StaffText.meta11),
        ],
      ),
    );
  }
}

class _ActiveConsultationRow extends StatelessWidget {
  const _ActiveConsultationRow({
    required this.customer,
    required this.product,
    required this.status,
  });

  final String customer;
  final String product;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4,
            children: <Widget>[
              Text(customer, style: StaffText.body12),
              Text(product, style: StaffText.meta11),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            status,
            style: StaffText.meta11,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

class _FlowStep {
  const _FlowStep({required this.number, required this.title, required this.description});

  final String number;
  final String title;
  final String description;
}

class _ConsultationFlowRow extends StatelessWidget {
  const _ConsultationFlowRow({required this.steps});

  final List<_FlowStep> steps;

  // Below this width, 4 equal flex columns get too cramped to read; the
  // Figma reference (1440px frame) has no narrower variant to match, so
  // this fallback breakpoint is this app's own responsive addition.
  static const double _rowBreakpoint = 700;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxWidth >= _rowBreakpoint) {
          // Matches Figma exactly: 4 equal-width flex ("Fill") columns
          // separated by arrow glyphs, all with a uniform 16px gap.
          final List<Widget> children = <Widget>[];
          for (int i = 0; i < steps.length; i++) {
            children.add(Expanded(child: _FlowStepCard(step: steps[i])));
            if (i != steps.length - 1) {
              children.add(const Text('→', style: StaffText.body12));
            }
          }
          return IntrinsicHeight(
            child: Row(
              spacing: 16,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          );
        }

        final List<Widget> children = <Widget>[];
        for (int i = 0; i < steps.length; i++) {
          children.add(SizedBox(width: 220, child: _FlowStepCard(step: steps[i])));
          if (i != steps.length - 1) {
            children.add(const Text('→', style: StaffText.body12));
          }
        }
        return Wrap(
          spacing: 16,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: children,
        );
      },
    );
  }
}

class _FlowStepCard extends StatelessWidget {
  const _FlowStepCard({required this.step});

  final _FlowStep step;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: <Widget>[
          Text(step.number, style: StaffText.body12, textAlign: TextAlign.center),
          Text(step.title, style: StaffText.body12, textAlign: TextAlign.center),
          Text(step.description, style: StaffText.meta11, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
