import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/dates.dart';
import '../../core/utils/dishes.dart';
import '../../data/models/daily_menu.dart';
import '../../data/models/time_slot.dart';
import '../../data/providers.dart';
import '../../shared/widgets/async_states.dart';
import '../../shared/widgets/dish_option_card.dart';
import '../../shared/widgets/time_slot_tile.dart';
import 'meal_selection.dart';

/// Feuille de composition d'un repas : Entrée / Plat / Dessert / Créneau,
/// bouton de confirmation visible uniquement quand la sélection est complète.
///
/// Renvoie `true` via `Navigator.pop` quand la réservation a été créée.
class MealCompositionSheet extends ConsumerStatefulWidget {
  const MealCompositionSheet({super.key, required this.menu});

  final DailyMenu menu;

  static Future<bool?> show(BuildContext context, DailyMenu menu) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => MealCompositionSheet(menu: menu),
    );
  }

  @override
  ConsumerState<MealCompositionSheet> createState() =>
      _MealCompositionSheetState();
}

class _MealCompositionSheetState extends ConsumerState<MealCompositionSheet> {
  MealSelection _selection = const MealSelection();
  bool _isSubmitting = false;
  Timer? _slotsRefreshTimer;

  DailyMenu get menu => widget.menu;

  @override
  void initState() {
    super.initState();
    // Capacités quasi temps réel : refetch des créneaux toutes les 30 s
    // (même cadence que la webapp).
    _slotsRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      ref.invalidate(menuTimeSlotsProvider(menu.id));
    });
  }

  @override
  void dispose() {
    _slotsRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _confirm() async {
    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(reservationsRepositoryProvider)
          .create(_selection.toCreatePayload());
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: context.appColors.destructive,
        ),
      );
      // Les capacités ont pu changer (créneau complet) : on rafraîchit.
      ref.invalidate(menuTimeSlotsProvider(menu.id));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final starters = getStarters(menu);
    final mains = getMainDishes(menu);
    final desserts = getDesserts(menu);
    final isComplete = _selection.isCompleteFor(menu);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Composer mon repas',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          formatDayLong(menu.date),
                          style: TextStyle(
                            color: colors.mutedForeground,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  if (starters.isNotEmpty) ...[
                    _SectionTitle('Entrée'),
                    ...starters.map((d) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: DishOptionCard(
                            dish: d,
                            selected: _selection.starter?.id == d.id,
                            onTap: () => setState(
                              () => _selection = _selection.toggleStarter(d),
                            ),
                          ),
                        )),
                    const SizedBox(height: 8),
                  ],
                  _SectionTitle('Plat'),
                  ...mains.map((d) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: DishOptionCard(
                          dish: d,
                          selected: _selection.mainDish?.id == d.id,
                          onTap: () => setState(
                            () => _selection = _selection.toggleMainDish(d),
                          ),
                        ),
                      )),
                  const SizedBox(height: 8),
                  if (desserts.isNotEmpty) ...[
                    _SectionTitle('Dessert'),
                    ...desserts.map((d) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: DishOptionCard(
                            dish: d,
                            selected: _selection.dessert?.id == d.id,
                            onTap: () => setState(
                              () => _selection = _selection.toggleDessert(d),
                            ),
                          ),
                        )),
                    const SizedBox(height: 8),
                  ],
                  if (_selection.mainDish != null) ...[
                    _SectionTitle('Créneau'),
                    _SlotPicker(
                      menu: menu,
                      selection: _selection,
                      onSelect: (slot) => setState(
                        () => _selection = _selection.withTimeSlot(slot),
                      ),
                    ),
                  ],
                  const SizedBox(height: 80),
                ],
              ),
            ),
            if (isComplete)
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandOrange,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _isSubmitting ? null : _confirm,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Confirmer la réservation'),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _SlotPicker extends ConsumerWidget {
  const _SlotPicker({
    required this.menu,
    required this.selection,
    required this.onSelect,
  });

  final DailyMenu menu;
  final MealSelection selection;
  final void Function(TimeSlot slot) onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slotsAsync = ref.watch(menuTimeSlotsProvider(menu.id));
    return slotsAsync.when(
      loading: () => const LoadingState(),
      error: (e, _) => ErrorState(
        message: e is ApiException
            ? e.message
            : 'Impossible de charger les créneaux',
        onRetry: () => ref.invalidate(menuTimeSlotsProvider(menu.id)),
      ),
      data: (slots) {
        if (slots.isEmpty) {
          return const EmptyState(
            icon: Icons.schedule,
            title: 'Aucun créneau disponible',
          );
        }
        return Column(
          children: slots
              .map((slot) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TimeSlotTile(
                      slot: slot,
                      selected: selection.timeSlot?.id == slot.id,
                      isPast: isTimeSlotPast(menu.date, slot.endTime),
                      onTap: () => onSelect(slot),
                    ),
                  ))
              .toList(),
        );
      },
    );
  }
}
