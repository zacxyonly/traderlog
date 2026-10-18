import 'package:flutter_test/flutter_test.dart';
import 'package:traderlog/models/trade.dart';
import 'package:traderlog/models/trading_account.dart';
import 'package:traderlog/utils/trade_analytics.dart';

Trade _trade(
  String id,
  DateTime date,
  double pl, {
  String sym = 'EUR/USD',
  TradeSide side = TradeSide.buy,
  double? entry,
  double? sl,
  double? exit,
  double? lot,
  String? note,
}) {
  return Trade(
    id: id,
    date: date,
    sym: sym,
    side: side,
    entry: entry,
    sl: sl,
    exit: exit,
    lot: lot,
    pl: pl,
    note: note,
  );
}

void main() {
  group('Streaks', () {
    test('finds longest win and loss streaks, BE breaks the run', () {
      final base = DateTime(2026, 10, 1);
      final pls = [1.0, 1.0, -1.0, -1.0, -1.0, 0.0, 1.0];
      final trades = [
        for (var i = 0; i < pls.length; i++)
          _trade('$i', base.add(Duration(days: i)), pls[i]),
      ];

      final s = TradeAnalytics.streaks(trades);
      expect(s.maxWinStreak, 2);
      expect(s.maxLossStreak, 3);
    });
  });

  group('Average R', () {
    test('averages realized R and skips trades without SL', () {
      final trades = [
        // Buy: risk 0.005, reward 0.010 => +2R
        _trade('a', DateTime(2026, 10, 1), 100,
            entry: 1.1, sl: 1.095, exit: 1.11),
        // Buy: risk 0.005, reward -0.005 => -1R
        _trade('b', DateTime(2026, 10, 2), -50,
            entry: 1.1, sl: 1.095, exit: 1.095),
        // No SL => excluded
        _trade('c', DateTime(2026, 10, 3), 20, entry: 1.1, exit: 1.2),
      ];

      expect(TradeAnalytics.averageR(trades), closeTo(0.5, 1e-9));
    });

    test('returns null when nothing can be computed', () {
      expect(TradeAnalytics.averageR([_trade('x', DateTime(2026, 10, 1), 5)]),
          isNull);
    });
  });

  group('Emotion impact', () {
    test('separates trades with negative emotions from the rest', () {
      final trades = [
        _trade('1', DateTime(2026, 10, 1), -40, note: 'FOMO'),
        _trade('2', DateTime(2026, 10, 2), 60, note: 'Disiplin'),
        _trade('3', DateTime(2026, 10, 3), 30),
      ];

      final impact = TradeAnalytics.emotionImpact(trades)!;
      expect(impact.negative.count, 1);
      expect(impact.negative.totalPL, -40);
      expect(impact.others.count, 2);
      expect(impact.others.totalPL, 90);
      expect(impact.others.winRate, closeTo(1.0, 1e-9));
    });
  });

  group('Risk per trade', () {
    test('risk ratio uses balance at the time of the trade', () {
      final account = TradingAccount(
        id: 'acc_real',
        name: 'Real',
        initialCapital: 10000,
        currency: 'USD',
      );
      // EUR/USD buy 1.0850, SL 1.0800, 1 lot => risk $500 = 5% of $10,000
      final trades = [
        _trade('r1', DateTime(2026, 10, 1), -500,
            entry: 1.085, sl: 1.08, exit: 1.08, lot: 1),
      ];

      final risk = TradeAnalytics.riskFor(trades, account, 'r1')!;
      expect(risk.riskAmount, closeTo(500, 1e-6));
      expect(risk.riskRatio, closeTo(0.05, 1e-9));
      expect(risk.rMultiple, closeTo(-1.0, 1e-9));
    });
  });

  group('Prop firm status', () {
    test('daily loss and drawdown are measured from the right base', () {
      final account = TradingAccount(
        id: 'acc_prop',
        name: 'Prop',
        type: 'prop_firm',
        initialCapital: 10000,
        currency: 'USD',
        dailyLossLimitPercent: 5,
        maxDrawdownPercent: 10,
      );
      final trades = [
        _trade('y', DateTime(2026, 10, 17, 10), 200),
        _trade('t1', DateTime(2026, 10, 18, 9), -150),
        _trade('t2', DateTime(2026, 10, 18, 11), -100),
      ];

      final status = TradeAnalytics.propFirmStatus(
        trades,
        account,
        DateTime(2026, 10, 18, 12),
      );

      expect(status.startOfDayBalance, closeTo(10200, 1e-9));
      expect(status.dailyLossRatio, closeTo(250 / 10200, 1e-9));
      expect(status.equity, closeTo(9950, 1e-9));
      expect(status.totalDrawdownRatio, closeTo(0.005, 1e-9));
      expect(status.dailyLimitRatio, closeTo(0.05, 1e-9));
      expect(status.maxDrawdownRatio, closeTo(0.10, 1e-9));
    });
  });

  group('TradingAccount risk rules', () {
    test('round-trips through map and keeps rules on copyWith', () {
      final acc = const TradingAccount(
        id: 'p',
        name: 'P',
        type: 'prop_firm',
      ).withRiskRules(
        maxRiskPercent: 1,
        dailyLossLimitPercent: 5,
        maxDrawdownPercent: 10,
      );

      final restored = TradingAccount.fromMap(acc.toMap());
      expect(restored.maxRiskPercent, 1);
      expect(restored.dailyLossLimitPercent, 5);
      expect(restored.maxDrawdownPercent, 10);

      final renamed = restored.copyWith(name: 'Baru');
      expect(renamed.maxRiskPercent, 1);
      expect(renamed.maxDrawdownPercent, 10);
    });

    test('old accounts without rule keys load with rules unset', () {
      final restored = TradingAccount.fromMap({
        'id': 'acc_real',
        'name': 'Lama',
        'type': 'real',
        'initialCapital': 1000,
        'currency': 'USD',
      });
      expect(restored.maxRiskPercent, isNull);
      expect(restored.dailyLossLimitPercent, isNull);
    });
  });
}
