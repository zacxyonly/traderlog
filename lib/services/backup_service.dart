import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';
import '../database/db_helper.dart';

class BackupRestoreResult {
  final bool success;
  final int restoredImagesCount;
  final String? message;

  BackupRestoreResult({
    required this.success,
    this.restoredImagesCount = 0,
    this.message,
  });
}

class BackupService {
  /// Builds in-memory ZIP archive from database bytes, screenshot images, and metadata
  static Uint8List createArchiveBytes({
    required Uint8List dbBytes,
    required Map<String, Uint8List> images,
    Map<String, dynamic>? extraMetadata,
  }) {
    final archive = Archive();

    // 1. Add SQLite database file
    archive.addFile(ArchiveFile('traderlog.db', dbBytes.length, dbBytes));

    // 2. Add screenshots in images/ subfolder
    images.forEach((fileName, bytes) {
      archive.addFile(ArchiveFile('images/$fileName', bytes.length, bytes));
    });

    // 3. Add manifest metadata
    final manifest = {
      'app': 'TraderLog',
      'version': '1.0.0',
      'exportDate': DateTime.now().toIso8601String(),
      'imageCount': images.length,
      ...?extraMetadata,
    };
    final manifestBytes = utf8.encode(jsonEncode(manifest));
    archive.addFile(ArchiveFile('manifest.json', manifestBytes.length, manifestBytes));

    final zipData = ZipEncoder().encode(archive);
    return Uint8List.fromList(zipData);
  }

  /// Exports a complete backup (.zip) containing SQLite database and screenshot images
  static Future<String> exportFullBackup({String? shareText}) async {
    // 1. Read SQLite database bytes
    final dbDir = await getDatabasesPath();
    final dbPath = p.join(dbDir, 'traderlog.db');
    final dbFile = File(dbPath);
    if (!await dbFile.exists()) {
      throw Exception('Database file not found at $dbPath');
    }
    final dbBytes = await dbFile.readAsBytes();

    // 2. Read all chart images from app documents
    final appDir = await getApplicationDocumentsDirectory();
    final Map<String, Uint8List> images = {};
    if (await appDir.exists()) {
      final files = appDir.listSync(recursive: false);
      for (final f in files) {
        if (f is File) {
          final baseName = p.basename(f.path);
          if (baseName.startsWith('chart_')) {
            try {
              final bytes = await f.readAsBytes();
              images[baseName] = bytes;
            } catch (_) {}
          }
        }
      }
    }

    // 3. Build ZIP
    final zipBytes = createArchiveBytes(
      dbBytes: dbBytes,
      images: images,
    );

    // 4. Save to temporary directory
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'traderlog_full_backup_$timestamp.zip';
    final zipFile = File(p.join(tempDir.path, fileName));
    await zipFile.writeAsBytes(zipBytes, flush: true);

    // 5. Share via native share sheet
    await Share.shareXFiles(
      [XFile(zipFile.path, mimeType: 'application/zip')],
      text: shareText ?? 'TraderLog Full Backup (.zip)',
      subject: 'TraderLog Backup',
    );

    return zipFile.path;
  }

  /// Restores complete backup (.zip) containing SQLite database and screenshot images
  static Future<BackupRestoreResult> restoreFullBackup(String zipFilePath) async {
    final zipFile = File(zipFilePath);
    if (!await zipFile.exists()) {
      return BackupRestoreResult(
        success: false,
        message: 'File cadangan tidak ditemukan.',
      );
    }

    try {
      final zipBytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(zipBytes);

      ArchiveFile? dbFileInZip;
      final List<ArchiveFile> imageFilesInZip = [];

      for (final file in archive) {
        if (file.name == 'traderlog.db') {
          dbFileInZip = file;
        } else if (file.name.startsWith('images/') && file.isFile) {
          imageFilesInZip.add(file);
        }
      }

      if (dbFileInZip == null) {
        return BackupRestoreResult(
          success: false,
          message: 'Format berkas zip tidak valid (file traderlog.db tidak ditemukan).',
        );
      }

      // 1. Safely close existing database connection
      await DBHelper.instance.closeDB();

      // 2. Overwrite database file
      final dbDir = await getDatabasesPath();
      final dbPath = p.join(dbDir, 'traderlog.db');
      final targetDbFile = File(dbPath);
      await targetDbFile.writeAsBytes(dbFileInZip.content as List<int>, flush: true);

      // 3. Extract screenshot images to app documents directory
      final appDir = await getApplicationDocumentsDirectory();
      int restoredImgCount = 0;
      for (final imgFile in imageFilesInZip) {
        final imgName = p.basename(imgFile.name);
        if (imgName.isNotEmpty) {
          final targetPath = p.join(appDir.path, imgName);
          final targetImg = File(targetPath);
          await targetImg.writeAsBytes(imgFile.content as List<int>, flush: true);
          restoredImgCount++;
        }
      }

      return BackupRestoreResult(
        success: true,
        restoredImagesCount: restoredImgCount,
        message: 'Cadangan berhasil dipulihkan.',
      );
    } catch (e) {
      return BackupRestoreResult(
        success: false,
        message: 'Gagal memulihkan cadangan: $e',
      );
    }
  }
}
