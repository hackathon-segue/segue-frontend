import 'package:flutter/material.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../utils/app_config.dart';
import '../utils/staff_design_tokens.dart';
import '../utils/structured_intent_vocabulary.dart';
import '../widgets/app_state_view.dart';
import '../widgets/section_card.dart';
import '../widgets/staff_app_shell.dart';
import '../widgets/staff_button.dart';
import '../widgets/staff_text_field.dart';

enum _ConditionBucket { none, essential, preferred, negotiable }

/// Issue #12 "의도 수정 화면" — Figma node 14:1610. Layout/title/card-group
/// copy match Figma; the bottom two buttons use the simpler "취소"/"저장"
/// labels instead of Figma's literal "의도 요약으로 돌아가기"/"수정 내용 확인" text
/// per explicit user direction. Figma's own field list for the condition
/// cards is generic placeholder copy ("제품 카테고리", "예산 범위", "선물 여부" —
/// none of which exist on [StructuredIntent]), so those specific controls
/// are built around the real model/API.md vocabulary instead of copying
/// Figma's fictional field names verbatim.
///
/// Edits happen entirely in LOCAL widget state — nothing is written back to
/// [LastIntentSessionController] until "저장" is pressed, and "취소" simply
/// pops without ever touching the session, so the original StructuredIntent
/// is untouched by construction (no separate "restore" step needed).
///
/// The essential/preferred/negotiable condition maps are edited through
/// [StructuredIntentVocabulary]'s fixed key/value vocabulary rather than
/// free text, so a save can never produce a key/value pair the `/decide`
/// API contract wouldn't accept.
class LastIntentEditScreen extends StatefulWidget {
  const LastIntentEditScreen({
    required this.customer,
    required this.cartItem,
    super.key,
  });

  final Customer customer;
  final CartItem cartItem;

  @override
  State<LastIntentEditScreen> createState() => _LastIntentEditScreenState();
}

class _LastIntentEditScreenState extends State<LastIntentEditScreen> {
  final TextEditingController _purposeController = TextEditingController();
  final Map<String, _ConditionBucket> _buckets = <String, _ConditionBucket>{};
  final Map<String, String?> _values = <String, String?>{};
  final Set<String> _physicalCheck = <String>{};
  PurchaseUrgency _urgency = PurchaseUrgency.flexible;
  bool? _canWait;
  bool? _canVisitOtherStore;
  bool _seeded = false;
  bool _saving = false;

  // Saving itself is just a local state write (no network call), so
  // without an artificial floor the loading state would flash by too fast
  // to see — same rationale as the utterance/follow-up screens.
  static const Duration _minSavingDuration = Duration(milliseconds: 600);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reading the session here (not initState()) because
    // dependOnInheritedWidgetOfExactType (used by LastIntentSessionScope.of)
    // isn't allowed before initState() has finished.
    if (_seeded) {
      return;
    }
    _seeded = true;
    final LastIntentSessionController session = LastIntentSessionScope.of(
      context,
    ).sessionFor(customer: widget.customer, cartItem: widget.cartItem);
    final StructuredIntent intent =
        session.state.structuredIntent ?? StructuredIntent.empty();

    _purposeController.text = intent.purpose;
    for (final String key in StructuredIntentVocabulary.attributeLabels.keys) {
      if (intent.essentialConditions.containsKey(key)) {
        _buckets[key] = _ConditionBucket.essential;
        _values[key] = intent.essentialConditions[key];
      } else if (intent.preferredConditions.containsKey(key)) {
        _buckets[key] = _ConditionBucket.preferred;
        _values[key] = intent.preferredConditions[key];
      } else if (intent.negotiableConditions.containsKey(key)) {
        _buckets[key] = _ConditionBucket.negotiable;
        _values[key] = intent.negotiableConditions[key];
      } else {
        _buckets[key] = _ConditionBucket.none;
        _values[key] = null;
      }
    }
    _physicalCheck.addAll(intent.physicalCheckAttributes);
    _urgency = intent.purchaseUrgency;
    _canWait = intent.canWait;
    _canVisitOtherStore = intent.canVisitOtherStore;
  }

  @override
  void dispose() {
    _purposeController.dispose();
    super.dispose();
  }

  bool get _hasIncompleteBucket => _buckets.entries.any(
    (MapEntry<String, _ConditionBucket> e) =>
        e.value != _ConditionBucket.none && _values[e.key] == null,
  );

  Future<void> _save(LastIntentSessionController session) async {
    if (_hasIncompleteBucket || _saving) {
      return;
    }
    setState(() => _saving = true);
    final Stopwatch stopwatch = Stopwatch()..start();

    final Map<String, String> essential = <String, String>{};
    final Map<String, String> preferred = <String, String>{};
    final Map<String, String> negotiable = <String, String>{};
    for (final String key in StructuredIntentVocabulary.attributeLabels.keys) {
      final String? value = _values[key];
      if (value == null) {
        continue;
      }
      switch (_buckets[key]!) {
        case _ConditionBucket.essential:
          essential[key] = value;
        case _ConditionBucket.preferred:
          preferred[key] = value;
        case _ConditionBucket.negotiable:
          negotiable[key] = value;
        case _ConditionBucket.none:
          break;
      }
    }

    final StructuredIntent current =
        session.state.structuredIntent ?? StructuredIntent.empty();
    // Built directly (not via copyWith) because copyWith's `field ?? this.field`
    // pattern can't express "explicitly set canWait back to null (미확인)".
    session.updateStructuredIntent(
      StructuredIntent(
        purpose: _purposeController.text.trim(),
        essentialConditions: essential,
        preferredConditions: preferred,
        negotiableConditions: negotiable,
        purchaseUrgency: _urgency,
        physicalCheckAttributes: _physicalCheck.toList(),
        canWait: _canWait,
        canVisitOtherStore: _canVisitOtherStore,
        needsFollowUp: current.needsFollowUp,
        followUpReason: current.followUpReason,
      ),
    );

    final Duration remaining = _minSavingDuration - stopwatch.elapsed;
    if (remaining > Duration.zero) {
      await Future<void>.delayed(remaining);
    }
    if (!mounted) {
      return;
    }
    // 요약 확인 화면으로 돌아가면 방금 저장한 최신 StructuredIntent가 즉시 표시된다
    // (같은 세션의 structuredIntent를 읽으므로 별도 전달이 필요 없다).
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final LastIntentSessionController session = LastIntentSessionScope.of(
      context,
    ).sessionFor(customer: widget.customer, cartItem: widget.cartItem);

    return StaffAppShell(
      currentRoute: AppRoutes.lastIntentIntro,
      body: _saving
          ? const AppStateView.loading(title: '로딩중...')
          : _buildForm(session),
    );
  }

  Widget _buildForm(LastIntentSessionController session) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 16,
      children: <Widget>[
        const Text('고객 구매 조건 수정', style: StaffText.header16SemiBold),
        const Text(
          'AI가 정리한 조건을 고객과 함께 확인하고 필요한 항목을 수정하세요.',
          style: StaffText.body12,
        ),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: <Widget>[
              const Text('기본 조건', style: StaffText.header16SemiBold),
              const Text('사용 목적', style: StaffText.meta11),
              StaffTextField(label: '', controller: _purposeController),
            ],
          ),
        ),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: <Widget>[
              const Text('핵심 우선 조건', style: StaffText.header16SemiBold),
              if (_hasIncompleteBucket)
                const Text(
                  '분류를 선택한 항목은 값도 함께 선택해야 저장할 수 있습니다.',
                  style: TextStyle(fontSize: 11, color: Colors.red),
                ),
              for (final String key
                  in StructuredIntentVocabulary.attributeLabels.keys)
                _AttributeEditRow(
                  attributeKey: key,
                  bucket: _buckets[key]!,
                  value: _values[key],
                  onBucketChanged: (_ConditionBucket bucket) {
                    setState(() {
                      _buckets[key] = bucket;
                      if (bucket == _ConditionBucket.none) {
                        _values[key] = null;
                      }
                    });
                  },
                  onValueChanged: (String value) {
                    setState(() => _values[key] = value);
                  },
                ),
            ],
          ),
        ),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: <Widget>[
              const Text('실물로 확인하고 싶은 요소', style: StaffText.header16SemiBold),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  for (final String key
                      in StructuredIntentVocabulary.attributeLabels.keys)
                    FilterChip(
                      label: Text(
                        StructuredIntentVocabulary.attributeLabel(key),
                      ),
                      selected: _physicalCheck.contains(key),
                      onSelected: (bool selected) {
                        setState(() {
                          if (selected) {
                            _physicalCheck.add(key);
                          } else {
                            _physicalCheck.remove(key);
                          }
                        });
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: <Widget>[
              const Text('구매 상황', style: StaffText.header16SemiBold),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 4,
                children: <Widget>[
                  const Text('구매 시급성', style: StaffText.meta11),
                  DropdownButtonFormField<PurchaseUrgency>(
                    initialValue: _urgency,
                    isDense: true,
                    items: <DropdownMenuItem<PurchaseUrgency>>[
                      for (final PurchaseUrgency urgency
                          in PurchaseUrgency.values)
                        DropdownMenuItem<PurchaseUrgency>(
                          value: urgency,
                          child: Text(
                            StructuredIntentVocabulary.purchaseUrgencyLabel(
                              urgency,
                            ),
                            style: StaffText.body14,
                          ),
                        ),
                    ],
                    onChanged: (PurchaseUrgency? value) {
                      if (value != null) {
                        setState(() => _urgency = value);
                      }
                    },
                  ),
                ],
              ),
              _TriStateRow(
                label: '대기 가능 여부',
                value: _canWait,
                onChanged: (bool? value) => setState(() => _canWait = value),
              ),
              _TriStateRow(
                label: '타 매장 방문 가능 여부',
                value: _canVisitOtherStore,
                onChanged: (bool? value) =>
                    setState(() => _canVisitOtherStore = value),
              ),
            ],
          ),
        ),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 12,
          runSpacing: 8,
          children: <Widget>[
            StaffButton(
              label: '취소',
              variant: StaffButtonVariant.secondary,
              // 세션 상태를 한 번도 건드리지 않았으므로 그냥 닫기만 하면 원본이
              // 그대로 유지된다.
              onPressed: () => Navigator.of(context).pop(),
            ),
            StaffButton(
              label: '저장',
              variant: _hasIncompleteBucket
                  ? StaffButtonVariant.secondary
                  : StaffButtonVariant.primary,
              onPressed: _hasIncompleteBucket ? null : () => _save(session),
            ),
          ],
        ),
      ],
    );
  }
}

class _AttributeEditRow extends StatelessWidget {
  const _AttributeEditRow({
    required this.attributeKey,
    required this.bucket,
    required this.value,
    required this.onBucketChanged,
    required this.onValueChanged,
  });

  final String attributeKey;
  final _ConditionBucket bucket;
  final String? value;
  final ValueChanged<_ConditionBucket> onBucketChanged;
  final ValueChanged<String> onValueChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      // Wrap (not Row) so narrow viewports reflow to a second line instead
      // of overflowing — three fixed-width controls plus a label don't
      // reliably fit one line below ~820px.
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 4,
        children: <Widget>[
          SizedBox(
            width: 120,
            child: Text(
              StructuredIntentVocabulary.attributeLabel(attributeKey),
              style: StaffText.body12,
            ),
          ),
          SizedBox(
            width: 160,
            child: DropdownButtonFormField<_ConditionBucket>(
              initialValue: bucket,
              isDense: true,
              items: const <DropdownMenuItem<_ConditionBucket>>[
                DropdownMenuItem<_ConditionBucket>(
                  value: _ConditionBucket.none,
                  child: Text('미지정'),
                ),
                DropdownMenuItem<_ConditionBucket>(
                  value: _ConditionBucket.essential,
                  child: Text('필수'),
                ),
                DropdownMenuItem<_ConditionBucket>(
                  value: _ConditionBucket.preferred,
                  child: Text('선호'),
                ),
                DropdownMenuItem<_ConditionBucket>(
                  value: _ConditionBucket.negotiable,
                  child: Text('양보 가능'),
                ),
              ],
              onChanged: (_ConditionBucket? newBucket) {
                if (newBucket != null) {
                  onBucketChanged(newBucket);
                }
              },
            ),
          ),
          if (bucket != _ConditionBucket.none)
            SizedBox(
              width: 160,
              child: DropdownButtonFormField<String>(
                initialValue: value,
                isDense: true,
                hint: const Text('값 선택'),
                items: <DropdownMenuItem<String>>[
                  for (final String option
                      in StructuredIntentVocabulary
                          .attributeValues[attributeKey]!)
                    DropdownMenuItem<String>(
                      value: option,
                      child: Text(
                        StructuredIntentVocabulary.attributeValueLabel(
                          attributeKey,
                          option,
                        ),
                      ),
                    ),
                ],
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    onValueChanged(newValue);
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _TriStateRow extends StatelessWidget {
  const _TriStateRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool? value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 4,
      children: <Widget>[
        SizedBox(width: 160, child: Text(label, style: StaffText.body12)),
        SegmentedButton<bool?>(
          segments: const <ButtonSegment<bool?>>[
            ButtonSegment<bool?>(value: null, label: Text('미확인')),
            ButtonSegment<bool?>(value: true, label: Text('예')),
            ButtonSegment<bool?>(value: false, label: Text('아니오')),
          ],
          selected: <bool?>{value},
          onSelectionChanged: (Set<bool?> selection) =>
              onChanged(selection.first),
        ),
      ],
    );
  }
}
