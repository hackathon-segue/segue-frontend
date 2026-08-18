import 'package:flutter/material.dart';

import '../utils/staff_design_tokens.dart';

/// Matches the Figma "Input" checkbox: filled 16x16 box with a white check
/// glyph when checked (node 14:964's "동의 범위" rows), and an empty white
/// box with a #D1D5DB 1.5px border when unchecked (node 14:663 "check").
///
/// Tappable — the CA must explicitly check each of the three "동의 범위"
/// rows before the "동의하고 장바구니 확인" button becomes usable (see
/// [ConsentScreen]). SCHEMA.md's `customer_consent` still only stores one
/// overall status/scope per customer; these three checks are a client-side
/// confirmation gate, not three separate persisted fields.
class StaffCheckRow extends StatelessWidget {
  const StaffCheckRow({
    required this.label,
    required this.checked,
    required this.onChanged,
    super.key,
  });

  final String label;
  final bool checked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final Widget box = Container(
      width: 16,
      height: 16,
      margin: const EdgeInsets.only(top: 2),
      decoration: BoxDecoration(
        color: checked ? StaffColors.primary : Colors.white,
        border: Border.all(
          color: checked ? StaffColors.primary : StaffColors.inputBorder,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(3),
      ),
      child: checked ? const Icon(Icons.check, size: 10, color: Colors.white) : null,
    );

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: () => onChanged(!checked),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            box,
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: StaffText.body14)),
          ],
        ),
      ),
    );
  }
}
