import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart' as sql;

class SQLHelper {
  static Future<void> createTables(sql.Database database) async {
    await database.execute("""
      CREATE TABLE diary (
        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        feeling TEXT,
        description TEXT,
        createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        isFavorite INTEGER NOT NULL DEFAULT 0
      )
    """);
  }

static Future<void> _migrateTables(sql.Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 3) {
    await db.execute("ALTER TABLE diary ADD COLUMN isFavorite INTEGER DEFAULT 0");
  }
}


  static Future<sql.Database?> openDB() async {
    if (kIsWeb) {
      debugPrint("⚠️ SQLite not available on web.");
      return null;
    }

    return sql.openDatabase(
      'diary.db',
      version: 3,
      onCreate: (db, version) async {
        await createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await _migrateTables(db, oldVersion, newVersion);
      },
    );
  }

  static Future<int> createDiary(String feeling, String description, DateTime createdAt) async {
    final db = await openDB();
    if (db == null) return -1;
    return db.insert('diary', {
      'feeling': feeling,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'isFavorite': 0,
    });
  }

  static Future<List<Map<String, dynamic>>> getDiaries() async {
    final db = await openDB();
    if (db == null) return [];
    return db.query('diary', orderBy: "createdAt DESC");
  }

  static Future<int> updateDiary(int id, String feeling, String description) async {
    final db = await openDB();
    if (db == null) return -1;
    return db.update(
      'diary',
      {
        'feeling': feeling,
        'description': description,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> deleteDiary(int id) async {
    final db = await openDB();
    if (db == null) return;
    await db.delete('diary', where: "id = ?", whereArgs: [id]);
  }

  static Future<void> toggleFavorite(int id, bool isFav) async {
  final db = await SQLHelper.openDB();
  if (db == null) return;
  await db.update(
    'diary',
    {'isFavorite': isFav ? 1 : 0},
    where: 'id = ?',
    whereArgs: [id],
  );
}

}
