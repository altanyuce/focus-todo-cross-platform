import 'dart:ui';

import 'package:flutter/material.dart';

enum AppThemePreference { light, dark, system }

enum AppLanguage { en, tr, de, es, it }

extension AppThemePreferenceX on AppThemePreference {
  String get storageValue {
    switch (this) {
      case AppThemePreference.light:
        return 'light';
      case AppThemePreference.dark:
        return 'dark';
      case AppThemePreference.system:
        return 'system';
    }
  }

  ThemeMode get themeMode {
    switch (this) {
      case AppThemePreference.light:
        return ThemeMode.light;
      case AppThemePreference.dark:
        return ThemeMode.dark;
      case AppThemePreference.system:
        return ThemeMode.system;
    }
  }

  static AppThemePreference fromStorage(String? value) {
    switch (value) {
      case 'light':
        return AppThemePreference.light;
      case 'dark':
        return AppThemePreference.dark;
      case 'system':
      default:
        return AppThemePreference.system;
    }
  }
}

extension AppLanguageX on AppLanguage {
  String get code {
    switch (this) {
      case AppLanguage.en:
        return 'en';
      case AppLanguage.tr:
        return 'tr';
      case AppLanguage.de:
        return 'de';
      case AppLanguage.es:
        return 'es';
      case AppLanguage.it:
        return 'it';
    }
  }

  Locale get locale => Locale(code);

  static AppLanguage fromStorage(String? value) {
    switch (value) {
      case 'tr':
        return AppLanguage.tr;
      case 'de':
        return AppLanguage.de;
      case 'es':
        return AppLanguage.es;
      case 'it':
        return AppLanguage.it;
      case 'en':
      default:
        return AppLanguage.en;
    }
  }
}

class AppPreferencesState {
  const AppPreferencesState({
    required this.themePreference,
    required this.language,
  });

  static const AppPreferencesState initial = AppPreferencesState(
    themePreference: AppThemePreference.system,
    language: AppLanguage.en,
  );

  final AppThemePreference themePreference;
  final AppLanguage language;

  ThemeMode get themeMode => themePreference.themeMode;

  Locale get locale => language.locale;

  AppPreferencesState copyWith({
    AppThemePreference? themePreference,
    AppLanguage? language,
  }) {
    return AppPreferencesState(
      themePreference: themePreference ?? this.themePreference,
      language: language ?? this.language,
    );
  }

  static AppLanguage fallbackLanguageFromPlatform() {
    return AppLanguageX.fromStorage(
      PlatformDispatcher.instance.locale.languageCode,
    );
  }
}
