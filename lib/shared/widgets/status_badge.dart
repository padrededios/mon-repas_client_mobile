import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

enum BadgeVariant { neutral, secondary, destructive, success, warning, special }

/// Badge de statut — équivalent du composant `Badge` de la webapp.
class StatusBadge extends StatelessWidget {
  const StatusBadge(this.label, {super.key, this.variant = BadgeVariant.neutral});

  final String label;
  final BadgeVariant variant;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final (bg, fg) = switch (variant) {
      BadgeVariant.neutral => (colors.primary, colors.primaryForeground),
      BadgeVariant.secondary => (colors.secondary, colors.secondaryForeground),
      BadgeVariant.destructive => (
          colors.destructive,
          colors.destructiveForeground
        ),
      BadgeVariant.success => (colors.success, Colors.white),
      BadgeVariant.warning => (colors.warning, Colors.white),
      BadgeVariant.special => (AppColors.categoryEvent, Colors.white),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
