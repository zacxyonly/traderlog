import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traderlog/models/app_settings.dart';
import 'package:traderlog/models/trade.dart';
import 'package:traderlog/models/trading_account.dart';
import 'package:traderlog/services/backup_service.dart';
import 'package:traderlog/utils/pin_hasher.dart';

List<int> _zip(Map<String, List<int>> files) {
  final a = Archive();
  files.forEach((name, bytes) {
    final data = Uint8List.fromList(bytes);
    a.addFile(ArchiveFile(name, data.length, data));
  });
  final dynamic out = ZipEncoder().encode(a);
  return List<int>.from(out as List);
}

void main() {
  late Directory tmp;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('traderlog_backup_test_');
  });

  tearDown(() {
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  File writeImage(String name, List<int> bytes) =>
      File('${tmp.path}/$name')..writeAsBytesSync(bytes);

  test('round trip keeps trades, screenshots, accounts and settings', () async {
    final before = writeImage('before.png', [1, 2, 3, 4, 5]);
    final after = writeImage('after.jpg', [9, 8, 7]);

    final trades = [
      Trade(
        id: 'a1',
        date: DateTime(2026, 10, 1, 9, 30),
        sym: 'EUR/USD',
        side: TradeSide.buy,
        entry: 1.08,
        exit: 1.085,
        lot: 0.1,
        pl: 50,
        why: 'Breakout',
        note: 'Calm',
        imagePath: before.path,
        imagePathAfter: after.path,
        accountId: 'acc_demo',
      ),
      Trade(
        id: 'b2',
        date: DateTime(2026, 10, 2),
        sym: 'XAU/USD',
        side: TradeSide.sell,
        pl: -20,
        accountId: 'acc_real',
      ),
    ];

    final settings = AppSettings(
      traderName: 'Rina',
      languageCode: 'en',
      weekStartsMonday: true,
      defaultLot: 0.05,
      hideBalance: true,
      activeAccountId: 'acc_demo',
      accounts: [
        const TradingAccount(id: 'acc_real', name: 'Real', initialCapital: 500),
        const TradingAccount(
            id: 'acc_demo', name: 'Demo', type: 'demo', initialCapital: 10000),
      ],
      symbols: const ['EUR/USD', 'XAU/USD', 'MY/CUSTOM'],
      pinHash: PinHasher.hash('1234'),
      isBiometricEnabled: true,
      lastBackupDate: '2026-10-10T10:00:00',
    );

    final bytes = BackupService.buildBackupBytes(
      trades: trades,
      settings: settings,
      now: DateTime(2026, 10, 18, 7),
    );

    final opened = BackupService.open(bytes);
    expect(opened.preview.tradeCount, 2);
    expect(opened.preview.accountCount, 2);
    expect(opened.preview.imageCount, 2);
    expect(opened.preview.createdAt, DateTime(2026, 10, 18, 7));

    final restoreDir = Directory('${tmp.path}/restore');
    final data = await opened.materialize(restoreDir);

    expect(data.trades.length, 2);
    final t0 = data.trades.firstWhere((t) => t.id == 'a1');
    expect(t0.sym, 'EUR/USD');
    expect(t0.pl, 50);
    expect(t0.why, 'Breakout');
    expect(t0.accountId, 'acc_demo');
    expect(File(t0.imagePath!).readAsBytesSync(), [1, 2, 3, 4, 5]);
    expect(File(t0.imagePathAfter!).readAsBytesSync(), [9, 8, 7]);
    expect(t0.imagePath!.startsWith(restoreDir.path), true);
    expect(t0.imagePath!.endsWith('.png'), true);

    final t1 = data.trades.firstWhere((t) => t.id == 'b2');
    expect(t1.imagePath, isNull);
    expect(t1.imagePathAfter, isNull);

    final s = data.settings;
    expect(s.traderName, 'Rina');
    expect(s.languageCode, 'en');
    expect(s.weekStartsMonday, true);
    expect(s.defaultLot, 0.05);
    expect(s.hideBalance, true);
    expect(s.activeAccountId, 'acc_demo');
    expect(s.accounts.map((a) => a.id), ['acc_real', 'acc_demo']);
    expect(s.accounts[1].initialCapital, 10000);
    expect(s.symbols, contains('MY/CUSTOM'));
  });

  test('PIN hash, biometric flag and last-backup date are never exported', () {
    final settings = AppSettings(
      pinHash: PinHasher.hash('1234'),
      isBiometricEnabled: true,
      lastBackupDate: '2026-10-10T10:00:00',
    );
    final bytes = BackupService.buildBackupBytes(trades: [], settings: settings);

    final archive = ZipDecoder().decodeBytes(bytes);
    final dataFile = archive.firstWhere((f) => f.name == 'data.json');
    final text = utf8.decode(List<int>.from(dataFile.content as List));
    expect(text.contains('pin_code'), false);
    expect(text.contains('v1:'), false);
    expect(text.contains('is_biometric_enabled'), false);
    expect(text.contains('last_backup_date'), false);

    final restored = BackupService.open(bytes);
    // Restored settings carry no PIN.
    return restored.materialize(Directory('${tmp.path}/r')).then((d) {
      expect(d.settings.isPinSet, false);
      expect(d.settings.isBiometricEnabled, false);
    });
  });

  test('missing screenshot file keeps the trade, drops only the image', () async {
    final trade = Trade(
      id: 'x',
      date: DateTime(2026, 10, 3),
      sym: 'BTC/USD',
      side: TradeSide.buy,
      pl: 5,
      imagePath: '${tmp.path}/deleted.png',
    );
    final bytes =
        BackupService.buildBackupBytes(trades: [trade], settings: AppSettings());
    final opened = BackupService.open(bytes);
    expect(opened.preview.imageCount, 0);
    final data = await opened.materialize(Directory('${tmp.path}/r'));
    expect(data.trades.single.id, 'x');
    expect(data.trades.single.imagePath, isNull);
  });

  test('rejects files that are not a TraderLog backup', () {
    expect(() => BackupService.open([1, 2, 3, 4]),
        throwsA(isA<BackupException>()));

    expect(
      () => BackupService.open(_zip({'hello.txt': utf8.encode('hi')})),
      throwsA(isA<BackupException>()),
    );

    expect(
      () => BackupService.open(_zip({
        'manifest.json':
            utf8.encode(jsonEncode({'app': 'other', 'formatVersion': 1})),
        'data.json': utf8.encode(jsonEncode({'trades': [], 'settings': {}})),
      })),
      throwsA(isA<BackupException>()),
    );
  });

  test('rejects a backup from a newer format version', () {
    final bytes = _zip({
      'manifest.json': utf8.encode(
          jsonEncode({'app': 'traderlog', 'formatVersion': 999})),
      'data.json': utf8.encode(jsonEncode({'trades': [], 'settings': {}})),
    });
    expect(
      () => BackupService.open(bytes),
      throwsA(predicate((e) => e is BackupException && e.message.contains('lebih baru'))),
    );
  });

  test('corrupt trade data fails before anything is written', () {
    final bytes = _zip({
      'manifest.json': utf8.encode(
          jsonEncode({'app': 'traderlog', 'formatVersion': 1})),
      'data.json': utf8.encode(jsonEncode({
        'trades': [
          {'id': 'bad'}
        ],
        'settings': {}
      })),
    });
    expect(() => BackupService.open(bytes), throwsA(isA<BackupException>()));
  });

  test('path traversal in image references is ignored', () async {
    final evilTarget = File('${tmp.path}/evil.txt');
    final bytes = _zip({
      'manifest.json': utf8.encode(
          jsonEncode({'app': 'traderlog', 'formatVersion': 1})),
      'data.json': utf8.encode(jsonEncode({
        'trades': [
          {
            'id': 't',
            'date': DateTime(2026, 10, 1).toIso8601String(),
            'sym': 'EUR/USD',
            'side': 'BUY',
            'pl': 1.0,
            'image_path': 'images/../../evil.txt',
            'image_path_after': '/etc/passwd',
            'account_id': 'acc_real',
          }
        ],
        'settings': {}
      })),
      '../evil.txt': utf8.encode('pwned'),
    });

    final opened = BackupService.open(bytes);
    expect(opened.preview.imageCount, 0);
    final dir = Directory('${tmp.path}/safe');
    final data = await opened.materialize(dir);
    expect(data.trades.single.imagePath, isNull);
    expect(data.trades.single.imagePathAfter, isNull);
    expect(evilTarget.existsSync(), false);
    expect(dir.listSync(), isEmpty);
  });
}
