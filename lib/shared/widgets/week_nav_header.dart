import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/dates.dart';

/// Navigation de semaine partagée (Accueil, Réserver) : numéro de semaine
/// centré, flèches ◀ / ▶ de part et d'autre, plage de dates en sous-titre.
class WeekNavHeader extends StatelessWidget {
  const WeekNavHeader({
    super.key,
    required this.anchor,
    required this.onPrevious,
    required this.onNext,
  });

  /// Jour quelconque de la semaine affichée.
  final DateTime anchor;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final days = weekDays(anchor);
    final rangeLabel =
        '${DateFormat('d MMM', 'fr_FR').format(days.first)} – '
        '${DateFormat('d MMM', 'fr_FR').format(days.last)}';

    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          tooltip: 'Semaine précédente',
          onPressed: onPrevious,
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                'Semaine ${isoWeekNumber(anchor)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              Text(
                rangeLabel,
                style: TextStyle(color: colors.mutedForeground, fontSize: 13),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          tooltip: 'Semaine suivante',
          onPressed: onNext,
        ),
      ],
    );
  }
}
