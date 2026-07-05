import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/dates.dart';
import '../../data/models/notification_item.dart';
import '../../data/models/notification_preferences.dart';
import '../../data/providers.dart';

/// Panneau de notifications (cloche de l'AppBar) : liste, tout lire / tout
/// supprimer, lecture et suppression unitaires, préférences par type.
class NotificationsPanel extends ConsumerStatefulWidget {
  const NotificationsPanel({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const NotificationsPanel(),
    );
  }

  @override
  ConsumerState<NotificationsPanel> createState() =>
      _NotificationsPanelState();
}

class _NotificationsPanelState extends ConsumerState<NotificationsPanel> {
  bool _showPreferences = false;

  static const _typeIcons = {
    NotificationType.mealReminder: Icons.restaurant,
    NotificationType.doggybagReminder: Icons.inventory_2,
    NotificationType.eventNew: Icons.auto_awesome,
    NotificationType.system: Icons.info_outline,
  };

  static const _typeColors = {
    NotificationType.mealReminder: AppColors.categoryMeal,
    NotificationType.doggybagReminder: AppColors.categoryDoggyBag,
    NotificationType.eventNew: AppColors.categoryEvent,
    NotificationType.system: AppColors.brandOrange,
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final state = ref.watch(notificationsProvider);
    final notifier = ref.read(notificationsProvider.notifier);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _showPreferences ? 'Préférences' : 'Notifications',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  if (!_showPreferences && state.items.isNotEmpty) ...[
                    IconButton(
                      icon: const Icon(Icons.done_all),
                      tooltip: 'Tout marquer comme lu',
                      onPressed: notifier.markAllRead,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_sweep_outlined),
                      tooltip: 'Tout supprimer',
                      onPressed: notifier.clearAll,
                    ),
                  ],
                  IconButton(
                    icon: Icon(
                      _showPreferences ? Icons.notifications : Icons.settings,
                    ),
                    tooltip: _showPreferences
                        ? 'Retour aux notifications'
                        : 'Préférences',
                    onPressed: () => setState(
                      () => _showPreferences = !_showPreferences,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: _showPreferences
                  ? ListView(
                      controller: scrollController,
                      children: NotificationType.values
                          .map(
                            (type) => SwitchListTile(
                              secondary: Icon(
                                _typeIcons[type],
                                color: _typeColors[type],
                              ),
                              title: Text(notificationLabels[type]!),
                              subtitle: Text(
                                notificationDescriptions[type]!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colors.mutedForeground,
                                ),
                              ),
                              value: state.preferences.isEnabled(type),
                              onChanged: (v) =>
                                  notifier.setPreference(type, v),
                            ),
                          )
                          .toList(),
                    )
                  : state.items.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.notifications_none,
                                size: 44,
                                color: colors.mutedForeground,
                              ),
                              const SizedBox(height: 8),
                              const Text('Aucune notification'),
                              Text(
                                'Vous êtes à jour !',
                                style: TextStyle(
                                  color: colors.mutedForeground,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          controller: scrollController,
                          itemCount: state.items.length,
                          separatorBuilder: (_, _) =>
                              const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final n = state.items[i];
                            return Dismissible(
                              key: ValueKey(n.id),
                              direction: DismissDirection.endToStart,
                              onDismissed: (_) => notifier.remove(n.id),
                              background: Container(
                                color: colors.destructive,
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 16),
                                child: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.white,
                                ),
                              ),
                              child: ListTile(
                                onTap: () => notifier.markRead(n.id),
                                leading: Icon(
                                  _typeIcons[n.type],
                                  color: _typeColors[n.type],
                                ),
                                title: Text(
                                  n.title,
                                  style: TextStyle(
                                    fontWeight: n.read
                                        ? FontWeight.w400
                                        : FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    if (n.message.isNotEmpty)
                                      Text(
                                        n.message,
                                        style:
                                            const TextStyle(fontSize: 13),
                                      ),
                                    Text(
                                      relativeTime(n.createdAt),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: colors.mutedForeground,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: n.read
                                    ? null
                                    : Container(
                                        width: 9,
                                        height: 9,
                                        decoration: const BoxDecoration(
                                          color: AppColors.brandOrange,
                                          shape: BoxShape.circle,
                                        ),
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
