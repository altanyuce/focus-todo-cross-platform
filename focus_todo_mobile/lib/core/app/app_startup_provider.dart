import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/presentation/providers/app_preferences_provider.dart';
import '../../features/tasks/presentation/providers/tasks_providers.dart';

final appStartupProvider = FutureProvider<void>((Ref ref) async {
  await ref.read(appPreferencesProvider.notifier).initialize();
  await ref.read(tasksProvider.notifier).initialize();
});
