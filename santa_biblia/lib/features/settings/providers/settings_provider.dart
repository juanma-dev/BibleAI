import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../data/models/bible_models.dart';
import '../../../data/repositories/settings_repository.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize in main.dart');
});

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  throw UnimplementedError('Initialize in main.dart');
});

final initialApiKeyProvider = Provider<String>((ref) {
  throw UnimplementedError('Initialize in main.dart');
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final storage = ref.watch(secureStorageProvider);
  final initialApiKey = ref.watch(initialApiKeyProvider);
  return SettingsRepository(prefs, storage, initialApiKey);
});

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    final repo = ref.watch(settingsRepositoryProvider);
    return repo.load();
  }

  Future<void> setThemeMode(ThemeModePreference mode) async {
    state = state.copyWith(themeMode: mode);
    await _save();
  }

  Future<void> setLanguage(String language) async {
    state = state.copyWith(language: language);
    await _save();
  }

  Future<void> setBibleVersion(String version) async {
    state = state.copyWith(bibleVersion: version);
    await _save();
  }

  Future<void> setFontSize(double size) async {
    state = state.copyWith(fontSize: size);
    await _save();
  }

  Future<void> setAiProvider(AiProvider provider) async {
    state = state.copyWith(aiProvider: provider);
    await _save();
  }

  Future<void> setAiApiKey(String key) async {
    state = state.copyWith(aiApiKey: key);
    await _save();
  }

  Future<void> setBackendUrl(String url) async {
    state = state.copyWith(backendUrl: url);
    await _save();
  }

  Future<void> _save() async {
    final repo = ref.read(settingsRepositoryProvider);
    await repo.save(state);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

final themeModeProvider = Provider<ThemeMode>((ref) {
  final settings = ref.watch(settingsProvider);
  return switch (settings.themeMode) {
    ThemeModePreference.light => ThemeMode.light,
    ThemeModePreference.dark => ThemeMode.dark,
    ThemeModePreference.system => ThemeMode.system,
  };
});
