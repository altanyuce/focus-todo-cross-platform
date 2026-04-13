import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/presentation/providers/app_preferences_provider.dart';
import '../../localization/app_localization_config.dart';
import '../../theme/app_theme.dart';
import 'app_startup_provider.dart';
import '../router/app_router.dart';

class FocusTodoApp extends ConsumerWidget {
  const FocusTodoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final startup = ref.watch(appStartupProvider);
    final preferences = ref.watch(appPreferencesProvider);
    final router = ref.watch(appRouterProvider);

    if (startup.isLoading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: preferences.themeMode,
        locale: preferences.locale,
        supportedLocales: AppLocalizationConfig.supportedLocales,
        localizationsDelegates: AppLocalizationConfig.localizationsDelegates,
        home: const _StartupScreen(),
      );
    }

    if (startup.hasError) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: preferences.themeMode,
        locale: preferences.locale,
        supportedLocales: AppLocalizationConfig.supportedLocales,
        localizationsDelegates: AppLocalizationConfig.localizationsDelegates,
        home: Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () => ref.invalidate(appStartupProvider),
              child: const Text('Retry'),
            ),
          ),
        ),
      );
    }

    return MaterialApp.router(
      title: 'Focus Todo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: preferences.themeMode,
      locale: preferences.locale,
      supportedLocales: AppLocalizationConfig.supportedLocales,
      localizationsDelegates: AppLocalizationConfig.localizationsDelegates,
      routerConfig: router,
    );
  }
}

class _StartupScreen extends StatelessWidget {
  const _StartupScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
