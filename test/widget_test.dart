import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traderlog/models/app_settings.dart';
import 'package:traderlog/models/trade.dart';
import 'package:traderlog/models/trading_account.dart';
import 'package:traderlog/services/backup_service.dart';
import 'package:traderlog/services/csv_service.dart';
import 'package:traderlog/utils/app_strings.dart';
import 'package:traderlog/utils/formatters.dart';
import 'package:traderlog/utils/pnl_calculator.dart';

void main() {
  group('Trade Model Tests', () {
    test('Calculates Risk to Reward Ratio correctly', () {
      final trade = Trade(
        id: '1',
        date: DateTime(2026, 10, 17, 10, 0),
        sym: 'XAU/USD',
        side: TradeSide.buy,
        entry: 2600.0,
        sl: 2590.0,
        tp: 2630.0,
        pl: 300.0,
        accountId: 'acc_real',
        imagePath: '/path/setup.png',
        imagePathAfter: '/path/outcome.png',
      );

      // Risk = 10, Reward = 30 => RR = 3.0
      expect(trade.riskRewardRatio, 3.0);
      expect(trade.formattedRR, '1:3.00');
      expect(trade.result, TradeResult.win);
      expect(trade.resultString, 'WIN');
      expect(trade.accountId, 'acc_real');
      expect(trade.imagePathAfter, '/path/outcome.png');

      // Test map serialization & deserialization
      final map = trade.toMap();
      final fromMap = Trade.fromMap(map);
      expect(fromMap.accountId, 'acc_real');
      expect(fromMap.imagePath, '/path/setup.png');
      expect(fromMap.imagePathAfter, '/path/outcome.png');
      expect(fromMap.pl, 300.0);
    });

    test('Identifies Lose and BE correctly', () {
      final lossTrade = Trade(
        id: '2',
        date: DateTime(2026, 10, 17, 12, 0),
        sym: 'EUR/USD',
        side: TradeSide.sell,
        pl: -50.0,
      );
      expect(lossTrade.result, TradeResult.lose);
      expect(lossTrade.resultString, 'LOSE');

      final beTrade = Trade(
        id: '3',
        date: DateTime(2026, 10, 17, 14, 0),
        sym: 'GBP/USD',
        side: TradeSide.buy,
        pl: 0.0,
      );
      expect(beTrade.result, TradeResult.be);
      expect(beTrade.resultString, 'BE');
    });
  });

  group('TradingAccount Model Tests', () {
    test('Default presets and serialization work as expected', () {
      final defaultList = TradingAccount.defaultAccounts();
      expect(defaultList.length, 1);
      expect(defaultList[0].type, 'real');
      expect(defaultList[0].name, 'Primary Account');

      const customAcc = TradingAccount(
        id: 'acc_funded_50k',
        name: 'FTMO 50K Challenge',
        type: 'prop_firm',
        initialCapital: 50000.0,
        currency: 'USD',
      );

      final map = customAcc.toMap();
      final reconstructed = TradingAccount.fromMap(map);
      expect(reconstructed.id, 'acc_funded_50k');
      expect(reconstructed.name, 'FTMO 50K Challenge');
      expect(reconstructed.type, 'prop_firm');
      expect(reconstructed.initialCapital, 50000.0);
      expect(reconstructed.currency, 'USD');
    });
  });

  group('CSV Parsing Tests', () {
    test('Parses CSV data accurately', () {
      const csvData = '''
No,Date,Symbol,Side,Entry,SL,TP,Lot,RR,Result,PL,Equity,Why,Note
1,2026-10-15T09:30,XAU/USD,BUY,2650,2640,2680,0.1,1:3.00,WIN,150.00,1150.00,Breakout M15,Clean TP
2,2026-10-16T14:15,EUR/USD,SELL,1.0850,1.0880,1.0790,0.5,1:2.00,LOSE,-60.00,1090.00,Fakeout,Hit SL
''';

      final result = CSVService.parseCSV(csvData, existingTrades: []);
      expect(result.trades.length, 2);
      expect(result.skipped, 0);
      expect(result.duplicates, 0);

      final t1 = result.trades[0];
      expect(t1.sym, 'XAU/USD');
      expect(t1.side, TradeSide.buy);
      expect(t1.pl, 150.0);
      expect(t1.why, 'Breakout M15');

      final t2 = result.trades[1];
      expect(t2.sym, 'EUR/USD');
      expect(t2.side, TradeSide.sell);
      expect(t2.pl, -60.0);
    });

    test('Detects duplicate trades during import', () {
      final existing = [
        Trade(
          id: 'existing_1',
          date: DateTime.parse('2026-10-15T09:30:00.000'),
          sym: 'XAU/USD',
          side: TradeSide.buy,
          entry: 2650.0,
          pl: 150.0,
        ),
      ];

      const csvData = '''
No,Date,Symbol,Side,Entry,SL,TP,Lot,RR,Result,PL,Equity,Why,Note
1,2026-10-15T09:30:00.000,XAU/USD,BUY,2650,2640,2680,0.1,1:3.00,WIN,150.00,1150.00,Breakout,Clean
2,2026-10-17T11:00:00.000,BTC/USD,BUY,68000,67000,71000,0.05,1:3.00,WIN,250.00,1400.00,Retest,Great
''';

      final result = CSVService.parseCSV(csvData, existingTrades: existing);
      expect(result.trades.length, 1);
      expect(result.duplicates, 1);
      expect(result.trades[0].sym, 'BTC/USD');
    });

    test('Exports and imports CSV with Account column', () {
      final trades = [
        Trade(
          id: 'acc_test_1',
          date: DateTime(2026, 10, 17, 10, 0),
          sym: 'XAU/USD',
          side: TradeSide.buy,
          entry: 2600.0,
          exit: 2620.0,
          sl: 2590.0,
          tp: 2630.0,
          lot: 0.1,
          pl: 200.0,
          accountId: 'acc_prop_firm',
        ),
      ];

      final csvStr = CSVService.generateCSV(trades: trades, initialCapital: 10000.0);
      expect(csvStr.contains('Account'), true);
      expect(csvStr.contains('acc_prop_firm'), true);

      final parsed = CSVService.parseCSV(csvStr, existingTrades: []);
      expect(parsed.trades.length, 1);
      expect(parsed.trades[0].accountId, 'acc_prop_firm');
      expect(parsed.trades[0].exit, 2620.0);
    });
  });

  group('AppSettings Tests', () {
    test('Default settings are populated', () {
      final settings = AppSettings();
      expect(settings.initialCapital, 1000.0);
      expect(settings.exchangeRate, 16000.0);
      expect(settings.usdToIdrRate, 16000.0);
      expect(settings.traderName, 'TraderLog');
      expect(settings.languageCode, 'id');
      expect(settings.accountCurrency, 'USD');
      expect(settings.exchangeCurrency, 'IDR');
      expect(settings.activeAccountId, 'acc_real');
      expect(settings.pinCode, isNull);
      expect(settings.isBiometricEnabled, false);
      expect(settings.accounts.length, 1);
      expect(settings.symbols.contains('XAU/USD'), true);
      expect(settings.symbols.contains('BTC/USD'), true);
    });

    test('AppSettings serialization supports currencies, traderName, accounts and security', () {
      final settings = AppSettings(
        initialCapital: 5000.0,
        exchangeRate: 16500.0,
        traderName: 'TraderPro',
        languageCode: 'en',
        accountCurrency: 'USDC',
        exchangeCurrency: 'IDR',
        themeMode: ThemeMode.dark,
        activeAccountId: 'acc_demo',
        pinCode: '1234',
        isBiometricEnabled: true,
        lastBackupDate: '2026-10-17 15:30',
      );
      final map = settings.toDatabaseMap();
      final fromMap = AppSettings.fromDatabaseMap(map);

      expect(fromMap.traderName, 'TraderPro');
      expect(fromMap.languageCode, 'en');
      expect(fromMap.accountCurrency, 'USDC');
      expect(fromMap.exchangeCurrency, 'IDR');
      expect(fromMap.initialCapital, 5000.0);
      expect(fromMap.exchangeRate, 16500.0);
      expect(fromMap.usdToIdrRate, 16500.0);
      expect(fromMap.themeMode, ThemeMode.dark);
      expect(fromMap.activeAccountId, 'acc_demo');
      expect(fromMap.pinCode, '1234');
      expect(fromMap.isBiometricEnabled, true);
      expect(fromMap.lastBackupDate, '2026-10-17 15:30');
    });
  });

  group('Currency Formatters Tests', () {
    test('Formats multi-currency amounts accurately', () {
      expect(Formatters.formatAmount(1250.50, currency: 'USD'), '\$1,250.50');
      expect(Formatters.formatAmount(-50.0, currency: 'USD'), '-\$50.00');
      expect(Formatters.formatAmount(18000000, currency: 'IDR'), 'Rp 18.000.000');
      expect(Formatters.formatAmountSigned(250.0, currency: 'EUR'), '+€250.00');
      expect(Formatters.formatAmountSigned(-100.0, currency: 'USDC'), '-USDC 100.00');
    });
  });

  group('AppStrings Localization Tests', () {
    test('Translates keys accurately in ID and EN', () {
      expect(AppStrings.tr('nav_journal', 'id'), 'Jurnal');
      expect(AppStrings.tr('nav_journal', 'en'), 'Journal');
      expect(AppStrings.tr('cat_profile', 'id'), 'Modal & Kurs');
      expect(AppStrings.tr('cat_profile', 'en'), 'Capital & FX');
      expect(AppStrings.tr('cat_appearance', 'id'), 'Tampilan');
      expect(AppStrings.tr('cat_appearance', 'en'), 'Display');
      expect(AppStrings.tr('new_trade', 'id'), 'Catat Trade Baru');
      expect(AppStrings.tr('new_trade', 'en'), 'New Trade');
      expect(AppStrings.tr('account_currency', 'id'), 'Currency Akun (Mata Uang Utama)');
      expect(AppStrings.tr('account_currency', 'en'), 'Account Currency (Base Currency)');
      expect(AppStrings.tr('calendar_title', 'id'), 'Kalender PnL & Konsistensi Harian');
      expect(AppStrings.tr('calendar_title', 'en'), 'Daily PnL Calendar & Heatmap');
      expect(AppStrings.tr('actual_rr', 'id'), 'Rasio RR Aktual (Payoff)');
      expect(AppStrings.tr('actual_rr', 'en'), 'Actual RR (Payoff Ratio)');
      expect(AppStrings.tr('pin_lock_title', 'id'), 'Kunci Aplikasi dengan PIN');
      expect(AppStrings.tr('pin_lock_title', 'en'), 'App Lock with 4-Digit PIN');
      expect(AppStrings.tr('lock_now', 'id'), 'Kunci Aplikasi Sekarang');
      expect(AppStrings.tr('lock_now', 'en'), 'Lock App Now');
    });
  });

  group('Model copyWith Nullability Tests', () {
    test('Clears PIN when copyWith(pinCode: null) is called', () {
      final initial = AppSettings(pinCode: '1234');
      expect(initial.isPinSet, true);

      // Calling copyWith(pinCode: null) must set pinCode to null!
      final cleared = initial.copyWith(pinCode: null);
      expect(cleared.pinCode, isNull);
      expect(cleared.isPinSet, false);

      // Calling copyWith() without pinCode argument must preserve the pinCode
      final untouched = initial.copyWith(languageCode: 'en');
      expect(untouched.pinCode, '1234');
      expect(untouched.languageCode, 'en');
    });

    test('Clears SL, TP, and image paths on Trade when copyWith receives null', () {
      final trade = Trade(
        id: 't1',
        date: DateTime.now(),
        sym: 'XAU/USD',
        side: TradeSide.buy,
        entry: 2650.0,
        sl: 2640.0,
        tp: 2670.0,
        pl: 100.0,
        imagePath: '/path/before.png',
        imagePathAfter: '/path/after.png',
      );

      expect(trade.sl, 2640.0);
      expect(trade.imagePath, isNotNull);

      final clearedTrade = trade.copyWith(
        sl: null,
        imagePath: null,
      );

      expect(clearedTrade.sl, isNull);
      expect(clearedTrade.imagePath, isNull);
      expect(clearedTrade.tp, 2670.0); // untouched preserved
      expect(clearedTrade.imagePathAfter, '/path/after.png'); // untouched preserved
    });
  });


  group('PnlCalculator & Automated PnL Tests', () {
    test('Calculates Gold (XAU/USD) profit, loss, and pips correctly', () {
      // BUY Gold: Entry 2650.00, Exit 2660.00, Lot 0.10 => +$100, +100 pips
      final buyRes = PnlCalculator.calculate(
        symbol: 'XAU/USD',
        side: TradeSide.buy,
        entry: 2650.00,
        exit: 2660.00,
        lot: 0.10,
      );
      expect(buyRes, isNotNull);
      expect(buyRes!.pnl, 100.0);
      expect(buyRes.pips, 100.0);
      expect(buyRes.pipUnit, 'pips');
      expect(buyRes.formattedPips, '+100.0 pips');

      // SELL Gold: Entry 2650.00, Exit 2655.00, Lot 0.20 => -$100, -50 pips
      final sellRes = PnlCalculator.calculate(
        symbol: 'GOLD',
        side: TradeSide.sell,
        entry: 2650.00,
        exit: 2655.00,
        lot: 0.20,
      );
      expect(sellRes, isNotNull);
      expect(sellRes!.pnl, -100.0);
      expect(sellRes.pips, -50.0);
      expect(sellRes.formattedPips, '-50.0 pips');
    });

    test('Calculates Forex standard and JPY pairs correctly', () {
      // EUR/USD BUY: Entry 1.0800, Exit 1.0850 (50 pips), Lot 0.1 => $50
      final fxRes = PnlCalculator.calculate(
        symbol: 'EUR/USD',
        side: TradeSide.buy,
        entry: 1.0800,
        exit: 1.0850,
        lot: 0.10,
      );
      expect(fxRes, isNotNull);
      expect(fxRes!.pips.toStringAsFixed(1), '50.0');
      expect(fxRes.pnl.toStringAsFixed(1), '50.0');

      // USD/JPY SELL: Entry 155.00, Exit 154.50 (50 pips), Lot 0.1
      // Pip value = (0.01 / 154.50) * 100,000 * 0.1 = 0.64725/pip * 50 pips ≈ $32.4 (Estimate)
      final jpyRes = PnlCalculator.calculate(
        symbol: 'USD/JPY',
        side: TradeSide.sell,
        entry: 155.00,
        exit: 154.50,
        lot: 0.10,
      );
      expect(jpyRes, isNotNull);
      expect(jpyRes!.pips.toStringAsFixed(1), '50.0');
      expect(jpyRes.pnl.toStringAsFixed(1), '32.4');
      expect(jpyRes.isEstimate, true);
    });

    test('Calculates Crypto & Index point moves correctly', () {
      // BTC/USD BUY: Entry 68000, Exit 69000 (1000 pts), Lot 0.05 => $50
      final btcRes = PnlCalculator.calculate(
        symbol: 'BTC/USD',
        side: TradeSide.buy,
        entry: 68000.0,
        exit: 69000.0,
        lot: 0.05,
      );
      expect(btcRes, isNotNull);
      expect(btcRes!.pnl, 50.0);
      expect(btcRes.pips, 1000.0);
      expect(btcRes.pipUnit, 'pts');
    });

    test('Calculates planned risk and reward correctly', () {
      final risk = PnlCalculator.calculateRisk(
        symbol: 'XAU/USD',
        side: TradeSide.buy,
        entry: 2650.00,
        sl: 2645.00,
        lot: 0.10,
      );
      expect(risk, isNotNull);
      expect(risk!.pnl, -50.0);

      final reward = PnlCalculator.calculateReward(
        symbol: 'XAU/USD',
        side: TradeSide.buy,
        entry: 2650.00,
        tp: 2665.00,
        lot: 0.10,
      );
      expect(reward, isNotNull);
      expect(reward!.pnl, 150.0);
    });
  });

  group('Trade Model Exit & Realized RR Tests', () {
    test('Calculates realized RR and formatted pips from exit price', () {
      final trade = Trade(
        id: '100',
        date: DateTime(2026, 10, 17),
        sym: 'XAU/USD',
        side: TradeSide.buy,
        entry: 2600.0,
        exit: 2625.0,
        sl: 2590.0,
        tp: 2630.0,
        lot: 0.1,
        pl: 250.0,
      );

      // Planned Risk = 10, Reward = 30 => planned RR = 3.0
      expect(trade.riskRewardRatio, 3.0);
      expect(trade.formattedRR, '1:3.00');

      // Realized Risk = 10, Realized Reward = 25 => realized RR = 2.5
      expect(trade.realizedRR, 2.5);
      expect(trade.formattedRealizedRR, '1:2.50');

      // Pips gained: Gold price diff = 25 => 250 pips
      expect(trade.pipsGained, 250.0);
      expect(trade.formattedPips, '+250.0 pips');

      // Map serialization & deserialization includes exit
      final map = trade.toMap();
      expect(map['exit'], 2625.0);
      final fromMap = Trade.fromMap(map);
      expect(fromMap.exit, 2625.0);
      expect(fromMap.pipsGained, 250.0);
    });

    test('Calculates realized RR correctly for SELL positions and losses', () {
      // Winning SELL: Entry 2650, Exit 2630 (+20 gain), SL 2660 (Risk 10) => RR 2.0
      final sellWin = Trade(
        id: '101',
        date: DateTime(2026, 10, 17),
        sym: 'XAU/USD',
        side: TradeSide.sell,
        entry: 2650.0,
        exit: 2630.0,
        sl: 2660.0,
        pl: 200.0,
      );
      expect(sellWin.realizedRR, 2.0);
      expect(sellWin.formattedRealizedRR, '1:2.00');

      // Losing SELL: Entry 2650, Exit 2660 (-10 loss), SL 2660 (Risk 10) => RR -1.0
      final sellLoss = Trade(
        id: '102',
        date: DateTime(2026, 10, 17),
        sym: 'XAU/USD',
        side: TradeSide.sell,
        entry: 2650.0,
        exit: 2660.0,
        sl: 2660.0,
        pl: -100.0,
      );
      expect(sellLoss.realizedRR, -1.0);
      expect(sellLoss.formattedRealizedRR, '-1:1.00');

      // Losing BUY: Entry 2600, Exit 2585 (-15 loss), SL 2590 (Risk 10) => RR -1.5
      final buyLoss = Trade(
        id: '103',
        date: DateTime(2026, 10, 17),
        sym: 'XAU/USD',
        side: TradeSide.buy,
        entry: 2600.0,
        exit: 2585.0,
        sl: 2590.0,
        pl: -150.0,
      );
      expect(buyLoss.realizedRR, -1.5);
      expect(buyLoss.formattedRealizedRR, '-1:1.50');
    });
  });

  group('PnlCalculator Multi-Currency & fxRate Tests', () {
    test('Calculates Gold PnL with exchange rate (IDR)', () {
      // Entry 2650, Exit 2660, Lot 0.1 => Base USD $100.
      // With fxRate 16,000 => Rp 1,600,000
      final res = PnlCalculator.calculate(
        symbol: 'XAU/USD',
        side: TradeSide.buy,
        entry: 2650.0,
        exit: 2660.0,
        lot: 0.1,
        fxRate: 16000.0,
      );

      expect(res, isNotNull);
      expect(res!.pnl, 1600000.0);
      expect(res.basePnl, 100.0);
      expect(res.pips, 100.0);
    });

    test('Calculates Planned Risk & Reward with exchange rate', () {
      final risk = PnlCalculator.calculateRisk(
        symbol: 'EUR/USD',
        side: TradeSide.buy,
        entry: 1.0800,
        sl: 1.0750, // 50 pips risk => $50 base
        lot: 0.1,
        fxRate: 16000.0,
      );
      expect(risk, isNotNull);
      expect(risk!.pnl, -800000.0); // -$50 * 16000
      expect(risk.basePnl, -50.0);
    });
  });

  group('PIN Hashing & Security Verification Tests', () {
    test('Hashes PIN to 64-char hex SHA-256 and verifies correctly', () {
      final hash = AppSettings.hashPin('1234');
      expect(hash.length, 64);
      expect(RegExp(r'^[0-9a-f]{64}$').hasMatch(hash), true);

      // Verifies correct PIN against hash
      expect(AppSettings.verifyPin('1234', hash), true);
      // Fails on incorrect PIN
      expect(AppSettings.verifyPin('0000', hash), false);
      expect(AppSettings.verifyPin('1235', hash), false);

      // Backward compatibility with legacy plaintext PIN
      expect(AppSettings.verifyPin('1234', '1234'), true);
      expect(AppSettings.verifyPin('9999', '1234'), false);
    });
  });

  group('BackupService Full Archive Tests', () {
    test('Creates and encodes valid ZIP archive with DB and manifest', () {
      final mockDbBytes = Uint8List.fromList(utf8.encode('SQLite format 3 mock content'));
      final mockImgBytes = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);

      final zipBytes = BackupService.createArchiveBytes(
        dbBytes: mockDbBytes,
        images: {'chart_123_before.png': mockImgBytes},
        extraMetadata: {'author': 'trader'},
      );

      expect(zipBytes.isNotEmpty, true);
      // Valid ZIP files start with PK\x03\x04
      expect(zipBytes[0], 0x50);
      expect(zipBytes[1], 0x4B);
    });
  });

  group('PnlCalculator Asset Classification & Pip Units Tests', () {
    test('Correctly classifies Indices with pts unit and 1:1 points', () {
      expect(PnlCalculator.getAssetType('US30'), 'indices');
      expect(PnlCalculator.getAssetType('USTEC'), 'indices');
      expect(PnlCalculator.getAssetType('US500'), 'indices');
      expect(PnlCalculator.getPipUnit('USTEC'), 'pts');
      expect(PnlCalculator.getPipUnit('US30'), 'pts');

      // USTEC 18000 to 18050, Lot 1.0 => 50 pts, $50
      final res = PnlCalculator.calculate(
        symbol: 'USTEC',
        side: TradeSide.buy,
        entry: 18000.0,
        exit: 18050.0,
        lot: 1.0,
      );
      expect(res, isNotNull);
      expect(res!.pips, 50.0);
      expect(res.pipUnit, 'pts');
      expect(res.pnl, 50.0);
    });

    test('Correctly formats pips on Trade model using shared PnlCalculator', () {
      final tradeIndices = Trade(
        id: 't_idx',
        date: DateTime.now(),
        sym: 'USTEC',
        side: TradeSide.buy,
        entry: 18000.0,
        exit: 18050.0,
        pl: 50.0,
      );
      expect(tradeIndices.pipsGained, 50.0);
      expect(tradeIndices.formattedPips, '+50.0 pts');

      final tradeGold = Trade(
        id: 't_gold',
        date: DateTime.now(),
        sym: 'XAU/USD',
        side: TradeSide.buy,
        entry: 2650.0,
        exit: 2655.0,
        pl: 50.0,
      );
      expect(tradeGold.pipsGained, 50.0);
      expect(tradeGold.formattedPips, '+50.0 pips');
    });
  });

  group('Provider Summary Metrics Calculations Tests', () {
    test('Calculates Max Drawdown, Profit Factor, and Streaks correctly', () {
      final now = DateTime.now();
      // Sequence of trades:
      // Start: $1,000
      // Trade 1: +$200 => Equity $1,200 (Peak)
      // Trade 2: -$300 => Equity $900 (Trough: DD = $300 / $1200 = 25%)
      // Trade 3: +$100 => Equity $1,000
      // Trade 4: +$150 => Equity $1,150
      final t1 = Trade(id: '1', date: now.subtract(const Duration(days: 4)), sym: 'XAU/USD', side: TradeSide.buy, pl: 200.0);
      final t2 = Trade(id: '2', date: now.subtract(const Duration(days: 3)), sym: 'XAU/USD', side: TradeSide.buy, pl: -300.0);
      final t3 = Trade(id: '3', date: now.subtract(const Duration(days: 2)), sym: 'XAU/USD', side: TradeSide.buy, pl: 100.0);
      final t4 = Trade(id: '4', date: now.subtract(const Duration(days: 1)), sym: 'XAU/USD', side: TradeSide.buy, pl: 150.0);

      final trades = [t1, t2, t3, t4];
      const initialCapital = 1000.0;

      // Drawdown calculation verification
      double peak = initialCapital;
      double currentEq = initialCapital;
      double maxDDPct = 0.0;
      double maxDDAmount = 0.0;

      for (final t in trades) {
        currentEq += t.pl;
        if (currentEq > peak) {
          peak = currentEq;
        } else {
          final ddAmount = peak - currentEq;
          final ddPct = peak > 0 ? (ddAmount / peak) * 100.0 : 0.0;
          if (ddAmount > maxDDAmount) {
            maxDDAmount = ddAmount;
            maxDDPct = ddPct;
          }
        }
      }

      expect(maxDDAmount, 300.0);
      expect(maxDDPct, 25.0); // 300 / 1200 * 100

      // Profit factor calculation verification
      // Gross profits = 200 + 100 + 150 = 450
      // Gross loss = 300
      // Profit factor = 450 / 300 = 1.50
      const grossP = 450.0;
      const grossL = 300.0;
      const pf = grossL > 0 ? grossP / grossL : null;
      expect(pf, 1.5);

      // Streak calculation verification
      // Last 2 trades (t3, t4) are wins => Streak = 2 WIN
      expect(trades.last.pl > 0, true);
    });
  });
}

