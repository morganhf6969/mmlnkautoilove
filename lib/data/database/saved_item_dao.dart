import 'package:sqflite/sqflite.dart';
import 'app_database.dart';
import '../models/saved_item.dart';

class SavedItemDao {
  static const String tableName = 'saved_items';

  Future<void> insert(SavedItem item) async {
    final db = await AppDatabase.database;
    await db.insert(
      tableName,
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> update(SavedItem item) async {
    if (item.id == null) return;

    final db = await AppDatabase.database;
    await db.update(
      tableName,
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<List<SavedItem>> getAll() async {
    final db = await AppDatabase.database;
    final maps = await db.query(
      tableName,
      orderBy: 'created_at DESC',
    );
    return maps.map(SavedItem.fromMap).toList();
  }

  Future<List<SavedItem>> getByCategory(String category) async {
    final db = await AppDatabase.database;

    final maps = await db.query(
      tableName,
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'created_at DESC',
    );

    return maps.map(SavedItem.fromMap).toList();
  }

  Future<List<SavedItem>> getUncategorized() async {
    final db = await AppDatabase.database;

    final maps = await db.query(
      tableName,
      where: 'category IS NULL OR category = ?',
      whereArgs: [''],
      orderBy: 'created_at DESC',
    );

    return maps.map(SavedItem.fromMap).toList();
  }

  Future<int> countByCategory(String category) async {
    final db = await AppDatabase.database;

    if (category == 'Senza categoria') {
      final result = await db.rawQuery('''
        SELECT COUNT(*) as count
        FROM $tableName
        WHERE category IS NULL OR category = ''
      ''');
      return Sqflite.firstIntValue(result) ?? 0;
    }

    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) as count
      FROM $tableName
      WHERE category = ?
      ''',
      [category],
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> moveCategory(String from, String to) async {
    final db = await AppDatabase.database;
    await db.update(
      tableName,
      {'category': to},
      where: 'category = ?',
      whereArgs: [from],
    );
  }

  Future<void> delete(int id) async {
    final db = await AppDatabase.database;
    await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteAll() async {
    final db = await AppDatabase.database;
    await db.delete(tableName);
  }

  // =========================
  // SEARCH OTTIMIZZATA
  // =========================
  Future<List<SavedItem>> search(
    String query, {
    bool newestFirst = true,
  }) async {
    final db = await AppDatabase.database;

    final words = query
        .toLowerCase()
        .split(' ')
        .where((w) => w.trim().isNotEmpty)
        .toList();

    if (words.isEmpty) return [];

    String whereClause = '';
    List<String> args = [];

    for (int i = 0; i < words.length; i++) {
      whereClause += '''
      (
        LOWER(url) LIKE ? OR
        LOWER(og_title) LIKE ? OR
        LOWER(category) LIKE ? OR
        LOWER(hashtags) LIKE ?
      )
      ''';

      if (i < words.length - 1) {
        whereClause += ' AND ';
      }

      final like = '%${words[i]}%';
      args.addAll([like, like, like, like]);
    }

    final maps = await db.query(
      tableName,
      where: whereClause,
      whereArgs: args,
      orderBy:
          'created_at ${newestFirst ? 'DESC' : 'ASC'}',
    );

    return maps.map(SavedItem.fromMap).toList();
  }
}
