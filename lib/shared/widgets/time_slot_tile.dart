import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/dates.dart';
import 'status_badge.dart';

/// Créneau horaire (menu ou événement) : places restantes, barre de
/// remplissage, badges Passé / COMPLET / Bientôt complet / Disponible.
class TimeSlotTile extends StatelessWidget {
  const TimeSlotTile({
    super.key,
    required this.startTime,
    required this.endTime,
    required this.capacity,
    required this.reservedCount,
    required this.selected,
    required this.isPast,
    required this.onTap,
    this.accentColor = AppColors.brandOrange,
  });

  /// "HH:MM:SS"
  final String startTime;
  final String endTime;
  final int capacity;
  final int reservedCount;
  final bool selected;
  final bool isPast;
  final VoidCallback onTap;
  final Color accentColor;

  int get _remaining => capacity - reservedCount;
  bool get _isFull => _remaining <= 0;
  bool get _isAlmostFull => capacity > 0 && reservedCount / capacity >= 0.9;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final disabled = isPast || _isFull;
    final fillRatio = capacity > 0 ? reservedCount / capacity : 0.0;

    final badge = isPast
        ? const StatusBadge('Passé', variant: BadgeVariant.secondary)
        : _isFull
            ? const StatusBadge('COMPLET', variant: BadgeVariant.destructive)
            : _isAlmostFull
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
            color: selected ? accentColor : colors.border,
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
                      color: selected ? accentColor : colors.mutedForeground,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${formatTimeHm(startTime)} – ${formatTimeHm(endTime)}',
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
                      '$_remaining place${_remaining > 1 ? 's' : ''}',
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
