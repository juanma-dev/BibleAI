// Quick inspector to verify the DB at the user-documents path is valid.
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> main(List<String> args) async {
  sqfliteFfiInit();
  final factory = databaseFactoryFfi;

  final target = args.isNotEmpty
      ? args.first
      : '${Platform.environment['USERPROFILE']}\\Documents\\santa_biblia\\santa_biblia.db';

  stdout.writeln('Inspeccionando: $target');
  if (!await File(target).exists()) {
    stdout.writeln('  ❌ NO EXISTE');
    return;
  }
  stdout.writeln('  tamaño: ${(await File(target).length()) ~/ 1024} KB');

  final db = await factory.openDatabase(target,
      options: OpenDatabaseOptions(readOnly: true));
  try {
    final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name");
    stdout.writeln('  tablas: ${tables.map((t) => t['name']).join(', ')}');

    final counts = await db.rawQuery(
        'SELECT version_id, COUNT(*) c FROM verses GROUP BY version_id ORDER BY version_id');
    stdout.writeln('  versículos por versión:');
    for (final r in counts) {
      stdout.writeln('    ${r['version_id']}: ${r['c']}');
    }

    final gen5 = await db.rawQuery(
        "SELECT verse, text FROM verses WHERE version_id='rv1909' AND book_id=1 AND chapter=5 ORDER BY verse LIMIT 3");
    stdout.writeln('  Génesis 5 (rv1909) primeros 3:');
    for (final r in gen5) {
      stdout.writeln('    v${r['verse']}: ${r['text']}');
    }
  } finally {
    await db.close();
  }
}
