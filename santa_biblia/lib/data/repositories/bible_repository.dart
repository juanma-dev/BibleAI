import 'package:flutter/foundation.dart';
import '../../core/constants/bible_constants.dart';
import '../database/bible_database.dart';
import '../database/bible_seeder.dart';
import '../models/bible_models.dart';
import 'bible_api_service.dart';

class BibleRepository {
  final BibleDatabase _db;
  final BibleApiService _api = BibleApiService();

  BibleRepository(this._db);

  Future<List<BibleVerse>> getChapter({
    required String versionId,
    required int bookId,
    required int chapter,
  }) async {
    // On web, sqflite is unavailable — fetch directly from bible-api.com
    if (kIsWeb) {
      final bookData = BibleConstants.bibleBooks.firstWhere((b) => b['id'] == bookId);
      return _api.getChapter(
        versionId: versionId,
        bookId: bookId,
        chapter: chapter,
        bookNameEn: bookData['name_en'] as String,
      );
    }
    await _ensureVersionLoaded(versionId);
    return _db.getChapter(versionId: versionId, bookId: bookId, chapter: chapter);
  }

  Future<BibleVerse?> getVerse({
    required String versionId,
    required int bookId,
    required int chapter,
    required int verse,
  }) async {
    if (kIsWeb) return null;
    return _db.getVerse(
      versionId: versionId,
      bookId: bookId,
      chapter: chapter,
      verse: verse,
    );
  }

  Future<List<BibleVerse>> searchVerses({
    required String versionId,
    required String query,
    int limit = 10,
  }) async {
    if (kIsWeb) {
      return _api.searchVerses(versionId: versionId, query: query, limit: limit);
    }
    await _ensureVersionLoaded(versionId);
    return _db.searchVerses(versionId: versionId, query: query, limit: limit);
  }

  Future<void> _ensureVersionLoaded(String versionId) async {
    final loaded = await _db.isVersionLoaded(versionId);
    if (!loaded) {
      await BibleSeeder.seedVersionIfNeeded(versionId);
    }
  }

  Future<bool> isVersionLoaded(String versionId) {
    if (kIsWeb) return Future.value(true);
    return _db.isVersionLoaded(versionId);
  }
}
