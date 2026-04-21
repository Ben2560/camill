import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/camill_colors.dart';
import '../../../core/theme/camill_theme.dart';

class TaxBreakdownRow extends StatelessWidget {
  final String label;
  final int amount;
  final CamillColors colors;
  final NumberFormat fmt;

  const TaxBreakdownRow({
    super.key,
    required this.label,
    required this.amount,
    required this.colors,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: colors.primary.withAlpha(160),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: camillBodyStyle(12, colors.textMuted))),
        Text(fmt.format(amount),
            style: camillBodyStyle(12, colors.textMuted, weight: FontWeight.w500)),
      ],
    );
  }
}
