import 'package:shared_preferences/shared_preferences.dart';

import '../../presentation/state/app_preferences_state.dart';

class AppPreferencesLocalDataSource {
  static const String themeKey = 'focus-todo-theme';
  static const String languageKey = 'focus-todo-language';

  Future<AppPreferencesState?> load() async {
    final preferences = await SharedPreferences.getInstance();
    final rawTheme = preferences.getString(themeKey);
    final rawLanguage = preferences.getString(languageKey);

    if (rawTheme == null && rawLanguage == null) {
      return null;
    }

    return AppPreferencesState(
      themePreference: AppThemePreferenceX.fromStorage(rawTheme),
      language: AppLanguageX.fromStorage(rawLanguage),
    );
  }

  Future<void> save(AppPreferencesState state) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(themeKey, state.themePreference.storageValue);
    await preferences.setString(languageKey, state.language.code);
  }
}
