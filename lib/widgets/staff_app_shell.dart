import 'package:flutter/material.dart';

import '../providers/providers.dart';
import '../utils/app_config.dart';
import '../utils/staff_design_tokens.dart';
import 'segue_card_shell.dart';

/// Shared layout shell for every staff/tablet screen, matching Figma's
/// top-level frame exactly: `get_metadata` on all 6 reference nodes
/// confirms the white rounded-12/bordered/shadowed card fills its 1440x900
/// frame edge-to-edge (`size-full`, zero surrounding margin) — there is no
/// inset "page background" around it. It contains a fixed top bar, a
/// persistent 265px sidebar and a scrollable content column.
///
/// Issue #48 ("GLOBAL UI LOCK", header/nav must be identical everywhere):
/// the header/sidebar chrome now delegates to [TabletHeader]/
/// [TabletNavSidebar] — the same shared components the Last Intent flow
/// screens use via [SegueCardShell] — instead of this file's own
/// now-retired `StaffTopBar`/`StaffSidebar`. Deliberately keeps this
/// widget's own `(currentRoute, body)` API and content-area padding/scroll
/// behavior unchanged so none of its 9 call sites (or their own body
/// content) need to change — only the shared chrome swaps, per Issue #48's
/// "이번 작업에서는 개별 화면 디자인 교체를 시작하지 않는다" scope limit.
class StaffAppShell extends StatelessWidget {
  const StaffAppShell({required this.currentRoute, required this.body, super.key});

  final String currentRoute;
  final Widget body;

  static TabletMenuItem _menuItemFor(String route) {
    return switch (route) {
      AppRoutes.staffHome => TabletMenuItem.home,
      _ => TabletMenuItem.customerSearch,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(StaffRadii.shell),
            border: Border.all(color: StaffColors.cardBorder),
            boxShadow: StaffShadows.shell,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(StaffRadii.shell),
            child: Column(
              children: <Widget>[
                const TabletHeader(),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      TabletNavSidebar(
                        activeMenuItem: _menuItemFor(currentRoute),
                        sessionCount: LastIntentSessionScope.of(context).activeCount,
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: body,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
