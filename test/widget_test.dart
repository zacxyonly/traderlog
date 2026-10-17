import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traderlog/models/trade.dart';
import 'package:traderlog/models/app_settings.dart';
import 'package:traderlog/services/csv_service.dart';
import 'package:traderlog/services/currency_service.dart';
import 'package:traderlog/utils/app_strings.dart';
import 'package:traderlog/utils/formatters.dart';

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
      );

      // Risk = 10, Reward = 30 => RR = 3.0
      expect(trade.riskRewardRatio, 3.0);
      expect(trade.formattedRR, '1:3.00');
      expect(trade.result, TradeResult.win);
      expect(trade.resultString, 'WIN');
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
  });

  group('AppSettings Tests', () {
    test('Default settings are populated', () {
      final settings = AppSettings();
      expect(settings.initialCapital, 1000.0);
      expect(settings.usdToIdrRate, 17998.0);
      expect(settings.traderName, 'Zacxy');
      expect(settings.languageCode, 'id');
      expect(settings.accountCurrency, 'USD');
      expect(settings.exchangeCurrency, 'IDR');
      expect(settings.symbols.contains('XAU/USD'), true);
      expect(settings.symbols.contains('BTC/USD'), true);
    });

    test('AppSettings serialization supports currencies, traderName and languageCode', () {
      final settings = AppSettings(
        initialCapital: 5000.0,
        usdToIdrRate: 16500.0,
        traderName: 'TraderPro',
        languageCode: 'en',
        accountCurrency: 'USDC',
        exchangeCurrency: 'IDR',
        themeMode: ThemeMode.dark,
      );
      final map = settings.toDatabaseMap();
      final fromMap = AppSettings.fromDatabaseMap(map);

      expect(fromMap.traderName, 'TraderPro');
      expect(fromMap.languageCode, 'en');
      expect(fromMap.accountCurrency, 'USDC');
      expect(fromMap.exchangeCurrency, 'IDR');
      expect(fromMap.initialCapital, 5000.0);
      expect(fromMap.usdToIdrRate, 16500.0);
      expect(fromMap.themeMode, ThemeMode.dark);
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
      expect(AppStrings.tr('cat_profile', 'id'), 'Profil');
      expect(AppStrings.tr('cat_profile', 'en'), 'Profile');
      expect(AppStrings.tr('cat_appearance', 'id'), 'Tampilan');
      expect(AppStrings.tr('cat_appearance', 'en'), 'Display');
      expect(AppStrings.tr('new_trade', 'id'), 'Trade Baru');
      expect(AppStrings.tr('new_trade', 'en'), 'New Trade');
      expect(AppStrings.tr('account_currency', 'id'), 'Currency Akun (Mata Uang Utama)');
      expect(AppStrings.tr('account_currency', 'en'), 'Account Currency (Base Currency)');
    });
  });

  group('CurrencyService & Exchange Rate Tests', () {
    test('Returns 1.0 immediately when base and target currency match', () async {
      final rateUsd = await CurrencyService.fetchExchangeRate(
        baseCurrency: 'USD',
        targetCurrency: 'USD',
      );
      expect(rateUsd, 1.0);

      final rateUsdcUsd = await CurrencyService.fetchExchangeRate(
        baseCurrency: 'USDC',
        targetCurrency: 'USD',
      );
      expect(rateUsdcUsd, 1.0);

      final rateIdr = await CurrencyService.fetchExchangeRate(
        baseCurrency: 'IDR',
        targetCurrency: 'IDR',
      );
      expect(rateIdr, 1.0);
    });

    test('Translates sync rate strings with parameters', () {
      final syncedId = AppStrings.tr('rate_synced', 'id', params: {
        'base': 'USD',
        'target': 'IDR',
        'rate': '16250',
      });
      expect(syncedId, 'Kurs berhasil diperbarui: 1 USD = 16250 IDR');

      final syncedEn = AppStrings.tr('rate_synced', 'en', params: {
        'base': 'USD',
        'target': 'IDR',
        'rate': '16250',
      });
      expect(syncedEn, 'Rate updated: 1 USD = 16250 IDR');
    });
  });
}

