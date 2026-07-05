import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/providers.dart';
import '../../shared/widgets/brand_logo.dart';
import '../menus/menus_screen.dart';

/// Coquille principale : AppBar commune + 5 onglets (transposition mobile
/// de la navigation horizontale de la webapp).
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final user = ref.watch(authProvider.select((s) => s.user));
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        title: Row(
          children: [
            const BrandLogo(height: 32),
            const SizedBox(width: 8),
            Text(
              'Mon Repas',
              style:
                  AppTypography.brandTitle.copyWith(color: colors.foreground),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notifications',
            // Panneau de notifications : Phase 8.
            onPressed: () {},
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: 'Profil',
            onSelected: (value) async {
              switch (value) {
                case 'theme-light':
                  ref
                      .read(themeModeProvider.notifier)
                      .setMode(ThemeMode.light);
                case 'theme-dark':
                  ref.read(themeModeProvider.notifier).setMode(ThemeMode.dark);
                case 'theme-system':
                  ref
                      .read(themeModeProvider.notifier)
                      .setMode(ThemeMode.system);
                case 'logout':
                  await ref.read(authProvider.notifier).logout();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.fullName ?? '',
                      style: TextStyle(
                        color: colors.foreground,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      user?.email ?? '',
                      style: TextStyle(
                        color: colors.mutedForeground,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              _themeItem('theme-light', 'Thème clair', Icons.light_mode_outlined,
                  themeMode == ThemeMode.light),
              _themeItem('theme-dark', 'Thème sombre', Icons.dark_mode_outlined,
                  themeMode == ThemeMode.dark),
              _themeItem('theme-system', 'Thème système',
                  Icons.brightness_auto_outlined, themeMode == ThemeMode.system),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20),
                    SizedBox(width: 8),
                    Text('Se déconnecter'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: const [
          _PlaceholderTab(title: 'Accueil'), // Dashboard : Phase 3
          MenusScreen(),
          _PlaceholderTab(title: 'DoggyBag'), // Phase 6
          _PlaceholderTab(title: 'Événements'), // Phase 7
          _PlaceholderTab(title: 'Commandes'), // Phase 5
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            activeIcon: Icon(Icons.calendar_month),
            label: 'Réserver',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2),
            label: 'DoggyBag',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome_outlined),
            activeIcon: Icon(Icons.auto_awesome),
            label: 'Événements',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'Commandes',
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _themeItem(
    String value,
    String label,
    IconData icon,
    bool selected,
  ) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          if (selected)
            const Icon(Icons.check, size: 18, color: AppColors.brandOrange),
        ],
      ),
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.construction, size: 40, color: colors.mutedForeground),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          Text(
            'Bientôt disponible',
            style: TextStyle(color: colors.mutedForeground),
          ),
        ],
      ),
    );
  }
}
