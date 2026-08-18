import 'package:flutter/material.dart';

import '../utils/staff_design_tokens.dart';
import 'staff_sidebar.dart';
import 'staff_top_bar.dart';

/// Shared layout shell for every staff/tablet screen, matching Figma's
/// top-level frame exactly: `get_metadata` on all 6 reference nodes
/// confirms the white rounded-12/bordered/shadowed card fills its 1440x900
/// frame edge-to-edge (`size-full`, zero surrounding margin) — there is no
/// inset "page background" around it. It contains a fixed top bar, a
/// persistent 240px sidebar (no collapse/drawer variant appears anywhere
/// in the Figma file) and a scrollable content column that simply fills
/// the remaining body width (1200 - 24*2 = 1152 at the reference size, no
/// independent max-width component in the design).
///
/// Deliberately does not prescribe the inner content's layout (gap/title
/// style) beyond shared scroll + padding — the reference file itself is
/// not fully consistent about title/subtitle spacing across screens, so
/// each screen builds its own body content.
class StaffAppShell extends StatelessWidget {
  const StaffAppShell({required this.currentRoute, required this.body, super.key});

  final String currentRoute;
  final Widget body;

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
                const StaffTopBar(),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      StaffSidebar(currentRoute: currentRoute),
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
