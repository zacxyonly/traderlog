import 'dart:math';
import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/app_settings.dart';
import '../models/trade.dart';

class SymbolStat {
  final String symbol;
  final int count;
  final int winCount;
  final double totalPL;

  SymbolStat({
    required this.symbol,
    required this.count,
    required this.winCount,
    required this.totalPL,
  });

  double get winRate => count > 0 ? winCount / count : 0.0;
}

class PeriodSummary {
  final int totalTrades;
  final int winCount;
  final int loseCount;
  final int beCount;
  final double winRate;
  final double grossProfit;
  final double grossLoss;
  final double netProfit;
  final double? profitFactor;
  final double avgWin;
  final double avgLoss;
  final double expectancy;
  final double bestTrade;
  final double worstTrade;
  final double maxDrawdown;
  final double avgRR;
  final int streakCount;
  final String streakType; // 'WIN', 'LOSE', or '-'
  final List<double> equityPoints;
  final List<SymbolStat> symbolStats;

  PeriodSummary({
    required this.totalTrades,
    required this.winCount,
    required this.loseCount,
    required this.beCount,
    required this.winRate,
    required this.grossProfit,
    required this.grossLoss,
    required this.netProfit,
    required this.profitFactor,
    required this.avgWin,
    required this.avgLoss,
    required this.expectancy,
    required this.bestTrade,
    required this.worstTrade,
    required this.maxDrawdown,
    required this.avgRR,
    required this.streakCount,
    required this.streakType,
    required this.equityPoints,
    required this.symbolStats,
  });
}

class TradeProvider extends ChangeNotifier {
  final DBHelper _db = DBHelper.instance;

  List<Trade> _trades = [];
  AppSettings _settings = AppSettings();
  bool _isLoading = true;

  List<Trade> get trades => _trades;
  AppSettings get settings => _settings;
  bool get isLoading => _isLoading;

  TradeProvider() {
    loadData();
  }

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _settings = await _db.getSettings();
      _trades = await _db.getAllTrades();
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Trade Operations ---
  Future<void> addTrade(Trade trade) async {
    await _db.insertTrade(trade);
    _trades.add(trade);
    _trades.sort((a, b) => a.date.compareTo(b.date));

    // If symbol is new, add to settings symbols
    if (!_settings.symbols.contains(trade.sym)) {
      final updatedSyms = List<String>.from(_settings.symbols)..add(trade.sym);
      await updateSettings(_settings.copyWith(symbols: updatedSyms));
    } else {
      notifyListeners();
    }
  }

  Future<void> updateTrade(Trade trade) async {
    await _db.updateTrade(trade);
    final idx = _trades.indexWhere((t) => t.id == trade.id);
    if (idx != -1) {
      _trades[idx] = trade;
      _trades.sort((a, b) => a.date.compareTo(b.date));
      notifyListeners();
    }
  }

  Future<void> deleteTrade(String id) async {
    await _db.deleteTrade(id);
    _trades.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  Future<void> deleteAllTrades() async {
    await _db.deleteAllTrades();
    _trades.clear();
    notifyListeners();
  }

  Future<void> importTrades(List<Trade> imported, {bool replace = false}) async {
    await _db.insertTradesBatch(imported, replace: replace);

    if (replace) {
      _trades = List.from(imported);
    } else {
      _trades.addAll(imported);
    }
    _trades.sort((a, b) => a.date.compareTo(b.date));

    // Add any new symbols to settings
    final newSymbols = Set<String>.from(_settings.symbols);
    for (final t in imported) {
      if (t.sym.isNotEmpty) newSymbols.add(t.sym);
    }
    if (newSymbols.length != _settings.symbols.length) {
      await updateSettings(_settings.copyWith(symbols: newSymbols.toList()));
    } else {
      notifyListeners();
    }
  }

  // --- Settings Operations ---
  Future<void> updateSettings(AppSettings newSettings) async {
    _settings = newSettings;
    await _db.saveSettings(newSettings);
    notifyListeners();
  }

  Future<void> updateLanguage(String langCode) async {
    await updateSettings(_settings.copyWith(languageCode: langCode));
  }

  Future<void> updateTraderName(String name) async {
    await updateSettings(_settings.copyWith(traderName: name));
  }

  Future<void> updateAccountCurrency(String currency) async {
    await updateSettings(_settings.copyWith(accountCurrency: currency));
  }

  Future<void> updateExchangeCurrency(String currency) async {
    await updateSettings(_settings.copyWith(exchangeCurrency: currency));
  }

  Future<void> addSymbol(String symbol) async {
    final sym = symbol.trim().toUpperCase();
    if (sym.isNotEmpty && !_settings.symbols.contains(sym)) {
      final updated = List<String>.from(_settings.symbols)..add(sym);
      await updateSettings(_settings.copyWith(symbols: updated));
    }
  }

  Future<void> removeSymbol(String symbol) async {
    final updated = List<String>.from(_settings.symbols)..remove(symbol);
    await updateSettings(_settings.copyWith(symbols: updated));
  }

  // --- Real-Time Financial Calculations ---
  double get currentEquity {
    double eq = _settings.initialCapital;
    for (final t in _trades) {
      eq += t.pl;
    }
    return eq;
  }

  double get totalProfitLoss => currentEquity - _settings.initialCapital;

  double get totalProfitLossPercentage {
    if (_settings.initialCapital <= 0) return 0.0;
    return totalProfitLoss / _settings.initialCapital;
  }

  double get currentEquityIDR => currentEquity * _settings.usdToIdrRate;

  /// Chronological equity history points for chart sparkline
  List<double> get equityHistory {
    final points = <double>[_settings.initialCapital];
    double eq = _settings.initialCapital;
    for (final t in _trades) {
      eq += t.pl;
      points.add(eq);
    }
    return points;
  }

  /// Filtered list of trades for Journal screen (reverse chronological)
  List<Trade> getFilteredTrades({String query = '', String filter = 'ALL'}) {
    final q = query.trim().toLowerCase();
    final list = _trades.reversed.where((t) {
      if (filter != 'ALL' && t.resultString != filter) return false;
      if (q.isNotEmpty) {
        final fullText = '${t.sym} ${t.why ?? ''} ${t.note ?? ''}'.toLowerCase();
        if (!fullText.contains(q)) return false;
      }
      return true;
    }).toList();
    return list;
  }

  /// Summary statistics calculation for 'all', '30', or '7' days
  PeriodSummary getSummaryStats(String period) {
    List<Trade> filtered;
    final now = DateTime.now();

    if (period == '30') {
      final threshold = now.subtract(const Duration(days: 30));
      filtered = _trades.where((t) => t.date.isAfter(threshold)).toList();
    } else if (period == '7') {
      final threshold = now.subtract(const Duration(days: 7));
      filtered = _trades.where((t) => t.date.isAfter(threshold)).toList();
    } else {
      filtered = List.from(_trades);
    }

    if (filtered.isEmpty) {
      return PeriodSummary(
        totalTrades: 0,
        winCount: 0,
        loseCount: 0,
        beCount: 0,
        winRate: 0.0,
        grossProfit: 0.0,
        grossLoss: 0.0,
        netProfit: 0.0,
        profitFactor: null,
        avgWin: 0.0,
        avgLoss: 0.0,
        expectancy: 0.0,
        bestTrade: 0.0,
        worstTrade: 0.0,
        maxDrawdown: 0.0,
        avgRR: 0.0,
        streakCount: 0,
        streakType: '-',
        equityPoints: [_settings.initialCapital],
        symbolStats: [],
      );
    }

    final n = filtered.length;
    final wins = filtered.where((t) => t.result == TradeResult.win).toList();
    final loses = filtered.where((t) => t.result == TradeResult.lose).toList();
    final beCount = n - wins.length - loses.length;

    final grossProfit = wins.fold<double>(0.0, (sum, t) => sum + t.pl);
    final grossLoss = loses.fold<double>(0.0, (sum, t) => sum + t.pl);
    final netProfit = grossProfit + grossLoss;

    final double? profitFactor = grossLoss != 0
        ? (grossProfit / grossLoss.abs())
        : (grossProfit > 0 ? double.infinity : null);

    final winRate = n > 0 ? wins.length / n : 0.0;
    final avgWin = wins.isNotEmpty ? grossProfit / wins.length : 0.0;
    final avgLoss = loses.isNotEmpty ? grossLoss / loses.length : 0.0;
    final expectancy = n > 0 ? netProfit / n : 0.0;

    final pls = filtered.map((t) => t.pl).toList();
    final bestTrade = pls.reduce(max);
    final worstTrade = pls.reduce(min);

    // Equity points & Max Drawdown
    final equityPoints = <double>[_settings.initialCapital];
    double eq = _settings.initialCapital;
    for (final t in filtered) {
      eq += t.pl;
      equityPoints.add(eq);
    }

    double peak = equityPoints[0];
    double maxDD = 0.0;
    for (final v in equityPoints) {
      if (v > peak) peak = v;
      if (peak > 0) {
        final dd = (peak - v) / peak;
        if (dd > maxDD) maxDD = dd;
      }
    }

    // Average Risk:Reward
    final rrList = filtered
        .map((t) => t.riskRewardRatio)
        .where((r) => r != null && r > 0)
        .map((r) => r!)
        .toList();
    final avgRR = rrList.isNotEmpty
        ? rrList.reduce((a, b) => a + b) / rrList.length
        : 0.0;

    // Current Streak
    int streakCount = 0;
    String streakType = '-';
    for (int i = filtered.length - 1; i >= 0; i--) {
      final res = filtered[i].result;
      if (res == TradeResult.be) break;
      final currentType = res == TradeResult.win ? 'WIN' : 'LOSE';
      if (streakType == '-') {
        streakType = currentType;
      }
      if (streakType != currentType) break;
      streakCount++;
    }

    // Per Symbol Breakdown
    final uniqueSymbols = filtered.map((t) => t.sym).toSet().toList();
    final List<SymbolStat> symStats = [];
    for (final s in uniqueSymbols) {
      final symTrades = filtered.where((t) => t.sym == s).toList();
      final winC = symTrades.where((t) => t.result == TradeResult.win).length;
      final totalP = symTrades.fold<double>(0.0, (acc, t) => acc + t.pl);
      symStats.add(SymbolStat(
        symbol: s,
        count: symTrades.length,
        winCount: winC,
        totalPL: totalP,
      ));
    }
    symStats.sort((a, b) => b.totalPL.compareTo(a.totalPL));

    return PeriodSummary(
      totalTrades: n,
      winCount: wins.length,
      loseCount: loses.length,
      beCount: beCount,
      winRate: winRate,
      grossProfit: grossProfit,
      grossLoss: grossLoss,
      netProfit: netProfit,
      profitFactor: profitFactor,
      avgWin: avgWin,
      avgLoss: avgLoss,
      expectancy: expectancy,
      bestTrade: bestTrade,
      worstTrade: worstTrade,
      maxDrawdown: maxDD,
      avgRR: avgRR,
      streakCount: streakCount,
      streakType: streakType,
      equityPoints: equityPoints,
      symbolStats: symStats,
    );
  }
}
