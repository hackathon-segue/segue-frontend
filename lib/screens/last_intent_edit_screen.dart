import 'package:flutter/material.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../utils/app_config.dart';
import '../utils/segue_card_tokens.dart';
import '../utils/structured_intent_vocabulary.dart';
import '../widgets/app_state_view.dart';
import '../widgets/segue_card_shell.dart';
import '../widgets/segue_info_card.dart';
import 'last_intent_card_screen.dart';
import 'last_intent_intro_screen.dart';

/// "고객 구매 조건 수정" — condition-key + value row editor (attached design,
/// node not re-fetched per explicit direction). Reached from
/// [LastIntentConfirmScreen]'s "수정할게요".
///
/// All edits live in LOCAL widget state until "다음 단계로" is pressed —
/// nothing is written back to [LastIntentSessionController] before then, so
/// navigating away (back button) leaves the session's [StructuredIntent]
/// untouched. "다음 단계로" writes the edited intent into the session (same
/// [LastIntentSessionController.updateStructuredIntent] call the old
/// "저장" used) and then calls [LastIntentSessionController.decide] itself
/// — the exact same call [LastIntentConfirmScreen]'s "맞아요, 다음 단계로"
/// makes, reading `session.state.structuredIntent` (now the just-saved
/// edit) — so this screen's own button sends the full edited
/// StructuredIntent straight to `/api/consultations/decide` without a
/// second confirm-screen click, and skips ahead to
/// [LastIntentCardScreen] on success exactly like the confirm screen does.
///
/// essentialConditions/preferredConditions/negotiableConditions are each
/// edited as their own growable list of (key, value) rows instead of one
/// fixed 17-row table — "+ 조건 추가" appends a blank row, and a key already
/// used in ANY of the three maps is excluded from every other row's key
/// dropdown, so a key can never end up in more than one map at once (the
/// same invariant the old bucket-based UI enforced, just expressed as three
/// lists instead of one shared bucket per key).
/// Shared look for every dropdown on this screen — square corners (no
/// screen elsewhere in the app rounds an input/button either) and a
/// neutral ink/gray border instead of the app theme's default blue focus
/// color, matching this screen's own achromatic SEGUE palette rather than
/// Material's seeded ColorScheme.
const InputDecoration dropdownFieldDecoration = InputDecoration(
  isDense: true,
  filled: true,
  fillColor: Colors.white,
  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.zero,
    borderSide: BorderSide(color: SegueCardColors.border, width: 1.5),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.zero,
    borderSide: BorderSide(color: SegueCardColors.border, width: 1.5),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.zero,
    borderSide: BorderSide(color: SegueCardColors.ink, width: 1.5),
  ),
);

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

class _ConditionRow {
  _ConditionRow({this.key, this.value});

  String? key;
  String? value;
}

class _LastIntentEditScreenState extends State<LastIntentEditScreen> {
  final TextEditingController _purposeController = TextEditingController();
  final List<_ConditionRow> _essentialRows = <_ConditionRow>[];
  final List<_ConditionRow> _preferredRows = <_ConditionRow>[];
  final List<_ConditionRow> _negotiableRows = <_ConditionRow>[];
  final Set<String> _physicalCheck = <String>{};
  PurchaseUrgency _urgency = PurchaseUrgency.flexible;
  bool? _canWait;
  bool? _canVisitOtherStore;

  // Preserved as-is (not editable here) and passed straight through to the
  // decide() payload — per the issue, these two fields stay off this
  // screen entirely but must not be dropped from the request.
  bool _needsFollowUp = false;
  String _followUpReason = '';

  bool _seeded = false;
  bool _deciding = false;

  // MockSegueRepository/RealSegueRepository can both resolve fast enough
  // that the loading state would flash by unseen without a floor — same
  // rationale already used on the utterance/follow-up/confirm screens.
  static const Duration _minDecidingDuration = Duration(milliseconds: 600);

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
    _essentialRows.addAll(
      intent.essentialConditions.entries.map(
        (MapEntry<String, String> e) =>
            _ConditionRow(key: e.key, value: e.value),
      ),
    );
    _preferredRows.addAll(
      intent.preferredConditions.entries.map(
        (MapEntry<String, String> e) =>
            _ConditionRow(key: e.key, value: e.value),
      ),
    );
    _negotiableRows.addAll(
      intent.negotiableConditions.entries.map(
        (MapEntry<String, String> e) =>
            _ConditionRow(key: e.key, value: e.value),
      ),
    );
    _physicalCheck.addAll(intent.physicalCheckAttributes);
    _urgency = intent.purchaseUrgency;
    _canWait = intent.canWait;
    _canVisitOtherStore = intent.canVisitOtherStore;
    _needsFollowUp = intent.needsFollowUp;
    _followUpReason = intent.followUpReason;
  }

  @override
  void dispose() {
    _purposeController.dispose();
    super.dispose();
  }

  List<_ConditionRow> get _allRows => <_ConditionRow>[
    ..._essentialRows,
    ..._preferredRows,
    ..._negotiableRows,
  ];

  /// Attribute keys already used in ANY of the three condition maps —
  /// excludes [excluding] itself so a row keeps showing its own current key
  /// as a selectable option while editing it.
  Set<String> _usedKeys({_ConditionRow? excluding}) {
    final Set<String> keys = <String>{};
    for (final _ConditionRow row in _allRows) {
      if (row.key != null && !identical(row, excluding)) {
        keys.add(row.key!);
      }
    }
    return keys;
  }

  bool get _hasIncompleteRow =>
      _allRows.any((_ConditionRow r) => r.key == null || r.value == null);

  Map<String, String> _toMap(List<_ConditionRow> rows) {
    return <String, String>{
      for (final _ConditionRow r in rows)
        if (r.key != null && r.value != null) r.key!: r.value!,
    };
  }

  Future<void> _proceed(LastIntentSessionController session) async {
    if (_hasIncompleteRow || _deciding) {
      return;
    }
    setState(() => _deciding = true);
    final Stopwatch stopwatch = Stopwatch()..start();

    // AC: 수정된 structuredIntent 전체가 그대로 decide()의 요청에 실린다 —
    // decide()가 읽는 session.state.structuredIntent를 먼저 이걸로 갱신한다.
    session.updateStructuredIntent(
      StructuredIntent(
        purpose: _purposeController.text.trim(),
        essentialConditions: _toMap(_essentialRows),
        preferredConditions: _toMap(_preferredRows),
        negotiableConditions: _toMap(_negotiableRows),
        purchaseUrgency: _urgency,
        physicalCheckAttributes: _physicalCheck.toList(),
        canWait: _canWait,
        canVisitOtherStore: _canVisitOtherStore,
        needsFollowUp: _needsFollowUp,
        followUpReason: _followUpReason,
      ),
    );
    await session.decide();

    final Duration remaining = _minDecidingDuration - stopwatch.elapsed;
    if (remaining > Duration.zero) {
      await Future<void>.delayed(remaining);
    }
    if (!mounted) {
      return;
    }
    setState(() => _deciding = false);
    if (session.state.decisionResult != null) {
      session.setCurrentStep(LastIntentStep.card);
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => LastIntentCardScreen(
            customer: widget.customer,
            cartItem: widget.cartItem,
          ),
          settings: const RouteSettings(name: AppRoutes.lastIntentCard),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final LastIntentSessionManager manager = LastIntentSessionScope.of(context);
    final LastIntentSessionController session = manager.sessionFor(
      customer: widget.customer,
      cartItem: widget.cartItem,
    );

    return SegueCardShell(
      pageTitle: 'CURRENT SESSION',
      activeMenuItem: TabletMenuItem.currentSession,
      sessionCount: manager.activeCount,
      guardedSession: session,
      stepBadge: '3/5',
      screenTitle: '고객 구매 조건 수정',
      subtitle: 'AI가 정리한 조건을 고객과 함께 확인하고 필요한 항목을 수정하세요.',
      bodyTopGap: 24,
      body: ListenableBuilder(
        listenable: session,
        builder: (BuildContext context, Widget? _) {
          if (_deciding || session.state.decisionState.isLoading) {
            return const AppStateView.loading();
          }
          if (session.state.decisionState.hasError) {
            return AppStateView.error(
              message: 'Last Intent Card 생성에 실패했습니다. 다시 시도해 주세요.',
              onAction: () => _proceed(session),
              secondaryActionLabel: '이전으로 돌아가기',
              onSecondaryAction: () => Navigator.of(context).pop(),
            );
          }
          return _buildForm();
        },
      ),
      bottomBar: SegueBottomActionRow(
        onBackToStart: () => navigateToLastIntentIntro(
          context,
          customer: widget.customer,
          cartItem: widget.cartItem,
        ),
        topPadding: 28,
        cta: Wrap(
          alignment: WrapAlignment.end,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 14,
          runSpacing: 12,
          children: <Widget>[
            _SecondaryActionButton(
              label: '이전으로 돌아가기',
              onPressed: () => Navigator.of(context).pop(),
            ),
            _PrimaryActionButton(
              label: '다음 단계로',
              onPressed: _hasIncompleteRow ? null : () => _proceed(session),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    final Widget leftColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _EditInfoCard(
          title: '사용 목적',
          child: _PurposeField(controller: _purposeController),
        ),
        const SizedBox(height: 12),
        _buildConditionSection(title: '핵심 우선 조건', rows: _essentialRows),
        const SizedBox(height: 12),
        _buildConditionSection(title: '선호 조건', rows: _preferredRows),
        const SizedBox(height: 12),
        _buildConditionSection(title: '양보 가능한 조건', rows: _negotiableRows),
      ],
    );

    final Widget rightColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildPurchaseSituationSection(),
        const SizedBox(height: 12),
        _buildPhysicalCheckSection(),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            if (constraints.maxWidth < 950) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  leftColumn,
                  const SizedBox(height: 12),
                  rightColumn,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(child: leftColumn),
                const SizedBox(width: 17),
                Expanded(child: rightColumn),
              ],
            );
          },
        ),
        if (_hasIncompleteRow) ...<Widget>[
          const SizedBox(height: 12),
          const Text(
            '추가한 조건은 값까지 선택해야 다음 단계로 진행할 수 있습니다.',
            style: _EditTextStyles.warning,
          ),
        ],
      ],
    );
  }

  Widget _buildConditionSection({
    required String title,
    required List<_ConditionRow> rows,
  }) {
    final bool canAddMore =
        _usedKeys().length < StructuredIntentVocabulary.attributeLabels.length;
    return _EditInfoCard(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (final _ConditionRow row in rows)
            _ConditionRowEditor(
              row: row,
              availableKeys: <String>[
                for (final String key
                    in StructuredIntentVocabulary.attributeLabels.keys)
                  if (key == row.key ||
                      !_usedKeys(excluding: row).contains(key))
                    key,
              ],
              onKeyChanged: (String key) {
                setState(() {
                  row.key = key;
                  row.value = null;
                });
              },
              onValueChanged: (String value) {
                setState(() => row.value = value);
              },
              onDelete: () => setState(() => rows.remove(row)),
            ),
          const SizedBox(height: 4),
          _InlineActionButton(
            label: '+ 조건 추가',
            onPressed: canAddMore
                ? () => setState(() => rows.add(_ConditionRow()))
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildPhysicalCheckSection() {
    return _EditInfoCard(
      title: '실물로 확인하고 싶은 요소',
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: <Widget>[
          for (final String key
              in StructuredIntentVocabulary.attributeLabels.keys)
            FilterChip(
              label: Text(
                StructuredIntentVocabulary.attributeLabel(key),
                style: _physicalCheck.contains(key)
                    ? _EditTextStyles.chipSelected
                    : _EditTextStyles.chip,
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
              showCheckmark: false,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
                side: BorderSide(color: SegueCardColors.border),
              ),
              backgroundColor: Colors.white,
              selectedColor: SegueCardColors.ink,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            ),
        ],
      ),
    );
  }

  Widget _buildPurchaseSituationSection() {
    return _EditInfoCard(
      title: '구매 상황',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('구매 시급성', style: _EditTextStyles.fieldLabel),
          const SizedBox(height: 6),
          DropdownButtonFormField<PurchaseUrgency>(
            initialValue: _urgency,
            isDense: true,
            isExpanded: true,
            decoration: dropdownFieldDecoration,
            dropdownColor: Colors.white,
            iconEnabledColor: SegueCardColors.muted,
            style: _EditTextStyles.input,
            items: <DropdownMenuItem<PurchaseUrgency>>[
              for (final PurchaseUrgency urgency in PurchaseUrgency.values)
                DropdownMenuItem<PurchaseUrgency>(
                  value: urgency,
                  child: Text(
                    StructuredIntentVocabulary.purchaseUrgencyLabel(urgency),
                    style: _EditTextStyles.input,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (PurchaseUrgency? value) {
              if (value != null) {
                setState(() => _urgency = value);
              }
            },
          ),
          const SizedBox(height: 12),
          _TriStateRow(
            label: '대기 가능 여부',
            value: _canWait,
            onChanged: (bool? value) => setState(() => _canWait = value),
          ),
          const SizedBox(height: 8),
          _TriStateRow(
            label: '타 매장 방문 가능 여부',
            value: _canVisitOtherStore,
            onChanged: (bool? value) =>
                setState(() => _canVisitOtherStore = value),
          ),
        ],
      ),
    );
  }
}

class _ConditionRowEditor extends StatelessWidget {
  const _ConditionRowEditor({
    required this.row,
    required this.availableKeys,
    required this.onKeyChanged,
    required this.onValueChanged,
    required this.onDelete,
  });

  final _ConditionRow row;
  final List<String> availableKeys;
  final ValueChanged<String> onKeyChanged;
  final ValueChanged<String> onValueChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final List<String> valueOptions =
        StructuredIntentVocabulary.attributeValues[row.key] ?? const <String>[];

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 6,
        children: <Widget>[
          SizedBox(
            width: 190,
            child: DropdownButtonFormField<String>(
              initialValue: row.key,
              isDense: true,
              isExpanded: true,
              decoration: dropdownFieldDecoration,
              dropdownColor: Colors.white,
              iconEnabledColor: SegueCardColors.muted,
              style: _EditTextStyles.input,
              hint: const Text('조건 선택', style: _EditTextStyles.placeholder),
              items: <DropdownMenuItem<String>>[
                for (final String key in availableKeys)
                  DropdownMenuItem<String>(
                    value: key,
                    child: Text(
                      StructuredIntentVocabulary.attributeLabel(key),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (String? key) {
                if (key != null) {
                  onKeyChanged(key);
                }
              },
            ),
          ),
          const Icon(
            Icons.arrow_forward,
            size: 15,
            color: SegueCardColors.muted,
          ),
          SizedBox(
            width: 190,
            child: DropdownButtonFormField<String>(
              initialValue: row.value,
              isDense: true,
              isExpanded: true,
              decoration: dropdownFieldDecoration,
              dropdownColor: Colors.white,
              iconEnabledColor: SegueCardColors.muted,
              style: _EditTextStyles.input,
              hint: const Text('값 선택', style: _EditTextStyles.placeholder),
              items: <DropdownMenuItem<String>>[
                for (final String value in valueOptions)
                  DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      StructuredIntentVocabulary.attributeValueLabel(
                        row.key ?? '',
                        value,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: row.key == null
                  ? null
                  : (String? value) {
                      if (value != null) {
                        onValueChanged(value);
                      }
                    },
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline,
              color: SegueCardColors.muted,
            ),
            tooltip: '조건 삭제',
            onPressed: onDelete,
            style: IconButton.styleFrom(
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
              side: const BorderSide(color: SegueCardColors.border),
              minimumSize: const Size(42, 42),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditInfoCard extends StatelessWidget {
  const _EditInfoCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SegueInfoCard(
      title: title,
      titleStyle: SegueCardText.sectionHeading20,
      child: child,
    );
  }
}

class _PurposeField extends StatelessWidget {
  const _PurposeField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      minLines: 1,
      maxLines: 2,
      style: _EditTextStyles.input,
      decoration: dropdownFieldDecoration.copyWith(
        hintText: '사용 목적 입력',
        hintStyle: _EditTextStyles.placeholder,
      ),
    );
  }
}

class _InlineActionButton extends StatelessWidget {
  const _InlineActionButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onPressed,
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: SegueCardColors.ink),
          ),
          child: Text(
            label,
            style: _EditTextStyles.inlineAction,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ),
    );
  }
}

class _SecondaryActionButton extends StatelessWidget {
  const _SecondaryActionButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onPressed,
        child: Container(
          width: 142,
          height: 43,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: SegueCardColors.ink),
          ),
          child: Text(
            label,
            style: _EditTextStyles.secondaryAction,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  const _PrimaryActionButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SegueCtaButton(label: label, onPressed: onPressed);
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

  static const double _buttonGroupWidth = 288;
  static const double _segmentMinWidth = _buttonGroupWidth / 3;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 4,
      children: <Widget>[
        SizedBox(
          width: 154,
          child: Text(label, style: _EditTextStyles.fieldLabel),
        ),
        SizedBox(
          width: _buttonGroupWidth,
          child: SegmentedButton<bool?>(
            expandedInsets: EdgeInsets.zero,
            segments: const <ButtonSegment<bool?>>[
              ButtonSegment<bool?>(
                value: null,
                label: _TriStateSegmentLabel('미확인'),
              ),
              ButtonSegment<bool?>(
                value: true,
                label: _TriStateSegmentLabel('예'),
              ),
              ButtonSegment<bool?>(
                value: false,
                label: _TriStateSegmentLabel('아니오'),
              ),
            ],
            selected: <bool?>{value},
            onSelectionChanged: (Set<bool?> selection) =>
                onChanged(selection.first),
            // Material 3's default SegmentedButton pulls from the app's
            // seeded (blue-leaning) ColorScheme and pill-shapes each
            // segment — overridden here to the same square, ink/white/gray
            // palette every other control on this screen uses.
            style: SegmentedButton.styleFrom(
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
              backgroundColor: Colors.white,
              foregroundColor: SegueCardColors.ink,
              side: const BorderSide(color: SegueCardColors.border),
              selectedBackgroundColor: SegueCardColors.ink,
              selectedForegroundColor: Colors.white,
              textStyle: _EditTextStyles.fieldLabel,
              padding: EdgeInsets.zero,
              minimumSize: const Size(_segmentMinWidth, 40),
            ),
          ),
        ),
      ],
    );
  }
}

abstract final class _EditTextStyles {
  static const TextStyle input = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: SegueCardColors.ink,
    height: 1.25,
  );

  static const TextStyle placeholder = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: SegueCardColors.placeholderMuted,
  );

  static const TextStyle fieldLabel = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: SegueCardColors.secondaryText,
  );

  static const TextStyle chip = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: SegueCardColors.ink,
  );

  static const TextStyle chipSelected = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static const TextStyle inlineAction = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: SegueCardColors.ink,
  );

  static const TextStyle secondaryAction = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: SegueCardColors.ink,
  );

  static const TextStyle warning = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: Color(0xFFB42318),
  );
}

class _TriStateSegmentLabel extends StatelessWidget {
  const _TriStateSegmentLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        label,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.visible,
      ),
    );
  }
}
