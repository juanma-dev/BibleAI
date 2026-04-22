import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/bible_models.dart';
import 'bible_database.dart';

/// Downloads and seeds public domain Bible versions from public APIs.
/// Uses bible-api.com (no key required) for WEB and other public domain versions.
class BibleSeeder {
  static const String _apiBase = 'https://bible-api.com';

  // Maps our internal IDs to bible-api.com translation codes
  static const Map<String, String> _apiTranslationMap = {
    'web': 'web',
    'kjv': 'kjv',
    'asv': 'asv',
    'rv1909': 'rv1909',
  };

  static Future<void> seedVersionIfNeeded(String versionId) async {
    final db = BibleDatabase.instance;
    if (await db.isVersionLoaded(versionId)) return;

    final apiCode = _apiTranslationMap[versionId];
    if (apiCode == null) {
      debugPrint('No API mapping for version: $versionId');
      return;
    }

    debugPrint('Seeding Bible version: $versionId');
    await _downloadAndSeed(versionId, apiCode, db);
  }

  static Future<void> _downloadAndSeed(
    String versionId,
    String apiCode,
    BibleDatabase db,
  ) async {
    // We download book by book to avoid timeout and memory issues
    // Books 1-66
    for (int bookId = 1; bookId <= 66; bookId++) {
      try {
        await _seedBook(db, versionId, apiCode, bookId);
      } catch (e) {
        debugPrint('Error seeding book $bookId: $e');
      }
    }
  }

  static Future<void> _seedBook(
    BibleDatabase db,
    String versionId,
    String apiCode,
    int bookId,
  ) async {
    // bible-api.com supports full book queries
    final bookAbbr = _bookAbbreviations[bookId];
    if (bookAbbr == null) return;

    final uri = Uri.parse('$_apiBase/$bookAbbr?translation=$apiCode');
    final response = await http.get(uri).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) return;

    final data = json.decode(response.body) as Map<String, dynamic>;
    final versesRaw = data['verses'] as List<dynamic>?;
    if (versesRaw == null) return;

    final verses = versesRaw.map((v) {
      final map = v as Map<String, dynamic>;
      return BibleVerse(
        id: 0,
        versionId: versionId,
        bookId: bookId,
        chapter: map['chapter'] as int,
        verse: map['verse'] as int,
        text: (map['text'] as String).trim(),
      );
    }).toList();

    await db.insertVersesBatch(verses);
    debugPrint('Seeded book $bookId ($bookAbbr) for $versionId: ${verses.length} verses');
  }

  static const Map<int, String> _bookAbbreviations = {
    1: 'genesis', 2: 'exodus', 3: 'leviticus', 4: 'numbers', 5: 'deuteronomy',
    6: 'joshua', 7: 'judges', 8: 'ruth', 9: '1+samuel', 10: '2+samuel',
    11: '1+kings', 12: '2+kings', 13: '1+chronicles', 14: '2+chronicles',
    15: 'ezra', 16: 'nehemiah', 17: 'esther', 18: 'job', 19: 'psalms',
    20: 'proverbs', 21: 'ecclesiastes', 22: 'song+of+solomon', 23: 'isaiah',
    24: 'jeremiah', 25: 'lamentations', 26: 'ezekiel', 27: 'daniel',
    28: 'hosea', 29: 'joel', 30: 'amos', 31: 'obadiah', 32: 'jonah',
    33: 'micah', 34: 'nahum', 35: 'habakkuk', 36: 'zephaniah', 37: 'haggai',
    38: 'zechariah', 39: 'malachi', 40: 'matthew', 41: 'mark', 42: 'luke',
    43: 'john', 44: 'acts', 45: 'romans', 46: '1+corinthians',
    47: '2+corinthians', 48: 'galatians', 49: 'ephesians', 50: 'philippians',
    51: 'colossians', 52: '1+thessalonians', 53: '2+thessalonians',
    54: '1+timothy', 55: '2+timothy', 56: 'titus', 57: 'philemon',
    58: 'hebrews', 59: 'james', 60: '1+peter', 61: '2+peter', 62: '1+john',
    63: '2+john', 64: '3+john', 65: 'jude', 66: 'revelation',
  };
}
