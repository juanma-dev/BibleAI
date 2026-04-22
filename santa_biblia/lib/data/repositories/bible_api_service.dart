import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/bible_models.dart';

/// Fetches Bible verses directly from bible-api.com (used on web, no SQLite needed)
class BibleApiService {
  static const String _base = 'https://bible-api.com';

  static const Map<String, String> _translationMap = {
    'web': 'web',
    'kjv': 'kjv',
    'asv': 'asv',
    'rv1909': 'rv1909',
    'rv1865': 'rv1909', // fallback
  };

  Future<List<BibleVerse>> getChapter({
    required String versionId,
    required int bookId,
    required int chapter,
    required String bookNameEn,
  }) async {
    final translation = _translationMap[versionId] ?? 'web';
    final bookSlug = _bookSlug(bookNameEn);
    final uri = Uri.parse('$_base/$bookSlug+$chapter?translation=$translation');

    final response = await http.get(uri).timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) return [];

    final data = json.decode(response.body) as Map<String, dynamic>;
    final verses = data['verses'] as List<dynamic>? ?? [];

    return verses.map((v) {
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
  }

  Future<List<BibleVerse>> searchVerses({
    required String versionId,
    required String query,
    int limit = 10,
  }) async {
    // bible-api.com doesn't support search — return empty on web
    // Full search requires SQLite (mobile) or a dedicated search API
    return [];
  }

  static String _bookSlug(String bookName) {
    return bookName
        .toLowerCase()
        .replaceAll(' ', '+')
        .replaceAll("'", '');
  }
}
