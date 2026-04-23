import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/bible_models.dart';
import '../../core/constants/app_constants.dart';

class SettingsRepository {
  final SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage;
  final String _initialApiKey;

  SettingsRepository(this._prefs, this._secureStorage, this._initialApiKey);

  AppSettings load() => AppSettings(
    themeMode: _loadThemeMode(),
    language: _prefs.getString(AppConstants.prefLanguage) ?? AppConstants.defaultLanguage,
    bibleVersion: _prefs.getString(AppConstants.prefBibleVersion) ?? AppConstants.defaultVersion,
    fontSize: _prefs.getDouble(AppConstants.prefFontSize) ?? AppConstants.defaultFontSize,
    aiProvider: _loadAiProvider(),
    aiApiKey: _initialApiKey,
    backendUrl: _loadBackendUrl(),
  );

  // Reads the persisted backend URL, but on non-Android platforms rewrites
  // 10.0.2.2 (the Android emulator's host-loopback alias) to localhost, which
  // is what every other platform actually needs to reach the .NET backend.
  String _loadBackendUrl() {
    final stored = _prefs.getString(AppConstants.prefBackendUrl);
    if (stored == null || stored.isEmpty) return AppConstants.defaultBackendUrl;
    final isAndroid = !kIsWeb && Platform.isAndroid;
    if (!isAndroid && stored.contains('10.0.2.2')) {
      return stored.replaceAll('10.0.2.2', 'localhost');
    }
    return stored;
  }

  Future<void> save(AppSettings settings) async {
    await _prefs.setString(AppConstants.prefThemeMode, settings.themeMode.name);
    await _prefs.setString(AppConstants.prefLanguage, settings.language);
    await _prefs.setString(AppConstants.prefBibleVersion, settings.bibleVersion);
    await _prefs.setDouble(AppConstants.prefFontSize, settings.fontSize);
    await _prefs.setString(AppConstants.prefAiProvider, settings.aiProvider.id);
    await _secureStorage.write(key: AppConstants.prefAiApiKey, value: settings.aiApiKey);
    await _prefs.setString(AppConstants.prefBackendUrl, settings.backendUrl);
  }

  ThemeModePreference _loadThemeMode() {
    final name = _prefs.getString(AppConstants.prefThemeMode);
    return ThemeModePreference.values.firstWhere(
      (e) => e.name == name,
      orElse: () => ThemeModePreference.system,
    );
  }

  AiProvider _loadAiProvider() {
    final id = _prefs.getString(AppConstants.prefAiProvider);
    return AiProvider.values.firstWhere(
      (e) => e.id == id,
      orElse: () => AiProvider.gemini,
    );
  }
}
