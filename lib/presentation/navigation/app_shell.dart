import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../views/timeline/timeline_view.dart';
import '../views/albums/albums_view.dart';
import '../views/graph/graph_view.dart';
import '../views/earth/earth_view.dart';
import '../views/search/search_view.dart';
import '../views/settings/settings_view.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentTab = 0;

  final List<Widget> _views = const [
    TimelineView(),
    AlbumsView(),
    GraphView(),
    EarthView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.glassBorder, width: 1),
              ),
              child: const Icon(
                Icons.diamond_outlined,
                color: AppColors.primaryLight,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Adamantine',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        actions: [
          // Search Action
          IconButton(
            icon: const Icon(Icons.search_rounded, color: AppColors.textPrimary),
            tooltip: 'Search',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchView()),
              );
            },
          ),
          // Settings Action
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: AppColors.textPrimary),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsView()),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: IndexedStack(
        index: _currentTab,
        children: _views,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.glassSurface,
          border: Border(
            top: BorderSide(color: AppColors.cardBorder, width: 0.8),
          ),
        ),
        child: SafeArea(
          child: NavigationBar(
            selectedIndex: _currentTab,
            onDestinationSelected: (idx) {
              setState(() => _currentTab = idx);
            },
            backgroundColor: Colors.transparent,
            indicatorColor: AppColors.primary.withValues(alpha: 0.25),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.photo_library_outlined, color: AppColors.textMuted),
                selectedIcon: Icon(Icons.photo_library_rounded, color: AppColors.primaryLight),
                label: 'Timeline',
              ),
              NavigationDestination(
                icon: Icon(Icons.folder_outlined, color: AppColors.textMuted),
                selectedIcon: Icon(Icons.folder_rounded, color: AppColors.primaryLight),
                label: 'Albums',
              ),
              NavigationDestination(
                icon: Icon(Icons.hub_outlined, color: AppColors.textMuted),
                selectedIcon: Icon(Icons.hub_rounded, color: AppColors.primaryLight),
                label: 'Graph',
              ),
              NavigationDestination(
                icon: Icon(Icons.public_outlined, color: AppColors.textMuted),
                selectedIcon: Icon(Icons.public_rounded, color: AppColors.primaryLight),
                label: 'Earth',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
