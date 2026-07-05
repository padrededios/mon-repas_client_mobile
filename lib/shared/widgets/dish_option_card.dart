import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/dishes.dart';
import '../../data/models/dish.dart';
import 'status_badge.dart';

/// Carte de choix d'un plat : badges Épuisé / « N restants » / Spécial,
/// coche de sélection. Un plat épuisé n'est pas sélectionnable, sauf
/// [allowWhenSoldOut] (plat actuellement réservé dans la feuille d'édition).
class DishOptionCard extends StatelessWidget {
  const DishOptionCard({
    super.key,
    required this.dish,
    required this.selected,
    required this.onTap,
    this.allowWhenSoldOut = false,
  });

  final Dish dish;
  final bool selected;
  final VoidCallback onTap;
  final bool allowWhenSoldOut;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final availability = getDishAvailability(dish);
    final soldOut = !availability.available;
    final disabled = soldOut && !allowWhenSoldOut;
    final remaining = availability.remaining;

    return Opacity(
      opacity: disabled ? 0.55 : 1,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: selected ? AppColors.brandOrange : colors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: disabled ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dish.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      if (dish.description?.isNotEmpty ?? false) ...[
                        const SizedBox(height: 2),
                        Text(
                          dish.description!,
                          style: TextStyle(
                            color: colors.mutedForeground,
                            fontSize: 13,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (isDailySpecialType(dish.type))
                            const StatusBadge(
                              'Spécial',
                              variant: BadgeVariant.special,
                            ),
                          if (soldOut)
                            const StatusBadge(
                              'Épuisé',
                              variant: BadgeVariant.destructive,
                            )
                          else if (remaining != null && remaining <= 5)
                            StatusBadge(
                              '$remaining restant${remaining > 1 ? 's' : ''}',
                              variant: BadgeVariant.warning,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  selected
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: selected
                      ? AppColors.brandOrange
                      : colors.mutedForeground,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
