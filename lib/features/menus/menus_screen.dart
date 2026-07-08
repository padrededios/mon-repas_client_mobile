import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/dates.dart';
import '../../core/utils/dishes.dart';
import '../../data/models/daily_menu.dart';
import '../../data/models/dish.dart';
import '../../data/providers.dart';
import '../../shared/widgets/async_states.dart';
import '../../shared/widgets/status_badge.dart';
import '../../shared/widgets/week_nav_header.dart';
import '../events/events_screen.dart';
import 'meal_composition_sheet.dart';

/// Onglet « Réserver » : semaine ISO avec navigation ◀ Semaine N ▶ centrée,
/// pastilles de jours (LUN → VEN) puis détail du menu du jour sélectionné.
class MenusScreen extends ConsumerStatefulWidget {
  const MenusScreen({super.key});

  @override
  ConsumerState<MenusScreen> createState() => _MenusScreenState();
}

class _MenusScreenState extends ConsumerState<MenusScreen> {
  DateTime _anchor = DateTime.now();

  /// Jour sélectionné dans les pastilles ; null = choix automatique
  /// (aujourd'hui si visible, sinon le premier jour de la semaine).
  DateTime? _selectedDay;

  ({int week, int year}) get _weekKey =>
      (week: isoWeekNumber(_anchor), year: isoWeekYear(_anchor));

  void _goToWeek(DateTime anchor) {
    setState(() {
      _anchor = anchor;
      _selectedDay = null;
    });
  }

  DateTime _resolveSelectedDay(List<DateTime> days) {
    final selected = _selectedDay;
    if (selected != null && days.any((d) => isSameDay(d, selected))) {
      return selected;
    }
    final today = DateTime.now();
    return days.firstWhere((d) => isSameDay(d, today), orElse: () => days.first);
  }

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
    // Revenir sur l'onglet Réserver ramène toujours à la semaine en cours.
    ref.listen<int>(homeTabIndexProvider, (previous, next) {
      if (next == 1 && previous != 1) {
        _goToWeek(DateTime.now());
      }
    });

    final menusAsync = ref.watch(weekMenusProvider(_weekKey));
    final days = weekDays(_anchor);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
          child: WeekNavHeader(
            anchor: _anchor,
            onPrevious: () => _goToWeek(addWeeks(_anchor, -1)),
            onNext: () => _goToWeek(addWeeks(_anchor, 1)),
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
            data: (menus) {
              // Un événement spécial à la même date prend le pas sur le menu.
              final events =
                  ref.watch(activeEventsProvider).valueOrNull ?? [];
              final reservedEventIds =
                  (ref.watch(myEventReservationsProvider).valueOrNull ?? [])
                      .where((r) => !r.isCancelled)
                      .map((r) => r.specialEventId)
                      .toSet();

              final selectedDay = _resolveSelectedDay(days);
              final selectedEvent = events
                  .where((e) => isSameDay(e.eventDate, selectedDay))
                  .firstOrNull;
              final selectedMenu = menus
                  .where((m) => isSameDay(m.date, selectedDay))
                  .firstOrNull;

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Row(
                      children: [
                        for (final (index, day) in days.indexed) ...[
                          if (index > 0) const SizedBox(width: 8),
                          Expanded(
                            child: _DayPill(
                              day: day,
                              isSelected: isSameDay(day, selectedDay),
                              hasContent: events.any(
                                    (e) => isSameDay(e.eventDate, day),
                                  ) ||
                                  menus.any((m) => isSameDay(m.date, day)),
                              isPast: isDayPast(day),
                              onTap: () =>
                                  setState(() => _selectedDay = day),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(weekMenusProvider(_weekKey));
                        ref.invalidate(activeEventsProvider);
                      },
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        children: [
                          if (selectedEvent != null)
                            EventCard(
                              event: selectedEvent,
                              isReserved:
                                  reservedEventIds.contains(selectedEvent.id),
                              onTap: () => context
                                  .push('/events/${selectedEvent.id}'),
                            )
                          else if (selectedMenu != null)
                            _DayMenuDetail(
                              menu: selectedMenu,
                              onReserve: () => _openComposition(selectedMenu),
                            )
                          else
                            _NoMenuCard(day: selectedDay),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Pastille de jour : « LUN / 6 ». Sélectionnée = orange plein ; jour sans
/// menu = numéro barré et estompé ; jour passé = estompé.
class _DayPill extends StatelessWidget {
  const _DayPill({
    required this.day,
    required this.isSelected,
    required this.hasContent,
    required this.isPast,
    required this.onTap,
  });

  final DateTime day;
  final bool isSelected;
  final bool hasContent;
  final bool isPast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final dimmed = !isSelected && (isPast || !hasContent);
    final dayLabel = DateFormat('EEE', 'fr_FR')
        .format(day)
        .replaceAll('.', '')
        .toUpperCase();

    return Opacity(
      opacity: dimmed ? 0.55 : 1,
      child: Material(
        color: isSelected ? AppColors.brandOrange : colors.card,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.brandOrange : colors.border,
              ),
            ),
            child: Column(
              children: [
                Text(
                  dayLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : colors.mutedForeground,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${day.day}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? Colors.white : colors.foreground,
                    decoration:
                        hasContent ? null : TextDecoration.lineThrough,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Détail du menu du jour sélectionné : entrées, plats et desserts visibles
/// en entier, puis bouton de composition du repas.
class _DayMenuDetail extends StatelessWidget {
  const _DayMenuDetail({required this.menu, required this.onReserve});

  final DailyMenu menu;
  final VoidCallback onReserve;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final past = isDayPast(menu.date) || areAllSlotsPast(menu.date);
    final dayLabel = toBeginningOfSentenceCase(
      DateFormat('EEEE d MMMM', 'fr_FR').format(menu.date),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    dayLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (past)
                  const StatusBadge('Passé', variant: BadgeVariant.secondary)
                else if (menu.timeSlots != null)
                  Text(
                    '${menu.timeSlots!.length} créneaux',
                    style: TextStyle(
                      color: colors.mutedForeground,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _DishSection(
              label: 'Entrées',
              color: colors.success,
              dishes: getStarters(menu),
            ),
            _DishSection(
              label: 'Plats',
              color: AppColors.categoryMeal,
              dishes: getMainDishes(menu),
            ),
            _DishSection(
              label: 'Desserts',
              color: colors.warning,
              dishes: getDesserts(menu),
            ),
            if (!past) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onReserve,
                  icon: const Icon(Icons.restaurant_menu, size: 18),
                  label: const Text('Composer mon repas'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DishSection extends StatelessWidget {
  const _DishSection({
    required this.label,
    required this.color,
    required this.dishes,
  });

  final String label;
  final Color color;
  final List<Dish> dishes;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    if (dishes.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: colors.mutedForeground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ...dishes.map((dish) {
            final availability = getDishAvailability(dish);
            return Padding(
              padding: const EdgeInsets.only(left: 14, bottom: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      dish.name,
                      style: TextStyle(
                        fontSize: 14,
                        color: availability.available
                            ? colors.foreground
                            : colors.mutedForeground,
                      ),
                    ),
                  ),
                  if (!availability.available)
                    const StatusBadge('Épuisé', variant: BadgeVariant.destructive)
                  else if (availability.remaining != null)
                    Text(
                      'Reste ${availability.remaining}',
                      style: TextStyle(
                        fontSize: 12,
                        color: availability.remaining! <= 5
                            ? colors.warning
                            : colors.mutedForeground,
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _NoMenuCard extends StatelessWidget {
  const _NoMenuCard({required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final dayLabel = toBeginningOfSentenceCase(
      DateFormat('EEEE d MMMM', 'fr_FR').format(day),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.no_meals, size: 32, color: colors.mutedForeground),
            const SizedBox(height: 8),
            Text(
              dayLabel,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'Pas de menu ce jour',
              style: TextStyle(color: colors.mutedForeground, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
