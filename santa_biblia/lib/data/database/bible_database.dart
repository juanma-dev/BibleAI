import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/bible_models.dart';

class BibleDatabase {
  static BibleDatabase? _instance;
  static Database? _db;

  BibleDatabase._();

  static BibleDatabase get instance {
    _instance ??= BibleDatabase._();
    return _instance!;
  }

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<String> _getDbPath() async {
    // On desktop (Windows/Linux/macOS), use the app documents directory
    // so the DB persists between runs and isn't wiped by OS
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      final appDir = await getApplicationDocumentsDirectory();
      final dir = Directory(p.join(appDir.path, 'santa_biblia'));
      await dir.create(recursive: true);
      return p.join(dir.path, 'santa_biblia.db');
    }
    return p.join(await getDatabasesPath(), 'santa_biblia.db');
  }

  Future<Database> _initDb() async {
    final path = await _getDbPath();

    // ── Copy pre-built database from assets if missing or stale ─────────────
    // Re-copy when:
    //   • file doesn't exist, OR
    //   • file is much smaller than the bundled asset (e.g. a previous run
    //     left an empty schema behind because the asset wasn't built yet).
    final dbFile = File(path);
    var shouldCopy = !await dbFile.exists();
    int? assetBytes;
    try {
      final data = await rootBundle.load('assets/db/santa_biblia.db');
      assetBytes = data.lengthInBytes;
      if (!shouldCopy) {
        final localBytes = await dbFile.length();
        // If local file is less than half the bundled size, assume it's stale.
        if (localBytes < assetBytes / 2) {
          debugPrint(
              'DB local ($localBytes B) más pequeña que asset ($assetBytes B), re-copiando');
          await dbFile.delete();
          shouldCopy = true;
        }
      }
      if (shouldCopy) {
        await dbFile.writeAsBytes(data.buffer.asUint8List(), flush: true);
        debugPrint('DB copiada desde assets: ${assetBytes ~/ 1024} KB');
      }
    } catch (e) {
      debugPrint('Asset DB no disponible ($e) — se usará esquema vacío');
    }

    return openDatabase(
      path,
      version: 1,
      // onCreate only runs if the DB was newly created (no asset DB present)
      onCreate: _createEmptySchema,
      onConfigure: (db) async {
        await db.execute('PRAGMA journal_mode=WAL');
        await db.execute('PRAGMA synchronous=NORMAL');
        await db.execute('PRAGMA cache_size=10000');
        await db.execute('PRAGMA temp_store=MEMORY');
      },
    );
  }

  /// Fallback: creates schema from scratch (used only when no bundled DB exists)
  Future<void> _createEmptySchema(Database db, int version) async {
    await db.execute('''
      CREATE TABLE verses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        version_id TEXT NOT NULL,
        book_id INTEGER NOT NULL,
        chapter INTEGER NOT NULL,
        verse INTEGER NOT NULL,
        text TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_verses_lookup ON verses(version_id, book_id, chapter)');
    await db.execute('''
      CREATE VIRTUAL TABLE verses_fts USING fts5(
        text, version_id UNINDEXED, book_id UNINDEXED,
        chapter UNINDEXED, verse_num UNINDEXED, row_id UNINDEXED,
        content='verses', content_rowid='id'
      )
    ''');
    await db.execute('''
      CREATE TRIGGER verses_ai AFTER INSERT ON verses BEGIN
        INSERT INTO verses_fts(rowid, text, version_id, book_id, chapter, verse_num, row_id)
        VALUES (new.id, new.text, new.version_id, new.book_id, new.chapter, new.verse, new.id);
      END
    ''');
  }

  // Fetch all verses for a chapter
  Future<List<BibleVerse>> getChapter({
    required String versionId,
    required int bookId,
    required int chapter,
  }) async {
    final db = await database;
    final rows = await db.query(
      'verses',
      where: 'version_id = ? AND book_id = ? AND chapter = ?',
      whereArgs: [versionId, bookId, chapter],
      orderBy: 'verse ASC',
    );
    return rows.map(BibleVerse.fromMap).toList();
  }

  // Full-text search for RAG
  Future<List<BibleVerse>> searchVerses({
    required String versionId,
    required String query,
    int limit = 10,
  }) async {
    final db = await database;
    final sanitized = query.replaceAll('"', '""');
    try {
      final rows = await db.rawQuery('''
        SELECT v.id, v.version_id, v.book_id, v.chapter, v.verse, v.text
        FROM verses v
        JOIN verses_fts fts ON v.id = fts.row_id
        WHERE fts.text MATCH ? AND v.version_id = ?
        ORDER BY rank
        LIMIT ?
      ''', [sanitized, versionId, limit]);
      return rows.map(BibleVerse.fromMap).toList();
    } catch (e) {
      // Fallback to LIKE search if FTS fails
      return _likeSearch(db, versionId: versionId, query: query, limit: limit);
    }
  }

  Future<List<BibleVerse>> _likeSearch(
    Database db, {
    required String versionId,
    required String query,
    required int limit,
  }) async {
    final words = query.split(' ').where((w) => w.length > 3).take(3).toList();
    if (words.isEmpty) return [];
    final conditions = words.map((_) => 'text LIKE ?').join(' AND ');
    final args = [versionId, ...words.map((w) => '%$w%'), limit];
    final rows = await db.rawQuery(
      'SELECT * FROM verses WHERE version_id = ? AND $conditions LIMIT ?',
      args,
    );
    return rows.map(BibleVerse.fromMap).toList();
  }

  // Get a single verse
  Future<BibleVerse?> getVerse({
    required String versionId,
    required int bookId,
    required int chapter,
    required int verse,
  }) async {
    final db = await database;
    final rows = await db.query(
      'verses',
      where: 'version_id = ? AND book_id = ? AND chapter = ? AND verse = ?',
      whereArgs: [versionId, bookId, chapter, verse],
      limit: 1,
    );
    return rows.isEmpty ? null : BibleVerse.fromMap(rows.first);
  }

  // Bulk insert verses (used by seeder)
  Future<void> insertVersesBatch(List<BibleVerse> verses) async {
    final db = await database;
    final batch = db.batch();
    for (final v in verses) {
      batch.insert(
        'verses',
        {'version_id': v.versionId, 'book_id': v.bookId, 'chapter': v.chapter, 'verse': v.verse, 'text': v.text},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }

  // Check if version is loaded
  Future<bool> isVersionLoaded(String versionId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM verses WHERE version_id = ?',
      [versionId],
    );
    return (result.first['count'] as int) > 0;
  }

  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }
}
