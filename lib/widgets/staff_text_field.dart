import 'package:flutter/material.dart';

import '../utils/staff_design_tokens.dart';

/// Matches the Figma "Input" (text variant) component: a 14px label above
/// a 38px-tall white box, 4px radius, #D1D5DB border.
class StaffTextField extends StatelessWidget {
  const StaffTextField({
    required this.label,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
    super.key,
  });

  final String label;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: StaffText.body14),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          style: StaffText.body14,
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: Colors.white,
            constraints: const BoxConstraints(minHeight: StaffSizes.inputHeight),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(StaffRadii.input),
              borderSide: const BorderSide(color: StaffColors.inputBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(StaffRadii.input),
              borderSide: const BorderSide(color: StaffColors.inputBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(StaffRadii.input),
              borderSide: const BorderSide(color: StaffColors.ink, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(StaffRadii.input),
              borderSide: const BorderSide(color: Colors.red),
            ),
          ),
        ),
      ],
    );
  }
}
