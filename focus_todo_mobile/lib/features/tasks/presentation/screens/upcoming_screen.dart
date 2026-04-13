import 'package:flutter/material.dart';

import '../state/tasks_ui_state.dart';
import '../widgets/tasks_screen_scaffold.dart';

class UpcomingScreen extends StatelessWidget {
  const UpcomingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const TasksScreenScaffold(section: Section.upcoming);
  }
}
