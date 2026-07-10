import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show toBeginningOfSentenceCase;

import '../../core/api/api_config.dart';
import '../../core/api/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/dates.dart';
import '../../data/models/special_event.dart';
import '../../data/providers.dart';
import '../../shared/widgets/async_states.dart';
import '../../shared/widgets/status_badge.dart';

/// Onglet Événements : liste des événements spéciaux actifs.
class EventsScreen extends ConsumerWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(activeEventsProvider);
    final myReservations =
        ref.watch(myEventReservationsProvider).valueOrNull ?? [];
    final reservedEventIds = myReservations
        .where((r) => !r.isCancelled)
        .map((r) => r.specialEventId)
        .toSet();

    return eventsAsync.when(
      loading: () => const LoadingState(),
      error: (e, _) => ErrorState(
        message: e is ApiException ? e.message : 'Erreur de chargement',
        onRetry: () => ref.invalidate(activeEventsProvider),
      ),
      data: (events) {
        if (events.isEmpty) {
          return const EmptyState(
            icon: Icons.auto_awesome_outlined,
            title: 'Aucun événement pour le moment',
            subtitle: 'Les événements spéciaux apparaîtront ici.',
          );
        }
        final sorted = [...events]
          ..sort((a, b) => a.eventDate.compareTo(b.eventDate));
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(activeEventsProvider);
            ref.invalidate(myEventReservationsProvider);
          },
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: sorted.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) => EventCard(
              event: sorted[i],
              isReserved: reservedEventIds.contains(sorted[i].id),
              onTap: () => context.push('/events/${sorted[i].id}'),
            ),
          ),
        );
      },
    );
  }
}

/// Carte événement (liste des événements et vue semaine des menus).
class EventCard extends StatelessWidget {
  const EventCard({
    super.key,
    required this.event,
    required this.isReserved,
    required this.onTap,
  });

  final SpecialEvent event;
  final bool isReserved;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final past = isDayPast(event.eventDate);
    final closed = event.isRegistrationClosed();
    final deadline = event.registrationDeadline;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (event.imageUrl != null)
              Image.network(
                ApiConfig.resolveMediaUrl(event.imageUrl!),
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _placeholder(colors),
              )
            else
              _placeholder(colors),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      const StatusBadge(
                        'Événement spécial',
                        variant: BadgeVariant.special,
                      ),
                      if (past)
                        const StatusBadge(
                          'Passé',
                          variant: BadgeVariant.secondary,
                        )
                      else if (closed)
                        const StatusBadge(
                          'Clôturé',
                          variant: BadgeVariant.destructive,
                        ),
                      if (isReserved)
                        const StatusBadge(
                          'Réservé ✓',
                          variant: BadgeVariant.success,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.name,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    toBeginningOfSentenceCase(formatDayLong(event.eventDate)),
                    style: TextStyle(
                      color: colors.mutedForeground,
                      fontSize: 13,
                    ),
                  ),
                  if (deadline != null && !past) ...[
                    const SizedBox(height: 4),
                    Text(
                      closed
                          ? 'Inscriptions clôturées'
                          : 'Inscriptions jusqu\'au ${formatDateMedium(deadline)}',
                      style: TextStyle(
                        color: closed ? colors.destructive : colors.warning,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (event.description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      event.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.mutedForeground,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(AppColors colors) {
    return Container(
      height: 90,
      width: double.infinity,
      color: AppColors.categoryEvent.withValues(alpha: 0.15),
      child: const Icon(
        Icons.auto_awesome,
        size: 40,
        color: AppColors.categoryEvent,
      ),
    );
  }
}
