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

  String? _phoneError;

  // Shared by the Form's validator (drives the field's red border) and
  // _submit (drives the visible message Text below the field) so the two
  // never say different things.
  static String? _phoneErrorMessage(String value, RegExp phonePattern) {
    final String trimmed = value.trim();
    // API.md: 고객 조회는 `GET /api/customers/lookup?phoneNumber=` 하나뿐이고
    // 회원번호로 조회하는 API는 없다 — 회원번호만 입력하고 전화번호를 비워두면
    // 예전엔 검증을 통과해 빈 전화번호로 조회를 시도해 항상 "조회 결과가
    // 없습니다"로 실패했다. 전화번호를 항상 필수로 만들어 그 실패를 명확한
    // 안내 문구로 바꾼다.
    if (trimmed.isEmpty) {
      return '휴대전화 번호를 입력해 주세요.';
    }
    if (!phonePattern.hasMatch(trimmed)) {
      return '010-0000-0000 형식으로 입력해 주세요.';
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    // Deferred to a post-frame callback (same pattern this screen's own
    // loadCart() pre-fetch below already uses) — calling
    // clearLookupResult()'s notifyListeners() synchronously during this
    // widget's own first build trips "setState() called during build",
    // since it would try to rebuild the ancestor StaffSessionScope while
    // this screen is still being mounted underneath it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        StaffSessionScope.of(context).clearLookupResult();
      }
    });
  }

  @override
  void dispose() {
    _memberNumberController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submit(StaffWebSessionController controller) {
    final bool valid = _formKey.currentState?.validate() ?? false;
    setState(() {
      _phoneError = valid
          ? null
          : _phoneErrorMessage(_phoneController.text, _phonePattern);
    });
    if (!valid) {
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

          if (state.currentCustomer != null &&
              state.currentCustomer!.hasConsented &&
              state.cartState.isIdle) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                controller.loadCart();
              }
            });
          }

          final Widget content = LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final Widget search = _SearchPanel(
                formKey: _formKey,
                memberNumberController: _memberNumberController,
                phoneController: _phoneController,
                phonePattern: _phonePattern,
                phoneError: _phoneError,
                onSubmit: () => _submit(controller),
              );
              final Widget result = _ResultPanel(
                controller: controller,
                state: state,
                onRetryLookup: _phoneController.text.trim().isEmpty
                    ? null
                    : () => _submit(controller),
              );

              // Figma: search column (335) → result card left 725, content
              // area left 294 → 725-294-335=96px gap.
              if (constraints.maxWidth < 700) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    search,
                    const SizedBox(height: 24),
                    result,
                  ],
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

          // A plain Column here would leave the footer pinned at its own
          // 347px height with dead white space below it on any viewport
          // taller than this screen's natural (search+result) content —
          // the outer SingleChildScrollView gives this Column an unbounded
          // maxHeight, so Expanded can't be used directly. Reading
          // `outerConstraints.minHeight` (the shell's real, finite
          // available height, passed down as this SAME Column's own
          // minHeight) and rebuilding it as a tightly-sized SizedBox makes
          // Expanded valid, so the footer image fills all remaining space
          // down to the shell's bottom edge instead of leaving a gap.
          return LayoutBuilder(
            builder: (BuildContext context, BoxConstraints outerConstraints) {
              return SizedBox(
                height: outerConstraints.minHeight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    content,
                    const SizedBox(height: 40),
                    const Expanded(child: _CustomerSearchFooterImage()),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Figma node 89:1001 "고객 조회 화면 - 조회하고 나서" (Footer Image, 89:1040) —
/// decorative background photo band beneath the search/result content, same
/// full-bleed pattern as Home's own footer (see `_HomeFooterImage` in
/// staff_home_screen.dart). Figma has it spanning left-51/top-558/w-1389/
/// h-347 on the 1440x900 canvas — left-51 sits behind the 265-wide sidebar
/// (so its visible left edge is flush against the sidebar, further left
/// than every other content element's own left inset), its right edge is
/// flush against the card's right edge, and it's bled 5px past the card's
/// bottom edge — all past the SegueCardShell's own 31px-left/right and
/// 24px-bottom content padding. `Padding` can't express a negative inset
/// (RenderPadding asserts `padding.isNonNegative`), so — same as
/// `_HomeFooterImage` — this reads the box the parent `Expanded` allocates
/// via LayoutBuilder and uses OverflowBox to paint 31px wider on each side
/// and 24px taller (added at the bottom via `Alignment.topCenter`) than
/// that box, unclipped — the outer ClipRRect still clips the result at the
/// card's rounded corner. The allocated height is floored at 347 (Figma's
/// own height) so the image never shrinks away on a very short viewport.
/// This asset already has its white-to-transparent fade baked in, so no
/// separate gradient overlay is layered on top here.
class _CustomerSearchFooterImage extends StatelessWidget {
  const _CustomerSearchFooterImage();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double height = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : constraints.minHeight;
        final double flooredHeight = height < 347 ? 347 : height;
        // See `_HomeFooterImage`'s matching comment — OverflowBox sizes
        // itself to the biggest its own incoming constraints allow, so it
        // needs a concrete (not unbounded) height from its immediate
        // parent; this Expanded slot already gives one, but pinning it
        // explicitly here keeps this in sync with that widget.
        return SizedBox(
          width: constraints.maxWidth,
          height: flooredHeight,
          child: OverflowBox(
            alignment: Alignment.topCenter,
            minWidth: 0,
            maxWidth: double.infinity,
            minHeight: 0,
            maxHeight: double.infinity,
            child: SizedBox(
              width: constraints.maxWidth + 62,
              height: flooredHeight + 24,
              child: Image.asset(
                'assets/images/customer_search_footer.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SearchPanel extends StatelessWidget {
  const _SearchPanel({
    required this.formKey,
    required this.memberNumberController,
    required this.phoneController,
    required this.phonePattern,
    required this.phoneError,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController memberNumberController;
  final TextEditingController phoneController;
  final RegExp phonePattern;

  /// Shown as a plain red Text below the phone field — kept outside
  /// SegueTextField's own fixed-height decoration so a validation failure
  /// never distorts the field's pixel-exact 42px box (see SegueTextField's
  /// `errorStyle`).
  final String? phoneError;
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
            // Returns '' (not the real message) on failure: this only
            // needs to flip the field into its error-border state — the
            // actual message renders once, below, as `phoneError`. Reusing
            // the real message here would duplicate it in the widget tree.
            validator: (String? value) =>
                _CustomerLookupScreenState._phoneErrorMessage(
                      value ?? '',
                      phonePattern,
                    ) ==
                    null
                ? null
                : '',
          ),
          if (phoneError != null) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              phoneError!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
          // Figma: input2 bottom 319+42=361 → button top 382 = 21px.
          const SizedBox(height: 21),
          SegueCompactButton(
            label: '고객 조회',
            backgroundColor: SegueCardColors.ctaBg,
            height: 32,
            textStyle: SegueCardText.compactButtonLabel15.copyWith(
              fontSize: 14,
            ),
            onPressed: onSubmit,
          ),
        ],
      ),
    );
  }
}

class _ResultPanel extends StatelessWidget {
  const _ResultPanel({
    required this.controller,
    required this.state,
    required this.onRetryLookup,
  });

  final StaffWebSessionController controller;
  final StaffWebSessionState state;

  /// Null when the phone field is empty (nothing to retry with yet), same
  /// gating [_SearchPanel]'s submit button already applies.
  final VoidCallback? onRetryLookup;

  @override
  Widget build(BuildContext context) {
    if (state.lookupState.isLoading) {
      // No loading UI for customer lookup — stays blank until the result
      // (or error) resolves.
      return const SizedBox.shrink();
    }
    if (state.lookupState.hasError) {
      final Object? error = state.lookupState.error;
      final String message = error is AppException
          ? error.message
          : '회원 정보를 다시 확인해 주세요.';
      final bool notFound =
          (error is ApiException && error.statusCode == 404) ||
          (error is AppException && error.code == 'CUSTOMER_NOT_FOUND');
      return AppStateView.error(
        title: notFound ? '조회 결과가 없습니다' : '고객 조회에 실패했습니다',
        message: message,
        onAction: onRetryLookup,
      );
    }
    // Reads the screen-local lookup result (reset every time this screen is
    // entered), NOT state.currentCustomer — otherwise a previous visit's
    // customer would flash back up immediately on re-entry.
    final Customer? customer = state.lookupState.data;
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
                label: customer.hasConsented ? '쇼핑백 확인' : '상담 데이터 이용 동의 확인',
                backgroundColor: SegueCardColors.ctaBg,
                showArrow: true,
                textStyle: SegueCardText.compactButtonLabel16,
                onPressed: () {
                  if (!customer.hasConsented) {
                    Navigator.of(context).pushNamed(AppRoutes.customerConsent);
                    return;
                  }
                  if (state.cartState.isIdle) {
                    controller.loadCart();
                  }
                  Navigator.of(context).pushNamed(AppRoutes.cartInventory);
                },
              );
              // The button's auto-width label has no narrower Figma
              // variant, so this app's own responsive fallback drops it
              // below the name instead of overflowing.
              if (constraints.maxWidth >= 500) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(child: name),
                    const SizedBox(width: 12),
                    cta,
                  ],
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
                const TextSpan(
                  text: '회원번호',
                  style: SegueCardText.detailLabel16,
                ),
                const TextSpan(text: '   ', style: SegueCardText.detailLabel16),
                TextSpan(
                  text: '${customer.id}',
                  style: SegueCardText.detailValue16,
                ),
              ],
            ),
          ),
          Text.rich(
            TextSpan(
              children: <InlineSpan>[
                const TextSpan(
                  text: '전화번호',
                  style: SegueCardText.detailLabel16,
                ),
                const TextSpan(text: '   ', style: SegueCardText.detailLabel16),
                TextSpan(
                  text: customer.phoneNumber,
                  style: SegueCardText.detailValue16,
                ),
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
