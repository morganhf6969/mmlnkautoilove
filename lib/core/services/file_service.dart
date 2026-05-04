import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class FileService {
  static Future<Directory> _filesDir() async => filesDir();

  /// Cartella privata dell'app per i file archiviati (pubblica per backup).
  static Future<Directory> filesDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'memolink_files'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Copia il file sorgente nella cartella privata dell'app.
  /// Restituisce il path locale del file copiato.
  static Future<String> copyToApp(String sourcePath) async {
    final dir = await _filesDir();
    final fileName = _uniqueName(p.basename(sourcePath));
    final dest = File(p.join(dir.path, fileName));
    await File(sourcePath).copy(dest.path);
    return dest.path;
  }

  /// Elimina il file fisico dal disco.
  static Future<void> deleteFile(String localPath) async {
    final f = File(localPath);
    if (await f.exists()) await f.delete();
  }

  /// Restituisce un nome univoco aggiungendo timestamp se il file esiste già.
  static String _uniqueName(String name) {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final ext = p.extension(name);
    final base = p.basenameWithoutExtension(name);
    return '${base}_$ts$ext';
  }

  /// Icona emoji in base all'estensione.
  static String iconForPath(String path) {
    final ext = p.extension(path).toLowerCase();
    switch (ext) {
      case '.pdf': return '📄';
      case '.doc':
      case '.docx': return '📝';
      case '.xls':
      case '.xlsx': return '📊';
      case '.ppt':
      case '.pptx': return '📊';
      case '.jpg':
      case '.jpeg':
      case '.png':
      case '.gif':
      case '.heic':
      case '.webp': return '🖼️';
      case '.mp4':
      case '.mov':
      case '.avi': return '🎬';
      case '.mp3':
      case '.m4a':
      case '.wav': return '🎵';
      case '.zip':
      case '.rar': return '🗜️';
      default: return '📎';
    }
  }

  static String nameFromPath(String path) => p.basename(path);
}
