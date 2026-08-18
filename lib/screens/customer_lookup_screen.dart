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
import '../widgets/staff_text_field.dart';

/// Figma node 14:859 "고객 조회 화면": phone-number lookup + inline cart
/// preview.
///
/// Scope note: only the search form, validation, mock lookup and the
/// resulting customer/cart *preview* belong to Issue #7. The dedicated
/// "장바구니·재고 확인" screen (Figma 14:1051, [CartInventoryScreen]) is a
/// separate destination this screen's consent button leads toward.
class CustomerLookupScreen extends StatefulWidget {
  const CustomerLookupScreen({super.key});

  @override
  State<CustomerLookupScreen> createState() => _CustomerLookupScreenState();
}

class _CustomerLookupScreenState extends State<CustomerLookupScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _memberNumberController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  static final RegExp _phonePattern = RegExp(r'^01[0-9]-\d{3,4}-\d{4}$');

  @override
  void dispose() {
    _memberNumberController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submit(StaffWebSessionController controller) {
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    controller.lookupCustomer(_phoneController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final StaffWebSessionController controller = StaffSessionScope.of(context);

    return StaffAppShell(
      currentRoute: AppRoutes.customerLookup,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 16,
        children: <Widget>[
          const Text('고객 조회', style: StaffText.title20Bold),
          const Text('테스트 고객 계정 또는 가상 휴대전화 번호로 고객을 조회하세요.', style: StaffText.body12),
          ListenableBuilder(
            listenable: controller,
            builder: (BuildContext context, Widget? _) {
              final StaffWebSessionState state = controller.state;

              if (state.customer != null &&
                  state.customer!.hasConsented &&
                  state.cartState.isIdle) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    controller.loadCart();
                  }
                });
              }

              return LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final Widget search = _SearchPanel(
                    formKey: _formKey,
                    memberNumberController: _memberNumberController,
                    phoneController: _phoneController,
                    phonePattern: _phonePattern,
                    onSubmit: () => _submit(controller),
                  );
                  final Widget result = _ResultPanel(state: state);

                  if (constraints.maxWidth < StaffSizes.twoPaneBreakpoint) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 16,
                      children: <Widget>[search, result],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 24,
                    children: <Widget>[
                      SizedBox(width: 380, child: search),
                      Expanded(child: result),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SearchPanel extends StatelessWidget {
  const _SearchPanel({
    required this.formKey,
    required this.memberNumberController,
    required this.phoneController,
    required this.phonePattern,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController memberNumberController;
  final TextEditingController phoneController;
  final RegExp phonePattern;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: <Widget>[
        SectionCard(
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 12,
              children: <Widget>[
                const Text('고객 검색', style: StaffText.header16SemiBold),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 12,
                  children: <Widget>[
                    StaffTextField(label: '회원 번호', controller: memberNumberController),
                    StaffTextField(
                      label: '휴대전화 번호',
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      validator: (String? value) {
                        final String trimmed = value?.trim() ?? '';
                        if (trimmed.isEmpty && memberNumberController.text.trim().isEmpty) {
                          return '휴대전화 번호를 입력해 주세요.';
                        }
                        if (trimmed.isNotEmpty && !phonePattern.hasMatch(trimmed)) {
                          return '010-0000-0000 형식으로 입력해 주세요.';
                        }
                        return null;
                      },
                    ),
                    const Text('예: 010-0000-0000 (MVP 테스트 번호 사용)', style: StaffText.meta11),
                    StaffButton(
                      label: '고객 조회',
                      variant: StaffButtonVariant.primary,
                      onPressed: onSubmit,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: <Widget>[
              Text('조회 안내', style: StaffText.header16SemiBold),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: <Widget>[
                  Text('MVP 단계에서는 실제 개인정보 대신 테스트 고객 계정과 가상 번호를 사용합니다.',
                      style: StaffText.body12),
                  Text('조회된 고객 정보는 상담 목적으로만 활용되며, 데이터 이용 동의 확인 후 진행됩니다.',
                      style: StaffText.body12),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ResultPanel extends StatelessWidget {
  const _ResultPanel({required this.state});

  final StaffWebSessionState state;

  @override
  Widget build(BuildContext context) {
    if (state.lookupState.isLoading) {
      return const AppStateView.loading(title: '고객 정보를 조회하고 있습니다');
    }
    if (state.lookupState.hasError) {
      final Object? error = state.lookupState.error;
      final String message = error is AppException ? error.message : '회원 정보를 다시 확인해 주세요.';
      return AppStateView.error(message: message);
    }
    final Customer? customer = state.customer;
    if (customer == null) {
      return const AppStateView.empty(
        title: '조회된 고객이 없습니다',
        message: '왼쪽에서 휴대전화 번호를 입력하고 고객을 조회하세요.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: <Widget>[
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: <Widget>[
              const Row(
                children: <Widget>[
                  Expanded(
                    child: Text('고객 정보', style: StaffText.header16SemiBold),
                  ),
                  Text('조회 기준 시점: 방금 전', style: StaffText.meta11),
                ],
              ),
              Row(
                spacing: 16,
                children: <Widget>[
                  const StaffImagePlaceholder.avatar(),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 4,
                      children: <Widget>[
                        Text(
                          customer.name,
                          style: StaffText.header16SemiBold,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '회원번호 MCM-TEST-${customer.id.toString().padLeft(4, '0')}',
                          style: StaffText.body12,
                        ),
                        const Text('가입일 정보 없음', style: StaffText.meta11),
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
            spacing: 12,
            children: <Widget>[
              const Row(
                children: <Widget>[
                  Expanded(
                    child: Text('장바구니 제품 목록', style: StaffText.header16SemiBold),
                  ),
                  Text('최근 담은 순', style: StaffText.meta11),
                ],
              ),
              _CartPreview(customer: customer, cartState: state.cartState),
            ],
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: StaffButton(
            label: '데이터 이용 동의 확인',
            variant: StaffButtonVariant.primary,
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.customerConsent),
          ),
        ),
      ],
    );
  }
}

class _CartPreview extends StatelessWidget {
  const _CartPreview({required this.customer, required this.cartState});

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
      spacing: 8,
      children: <Widget>[for (final CartItem item in items) _CartItemRow(item: item)],
    );
  }
}

class _CartItemRow extends StatelessWidget {
  const _CartItemRow({required this.item});

  final CartItem item;

  // Below this width the image + a legible name column + the status/chip
  // group can no longer share one row without the trailing group being
  // squeezed to nothing (measured: overflows below ~420px). The Figma
  // reference has no narrower variant, so stacking the trailing group under
  // the leading content — instead of forcing it onto the same row — is this
  // app's own responsive addition.
  static const double _rowBreakpoint = 420;

  @override
  Widget build(BuildContext context) {
    final String statusLabel = item.inventory.currentStoreInStock ? '현재 매장 보유' : '현재 매장 미보유';

    final Widget leading = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: 16,
      children: <Widget>[
        const StaffImagePlaceholder.square(size: 56),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4,
            children: <Widget>[
              Text(item.productName, style: StaffText.body12, overflow: TextOverflow.ellipsis),
              Text('컬러: ${item.color}', style: StaffText.meta11),
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
        Text(statusLabel, style: StaffText.meta11),
        StaffButton(label: item.actionButtonLabel, variant: StaffButtonVariant.chip, onPressed: () {}),
      ],
    );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxWidth >= _rowBreakpoint) {
          // Matches Figma exactly: Figma uses an invisible flex-fill spacer
          // between the name column and the trailing group (14:859
          // metadata, node 14:933 "Frame" h=1) — only the name column
          // (Expanded) should compete for leftover space here. Wrapping
          // `trailing` in Flexible/Expanded would instead split the
          // remaining width 50/50 with it, stranding the group mid-row.
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
    );
  }
}
