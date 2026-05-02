import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../data/database/app_database.dart';
import '../../data/models/saved_item.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';

class SavedItemRepository {
  // SALVATAGGIO
  Future<void> save(SavedItem item, {bool isPremium = false}) async {
    final db = await AppDatabase.database;

    // Controllo limite 10 link per versione Free (solo su nuovi inserimenti)
    // I link pre-seedati di I ❤️ Abitini non contano verso il limite
    if (!isPremium && item.id == null) {
      if (item.platform == 'file') {
        final int fileCount = await getUserFileCount();
        if (fileCount >= 10) {
          throw Exception("Limite di 10 file raggiunto. Passa a Premium per salvarne infiniti!");
        }
      } else {
        final int userCount = await getUserItemCount();
        if (userCount >= 10) {
          throw Exception("Limite di 10 link raggiunto. Passa a Premium per salvarne infiniti!");
        }
      }
    }
    
    final categoryId = await _getCategoryIdByName(item.category);

    final Map<String, dynamic> row = {
      'url': item.url,
      'category_id': categoryId,
      'platform': item.platform ?? 'manual',
      'hashtags': item.hashtags.join(','),
      'og_title': item.ogTitle,
      'og_image': item.ogImage,
      'title': item.ogTitle, 
      'thumbnail_url': item.ogImage, 
      'created_at': item.createdAt.toIso8601String(),
    };

    if (item.id != null) {
      await db.update(
        'saved_items',
        row,
        where: 'id = ?',
        whereArgs: [item.id],
      );
    } else {
      await db.insert(
        'saved_items',
        row,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  // RICERCA
  Future<List<SavedItem>> search(String query, {bool newestFirst = true}) async {
    final db = await AppDatabase.database;
    
    final cleanQuery = query.replaceAll('#', '').trim();
    if (cleanQuery.isEmpty) return [];

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT si.*, c.name as category_name 
      FROM saved_items si
      JOIN categories c ON si.category_id = c.id
      WHERE si.og_title LIKE ? 
         OR si.hashtags LIKE ? 
         OR si.url LIKE ?
         OR c.name LIKE ?
      ORDER BY si.created_at ${newestFirst ? 'DESC' : 'ASC'}
    ''', [
      '%$cleanQuery%', 
      '%$cleanQuery%', 
      '%$cleanQuery%', 
      '%$cleanQuery%'
    ]);

    return List.generate(maps.length, (i) {
      return SavedItem(
        id: maps[i]['id'],
        url: maps[i]['url'],
        category: maps[i]['category_name'] ?? 'Senza categoria',
        platform: maps[i]['platform'] ?? 'manual',
        hashtags: (maps[i]['hashtags'] as String? ?? '').split(',').where((e) => e.isNotEmpty).toList(),
        createdAt: maps[i]['created_at'] != null 
            ? DateTime.tryParse(maps[i]['created_at']) ?? DateTime.now()
            : DateTime.now(),
        ogTitle: maps[i]['og_title'],
        ogImage: maps[i]['og_image'],
      );
    });
  }

  // LETTURA PER CATEGORIA
  Future<List<SavedItem>> getByCategory(String categoryName) async {
    final db = await AppDatabase.database;
    final categoryId = await _getCategoryIdByName(categoryName);

    if (categoryId == null) return [];

    final List<Map<String, dynamic>> maps = await db.query(
      'saved_items',
      where: 'category_id = ?',
      whereArgs: [categoryId],
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) {
      return SavedItem(
        id: maps[i]['id'],
        url: maps[i]['url'],
        category: categoryName,
        platform: maps[i]['platform'] ?? 'manual',
        hashtags: (maps[i]['hashtags'] as String? ?? '').split(',').where((e) => e.isNotEmpty).toList(),
        createdAt: maps[i]['created_at'] != null 
            ? DateTime.tryParse(maps[i]['created_at']) ?? DateTime.now()
            : DateTime.now(),
        ogTitle: maps[i]['og_title'],
        ogImage: maps[i]['og_image'],
      );
    });
  }

  // CONTEGGIO LINK PER CATEGORIA
  Future<int> countByCategory(String categoryName) async {
    final db = await AppDatabase.database;
    final categoryId = await _getCategoryIdByName(categoryName);
    if (categoryId == null) return 0;

    final result = await db.rawQuery(
      'SELECT COUNT(*) as total FROM saved_items WHERE category_id = ?',
      [categoryId],
    );
    
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // CONTEGGIO TOTALE LINK
  Future<int> getTotalCount() async {
    final db = await AppDatabase.database;
    final result = await db.rawQuery('SELECT COUNT(*) as total FROM saved_items');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // CONTEGGIO LINK AGGIUNTI DALL'UTENTE (esclusi i link pre-seedati di I ❤️ Abitini)
  Future<int> getUserItemCount() async {
    final db = await AppDatabase.database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) as total
      FROM saved_items si
      JOIN categories c ON si.category_id = c.id
      WHERE c.name NOT LIKE '%Abitini%'
        AND si.platform != 'file'
    ''');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // CONTEGGIO FILE AGGIUNTI DALL'UTENTE
  Future<int> getUserFileCount() async {
    final db = await AppDatabase.database;
    final result = await db.rawQuery(
      "SELECT COUNT(*) as total FROM saved_items WHERE platform = 'file'",
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ELIMINAZIONE
  Future<void> delete(int id) async {
    final db = await AppDatabase.database;
    await db.delete('saved_items', where: 'id = ?', whereArgs: [id]);
  }

  // UTILITY: Trova l'ID della categoria dal nome
  Future<int?> _getCategoryIdByName(String name) async {
    final db = await AppDatabase.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'name = ?',
      whereArgs: [name],
    );
    if (maps.isNotEmpty) return maps.first['id'] as int;
    return null;
  }

  Future<List<SavedItem>> getAll() async {
    final db = await AppDatabase.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT si.*, c.name as category_name 
      FROM saved_items si
      LEFT JOIN categories c ON si.category_id = c.id
    ''');
    
    return maps.map((e) => SavedItem(
      id: e['id'],
      url: e['url'],
      category: e['category_name'] ?? 'Generale',
      platform: e['platform'] ?? 'manual',
      hashtags: (e['hashtags'] as String? ?? '').split(',').where((t) => t.isNotEmpty).toList(),
      createdAt: DateTime.tryParse(e['created_at'] ?? '') ?? DateTime.now(),
      ogTitle: e['og_title'],
      ogImage: e['og_image'],
    )).toList();
  }

  Future<void> deleteAll() async {
    final db = await AppDatabase.database;
    await db.delete('saved_items');
  }

  Future<int> deleteByCategory(String categoryName) async {
    final db = await AppDatabase.database;
    final categoryId = await _getCategoryIdByName(categoryName);
    if (categoryId == null) return 0;
    return await db.delete(
      'saved_items',
      where: 'category_id = ?',
      whereArgs: [categoryId],
    );
  }

  // --- LOGICA DI BACKUP AGGIORNATA ---

  Future<String?> exportBackup() async {
    try {
      final db = await AppDatabase.database;
      final List<Map<String, dynamic>> items = await db.query('saved_items');
      final List<Map<String, dynamic>> categories = await db.query('categories');

      final Map<String, dynamic> backupData = {
        'version': 1,
        'items': items,
        'categories': categories,
        'exported_at': DateTime.now().toIso8601String(),
      };

      final jsonString = jsonEncode(backupData);
      final bytes = utf8.encode(jsonString);

      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Salva il backup',
        fileName: 'memolink_backup.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: bytes, 
      );

      return outputFile;
    } catch (e) {
      debugPrint('Errore Export: $e');
      return null;
    }
  }

  Future<bool> importBackup() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );

      if (result != null) {
        String jsonString;
        
        if (result.files.single.bytes != null) {
          jsonString = utf8.decode(result.files.single.bytes!);
        } else if (result.files.single.path != null) {
          final file = File(result.files.single.path!);
          jsonString = await file.readAsString();
        } else {
          return false;
        }

        final Map<String, dynamic> backupData = jsonDecode(jsonString);
        final db = await AppDatabase.database;

        await db.transaction((txn) async {
          // 1. Inserisci le categorie (ignora se già esistono per nome)
          if (backupData['categories'] != null) {
            for (var cat in backupData['categories']) {
              await txn.insert('categories', cat,
                  conflictAlgorithm: ConflictAlgorithm.ignore);
            }
          }

          // 2. Costruisci una mappa nome→id reale (post-insert)
          final catRows = await txn.query('categories');
          final Map<String, int> nameToId = {
            for (var r in catRows) r['name'] as String: r['id'] as int,
          };

          // 3. Inserisci i link risolvendo il category_id per nome
          if (backupData['items'] != null) {
            for (var rawItem in backupData['items']) {
              final item = Map<String, dynamic>.from(rawItem);

              // Se il JSON contiene "category_name", usa quello per risolvere l'id
              if (item['category_name'] != null) {
                final resolvedId = nameToId[item['category_name']];
                if (resolvedId != null) item['category_id'] = resolvedId;
                item.remove('category_name');
              }

              // Rimuovi l'id originale così SQLite assegna uno nuovo (evita conflitti)
              item.remove('id');
              item['created_at'] ??= DateTime.now().toIso8601String();

              await txn.insert('saved_items', item,
                  conflictAlgorithm: ConflictAlgorithm.ignore);
            }
          }
        });
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Errore Import: $e');
      return false;
    }
  }
}