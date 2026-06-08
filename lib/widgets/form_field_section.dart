import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class FormFieldSection extends StatelessWidget {
  final String label;
  final Widget field;

  const FormFieldSection({
    super.key,
    required this.label,
    required this.field,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        field,
      ],
    );
  }
}
