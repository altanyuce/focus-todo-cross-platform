import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/app_preferences_local_data_source.dart';
import '../state/app_preferences_state.dart';

final appPreferencesLocalDataSourceProvider =
    Provider<AppPreferencesLocalDataSource>((Ref ref) {
      return AppPreferencesLocalDataSource();
    });

final appPreferencesProvider =
    NotifierProvider<AppPreferencesNotifier, AppPreferencesState>(
      AppPreferencesNotifier.new,
    );

class AppPreferencesNotifier extends Notifier<AppPreferencesState> {
  bool _initialized = false;

  @override
  AppPreferencesState build() {
    return AppPreferencesState(
      themePreference: AppThemePreference.system,
      language: AppPreferencesState.fallbackLanguageFromPlatform(),
    );
  }

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    final persisted = await ref
        .read(appPreferencesLocalDataSourceProvider)
        .load();

    state =
        persisted ??
        AppPreferencesState(
          themePreference: AppThemePreference.system,
          language: AppPreferencesState.fallbackLanguageFromPlatform(),
        );

    _initialized = true;

    if (persisted == null) {
      await ref.read(appPreferencesLocalDataSourceProvider).save(state);
    }
  }

  void setThemePreference(AppThemePreference themePreference) {
    state = state.copyWith(themePreference: themePreference);
    _persist();
  }

  void setLanguage(AppLanguage language) {
    state = state.copyWith(language: language);
    _persist();
  }

  void _persist() {
    if (!_initialized) {
      return;
    }

    unawaited(ref.read(appPreferencesLocalDataSourceProvider).save(state));
  }
}
