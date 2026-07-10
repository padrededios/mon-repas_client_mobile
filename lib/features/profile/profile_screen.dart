import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/notification_item.dart';
import '../../data/models/notification_preferences.dart';
import '../../data/providers.dart';
import 'change_password_sheet.dart';

/// Page profil : identité, sécurité (mot de passe), préférences de
/// notifications push / mail (mail à venir) et choix du thème.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _openChangePassword(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final changed = await ChangePasswordSheet.show(context);
    if (changed == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Mot de passe mis à jour avec succès'),
          backgroundColor: context.appColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final user = ref.watch(authProvider.select((s) => s.user));
    final preferences = ref.watch(
      notificationsProvider.select((s) => s.preferences),
    );

    final initials = [
      if ((user?.firstName ?? '').isNotEmpty) user!.firstName[0],
      if ((user?.lastName ?? '').isNotEmpty) user!.lastName[0],
    ].join().toUpperCase();

    return Scaffold(
      appBar: AppBar(title: const Text('Mon profil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- Identité ---
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor:
                        AppColors.brandOrange.withValues(alpha: 0.16),
                    child: Text(
                      initials.isEmpty ? '?' : initials,
                      style: const TextStyle(
                        color: AppColors.brandOrange,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullName ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          user?.email ?? '',
                          style: TextStyle(
                            color: colors.mutedForeground,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // --- Sécurité ---
          const _SectionTitle('Sécurité'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('Changer mon mot de passe'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _openChangePassword(context, ref),
            ),
          ),
          const SizedBox(height: 20),

          // --- Notifications push ---
          const _SectionTitle('Notifications push'),
          Card(
            child: Column(
              children: [
                for (final (index, type)
                    in NotificationType.values.indexed) ...[
                  if (index > 0) const Divider(),
                  SwitchListTile(
                    title: Text(notificationLabels[type] ?? type.name),
                    subtitle: Text(
                      notificationDescriptions[type] ?? '',
                      style: const TextStyle(fontSize: 12),
                    ),
                    value: preferences.isEnabled(type),
                    onChanged: (enabled) => ref
                        .read(notificationsProvider.notifier)
                        .setPreference(type, enabled),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // --- Notifications mail (à venir) ---
          Row(
            children: [
              const _SectionTitle('Notifications mail'),
              const SizedBox(width: 8),
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.brandOrange.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Bientôt disponible',
                  style: TextStyle(
                    color: AppColors.brandOrange,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Récapitulatif hebdomadaire'),
                  subtitle: const Text(
                    'Recevoir les menus de la semaine par e-mail',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: false,
                  onChanged: null,
                ),
                const Divider(),
                SwitchListTile(
                  title: const Text('Confirmations de réservation'),
                  subtitle: const Text(
                    'Recevoir un e-mail à chaque réservation',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: false,
                  onChanged: null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // --- Déconnexion ---
          OutlinedButton.icon(
            onPressed: () => ref.read(authProvider.notifier).logout(),
            icon: Icon(Icons.logout, size: 18, color: colors.destructive),
            label: Text(
              'Se déconnecter',
              style: TextStyle(color: colors.destructive),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: colors.destructive.withValues(alpha: 0.4)),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 2),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13,
          letterSpacing: 0.3,
          color: context.appColors.mutedForeground,
        ),
      ),
    );
  }
}
