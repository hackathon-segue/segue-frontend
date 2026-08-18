import 'package:flutter/material.dart';

import '../exceptions/app_exception.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../utils/app_config.dart';
import '../utils/segue_card_tokens.dart';
import '../widgets/app_state_view.dart';
import '../widgets/segue_card_shell.dart';

/// Figma node 89:928 "고객 조회 화면 - 조회하기 전" and 89:1001 "고객 조회 화면 -
/// 조회하고 나서" (Issue #48 — this screen's own visual rebuild against the
/// latest Figma, superseding the previous 14:859-based build). Uses the
/// shared [SegueCardShell]/[TabletHeader]/[TabletNavSidebar]/
/// [SegueTextField]/[SegueCompactButton] — no header/menu/input/button
/// markup is built here.
///
/// Business logic unchanged from the previous build: [StaffWebSessionController]
/// still owns the lookup/validation/cart-preload flow — this screen only
/// renders its result. Neither Figma node shows a cart-preview list (that
/// UI now only exists on [CartInventoryScreen], reached after consent), so
/// it's dropped here rather than kept as a 14:859-era leftover — but the
/// `loadCart()` pre-fetch this screen used to trigger for that preview stays
/// wired exactly as before, since [CartInventoryScreen] still benefits from
/// the head start even though this screen no longer displays the result.
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

    return SegueCardShell(
      pageTitle: 'CUSTOMER SEARCH',
      activeMenuItem: TabletMenuItem.customerSearch,
      sessionCount: LastIntentSessionScope.of(context).activeCount,
      subtitle: '고객님의 정보를 조회해 주세요.',
      // Figma (89:928): subtitle bottom 146+21=167 → "고객 검색" title top
      // 208 = 41px.
      bodyTopGap: 41,
      body: ListenableBuilder(
        listenable: controller,
        builder: (BuildContext context, Widget? _) {
          final StaffWebSessionState state = controller.state;

          if (state.customer != null && state.customer!.hasConsented && state.cartState.isIdle) {
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

              // Figma: search column (335) → result card left 725, content
              // area left 294 → 725-294-335=96px gap.
              if (constraints.maxWidth < 700) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[search, const SizedBox(height: 24), result],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(width: 335, child: search),
                  const SizedBox(width: 96),
                  Expanded(child: result),
                ],
              );
            },
          );
        },
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
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('고객 검색', style: SegueCardText.sectionHeading20),
          // Figma: title bottom 208+28=236 → divider 240 = 4px.
          const SizedBox(height: 4),
          // Figma "Line 2" asset: stroke #222222 (ink), NOT the muted border
          // gray other dividers in this system use.
          const Divider(height: 1, thickness: 1, color: SegueCardColors.ink),
          // Figma: divider 240 → input1 top 261 = 21px.
          const SizedBox(height: 21),
          SegueTextField(hintText: '회원번호', controller: memberNumberController),
          // Figma: input1 bottom 261+42=303 → input2 top 319 = 16px.
          const SizedBox(height: 16),
          SegueTextField(
            hintText: '전화번호',
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
          // Figma: input2 bottom 319+42=361 → button top 382 = 21px.
          const SizedBox(height: 21),
          SegueCompactButton(
            label: '고객 조회',
            backgroundColor: SegueCardColors.ctaBg,
            height: 32,
            textStyle: SegueCardText.compactButtonLabel15.copyWith(fontSize: 14),
            onPressed: onSubmit,
          ),
        ],
      ),
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
      // Figma (89:928): nothing renders on the right until a customer is
      // found.
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      // Figma: Details Container 626x159.
      padding: const EdgeInsets.fromLTRB(27, 27, 27, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: SegueCardColors.border, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final Widget name = Text(
                customer.name,
                style: SegueCardText.customerName22,
                overflow: TextOverflow.ellipsis,
              );
              final Widget cta = SegueCompactButton(
                label: '상담 데이터 이용 동의 확인',
                backgroundColor: SegueCardColors.ctaBg,
                showArrow: true,
                textStyle: SegueCardText.compactButtonLabel16,
                onPressed: () => Navigator.of(context).pushNamed(AppRoutes.customerConsent),
              );
              // The button's auto-width label has no narrower Figma
              // variant, so this app's own responsive fallback drops it
              // below the name instead of overflowing.
              if (constraints.maxWidth >= 500) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[Expanded(child: name), const SizedBox(width: 12), cta],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[name, const SizedBox(height: 12), cta],
              );
            },
          ),
          // Figma: name bottom 187+31=218 → details top 231 = 13px.
          const SizedBox(height: 13),
          Text.rich(
            TextSpan(
              children: <InlineSpan>[
                const TextSpan(text: '회원번호', style: SegueCardText.detailLabel16),
                const TextSpan(text: '   ', style: SegueCardText.detailLabel16),
                TextSpan(text: '${customer.id}', style: SegueCardText.detailValue16),
              ],
            ),
          ),
          Text.rich(
            TextSpan(
              children: <InlineSpan>[
                const TextSpan(text: '전화번호', style: SegueCardText.detailLabel16),
                const TextSpan(text: '   ', style: SegueCardText.detailLabel16),
                TextSpan(text: customer.phoneNumber, style: SegueCardText.detailValue16),
              ],
            ),
          ),
          // Figma: details block bottom 231+48=279 → box bottom 160+159=319,
          // 40px slack at the bottom the box just leaves as breathing room.
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
