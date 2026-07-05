import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/dates.dart';
import '../../data/models/doggybag_reservation.dart';
import '../../data/models/event_reservation.dart';
import '../../data/models/reservation.dart';
import '../../data/providers.dart';
import '../../shared/widgets/async_states.dart';
import '../../shared/widgets/status_badge.dart';
import '../dashboard/edit_reservation_sheet.dart';

/// Mes commandes : hero compteurs + 3 onglets Repas / DoggyBag / Événements,
/// segments En cours / Passé(e)s / Annulés, édition et annulation.
class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final meals = ref.watch(myReservationsProvider);
    final bags = ref.watch(myDoggyBagReservationsProvider);
    final events = ref.watch(myEventReservationsProvider);

    final upcomingMeals = (meals.valueOrNull ?? [])
        .where((r) =>
            !r.isCancelled &&
            r.dailyMenu != null &&
            !isDayPast(r.dailyMenu!.date))
        .length;
    final bagsToCollect = (bags.valueOrNull ?? [])
        .where((b) =>
            b.status == DoggyBagStatus.confirmed && !isDayPast(b.pickupDate))
        .length;
    final upcomingEvents = (events.valueOrNull ?? [])
        .where((e) =>
            !e.isCancelled &&
            e.specialEvent != null &&
            !isDayPast(e.specialEvent!.eventDate))
        .length;

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                _CounterChip(
                  color: AppColors.categoryMeal,
                  count: upcomingMeals,
                  label: 'repas à venir',
                ),
                const SizedBox(width: 8),
                _CounterChip(
                  color: AppColors.categoryDoggyBag,
                  count: bagsToCollect,
                  label: 'à récupérer',
                ),
                const SizedBox(width: 8),
                _CounterChip(
                  color: AppColors.categoryEvent,
                  count: upcomingEvents,
                  label: 'événements',
                ),
              ],
            ),
          ),
          TabBar(
            tabs: [
              Tab(text: 'Repas (${(meals.valueOrNull ?? []).length})'),
              Tab(text: 'DoggyBag (${(bags.valueOrNull ?? []).length})'),
              Tab(text: 'Événements (${(events.valueOrNull ?? []).length})'),
            ],
            labelStyle: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colors.foreground,
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _MealsTab(async: meals),
                _DoggyBagsTab(async: bags),
                _EventsTab(async: events),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CounterChip extends StatelessWidget {
  const _CounterChip({
    required this.color,
    required this.count,
    required this.label,
  });

  final Color color;
  final int count;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Column(
            children: [
              Text(
                '$count',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.mutedForeground,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<bool> _confirmCancel(BuildContext context, String title) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: const Text('Cette action est définitive.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Non'),
        ),
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: context.appColors.destructive,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Oui, supprimer'),
        ),
      ],
    ),
  );
  return confirmed == true;
}

void _showApiError(BuildContext context, Object e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(e is ApiException ? e.message : 'Une erreur est survenue'),
      backgroundColor: context.appColors.destructive,
    ),
  );
}

enum _Segment { active, past, cancelled }

class _SegmentPicker extends StatelessWidget {
  const _SegmentPicker({
    required this.value,
    required this.onChanged,
    required this.pastLabel,
  });

  final _Segment value;
  final ValueChanged<_Segment> onChanged;
  final String pastLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: SegmentedButton<_Segment>(
        segments: [
          const ButtonSegment(value: _Segment.active, label: Text('En cours')),
          ButtonSegment(value: _Segment.past, label: Text(pastLabel)),
          const ButtonSegment(
            value: _Segment.cancelled,
            label: Text('Annulés'),
          ),
        ],
        selected: {value},
        onSelectionChanged: (s) => onChanged(s.first),
        showSelectedIcon: false,
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 12)),
        ),
      ),
    );
  }
}

// --- Onglet Repas -----------------------------------------------------------

class _MealsTab extends ConsumerStatefulWidget {
  const _MealsTab({required this.async});

  final AsyncValue<List<Reservation>> async;

  @override
  ConsumerState<_MealsTab> createState() => _MealsTabState();
}

class _MealsTabState extends ConsumerState<_MealsTab> {
  _Segment _segment = _Segment.active;

  Future<void> _cancel(Reservation r) async {
    if (!await _confirmCancel(context, 'Supprimer cette réservation ?')) {
      return;
    }
    try {
      await ref.read(reservationsRepositoryProvider).cancel(r.id);
      ref.invalidate(myReservationsProvider);
    } on ApiException catch (e) {
      if (mounted) _showApiError(context, e);
    }
  }

  Future<void> _edit(Reservation r) async {
    final changed = await EditReservationSheet.show(context, r);
    if (changed == true) ref.invalidate(myReservationsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return widget.async.when(
      loading: () => const LoadingState(),
      error: (e, _) => ErrorState(
        message: e is ApiException ? e.message : 'Erreur de chargement',
        onRetry: () => ref.invalidate(myReservationsProvider),
      ),
      data: (all) {
        DateTime? dateOf(Reservation r) => r.dailyMenu?.date;
        final items = switch (_segment) {
          _Segment.active => all
              .where((r) =>
                  !r.isCancelled &&
                  dateOf(r) != null &&
                  !isDayPast(dateOf(r)!))
              .toList()
            ..sort((a, b) => dateOf(a)!.compareTo(dateOf(b)!)),
          _Segment.past => all
              .where((r) =>
                  !r.isCancelled && dateOf(r) != null && isDayPast(dateOf(r)!))
              .toList()
            ..sort((a, b) => dateOf(b)!.compareTo(dateOf(a)!)),
          _Segment.cancelled => all.where((r) => r.isCancelled).toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
        };

        return Column(
          children: [
            _SegmentPicker(
              value: _segment,
              pastLabel: 'Passées',
              onChanged: (s) => setState(() => _segment = s),
            ),
            Expanded(
              child: items.isEmpty
                  ? const EmptyState(
                      icon: Icons.restaurant_menu,
                      title: 'Aucune réservation ici',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final r = items[i];
                        final date = dateOf(r);
                        final active = _segment == _Segment.active;
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        date != null
                                            ? formatDayLong(date)
                                            : 'Date inconnue',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    switch (_segment) {
                                      _Segment.active => const StatusBadge(
                                          'Réservé ✓',
                                          variant: BadgeVariant.success,
                                        ),
                                      _Segment.past => const StatusBadge(
                                          'Passé',
                                          variant: BadgeVariant.secondary,
                                        ),
                                      _Segment.cancelled => const StatusBadge(
                                          'Annulé',
                                          variant: BadgeVariant.destructive,
                                        ),
                                    },
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (r.starter != null)
                                  _DishLine(
                                    icon: Icons.local_dining,
                                    label: r.starter!.name,
                                  ),
                                if (r.dish != null)
                                  _DishLine(
                                    icon: Icons.restaurant,
                                    label: r.dish!.name,
                                    bold: true,
                                  ),
                                if (r.dessert != null)
                                  _DishLine(
                                    icon: Icons.icecream_outlined,
                                    label: r.dessert!.name,
                                  ),
                                if (r.timeSlot != null)
                                  _DishLine(
                                    icon: Icons.schedule,
                                    label:
                                        '${formatTimeHm(r.timeSlot!.startTime)} – ${formatTimeHm(r.timeSlot!.endTime)}',
                                  ),
                                if (active) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit_outlined,
                                          size: 20,
                                        ),
                                        tooltip: 'Modifier',
                                        onPressed: () => _edit(r),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.close,
                                          size: 20,
                                          color: colors.destructive,
                                        ),
                                        tooltip: 'Annuler',
                                        onPressed: () => _cancel(r),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _DishLine extends StatelessWidget {
  const _DishLine({required this.icon, required this.label, this.bold = false});

  final IconData icon;
  final String label;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Icon(icon, size: 15, color: colors.mutedForeground),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Onglet DoggyBag ----------------------------------------------------------

class _DoggyBagsTab extends ConsumerStatefulWidget {
  const _DoggyBagsTab({required this.async});

  final AsyncValue<List<DoggyBagReservation>> async;

  @override
  ConsumerState<_DoggyBagsTab> createState() => _DoggyBagsTabState();
}

class _DoggyBagsTabState extends ConsumerState<_DoggyBagsTab> {
  _Segment _segment = _Segment.active;

  Future<void> _cancel(DoggyBagReservation b) async {
    if (!await _confirmCancel(context, 'Annuler ce DoggyBag ?')) return;
    try {
      await ref.read(doggyBagRepositoryProvider).cancel(b.id);
      ref.invalidate(myDoggyBagReservationsProvider);
    } on ApiException catch (e) {
      if (mounted) _showApiError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return widget.async.when(
      loading: () => const LoadingState(),
      error: (e, _) => ErrorState(
        message: e is ApiException ? e.message : 'Erreur de chargement',
        onRetry: () => ref.invalidate(myDoggyBagReservationsProvider),
      ),
      data: (all) {
        final items = switch (_segment) {
          _Segment.active => all
              .where((b) => b.status == DoggyBagStatus.confirmed)
              .toList()
            ..sort((a, b) => a.pickupDate.compareTo(b.pickupDate)),
          _Segment.past => all
              .where((b) => b.status == DoggyBagStatus.pickedUp)
              .toList()
            ..sort((a, b) => b.pickupDate.compareTo(a.pickupDate)),
          _Segment.cancelled => all
              .where((b) => b.status == DoggyBagStatus.cancelled)
              .toList()
            ..sort((a, b) => b.pickupDate.compareTo(a.pickupDate)),
        };

        return Column(
          children: [
            _SegmentPicker(
              value: _segment,
              pastLabel: 'Récupérés',
              onChanged: (s) => setState(() => _segment = s),
            ),
            Expanded(
              child: items.isEmpty
                  ? const EmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: 'Aucun DoggyBag ici',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final b = items[i];
                        return Card(
                          child: ListTile(
                            leading: const Icon(
                              Icons.inventory_2,
                              color: AppColors.categoryDoggyBag,
                            ),
                            title: Text(b.dish?.name ?? 'Plat'),
                            subtitle: Text(
                              '×${b.quantity} • retrait le ${formatDateMedium(b.pickupDate)}',
                              style: TextStyle(
                                color: colors.mutedForeground,
                                fontSize: 12,
                              ),
                            ),
                            trailing: switch (b.status) {
                              DoggyBagStatus.confirmed => IconButton(
                                  icon: Icon(
                                    Icons.close,
                                    size: 20,
                                    color: colors.destructive,
                                  ),
                                  tooltip: 'Annuler',
                                  onPressed: () => _cancel(b),
                                ),
                              DoggyBagStatus.pickedUp => const StatusBadge(
                                  'Récupéré ✓',
                                  variant: BadgeVariant.success,
                                ),
                              DoggyBagStatus.cancelled => const StatusBadge(
                                  'Annulé',
                                  variant: BadgeVariant.destructive,
                                ),
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

// --- Onglet Événements --------------------------------------------------------

class _EventsTab extends ConsumerStatefulWidget {
  const _EventsTab({required this.async});

  final AsyncValue<List<EventReservation>> async;

  @override
  ConsumerState<_EventsTab> createState() => _EventsTabState();
}

class _EventsTabState extends ConsumerState<_EventsTab> {
  _Segment _segment = _Segment.active;

  Future<void> _cancel(EventReservation e) async {
    if (!await _confirmCancel(context, 'Annuler cette inscription ?')) return;
    try {
      await ref.read(specialEventsRepositoryProvider).cancelReservation(e.id);
      ref.invalidate(myEventReservationsProvider);
    } on ApiException catch (err) {
      if (mounted) _showApiError(context, err);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return widget.async.when(
      loading: () => const LoadingState(),
      error: (e, _) => ErrorState(
        message: e is ApiException ? e.message : 'Erreur de chargement',
        onRetry: () => ref.invalidate(myEventReservationsProvider),
      ),
      data: (all) {
        DateTime? dateOf(EventReservation e) => e.specialEvent?.eventDate;
        final items = switch (_segment) {
          _Segment.active => all
              .where((e) =>
                  !e.isCancelled &&
                  dateOf(e) != null &&
                  !isDayPast(dateOf(e)!))
              .toList()
            ..sort((a, b) => dateOf(a)!.compareTo(dateOf(b)!)),
          _Segment.past => all
              .where((e) =>
                  !e.isCancelled && dateOf(e) != null && isDayPast(dateOf(e)!))
              .toList()
            ..sort((a, b) => dateOf(b)!.compareTo(dateOf(a)!)),
          _Segment.cancelled => all.where((e) => e.isCancelled).toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
        };

        return Column(
          children: [
            _SegmentPicker(
              value: _segment,
              pastLabel: 'Passés',
              onChanged: (s) => setState(() => _segment = s),
            ),
            Expanded(
              child: items.isEmpty
                  ? const EmptyState(
                      icon: Icons.auto_awesome_outlined,
                      title: 'Aucun événement ici',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final e = items[i];
                        final date = dateOf(e);
                        return Card(
                          child: ListTile(
                            leading: const Icon(
                              Icons.auto_awesome,
                              color: AppColors.categoryEvent,
                            ),
                            title: Text(e.specialEvent?.name ?? 'Événement'),
                            subtitle: Text(
                              [
                                if (date != null) formatDateMedium(date),
                                if (e.eventTimeSlot != null)
                                  '${formatTimeHm(e.eventTimeSlot!.startTime)} – ${formatTimeHm(e.eventTimeSlot!.endTime)}',
                              ].join(' • '),
                              style: TextStyle(
                                color: colors.mutedForeground,
                                fontSize: 12,
                              ),
                            ),
                            trailing: switch (_segment) {
                              _Segment.active => IconButton(
                                  icon: Icon(
                                    Icons.close,
                                    size: 20,
                                    color: colors.destructive,
                                  ),
                                  tooltip: 'Annuler',
                                  onPressed: () => _cancel(e),
                                ),
                              _Segment.past => const StatusBadge(
                                  'Passé',
                                  variant: BadgeVariant.secondary,
                                ),
                              _Segment.cancelled => const StatusBadge(
                                  'Annulé',
                                  variant: BadgeVariant.destructive,
                                ),
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
