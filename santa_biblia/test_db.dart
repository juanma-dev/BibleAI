import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';

void main() async {
  sqfliteFfiInit();
  var databaseFactory = databaseFactoryFfi;
  var dbPath = r'C:\Users\Ciadti\Documents\santa_biblia\santa_biblia.db';
  print('Checking $dbPath');
  var db = await databaseFactory.openDatabase(dbPath);
  var result = await db.rawQuery('SELECT version_id, COUNT(*) FROM verses GROUP BY version_id');
  print(result);
  await db.close();
}
