import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/trade.dart';
import '../models/app_settings.dart';

class DBHelper {
  static final DBHelper instance = DBHelper._init();
  static Database? _database;

  DBHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('traderlog.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
      onOpen: _onOpenDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE trades (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL,
        sym TEXT NOT NULL,
        side TEXT NOT NULL,
        entry REAL,
        sl REAL,
        tp REAL,
        lot REAL,
        pl REAL NOT NULL,
        why TEXT,
        note TEXT,
        image_path TEXT,
        image_path_after TEXT,
        account_id TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute('ALTER TABLE trades ADD COLUMN image_path_after TEXT;');
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE trades ADD COLUMN account_id TEXT DEFAULT 'acc_real';");
      } catch (_) {}
    }
  }

  Future<void> _onOpenDB(Database db) async {
    try {
      await db.execute('ALTER TABLE trades ADD COLUMN image_path_after TEXT;');
    } catch (_) {}
    try {
      await db.execute("ALTER TABLE trades ADD COLUMN account_id TEXT DEFAULT 'acc_real';");
    } catch (_) {}
  }

  // --- Trade Operations ---
  Future<int> insertTrade(Trade trade) async {
    final db = await instance.database;
    return await db.insert(
      'trades',
      trade.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateTrade(Trade trade) async {
    final db = await instance.database;
    return await db.update(
      'trades',
      trade.toMap(),
      where: 'id = ?',
      whereArgs: [trade.id],
    );
  }

  Future<int> deleteTrade(String id) async {
    final db = await instance.database;
    return await db.delete(
      'trades',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAllTrades() async {
    final db = await instance.database;
    return await db.delete('trades');
  }

  Future<List<Trade>> getAllTrades() async {
    final db = await instance.database;
    final result = await db.query('trades', orderBy: 'date ASC');
    return result.map((map) => Trade.fromMap(map)).toList();
  }

  Future<void> insertTradesBatch(List<Trade> trades, {bool replace = false}) async {
    final db = await instance.database;
    final batch = db.batch();

    if (replace) {
      batch.delete('trades');
    }

    for (final trade in trades) {
      batch.insert(
        'trades',
        trade.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  // --- Settings Operations ---
  Future<AppSettings> getSettings() async {
    final db = await instance.database;
    final result = await db.query('settings');

    final Map<String, String> map = {};
    for (final row in result) {
      final key = row['key'] as String;
      final val = row['value'] as String? ?? '';
      map[key] = val;
    }

    return AppSettings.fromDatabaseMap(map);
  }

  Future<void> saveSettings(AppSettings settings) async {
    final db = await instance.database;
    final batch = db.batch();

    final data = settings.toDatabaseMap();
    data.forEach((key, value) {
      batch.insert(
        'settings',
        {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });

    await batch.commit(noResult: true);
  }
}
