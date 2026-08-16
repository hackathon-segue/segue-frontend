import 'package:flutter/material.dart';

import '../utils/staff_design_tokens.dart';

/// Matches the Figma "Input" (check-on variant): a filled 16x16 checkbox
/// with a white check glyph, followed by a single label string. Read-only
/// — SCHEMA.md's `customer_consent` stores one status/scope per customer,
/// not per-row flags, so these three rows are always shown checked.
class StaffCheckRow extends StatelessWidget {
  const StaffCheckRow({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 16,
          height: 16,
          margin: const EdgeInsets.only(top: 2),
          decoration: BoxDecoration(
            color: StaffColors.primary,
            border: Border.all(color: StaffColors.primary, width: 1.5),
            borderRadius: BorderRadius.circular(3),
          ),
          child: const Icon(Icons.check, size: 10, color: Colors.white),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: StaffText.body14)),
      ],
    );
  }
}
