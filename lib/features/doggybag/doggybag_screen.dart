import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/dates.dart';
import '../../data/models/dish.dart';
import '../../data/providers.dart';
import '../../shared/widgets/status_badge.dart';
import 'doggybag_cart.dart';

/// Onglet DoggyBag : plats à emporter par jour (semaine courante → S+2),
/// deadlines quotidiennes, panier local et confirmation groupée.
class DoggyBagScreen extends ConsumerStatefulWidget {
  const DoggyBagScreen({super.key});

  @override
  ConsumerState<DoggyBagScreen> createState() => _DoggyBagScreenState();
}

class _DoggyBagScreenState extends ConsumerState<DoggyBagScreen> {
  /// Offset de semaine borné 0 → 2 (pas de passé, max 2 semaines à venir).
  int _weekOffset = 0;
  Timer? _refreshTimer;
  bool _isSubmitting = false;

  List<DateTime> get _days =>
      weekDays(addWeeks(DateTime.now(), _weekOffset));

  @override
  void initState() {
    super.initState();
    // Stocks quasi temps réel : refetch 60 s (cadence webapp).
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      for (final day in _days) {
        ref.invalidate(doggyBagAvailableProvider(day));
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _confirmCart() async {
    final cart = ref.read(doggyBagCartProvider);
    if (cart.isEmpty) return;
    setState(() => _isSubmitting = true);
    try {
      // Un POST par item, en parallèle (pickupDate dérivé côté API).
      await Future.wait(cart.map(
        (item) => ref.read(doggyBagRepositoryProvider).create(
              dishId: item.dish.id,
              quantity: item.quantity,
            ),
      ));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('DoggyBags réservés !'),
          backgroundColor: context.appColors.success,
        ),
      );
      ref.read(doggyBagCartProvider.notifier).clear();
      ref.invalidate(myDoggyBagReservationsProvider);
      for (final day in _days) {
        ref.invalidate(doggyBagAvailableProvider(day));
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: context.appColors.destructive,
        ),
      );
      for (final day in _days) {
        ref.invalidate(doggyBagAvailableProvider(day));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final days = _days;
    final cart = ref.watch(doggyBagCartProvider);
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
                      'DoggyBag',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      'Semaine ${isoWeekNumber(days.first)} • $rangeLabel',
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
                onPressed: _weekOffset > 0
                    ? () => setState(() => _weekOffset--)
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _weekOffset < 2
                    ? () => setState(() => _weekOffset++)
                    : null,
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: days.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _DayAvailability(day: days[i]),
          ),
        ),
        if (cart.isNotEmpty)
          _CartSummary(isSubmitting: _isSubmitting, onConfirm: _confirmCart),
      ],
    );
  }
}

class _DayAvailability extends ConsumerWidget {
  const _DayAvailability({required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final dayLabel = toBeginningOfSentenceCase(
      DateFormat('EEEE d MMMM', 'fr_FR').format(day),
    );
    final past = isDayPast(day);

    return Card(
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
                  const StatusBadge('Passé', variant: BadgeVariant.secondary),
              ],
            ),
            const SizedBox(height: 8),
            if (past)
              Text(
                'Jour passé — plus de réservation possible',
                style: TextStyle(color: colors.mutedForeground, fontSize: 13),
              )
            else
              _DishList(day: day),
          ],
        ),
      ),
    );
  }
}

class _DishList extends ConsumerWidget {
  const _DishList({required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final dishesAsync = ref.watch(doggyBagAvailableProvider(day));

    return dishesAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (e, _) {
        if (e is ApiException && e.isNotFound) {
          return Text(
            'Aucun plat à emporter ce jour',
            style: TextStyle(color: colors.mutedForeground, fontSize: 13),
          );
        }
        return Row(
          children: [
            Expanded(
              child: Text(
                e is ApiException ? e.message : 'Erreur de chargement',
                style: TextStyle(color: colors.destructive, fontSize: 13),
              ),
            ),
            TextButton(
              onPressed: () =>
                  ref.invalidate(doggyBagAvailableProvider(day)),
              child: const Text('Réessayer'),
            ),
          ],
        );
      },
      data: (dishes) {
        final eligible =
            dishes.where((d) => d.isDoggyBagEligible).toList();
        if (eligible.isEmpty) {
          return Text(
            'Aucun plat à emporter ce jour',
            style: TextStyle(color: colors.mutedForeground, fontSize: 13),
          );
        }
        final deadline = eligible
            .map((d) => d.doggyBagDeadline)
            .whereType<String>()
            .firstOrNull;
        final deadlinePassed =
            deadline != null && isTimeSlotPast(day, deadline);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (deadline != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: StatusBadge(
                  deadlinePassed
                      ? 'Délai dépassé (${deadlineLabel(deadline).toLowerCase()})'
                      : deadlineLabel(deadline),
                  variant: deadlinePassed
                      ? BadgeVariant.destructive
                      : BadgeVariant.warning,
                ),
              ),
            ...eligible.map(
              (dish) => _DishRow(
                dish: dish,
                day: day,
                locked: deadlinePassed,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DishRow extends ConsumerWidget {
  const _DishRow({required this.dish, required this.day, required this.locked});

  final Dish dish;
  final DateTime day;
  final bool locked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final quantity = ref.watch(
      doggyBagCartProvider.select(
        (items) => items
            .where((i) => i.dish.id == dish.id)
            .map((i) => i.quantity)
            .firstOrNull ??
            0,
      ),
    );
    final available = dish.availableForDoggyBag;
    final soldOut = available <= 0;
    final cart = ref.read(doggyBagCartProvider.notifier);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dish.name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  soldOut ? 'Épuisé' : '$available dispo',
                  style: TextStyle(
                    fontSize: 12,
                    color: soldOut
                        ? colors.destructive
                        : available <= 3
                            ? colors.warning
                            : colors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (!locked && !soldOut)
            quantity == 0
                ? OutlinedButton.icon(
                    onPressed: () => cart.add(dish, day),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Ajouter'),
                  )
                : Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () => cart.decrement(dish.id),
                      ),
                      Text(
                        '$quantity',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        color: AppColors.brandOrange,
                        onPressed:
                            quantity < DoggyBagCartNotifier.maxFor(dish)
                                ? () => cart.increment(dish.id)
                                : null,
                      ),
                    ],
                  ),
        ],
      ),
    );
  }
}

class _CartSummary extends ConsumerWidget {
  const _CartSummary({required this.isSubmitting, required this.onConfirm});

  final bool isSubmitting;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final notifier = ref.read(doggyBagCartProvider.notifier);
    ref.watch(doggyBagCartProvider);
    final grouped = notifier.groupedByDate();
    final total = notifier.totalItems;

    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Mon panier ($total)',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 160),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final entry in grouped.entries) ...[
                        Text(
                          toBeginningOfSentenceCase(
                            DateFormat('EEEE d MMMM', 'fr_FR')
                                .format(entry.key),
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.mutedForeground,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        ...entry.value.map(
                          (item) => Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${item.dish.name} ×${item.quantity}',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    size: 18),
                                color: colors.destructive,
                                visualDensity: VisualDensity.compact,
                                onPressed: () =>
                                    ref
                                        .read(doggyBagCartProvider.notifier)
                                        .remove(item.dish.id),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.categoryDoggyBag,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isSubmitting ? null : onConfirm,
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Confirmer la réservation'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
