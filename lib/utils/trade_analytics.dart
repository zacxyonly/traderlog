import '../models/trade.dart';
import '../models/trading_account.dart';
import 'pnl_calculator.dart';

/// Emosi yang dianggap negatif. Disamakan dengan daftar di layar Ringkasan.
const Set<String> kNegativeEmotionTags = {
  'FOMO',
  'Revenge Trade',
  'Overlot',
  'Greedy',
  'Hesitant',
};

class StreakStats {
  final int maxWinStreak;
  final int maxLossStreak;

  const StreakStats({required this.maxWinStreak, required this.maxLossStreak});
}

class WeekdayStat {
  /// DateTime.monday (1) sampai DateTime.sunday (7).
  final int weekday;
  final int count;
  final int winCount;
  final double totalPL;

  const WeekdayStat({
    required this.weekday,
    required this.count,
    required this.winCount,
    required this.totalPL,
  });

  double get winRate => count > 0 ? winCount / count : 0.0;
}

class EmotionGroupStat {
  final int count;
  final int winCount;
  final double totalPL;

  const EmotionGroupStat({
    required this.count,
    required this.winCount,
    required this.totalPL,
  });

  double get winRate => count > 0 ? winCount / count : 0.0;
}

class EmotionImpact {
  final EmotionGroupStat negative;
  final EmotionGroupStat others;

  const EmotionImpact({required this.negative, required this.others});
}

class TradeRisk {
  final Trade trade;

  /// Uang yang dipertaruhkan (jarak entry ke SL) dalam mata uang akun.
  /// null bila tidak bisa dihitung (SL tidak ada, atau pasangan non-USD).
  final double? riskAmount;

  /// riskAmount dibagi saldo sebelum trade, sebagai rasio (0.01 = 1%).
  final double? riskRatio;

  /// PnL dibagi riskAmount (R berdasarkan uang).
  final double? rMultiple;

  const TradeRisk({
    required this.trade,
    this.riskAmount,
    this.riskRatio,
    this.rMultiple,
  });
}

class PropFirmStatus {
  final double initialCapital;
  final double equity;
  final double startOfDayBalance;
  final double todayPL;
  final double? dailyLimitPercent;
  final double? maxDrawdownPercent;

  const PropFirmStatus({
    required this.initialCapital,
    required this.equity,
    required this.startOfDayBalance,
    required this.todayPL,
    this.dailyLimitPercent,
    this.maxDrawdownPercent,
  });

  /// Kerugian hari ini sebagai rasio terhadap saldo awal hari (0 jika tidak rugi).
  double get dailyLossRatio {
    if (todayPL >= 0 || startOfDayBalance <= 0) return 0.0;
    return -todayPL / startOfDayBalance;
  }

  /// Drawdown dari modal awal sebagai rasio (0 jika equity di atas modal awal).
  double get totalDrawdownRatio {
    if (initialCapital <= 0 || equity >= initialCapital) return 0.0;
    return (initialCapital - equity) / initialCapital;
  }

  double? get dailyLimitRatio =>
      dailyLimitPercent == null ? null : dailyLimitPercent! / 100;

  double? get maxDrawdownRatio =>
      maxDrawdownPercent == null ? null : maxDrawdownPercent! / 100;
}

class TradeAnalytics {
  TradeAnalytics._();

  static List<Trade> _chronological(List<Trade> trades) {
    final sorted = List<Trade>.from(trades);
    sorted.sort((a, b) => a.date.compareTo(b.date));
    return sorted;
  }

  static List<String> _tagsOf(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const [];
    return raw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  /// Rentetan menang dan kalah terpanjang. BE memutus rentetan.
  static StreakStats streaks(List<Trade> trades) {
    int bestWin = 0;
    int bestLoss = 0;
    int curWin = 0;
    int curLoss = 0;

    for (final t in _chronological(trades)) {
      switch (t.result) {
        case TradeResult.win:
          curWin++;
          curLoss = 0;
          if (curWin > bestWin) bestWin = curWin;
          break;
        case TradeResult.lose:
          curLoss++;
          curWin = 0;
          if (curLoss > bestLoss) bestLoss = curLoss;
          break;
        case TradeResult.be:
          curWin = 0;
          curLoss = 0;
          break;
      }
    }
    return StreakStats(maxWinStreak: bestWin, maxLossStreak: bestLoss);
  }

  /// Rata-rata R realisasi (ekspektansi dalam R). Trade tanpa entry/SL/exit
  /// dilewati. Mengembalikan null jika tidak ada trade yang bisa dihitung.
  static double? averageR(List<Trade> trades) {
    final values = <double>[];
    for (final t in trades) {
      final r = t.realizedRR;
      if (r != null) values.add(r);
    }
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a + b) / values.length;
  }

  /// Performa per hari dalam seminggu, hanya hari yang punya trade.
  static List<WeekdayStat> weekdayStats(List<Trade> trades) {
    final buckets = <int, List<Trade>>{};
    for (final t in trades) {
      buckets.putIfAbsent(t.date.weekday, () => []).add(t);
    }

    final result = <WeekdayStat>[];
    for (int d = DateTime.monday; d <= DateTime.sunday; d++) {
      final list = buckets[d];
      if (list == null || list.isEmpty) continue;
      result.add(WeekdayStat(
        weekday: d,
        count: list.length,
        winCount: list.where((t) => t.result == TradeResult.win).length,
        totalPL: list.fold<double>(0.0, (s, t) => s + t.pl),
      ));
    }
    return result;
  }

  /// Membandingkan trade yang memakai emosi negatif dengan trade lainnya.
  /// Mengembalikan null jika daftar trade kosong.
  static EmotionImpact? emotionImpact(List<Trade> trades) {
    if (trades.isEmpty) return null;

    final negative = <Trade>[];
    final others = <Trade>[];
    for (final t in trades) {
      final isNegative =
          _tagsOf(t.note).any((tag) => kNegativeEmotionTags.contains(tag));
      (isNegative ? negative : others).add(t);
    }

    EmotionGroupStat group(List<Trade> list) => EmotionGroupStat(
          count: list.length,
          winCount: list.where((t) => t.result == TradeResult.win).length,
          totalPL: list.fold<double>(0.0, (s, t) => s + t.pl),
        );

    return EmotionImpact(negative: group(negative), others: group(others));
  }

  /// Risiko per trade, dihitung berurutan dari modal awal akun sehingga
  /// setiap trade memakai saldo yang benar saat dibuka.
  static List<TradeRisk> riskProfile(
    List<Trade> accountTrades,
    TradingAccount account,
  ) {
    double balance = account.initialCapital;
    final out = <TradeRisk>[];

    for (final t in _chronological(accountTrades)) {
      final r = PnlCalculator.calculateRisk(
        symbol: t.sym,
        side: t.side,
        entry: t.entry,
        sl: t.sl,
        lot: t.lot,
        accountCurrency: account.currency,
      );

      double? riskAmount = r?.pnl?.abs();
      if (riskAmount != null && riskAmount <= 0) riskAmount = null;

      final double? riskRatio =
          (riskAmount != null && balance > 0) ? riskAmount / balance : null;
      final double? rMultiple =
          riskAmount != null ? t.pl / riskAmount : null;

      out.add(TradeRisk(
        trade: t,
        riskAmount: riskAmount,
        riskRatio: riskRatio,
        rMultiple: rMultiple,
      ));
      balance += t.pl;
    }
    return out;
  }

  /// Risiko untuk satu trade tertentu di dalam daftar.
  static TradeRisk? riskFor(
    List<Trade> accountTrades,
    TradingAccount account,
    String tradeId,
  ) {
    for (final r in riskProfile(accountTrades, account)) {
      if (r.trade.id == tradeId) return r;
    }
    return null;
  }

  /// Status aturan prop firm berdasarkan trade yang sudah tertutup.
  static PropFirmStatus propFirmStatus(
    List<Trade> accountTrades,
    TradingAccount account,
    DateTime now,
  ) {
    final midnight = DateTime(now.year, now.month, now.day);
    double startOfDay = account.initialCapital;
    double todayPL = 0.0;
    double equity = account.initialCapital;

    for (final t in accountTrades) {
      equity += t.pl;
      if (t.date.isBefore(midnight)) {
        startOfDay += t.pl;
      } else {
        todayPL += t.pl;
      }
    }

    return PropFirmStatus(
      initialCapital: account.initialCapital,
      equity: equity,
      startOfDayBalance: startOfDay,
      todayPL: todayPL,
      dailyLimitPercent: account.dailyLossLimitPercent,
      maxDrawdownPercent: account.maxDrawdownPercent,
    );
  }
}
