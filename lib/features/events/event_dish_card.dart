import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/event_dish.dart';

/// Carte de choix d'un plat d'événement (équivalent événementiel de
/// [DishOptionCard], sans gestion de quantités).
class EventDishOptionCard extends StatelessWidget {
  const EventDishOptionCard({
    super.key,
    required this.dish,
    required this.selected,
    required this.onTap,
  });

  final EventDish dish;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: selected ? AppColors.categoryEvent : colors.border,
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
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
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                selected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: selected
                    ? AppColors.categoryEvent
                    : colors.mutedForeground,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
