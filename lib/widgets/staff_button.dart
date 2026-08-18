import 'package:flutter/material.dart';

import '../utils/staff_design_tokens.dart';

/// Matches the Figma "Button" component's four variants exactly
/// (default/primary/secondary/chip). Auto-sized to its label (min-width
/// only) — never stretched — matching every button instance in the
/// reference file.
enum StaffButtonVariant { link, primary, secondary, chip }

class StaffButton extends StatelessWidget {
  const StaffButton({
    required this.label,
    required this.variant,
    this.onPressed,
    super.key,
  });

  final String label;
  final StaffButtonVariant variant;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case StaffButtonVariant.link:
        return _tappable(
          onPressed: onPressed,
          child: Text(label, style: StaffText.link14Muted),
        );
      case StaffButtonVariant.primary:
        return _tappable(
          onPressed: onPressed,
          child: Container(
            constraints: const BoxConstraints(minWidth: 60),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: StaffColors.primary,
              borderRadius: BorderRadius.circular(StaffRadii.button),
            ),
            child: Text(
              label,
              style: StaffText.buttonPrimary14,
              textAlign: TextAlign.center,
            ),
          ),
        );
      case StaffButtonVariant.secondary:
        return _tappable(
          onPressed: onPressed,
          child: Container(
            constraints: const BoxConstraints(minWidth: 60),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: StaffColors.ink),
              borderRadius: BorderRadius.circular(StaffRadii.button),
            ),
            child: Text(
              label,
              style: StaffText.buttonSecondary14,
              textAlign: TextAlign.center,
            ),
          ),
        );
      case StaffButtonVariant.chip:
        return _tappable(
          onPressed: onPressed,
          child: Container(
            constraints: const BoxConstraints(minWidth: 40),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: StaffColors.chipBg,
              border: Border.all(color: StaffColors.cardBorder),
              borderRadius: BorderRadius.circular(StaffRadii.chip),
            ),
            child: Text(
              label,
              style: StaffText.buttonSecondary14,
              textAlign: TextAlign.center,
            ),
          ),
        );
    }
  }

  Widget _tappable({required Widget child, VoidCallback? onPressed}) {
    // `type: transparency` is required — the default `MaterialType.canvas`
    // expands to fill all available space instead of hugging `child`,
    // which was silently stretching every StaffButton (e.g. the "데이터
    // 이용 동의 확인" button inside `Align`) to its parent's width.
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(StaffRadii.button),
        child: child,
      ),
    );
  }
}
