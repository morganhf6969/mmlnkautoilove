import 'package:sqflite/sqflite.dart';
import 'app_database.dart';

class Category {
  final int? id; 
  final String name;
  final int? iconCode;
  final int position;

  Category({
    this.id,
    required this.name,
    this.iconCode,
    required this.position,
  });

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as int?,
      name: map['name'] as String,
      iconCode: map['icon_code'] as int?,
      position: (map['position'] as int? ?? 0),
    );
  }
}

class CategoryDao {
  Future<List<Category>> getAll() async {
    final db = await AppDatabase.database;

    final maps = await db.query(
      'categories',
      orderBy: 'position ASC',
    );

    return maps.map((e) => Category.fromMap(e)).toList();
  }

  Future<void> insert(String name, int? iconCode) async {
    final db = await AppDatabase.database;

    final result = await db.rawQuery('SELECT MAX(position) as maxPos FROM categories');
    int nextPos = (result.first['maxPos'] as int? ?? -1) + 1;

    await db.insert(
      'categories',
      {
        'name': name,
        'icon_code': iconCode,
        'position': nextPos,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // RINOMINATO PER COMBACIARE CON LA HOME PAGE
  Future<void> updateNameAndIcon(int id, String name, int? iconCode) async {
    final db = await AppDatabase.database;
    await db.update(
      'categories',
      {
        'name': name, 
        'icon_code': iconCode
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updatePositions(List<Category> categories) async {
    final db = await AppDatabase.database;
    
    await db.transaction((txn) async {
      for (int i = 0; i < categories.length; i++) {
        await txn.update(
          'categories',
          {'position': i}, 
          where: 'id = ?',
          whereArgs: [categories[i].id],
        );
      }
    });
  }

  Future<void> delete(int id) async {
    final db = await AppDatabase.database;
    await db.transaction((txn) async {
      await txn.delete(
        'saved_items',
        where: 'category_id = ?',
        whereArgs: [id],
      );
      await txn.delete(
        'categories',
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }
}