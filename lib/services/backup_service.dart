import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/app_settings.dart';
import '../models/trade.dart';

class BackupException implements Exception {
  final String message;
  BackupException(this.message);

  @override
  String toString() => message;
}

/// Summary shown to the user before they confirm a restore.
class BackupPreview {
  final int tradeCount;
  final int accountCount;
  final int imageCount;
  final DateTime? createdAt;

  const BackupPreview({
    required this.tradeCount,
    required this.accountCount,
    required this.imageCount,
    required this.createdAt,
  });
}

/// Fully decoded backup, with screenshots already written to disk and the
/// trades' image paths pointing at those new files.
class BackupData {
  final List<Trade> trades;
  final AppSettings settings;

  const BackupData({required this.trades, required this.settings});
}

/// Full backup / restore as a single ZIP:
///
///   manifest.json   -> format marker + version + creation time
///   data.json       -> trades + accounts + settings
///   images/...      -> every screenshot attached to a trade
///
/// The PIN hash, biometric flag and "last backup" date are deliberately NOT
/// written to the backup: the file is meant to be uploaded to cloud storage,
/// and a PIN belongs to the device it was set on.
class BackupService {
  static const String appId = 'traderlog';
  static const int formatVersion = 1;
  static const String _manifestName = 'manifest.json';
  static const String _dataName = 'data.json';
  static const String _imagesDir = 'images/';

  /// Settings keys that never leave the device.
  static const Set<String> _deviceOnlyKeys = {
    'pin_code',
    'is_biometric_enabled',
    'last_backup_date',
  };

  static const Set<String> _allowedImageExt = {
    'jpg', 'jpeg', 'png', 'webp', 'gif', 'heic', 'heif',
  };

  // Guards against absurd / malicious archives.
  static const int _maxEntries = 20000;
  static const int _maxJsonBytes = 50 * 1024 * 1024;

  // ---------------------------------------------------------------- export

  /// Builds the ZIP in memory. Screenshots whose file no longer exists are
  /// simply left out (the trade is kept, without that image).
  static List<int> buildBackupBytes({
    required List<Trade> trades,
    required AppSettings settings,
    DateTime? now,
  }) {
    final archive = Archive();
    final tradeMaps = <Map<String, dynamic>>[];

    for (var i = 0; i < trades.length; i++) {
      final t = trades[i];
      final map = t.toMap();
      map['image_path'] =
          _addImage(archive, t.imagePath, '$_imagesDir${i}_before');
      map['image_path_after'] =
          _addImage(archive, t.imagePathAfter, '$_imagesDir${i}_after');
      tradeMaps.add(map);
    }

    final settingsMap = Map<String, String>.from(settings.toDatabaseMap())
      ..removeWhere((key, _) => _deviceOnlyKeys.contains(key));

    final data = <String, dynamic>{
      'trades': tradeMaps,
      'settings': settingsMap,
    };
    final manifest = <String, dynamic>{
      'app': appId,
      'formatVersion': formatVersion,
      'createdAt': (now ?? DateTime.now()).toIso8601String(),
      'tradeCount': trades.length,
    };

    _addBytes(archive, _manifestName, utf8.encode(jsonEncode(manifest)));
    _addBytes(archive, _dataName, utf8.encode(jsonEncode(data)));

    // `encode` is nullable in archive 3.x and non-nullable in 4.x; keeping it
    // dynamic compiles against both.
    final dynamic encoded = ZipEncoder().encode(archive);
    if (encoded == null) {
      throw BackupException('Gagal membuat file ZIP cadangan.');
    }
    return List<int>.from(encoded as List);
  }

  /// Returns the archive-relative name of the stored image, or null.
  static String? _addImage(Archive archive, String? path, String baseName) {
    if (path == null || path.trim().isEmpty) return null;
    try {
      final file = File(path);
      if (!file.existsSync()) return null;
      final bytes = file.readAsBytesSync();
      final ext = _extensionOf(path);
      final name = '$baseName.$ext';
      _addBytes(archive, name, bytes);
      return name;
    } catch (_) {
      return null;
    }
  }

  static void _addBytes(Archive archive, String name, List<int> bytes) {
    final data = Uint8List.fromList(bytes);
    archive.addFile(ArchiveFile(name, data.length, data));
  }

  static String _extensionOf(String path) {
    final dot = path.lastIndexOf('.');
    if (dot == -1 || dot == path.length - 1) return 'jpg';
    final ext = path.substring(dot + 1).toLowerCase();
    return _allowedImageExt.contains(ext) ? ext : 'jpg';
  }

  /// Builds the ZIP, writes it to a temp file and opens the share sheet.
  static Future<File> exportBackup({
    required List<Trade> trades,
    required AppSettings settings,
    required String fileName,
    String? shareText,
  }) async {
    final bytes = buildBackupBytes(trades: trades, settings: settings);
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/zip')],
      text: shareText,
      subject: 'TraderLog Backup',
    );
    return file;
  }

  // --------------------------------------------------------------- restore

  /// Opens and validates a backup. Nothing is written to disk yet.
  static OpenedBackup open(List<int> zipBytes) {
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(zipBytes);
    } catch (_) {
      throw BackupException('File ini bukan ZIP cadangan TraderLog yang valid.');
    }

    if (archive.length > _maxEntries) {
      throw BackupException('File cadangan terlalu besar atau tidak wajar.');
    }

    final entries = <String, ArchiveFile>{};
    for (final f in archive) {
      if (f.isFile) entries[f.name] = f;
    }

    final manifestFile = entries[_manifestName];
    final dataFile = entries[_dataName];
    if (manifestFile == null || dataFile == null) {
      throw BackupException('File ini bukan ZIP cadangan TraderLog yang valid.');
    }

    final Map<String, dynamic> manifest;
    final Map<String, dynamic> data;
    try {
      manifest = _readJson(manifestFile);
      data = _readJson(dataFile);
    } catch (_) {
      throw BackupException('Isi file cadangan rusak.');
    }

    if (manifest['app'] != appId) {
      throw BackupException('File ini bukan cadangan TraderLog.');
    }
    final version = manifest['formatVersion'];
    if (version is! int || version < 1) {
      throw BackupException('Versi format cadangan tidak dikenali.');
    }
    if (version > formatVersion) {
      throw BackupException(
        'Cadangan ini dibuat oleh versi TraderLog yang lebih baru. '
        'Perbarui aplikasi lalu coba lagi.',
      );
    }

    final rawTrades = data['trades'];
    final rawSettings = data['settings'];
    if (rawTrades is! List || rawSettings is! Map) {
      throw BackupException('Isi file cadangan rusak.');
    }

    final settingsMap = <String, String>{
      for (final e in rawSettings.entries)
        if (!_deviceOnlyKeys.contains(e.key.toString()))
          e.key.toString(): e.value?.toString() ?? '',
    };

    final tradeMaps = <Map<String, dynamic>>[];
    try {
      for (final raw in rawTrades) {
        tradeMaps.add(Map<String, dynamic>.from(raw as Map));
      }
      // Validate every trade up-front so a bad file fails before any write.
      for (final m in tradeMaps) {
        Trade.fromMap(m);
      }
    } catch (_) {
      throw BackupException('Data trade di file cadangan rusak.');
    }

    final settings = AppSettings.fromDatabaseMap(settingsMap);

    var imageCount = 0;
    for (final m in tradeMaps) {
      for (final key in const ['image_path', 'image_path_after']) {
        final ref = m[key];
        if (ref is String && _isSafeImageRef(ref) && entries.containsKey(ref)) {
          imageCount++;
        }
      }
    }

    return OpenedBackup._(
      entries: entries,
      tradeMaps: tradeMaps,
      settings: settings,
      preview: BackupPreview(
        tradeCount: tradeMaps.length,
        accountCount: settings.accounts.length,
        imageCount: imageCount,
        createdAt: DateTime.tryParse(manifest['createdAt']?.toString() ?? ''),
      ),
    );
  }

  static Map<String, dynamic> _readJson(ArchiveFile file) {
    if (file.size > _maxJsonBytes) throw const FormatException('too large');
    final dynamic content = file.content;
    final text = utf8.decode(List<int>.from(content as List));
    return Map<String, dynamic>.from(jsonDecode(text) as Map);
  }

  /// Only `images/<plain file name>` is ever honoured: no absolute paths, no
  /// `..`, no sub-directories.
  static bool _isSafeImageRef(String ref) {
    if (!ref.startsWith(_imagesDir)) return false;
    final rest = ref.substring(_imagesDir.length);
    if (rest.isEmpty) return false;
    if (rest.contains('/') || rest.contains('\\') || rest.contains('..')) {
      return false;
    }
    return true;
  }
}

/// A validated backup that has not touched the filesystem yet.
class OpenedBackup {
  final Map<String, ArchiveFile> _entries;
  final List<Map<String, dynamic>> _tradeMaps;
  final AppSettings _settings;
  final BackupPreview preview;

  OpenedBackup._({
    required Map<String, ArchiveFile> entries,
    required List<Map<String, dynamic>> tradeMaps,
    required AppSettings settings,
    required this.preview,
  })  : _entries = entries,
        _tradeMaps = tradeMaps,
        _settings = settings;

  /// Writes the screenshots into [imagesDir] under fresh file names and
  /// returns the trades with their image paths rewritten. If anything fails,
  /// the files written so far are removed again.
  Future<BackupData> materialize(Directory imagesDir) async {
    final written = <File>[];
    final stamp = DateTime.now().millisecondsSinceEpoch;
    try {
      if (!imagesDir.existsSync()) {
        imagesDir.createSync(recursive: true);
      }

      Future<String?> restoreImage(dynamic ref, String tag) async {
        if (ref is! String || !BackupService._isSafeImageRef(ref)) return null;
        final entry = _entries[ref];
        if (entry == null) return null;
        final ext = BackupService._extensionOf(ref);
        final file = File('${imagesDir.path}/restored_${stamp}_$tag.$ext');
        final dynamic content = entry.content;
        await file.writeAsBytes(List<int>.from(content as List), flush: true);
        written.add(file);
        return file.path;
      }

      final trades = <Trade>[];
      for (var i = 0; i < _tradeMaps.length; i++) {
        final map = Map<String, dynamic>.from(_tradeMaps[i]);
        map['image_path'] = await restoreImage(map['image_path'], '${i}_before');
        map['image_path_after'] =
            await restoreImage(map['image_path_after'], '${i}_after');
        trades.add(Trade.fromMap(map));
      }
      return BackupData(trades: trades, settings: _settings);
    } catch (e) {
      for (final f in written) {
        try {
          if (f.existsSync()) f.deleteSync();
        } catch (_) {}
      }
      if (e is BackupException) rethrow;
      throw BackupException('Gagal memulihkan data: $e');
    }
  }
}
