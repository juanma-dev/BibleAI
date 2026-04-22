// Bible Database Builder (Dart)
// ──────────────────────────────────────────────────────────────────────
// Construye santa_biblia/assets/db/santa_biblia.db con 5 versiones de
// dominio público. Ejecutar desde santa_biblia/:
//     dart run tool/build_bible_db.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const String _scrollmapperBase =
    'https://raw.githubusercontent.com/scrollmapper/bible_databases/master/formats/csv';

// versionId in our app  →  scrollmapper CSV filename
const Map<String, String> _scrollmapperSources = {
  'kjv': 'KJV.csv',
  'asv': 'ASV.csv',
  'rv1909': 'SpaRV.csv',
  'rv1865': 'SpaRV1865.csv',
};

// bible-api.com aggressively rate-limits (HTTP 403/429) so we don't fetch WEB
// that way. If a WEB CSV becomes available in scrollmapper, add it above.
const String _bibleApiBase = 'https://bible-api.com';
const Map<String, String> _bibleApiSources = <String, String>{};

// English book name → numeric book_id (1–66).
// Includes both Arabic and Roman numeral variants used by different sources.
const Map<String, int> _bookIdByName = {
  'Genesis': 1, 'Exodus': 2, 'Leviticus': 3, 'Numbers': 4, 'Deuteronomy': 5,
  'Joshua': 6, 'Judges': 7, 'Ruth': 8,
  '1 Samuel': 9, 'I Samuel': 9,
  '2 Samuel': 10, 'II Samuel': 10,
  '1 Kings': 11, 'I Kings': 11,
  '2 Kings': 12, 'II Kings': 12,
  '1 Chronicles': 13, 'I Chronicles': 13,
  '2 Chronicles': 14, 'II Chronicles': 14,
  'Ezra': 15, 'Nehemiah': 16, 'Esther': 17, 'Job': 18,
  'Psalms': 19, 'Psalm': 19,
  'Proverbs': 20, 'Ecclesiastes': 21,
  'Song of Solomon': 22, 'Song of Songs': 22, 'Canticles': 22,
  'Isaiah': 23, 'Jeremiah': 24, 'Lamentations': 25, 'Ezekiel': 26,
  'Daniel': 27, 'Hosea': 28, 'Joel': 29, 'Amos': 30, 'Obadiah': 31,
  'Jonah': 32, 'Micah': 33, 'Nahum': 34, 'Habakkuk': 35, 'Zephaniah': 36,
  'Haggai': 37, 'Zechariah': 38, 'Malachi': 39, 'Matthew': 40, 'Mark': 41,
  'Luke': 42, 'John': 43, 'Acts': 44, 'Romans': 45,
  '1 Corinthians': 46, 'I Corinthians': 46,
  '2 Corinthians': 47, 'II Corinthians': 47,
  'Galatians': 48, 'Ephesians': 49, 'Philippians': 50, 'Colossians': 51,
  '1 Thessalonians': 52, 'I Thessalonians': 52,
  '2 Thessalonians': 53, 'II Thessalonians': 53,
  '1 Timothy': 54, 'I Timothy': 54,
  '2 Timothy': 55, 'II Timothy': 55,
  'Titus': 56, 'Philemon': 57, 'Hebrews': 58, 'James': 59,
  '1 Peter': 60, 'I Peter': 60,
  '2 Peter': 61, 'II Peter': 61,
  '1 John': 62, 'I John': 62,
  '2 John': 63, 'II John': 63,
  '3 John': 64, 'III John': 64,
  'Jude': 65,
  'Revelation': 66, 'Revelation of John': 66,
};

// Book slugs for bible-api.com
const List<List<dynamic>> _bookSlugs = [
  [1, 'genesis'], [2, 'exodus'], [3, 'leviticus'], [4, 'numbers'],
  [5, 'deuteronomy'], [6, 'joshua'], [7, 'judges'], [8, 'ruth'],
  [9, '1+samuel'], [10, '2+samuel'], [11, '1+kings'], [12, '2+kings'],
  [13, '1+chronicles'], [14, '2+chronicles'], [15, 'ezra'], [16, 'nehemiah'],
  [17, 'esther'], [18, 'job'], [19, 'psalms'], [20, 'proverbs'],
  [21, 'ecclesiastes'], [22, 'song+of+solomon'], [23, 'isaiah'],
  [24, 'jeremiah'], [25, 'lamentations'], [26, 'ezekiel'], [27, 'daniel'],
  [28, 'hosea'], [29, 'joel'], [30, 'amos'], [31, 'obadiah'], [32, 'jonah'],
  [33, 'micah'], [34, 'nahum'], [35, 'habakkuk'], [36, 'zephaniah'],
  [37, 'haggai'], [38, 'zechariah'], [39, 'malachi'], [40, 'matthew'],
  [41, 'mark'], [42, 'luke'], [43, 'john'], [44, 'acts'], [45, 'romans'],
  [46, '1+corinthians'], [47, '2+corinthians'], [48, 'galatians'],
  [49, 'ephesians'], [50, 'philippians'], [51, 'colossians'],
  [52, '1+thessalonians'], [53, '2+thessalonians'], [54, '1+timothy'],
  [55, '2+timothy'], [56, 'titus'], [57, 'philemon'], [58, 'hebrews'],
  [59, 'james'], [60, '1+peter'], [61, '2+peter'], [62, '1+john'],
  [63, '2+john'], [64, '3+john'], [65, 'jude'], [66, 'revelation'],
];

Future<List<int>> _download(String url, {int retries = 3}) async {
  for (var attempt = 0; attempt < retries; attempt++) {
    try {
      final resp = await http
          .get(Uri.parse(url), headers: {'User-Agent': 'BibleDbBuilder/1.0'})
          .timeout(const Duration(seconds: 30));
      if (resp.statusCode == 200) return resp.bodyBytes;
      throw 'HTTP ${resp.statusCode}';
    } catch (e) {
      if (attempt == retries - 1) rethrow;
      await Future.delayed(Duration(seconds: 1 << attempt));
    }
  }
  throw 'unreachable';
}

Future<void> _createSchema(Database db) async {
  await db.execute('''
    CREATE TABLE IF NOT EXISTS verses (
      id          INTEGER PRIMARY KEY AUTOINCREMENT,
      version_id  TEXT    NOT NULL,
      book_id     INTEGER NOT NULL,
      chapter     INTEGER NOT NULL,
      verse       INTEGER NOT NULL,
      text        TEXT    NOT NULL
    )
  ''');
  await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_verses_lookup ON verses(version_id, book_id, chapter)');
  await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_verses_version ON verses(version_id)');
  // Standalone FTS5 (no external content) — populated via the AFTER INSERT
  // trigger below. Avoids the `rebuild` step and the column-name coupling to
  // the verses table that was causing failures.
  await db.execute('''
    CREATE VIRTUAL TABLE IF NOT EXISTS verses_fts USING fts5(
      text, version_id UNINDEXED, book_id UNINDEXED,
      chapter UNINDEXED, verse_num UNINDEXED, row_id UNINDEXED
    )
  ''');
  await db.execute('''
    CREATE TRIGGER IF NOT EXISTS verses_ai AFTER INSERT ON verses BEGIN
      INSERT INTO verses_fts(rowid, text, version_id, book_id, chapter, verse_num, row_id)
      VALUES (new.id, new.text, new.version_id, new.book_id, new.chapter, new.verse, new.id);
    END
  ''');
}

Future<int> _versionCount(Database db, String versionId) async {
  final r = await db.rawQuery(
      'SELECT COUNT(*) c FROM verses WHERE version_id = ?', [versionId]);
  return (r.first['c'] as int?) ?? 0;
}

// Parses a CSV line respecting quoted fields with "" escapes.
List<String> _parseCsvLine(String line) {
  final fields = <String>[];
  final buf = StringBuffer();
  var inQuotes = false;
  for (var i = 0; i < line.length; i++) {
    final ch = line[i];
    if (inQuotes) {
      if (ch == '"') {
        if (i + 1 < line.length && line[i + 1] == '"') {
          buf.write('"');
          i++;
        } else {
          inQuotes = false;
        }
      } else {
        buf.write(ch);
      }
    } else {
      if (ch == ',') {
        fields.add(buf.toString());
        buf.clear();
      } else if (ch == '"') {
        inQuotes = true;
      } else {
        buf.write(ch);
      }
    }
  }
  fields.add(buf.toString());
  return fields;
}

// Reads CSV text that may contain newlines inside quoted fields.
List<List<String>> _parseCsv(String text) {
  final rows = <List<String>>[];
  final buf = StringBuffer();
  var inQuotes = false;
  for (var i = 0; i < text.length; i++) {
    final ch = text[i];
    if (ch == '"') {
      if (inQuotes && i + 1 < text.length && text[i + 1] == '"') {
        buf.write('""');
        i++;
        continue;
      }
      inQuotes = !inQuotes;
      buf.write(ch);
    } else if (ch == '\n' && !inQuotes) {
      final line = buf.toString();
      buf.clear();
      if (line.isNotEmpty && line != '\r') {
        rows.add(_parseCsvLine(line.endsWith('\r')
            ? line.substring(0, line.length - 1)
            : line));
      }
    } else {
      buf.write(ch);
    }
  }
  if (buf.isNotEmpty) {
    rows.add(_parseCsvLine(buf.toString()));
  }
  return rows;
}

Future<void> _loadFromScrollmapper(
    Database db, String versionId, String filename) async {
  final url = '$_scrollmapperBase/$filename';
  stdout.write('\n  📥 Descargando ${versionId.toUpperCase()} ($filename)... ');
  final raw = await _download(url);
  stdout.writeln('✓ (${raw.length ~/ 1024} KB)');

  final text = utf8.decode(raw);
  final rows = _parseCsv(text);
  if (rows.isNotEmpty) rows.removeAt(0); // header: Book,Chapter,Verse,Text

  var inserted = 0;
  var skipped = 0;
  final batch = db.batch();
  for (final cols in rows) {
    if (cols.length < 4) continue;
    final bookId = _bookIdByName[cols[0]];
    if (bookId == null) {
      skipped++;
      continue;
    }
    batch.insert('verses', {
      'version_id': versionId,
      'book_id': bookId,
      'chapter': int.parse(cols[1]),
      'verse': int.parse(cols[2]),
      'text': cols[3].trim(),
    });
    inserted++;
  }
  stdout.write('  ✍️  Insertando $inserted versículos... ');
  await batch.commit(noResult: true);
  stdout.writeln('✓${skipped > 0 ? " (saltados: $skipped)" : ""}');
}

Future<void> _loadFromBibleApi(
    Database db, String versionId, String apiCode) async {
  stdout.writeln(
      '\n  📥 Descargando ${versionId.toUpperCase()} desde bible-api.com (66 libros)...');
  var total = 0;
  for (var i = 0; i < _bookSlugs.length; i++) {
    final bookId = _bookSlugs[i][0] as int;
    final slug = _bookSlugs[i][1] as String;
    final pct = ((i + 1) / 66 * 40).toInt();
    final bar = '█' * pct + '░' * (40 - pct);
    stdout.write(
        '\r  [$bar] ${i + 1}/66  ${slug.replaceAll('+', ' ').padRight(24)}');

    try {
      final url = '$_bibleApiBase/$slug?translation=$apiCode';
      final raw = await _download(url);
      final data = json.decode(utf8.decode(raw)) as Map<String, dynamic>;
      final verses = (data['verses'] as List<dynamic>? ?? []);
      final batch = db.batch();
      for (final v in verses) {
        final m = v as Map<String, dynamic>;
        batch.insert('verses', {
          'version_id': versionId,
          'book_id': bookId,
          'chapter': m['chapter'] as int,
          'verse': m['verse'] as int,
          'text': (m['text'] as String).trim(),
        });
      }
      await batch.commit(noResult: true);
      total += verses.length;
    } catch (e) {
      stdout.writeln('\n  ⚠️  $slug: $e — omitido');
    }
    await Future.delayed(const Duration(milliseconds: 300));
  }
  stdout.writeln('\n  ✓ $total versículos insertados');
}

Future<void> main() async {
  stdout.writeln('=' * 60);
  stdout.writeln('  🕊️  Santa Biblia — Bible DB Builder (Dart)');
  stdout.writeln('=' * 60);

  sqfliteFfiInit();
  final factory = databaseFactoryFfi;

  // Absolute path — sqflite_common_ffi rewrites bare relative paths into its
  // own `.dart_tool/sqflite_common_ffi/databases/…` directory.
  final projectRoot = Directory.current.path;
  final outputPath =
      '$projectRoot${Platform.pathSeparator}assets${Platform.pathSeparator}db${Platform.pathSeparator}santa_biblia.db';
  await Directory(
          '$projectRoot${Platform.pathSeparator}assets${Platform.pathSeparator}db')
      .create(recursive: true);

  final outFile = File(outputPath);
  if (await outFile.exists()) {
    stdout.writeln('\n  ⚠️  Ya existe — conservando para reanudar progreso');
  }

  final db = await factory.openDatabase(outputPath);
  try {
    await _createSchema(db);

    stdout.writeln(
        '\n┌─ SCROLLMAPPER (KJV, ASV, SpaRV, SpaRV1865) ─────────────┐');
    for (final e in _scrollmapperSources.entries) {
      final count = await _versionCount(db, e.key);
      if (count > 30000) {
        stdout.writeln(
            '  ✓ ${e.key.toUpperCase()} ya cargado ($count versículos), omitiendo');
        continue;
      }
      await _loadFromScrollmapper(db, e.key, e.value);
    }

    stdout.writeln(
        '\n┌─ BIBLE-API.COM (WEB) ───────────────────────────────────┐');
    for (final e in _bibleApiSources.entries) {
      final count = await _versionCount(db, e.key);
      if (count > 30000) {
        stdout.writeln(
            '  ✓ ${e.key.toUpperCase()} ya cargado ($count versículos), omitiendo');
        continue;
      }
      await _loadFromBibleApi(db, e.key, e.value);
    }

    stdout.writeln(
        '\n  🔍 FTS5 poblado en vivo por trigger (sin rebuild necesario)');

    stdout.writeln('\n  📊 Verificación:');
    final summary = await db.rawQuery(
        'SELECT version_id, COUNT(*) c FROM verses GROUP BY version_id ORDER BY version_id');
    for (final r in summary) {
      stdout.writeln('    ${r['version_id']}  ${r['c']} versículos');
    }
    final juan = await db.rawQuery(
        "SELECT text FROM verses WHERE version_id='kjv' AND book_id=43 AND chapter=3 AND verse=16");
    if (juan.isNotEmpty) {
      final t = juan.first['text'] as String;
      stdout.writeln(
          '\n  📖 Juan 3:16 (KJV): «${t.substring(0, t.length > 80 ? 80 : t.length)}...»');
    }

    // Must match `version: 1` in BibleDatabase._initDb, otherwise sqflite will
    // re-run onCreate on launch and blow up on CREATE TABLE verses.
    await db.execute('PRAGMA user_version = 1');

    stdout.write('\n  🧹 VACUUM... ');
    await db.execute('VACUUM');
    stdout.writeln('✓');
  } finally {
    await db.close();
  }

  final size = (await File(outputPath).length()) / 1048576;
  stdout.writeln(
      '\n  ✅ Base de datos lista: $outputPath (${size.toStringAsFixed(1)} MB)');
  stdout.writeln('=' * 60);
}
