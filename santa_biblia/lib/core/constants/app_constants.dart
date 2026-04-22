import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class AppConstants {
  static const String appName = 'La Santa Biblia';
  static const String appSubtitle = 'Asistida por AI';

  // Shared preferences keys
  static const String prefThemeMode = 'theme_mode';
  static const String prefLanguage = 'language';
  static const String prefBibleVersion = 'bible_version';
  static const String prefFontSize = 'font_size';
  static const String prefAiProvider = 'ai_provider';
  static const String prefAiApiKey = 'ai_api_key';
  static const String prefBackendUrl = 'backend_url';
  static const String prefLastBook = 'last_book';
  static const String prefLastChapter = 'last_chapter';
  static const String prefLastVersion = 'last_version';

  // Default values
  static const String defaultLanguage = 'es';
  static const String defaultVersion = 'rv1909';
  static const double defaultFontSize = 18.0;
  static const double minFontSize = 14.0;
  static const double maxFontSize = 28.0;

  // Backend — Android emulator maps host's localhost to 10.0.2.2.
  // Web/desktop/iOS simulator can reach localhost directly.
  static String get defaultBackendUrl {
    if (kIsWeb) return 'http://localhost:5000';
    if (Platform.isAndroid) return 'http://10.0.2.2:5000';
    return 'http://localhost:5000';
  }

  static const Duration httpTimeout = Duration(seconds: 30);

  // RAG
  static const int ragMaxVerses = 10;
  static const int searchResultsLimit = 20;
}
