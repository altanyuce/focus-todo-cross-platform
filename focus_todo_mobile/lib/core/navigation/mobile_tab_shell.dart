import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../localization/app_strings.dart';
import '../../features/tasks/presentation/state/tasks_ui_state.dart';

class MobileTabShell extends StatelessWidget {
  const MobileTabShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (int index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: <NavigationDestination>[
          NavigationDestination(
            icon: const Icon(Icons.today_outlined),
            selectedIcon: const Icon(Icons.today),
            label: strings.sectionLabel(Section.today),
          ),
          NavigationDestination(
            icon: const Icon(Icons.event_outlined),
            selectedIcon: const Icon(Icons.event),
            label: strings.sectionLabel(Section.upcoming),
          ),
          NavigationDestination(
            icon: const Icon(Icons.task_alt_outlined),
            selectedIcon: const Icon(Icons.task_alt),
            label: strings.sectionLabel(Section.completed),
          ),
        ],
      ),
    );
  }
}
