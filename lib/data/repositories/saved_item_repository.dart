import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import '../../data/database/app_database.dart';
import '../../data/models/saved_item.dart';
import '../../core/services/file_service.dart';
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

  // ─── SYNC CLOUD: @iloveabitini ─────────────────────────────────────────────

  /// Inserisce nel DB i link di "I ❤️ Abitini" presenti nel feed remoto
  /// che non sono ancora salvati localmente (deduplicazione per URL).
  /// Non conta verso il limite free e non tocca gli elementi già esistenti.
  Future<int> syncIloveAbitiniFromCloud(List<Map<String, dynamic>> remoteItems) async {
    final db = await AppDatabase.database;

    final catResult = await db.rawQuery(
      "SELECT id FROM categories WHERE name LIKE '%Abitini%' LIMIT 1",
    );
    if (catResult.isEmpty) return 0;
    final categoryId = catResult.first['id'] as int;

    int added = 0;
    for (final item in remoteItems) {
      final url = item['url'] as String?;
      if (url == null || url.isEmpty) continue;

      // Salta se già presente nel DB
      final existing = await db.rawQuery(
        'SELECT id FROM saved_items WHERE url = ? LIMIT 1',
        [url],
      );
      if (existing.isNotEmpty) continue;

      await db.insert('saved_items', {
        'url': url,
        'platform': item['platform'] ?? 'instagram',
        'category_id': categoryId,
        'hashtags': item['hashtags'] ?? '',
        'og_title': item['og_title'],
        'og_image': item['og_image'],
        'title': item['og_title'],
        'thumbnail_url': item['og_image'],
        'created_at': item['created_at'] ?? DateTime.now().toIso8601String(),
      });
      added++;
    }

    debugPrint('syncIloveAbitini: $added nuovi link aggiunti dal cloud.');
    return added;
  }

  // ─── BACKUP: solo link (JSON) ──────────────────────────────────────────────

  Future<String?> exportBackup() async {
    try {
      final db = await AppDatabase.database;
      final items = await db.query('saved_items');
      final categories = await db.query('categories');

      final backupData = {
        'version': 1,
        'includes_files': false,
        'items': items,
        'categories': categories,
        'exported_at': DateTime.now().toIso8601String(),
      };

      final bytes = utf8.encode(jsonEncode(backupData));
      await FilePicker.platform.saveFile(
        dialogTitle: 'Salva il backup',
        fileName: 'memolink_backup.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: bytes,
      );
      return 'ok';
    } catch (e) {
      debugPrint('Errore Export JSON: $e');
      return null;
    }
  }

  // ─── BACKUP: link + file fisici (ZIP) ──────────────────────────────────────

  Future<String?> exportBackupWithFiles() async {
    try {
      final db = await AppDatabase.database;
      final items = await db.query('saved_items');
      final categories = await db.query('categories');

      // Nel JSON salvo il solo nome del file (non il path assoluto)
      // così il ripristino funziona su qualsiasi dispositivo.
      final itemsWithBasename = items.map((row) {
        final m = Map<String, dynamic>.from(row);
        if (m['platform'] == 'file' && m['url'] != null) {
          m['file_basename'] = p.basename(m['url'] as String);
        }
        return m;
      }).toList();

      final backupData = {
        'version': 2,
        'includes_files': true,
        'items': itemsWithBasename,
        'categories': categories,
        'exported_at': DateTime.now().toIso8601String(),
      };

      final archive = Archive();

      // 1. backup.json
      final jsonBytes = utf8.encode(jsonEncode(backupData));
      archive.addFile(ArchiveFile('backup.json', jsonBytes.length, jsonBytes));

      // 2. File fisici
      final filesDir = await FileService.filesDir();
      if (await filesDir.exists()) {
        await for (final entity in filesDir.list()) {
          if (entity is File) {
            final fileBytes = await entity.readAsBytes();
            archive.addFile(ArchiveFile(
              'files/${p.basename(entity.path)}',
              fileBytes.length,
              fileBytes,
            ));
          }
        }
      }

      final zipBytes = ZipEncoder().encode(archive);
      if (zipBytes == null) return null;

      await FilePicker.platform.saveFile(
        dialogTitle: 'Salva il backup completo',
        fileName: 'memolink_backup_completo.zip',
        type: FileType.custom,
        allowedExtensions: ['zip'],
        bytes: Uint8List.fromList(zipBytes),
      );
      return 'ok';
    } catch (e) {
      debugPrint('Errore Export ZIP: $e');
      return null;
    }
  }

  // ─── RIPRISTINO (JSON o ZIP rilevato automaticamente) ──────────────────────

  Future<bool> importBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'zip'],
        withData: true,
      );
      if (result == null) return false;

      final ext = (result.files.single.extension ?? '').toLowerCase();

      if (ext == 'zip') {
        return await _importFromZip(result);
      } else {
        return await _importFromJson(result);
      }
    } catch (e) {
      debugPrint('Errore Import: $e');
      return false;
    }
  }

  // ─── Import da JSON ─────────────────────────────────────────────────────────

  Future<bool> _importFromJson(FilePickerResult result) async {
    try {
      String jsonString;
      if (result.files.single.bytes != null) {
        jsonString = utf8.decode(result.files.single.bytes!);
      } else if (result.files.single.path != null) {
        jsonString = await File(result.files.single.path!).readAsString();
      } else {
        return false;
      }

      final backupData = jsonDecode(jsonString) as Map<String, dynamic>;
      await _insertBackupData(backupData, fileBasenameToPath: {});
      return true;
    } catch (e) {
      debugPrint('Errore Import JSON: $e');
      return false;
    }
  }

  // ─── Import da ZIP ──────────────────────────────────────────────────────────

  Future<bool> _importFromZip(FilePickerResult result) async {
    try {
      late List<int> zipBytes;
      if (result.files.single.bytes != null) {
        zipBytes = result.files.single.bytes!;
      } else if (result.files.single.path != null) {
        zipBytes = await File(result.files.single.path!).readAsBytes();
      } else {
        return false;
      }

      final archive = ZipDecoder().decodeBytes(zipBytes);
      final filesDir = await FileService.filesDir();

      // Mappa basename → path locale dopo ripristino
      final Map<String, String> basenameToPath = {};

      // 1. Estrai i file fisici
      for (final file in archive) {
        if (file.isFile && file.name.startsWith('files/')) {
          final basename = p.basename(file.name);
          final dest = File(p.join(filesDir.path, basename));
          await dest.writeAsBytes(file.content as List<int>);
          basenameToPath[basename] = dest.path;
        }
      }

      // 2. Leggi backup.json
      final jsonFile = archive.findFile('backup.json');
      if (jsonFile == null) return false;
      final jsonString = utf8.decode(jsonFile.content as List<int>);
      final backupData = jsonDecode(jsonString) as Map<String, dynamic>;

      await _insertBackupData(backupData, fileBasenameToPath: basenameToPath);
      return true;
    } catch (e) {
      debugPrint('Errore Import ZIP: $e');
      return false;
    }
  }

  // ─── Inserimento dati nel DB ────────────────────────────────────────────────

  Future<void> _insertBackupData(
    Map<String, dynamic> backupData, {
    required Map<String, String> fileBasenameToPath,
  }) async {
    final db = await AppDatabase.database;

    await db.transaction((txn) async {
      // 1. Categorie
      if (backupData['categories'] != null) {
        for (final cat in backupData['categories']) {
          await txn.insert('categories', cat,
              conflictAlgorithm: ConflictAlgorithm.ignore);
        }
      }

      // 2. Mappa nome → id reale
      final catRows = await txn.query('categories');
      final nameToId = {
        for (final r in catRows) r['name'] as String: r['id'] as int,
      };

      // 3. Item
      if (backupData['items'] != null) {
        for (final rawItem in backupData['items']) {
          final item = Map<String, dynamic>.from(rawItem);

          // Risolvi category_id
          if (item['category_name'] != null) {
            final resolvedId = nameToId[item['category_name']];
            if (resolvedId != null) item['category_id'] = resolvedId;
            item.remove('category_name');
          }

          // Per i file: aggiorna il path con quello locale ripristinato
          if (item['platform'] == 'file' && item['file_basename'] != null) {
            final basename = item['file_basename'] as String;
            final localPath = fileBasenameToPath[basename];
            if (localPath != null) item['url'] = localPath;
            item.remove('file_basename');
          } else {
            item.remove('file_basename');
          }

          item.remove('id');
          item['created_at'] ??= DateTime.now().toIso8601String();

          await txn.insert('saved_items', item,
              conflictAlgorithm: ConflictAlgorithm.ignore);
        }
      }
    });
  }
}