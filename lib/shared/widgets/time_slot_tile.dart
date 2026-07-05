import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/dates.dart';
import '../../data/models/time_slot.dart';
import 'status_badge.dart';

/// Créneau horaire : places restantes, barre de remplissage, badges
/// Passé / COMPLET / Bientôt complet / Disponible.
class TimeSlotTile extends StatelessWidget {
  const TimeSlotTile({
    super.key,
    required this.slot,
    required this.selected,
    required this.isPast,
    required this.onTap,
  });

  final TimeSlot slot;
  final bool selected;
  final bool isPast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final disabled = isPast || slot.isFull;
    final fillRatio =
        slot.capacity > 0 ? slot.reservedCount / slot.capacity : 0.0;

    final badge = isPast
        ? const StatusBadge('Passé', variant: BadgeVariant.secondary)
        : slot.isFull
            ? const StatusBadge('COMPLET', variant: BadgeVariant.destructive)
            : slot.isAlmostFull
                ? const StatusBadge(
                    'Bientôt complet',
                    variant: BadgeVariant.warning,
                  )
                : const StatusBadge(
                    'Disponible',
                    variant: BadgeVariant.success,
                  );

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 18,
                      color:
                          selected ? AppColors.brandOrange : colors.mutedForeground,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${formatTimeHm(slot.startTime)} – ${formatTimeHm(slot.endTime)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    badge,
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: fillRatio,
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${slot.remainingSpots} place${slot.remainingSpots > 1 ? 's' : ''}',
                      style: TextStyle(
                        color: colors.mutedForeground,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
