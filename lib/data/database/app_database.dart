import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class AppDatabase {
  static Database? _database;
  static const String _dbName = 'memolink.db';

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _init();
    return _database!;
  }

  static Future<Database> _init() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _dbName);

    return await openDatabase(
      path,
      version: 9,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: (db) async {
        await _fixMissingColumns(db);
        await _createTables(db);
        await _ensureDefaultCategories(db);
      },
    );
  }

  static Future<void> _fixMissingColumns(Database db) async {
    var catColumns = await db.rawQuery('PRAGMA table_info(categories)');
    if (!catColumns.any((c) => c['name'] == 'position')) {
      await db.execute('ALTER TABLE categories ADD COLUMN position INTEGER DEFAULT 0');
    }
    if (!catColumns.any((c) => c['name'] == 'icon_code')) {
      await db.execute('ALTER TABLE categories ADD COLUMN icon_code INTEGER');
    }
  }

  static Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE NOT NULL,
        icon_code INTEGER,
        position INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS saved_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER,
        url TEXT NOT NULL,
        platform TEXT,
        hashtags TEXT,
        og_title TEXT,
        og_image TEXT,
        title TEXT,
        thumbnail_url TEXT,
        created_at TEXT,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE
      )
    ''');
  }

  static Future<void> _onCreate(Database db, int version) async {
    await _createTables(db);
    await _insertDefaultCategories(db);
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await _fixMissingColumns(db);
    if (oldVersion < 9) {
      // Sposta "I ❤️ Abitini" in posizione 0 e scala tutte le altre di +1
      await db.execute('''
        UPDATE categories
        SET position = position + 1
        WHERE name != 'I ❤️ Abitini'
      ''');
      await db.execute('''
        UPDATE categories
        SET position = 0
        WHERE name = 'I ❤️ Abitini'
      ''');
    }
  }

  static Future<void> _ensureDefaultCategories(Database db) async {
    // Tentiamo sempre di inserire le categorie di default (ConflictAlgorithm.ignore
    // garantisce che le categorie già esistenti non vengano duplicate). In questo
    // modo le nuove categorie di default vengono aggiunte anche ai DB già esistenti.
    await _insertDefaultCategories(db);
  }

  static Future<void> _insertDefaultCategories(Database db) async {
    // Corretta la chiave da 'icon' a 'icon_code' per combaciare con lo schema
    final List<Map<String, dynamic>> defaults = [
      {'name': 'I ❤️ Abitini', 'icon_code': 9},
      {'name': 'Cucina', 'icon_code': 1},
      {'name': 'Tecnologia', 'icon_code': 8},
      {'name': 'Arte', 'icon_code': 0},
      {'name': 'Musica', 'icon_code': 5},
      {'name': 'Divertente', 'icon_code': 2},
      {'name': 'Luoghi', 'icon_code': 3},
      {'name': 'Moda', 'icon_code': 4},
    ];

    for (int i = 0; i < defaults.length; i++) {
      await db.insert('categories', {
        'name': defaults[i]['name'],
        'icon_code': defaults[i]['icon_code'],
        'position': i,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }
}