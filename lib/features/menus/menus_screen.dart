import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/dates.dart';
import '../../core/utils/dishes.dart';
import '../../data/models/daily_menu.dart';
import '../../data/providers.dart';
import '../../shared/widgets/async_states.dart';
import '../../shared/widgets/status_badge.dart';
import 'meal_composition_sheet.dart';

/// Onglet « Réserver » : menus de la semaine ISO, navigation ◀ / ▶,
/// sélection d'un jour → feuille de composition du repas.
class MenusScreen extends ConsumerStatefulWidget {
  const MenusScreen({super.key});

  @override
  ConsumerState<MenusScreen> createState() => _MenusScreenState();
}

class _MenusScreenState extends ConsumerState<MenusScreen> {
  DateTime _anchor = DateTime.now();

  ({int week, int year}) get _weekKey =>
      (week: isoWeekNumber(_anchor), year: isoWeekYear(_anchor));

  Future<void> _openComposition(DailyMenu menu) async {
    final reserved = await MealCompositionSheet.show(context, menu);
    if (reserved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Réservation confirmée !'),
          backgroundColor: context.appColors.success,
        ),
      );
      ref.invalidate(myReservationsProvider);
      ref.invalidate(weekMenusProvider(_weekKey));
      ref.invalidate(menuTimeSlotsProvider(menu.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final menusAsync = ref.watch(weekMenusProvider(_weekKey));
    final days = weekDays(_anchor);
    final rangeLabel =
        '${DateFormat('d MMM', 'fr_FR').format(days.first)} – '
        '${DateFormat('d MMM', 'fr_FR').format(days.last)}';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Menus de la semaine',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      'Semaine ${_weekKey.week} • $rangeLabel',
                      style: TextStyle(
                        color: colors.mutedForeground,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Semaine précédente',
                onPressed: () =>
                    setState(() => _anchor = addWeeks(_anchor, -1)),
              ),
              TextButton(
                onPressed: () => setState(() => _anchor = DateTime.now()),
                child: const Text('Semaine actuelle'),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Semaine suivante',
                onPressed: () => setState(() => _anchor = addWeeks(_anchor, 1)),
              ),
            ],
          ),
        ),
        Expanded(
          child: menusAsync.when(
            loading: () => const LoadingState(),
            error: (e, _) {
              if (e is ApiException && e.isNotFound) {
                // État normal : le restaurateur n'a pas encore publié la semaine.
                return const EmptyState(
                  icon: Icons.restaurant_menu,
                  title: 'Menu de la semaine pas encore disponible',
                  subtitle:
                      'Les menus apparaîtront dès leur publication par le restaurant.',
                );
              }
              return ErrorState(
                message: e is ApiException
                    ? e.message
                    : 'Impossible de charger les menus',
                onRetry: () => ref.invalidate(weekMenusProvider(_weekKey)),
              );
            },
            data: (menus) => RefreshIndicator(
              onRefresh: () async =>
                  ref.invalidate(weekMenusProvider(_weekKey)),
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: days.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final day = days[index];
                  final menu = menus
                      .where((m) => isSameDay(m.date, day))
                      .firstOrNull;
                  return _DayCard(
                    day: day,
                    menu: menu,
                    onTap: menu != null ? () => _openComposition(menu) : null,
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({required this.day, required this.menu, this.onTap});

  final DateTime day;
  final DailyMenu? menu;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final m = menu;
    final past = m != null &&
        (isDayPast(m.date) || areAllSlotsPast(m.date));
    final selectable = m != null && !past;
    final dayLabel = toBeginningOfSentenceCase(
      DateFormat('EEEE d MMMM', 'fr_FR').format(day),
    );

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: selectable ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      dayLabel,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: past ? colors.mutedForeground : colors.foreground,
                      ),
                    ),
                  ),
                  if (past)
                    const StatusBadge('Passé', variant: BadgeVariant.secondary)
                  else if (m != null)
                    Icon(
                      Icons.chevron_right,
                      color: colors.mutedForeground,
                    ),
                ],
              ),
              const SizedBox(height: 6),
              if (m == null)
                Text(
                  'Pas de menu ce jour',
                  style: TextStyle(color: colors.mutedForeground, fontSize: 13),
                )
              else
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    _CountLabel(
                      icon: Icons.local_dining,
                      label: 'Entrées (${getStarters(m).length})',
                    ),
                    _CountLabel(
                      icon: Icons.restaurant,
                      label: 'Plats (${getMainDishes(m).length})',
                    ),
                    _CountLabel(
                      icon: Icons.icecream_outlined,
                      label: 'Desserts (${getDesserts(m).length})',
                    ),
                    if (m.timeSlots != null)
                      _CountLabel(
                        icon: Icons.schedule,
                        label: '${m.timeSlots!.length} créneaux',
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountLabel extends StatelessWidget {
  const _CountLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: colors.mutedForeground),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(color: colors.mutedForeground, fontSize: 13),
        ),
      ],
    );
  }
}
