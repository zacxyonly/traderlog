import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/app_settings.dart';
import '../models/trade.dart';
import '../models/trading_account.dart';

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

class TagStat {
  final String tag;
  final int count;
  final int winCount;
  final double totalPL;

  TagStat({
    required this.tag,
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
  final double maxDrawdownAmount;
  final double avgRR; // planned average RR
  final double? actualRR; // actual payoff ratio (avgWin / avgLoss)
  final int streakCount;
  final String streakType; // 'WIN', 'LOSE', or '-'
  final List<double> equityPoints;
  final List<SymbolStat> symbolStats;
  final List<Trade> trades;
  final List<TagStat> setupStats;
  final List<TagStat> emotionStats;

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
    required this.maxDrawdownAmount,
    required this.avgRR,
    required this.actualRR,
    required this.streakCount,
    required this.streakType,
    required this.equityPoints,
    required this.symbolStats,
    this.trades = const [],
    this.setupStats = const [],
    this.emotionStats = const [],
  });
}

class TradeProvider extends ChangeNotifier {
  final DBHelper _db = DBHelper.instance;

  List<Trade> _trades = [];
  AppSettings _settings = AppSettings();
  bool _isLoading = true;
  bool _isAppUnlocked = false;
  final Map<String, PeriodSummary> _summaryCache = {};
  List<Trade>? _cachedActiveTrades;

  void _invalidateCache() {
    _cachedActiveTrades = null;
    _summaryCache.clear();
  }

  /// Active account's trades (cached per account, chronological)
  List<Trade> get trades {
    return _cachedActiveTrades ??= _trades
        .where((t) => (t.accountId ?? 'acc_real') == _settings.activeAccountId)
        .toList();
  }

  /// All trades across all accounts
  List<Trade> get allTrades => List.unmodifiable(_trades);

  AppSettings get settings => _settings;
  bool get isLoading => _isLoading;
  bool get isAppUnlocked => _isAppUnlocked;

  TradingAccount get activeAccount => _settings.activeAccount;

  TradeProvider() {
    loadData();
  }

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _settings = await _db.getSettings();
      _trades = await _db.getAllTrades();
      _invalidateCache();
      if (!_settings.isPinSet) {
        _isAppUnlocked = true;
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Trade Operations ---
  Future<void> addTrade(Trade trade) async {
    _invalidateCache();
    final tradeWithAccount =
        (trade.accountId != null && trade.accountId!.isNotEmpty)
            ? trade
            : trade.copyWith(accountId: _settings.activeAccountId);

    await _db.insertTrade(tradeWithAccount);
    _trades.add(tradeWithAccount);
    _trades.sort((a, b) => a.date.compareTo(b.date));

    if (!_settings.symbols.contains(tradeWithAccount.sym)) {
      final updated = List<String>.from(_settings.symbols)..add(tradeWithAccount.sym);
      await updateSettings(_settings.copyWith(symbols: updated));
    } else {
      notifyListeners();
    }
  }

  Future<void> updateTrade(Trade trade) async {
    _invalidateCache();
    await _db.updateTrade(trade);
    final idx = _trades.indexWhere((t) => t.id == trade.id);
    if (idx != -1) {
      final old = _trades[idx];
      if (old.imagePath != null &&
          old.imagePath != trade.imagePath &&
          old.imagePath != trade.imagePathAfter) {
        _safeDeleteFile(old.imagePath);
      }
      if (old.imagePathAfter != null &&
          old.imagePathAfter != trade.imagePathAfter &&
          old.imagePathAfter != trade.imagePath) {
        _safeDeleteFile(old.imagePathAfter);
      }
      _trades[idx] = trade;
      _trades.sort((a, b) => a.date.compareTo(b.date));
      notifyListeners();
    }
  }

  Future<void> deleteTrade(String id) async {
    _invalidateCache();
    final idx = _trades.indexWhere((t) => t.id == id);
    if (idx != -1) {
      final t = _trades[idx];
      _safeDeleteFile(t.imagePath);
      _safeDeleteFile(t.imagePathAfter);
    }
    await _db.deleteTrade(id);
    _trades.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  Future<void> deleteAllTrades() async {
    _invalidateCache();
    final activeId = _settings.activeAccountId;
    for (final t in trades) {
      _safeDeleteFile(t.imagePath);
      _safeDeleteFile(t.imagePathAfter);
    }
    await _db.deleteTradesByAccount(activeId);
    _trades.removeWhere((t) => (t.accountId ?? 'acc_real') == activeId);
    notifyListeners();
  }

  Future<void> importTrades(List<Trade> imported, {bool replace = false}) async {
    _invalidateCache();
    final activeId = _settings.activeAccountId;
    final importedWithAccount = imported.map((t) {
      return (t.accountId != null && t.accountId!.isNotEmpty)
          ? t
          : t.copyWith(accountId: activeId);
    }).toList();

    if (replace) {
      for (final t in trades) {
        _safeDeleteFile(t.imagePath);
        _safeDeleteFile(t.imagePathAfter);
      }
      await _db.replaceTradesForAccount(activeId, importedWithAccount);
      _trades.removeWhere((t) => (t.accountId ?? 'acc_real') == activeId);
      _trades.addAll(importedWithAccount);
    } else {
      _trades.addAll(importedWithAccount);
      await _db.insertTradesBatch(importedWithAccount, replace: false);
    }
    _trades.sort((a, b) => a.date.compareTo(b.date));

    // Add any new symbols to settings
    final newSymbols = Set<String>.from(_settings.symbols);
    for (final t in importedWithAccount) {
      if (t.sym.isNotEmpty) newSymbols.add(t.sym);
    }
    if (newSymbols.length != _settings.symbols.length) {
      await updateSettings(_settings.copyWith(symbols: newSymbols.toList()));
    } else {
      notifyListeners();
    }
  }

  // --- Settings & Multi-Account Operations ---
  Future<void> updateSettings(AppSettings newSettings) async {
    _settings = newSettings;
    await _db.saveSettings(newSettings);
    notifyListeners();
  }

  Future<void> switchAccount(String accountId) async {
    _invalidateCache();
    if (_settings.activeAccountId != accountId) {
      final acc = _settings.accounts.firstWhere(
        (a) => a.id == accountId,
        orElse: () => _settings.accounts.first,
      );
      await updateSettings(_settings.copyWith(
        activeAccountId: accountId,
        accountCurrency: acc.currency,
      ));
    }
  }

  Future<void> addAccount(TradingAccount account) async {
    _invalidateCache();
    final updated = List<TradingAccount>.from(_settings.accounts)..add(account);
    await updateSettings(_settings.copyWith(
      accounts: updated,
      activeAccountId: account.id,
    ));
  }

  Future<void> updateAccount(TradingAccount account) async {
    _invalidateCache();
    final idx = _settings.accounts.indexWhere((a) => a.id == account.id);
    if (idx != -1) {
      final updated = List<TradingAccount>.from(_settings.accounts);
      updated[idx] = account;
      await updateSettings(_settings.copyWith(accounts: updated));
    }
  }

  Future<void> deleteAccount(String accountId) async {
    _invalidateCache();
    if (_settings.accounts.length <= 1) return;
    final updated = List<TradingAccount>.from(_settings.accounts)
      ..removeWhere((a) => a.id == accountId);
    final newActive = _settings.activeAccountId == accountId
        ? updated.first.id
        : _settings.activeAccountId;

    for (final t in _trades.where((t) => (t.accountId ?? 'acc_real') == accountId).toList()) {
      _safeDeleteFile(t.imagePath);
      _safeDeleteFile(t.imagePathAfter);
    }
    await _db.deleteTradesByAccount(accountId);
    _trades.removeWhere((t) => (t.accountId ?? 'acc_real') == accountId);

    await updateSettings(_settings.copyWith(
      accounts: updated,
      activeAccountId: newActive,
    ));
  }

  // --- Security PIN & Biometric ---
  bool _isSystemPickerActive = false;
  bool get isSystemPickerActive => _isSystemPickerActive;

  void setSystemPickerActive(bool active) {
    _isSystemPickerActive = active;
  }

  void unlockApp() {
    _isAppUnlocked = true;
    notifyListeners();
  }

  void lockApp() {
    if (_settings.isPinSet && !_isSystemPickerActive) {
      _isAppUnlocked = false;
      notifyListeners();
    }
  }

  Future<void> setPinCode(String? pin) async {
    final hashedPin = (pin != null && pin.trim().isNotEmpty)
        ? AppSettings.hashPin(pin.trim())
        : null;
    await updateSettings(_settings.copyWith(pinCode: hashedPin));
    _isAppUnlocked = true;
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await updateSettings(_settings.copyWith(isBiometricEnabled: enabled));
  }

  Future<void> updateLanguage(String langCode) async {
    await updateSettings(_settings.copyWith(languageCode: langCode));
  }

  Future<void> updateTraderName(String name) async {
    await updateSettings(_settings.copyWith(traderName: name));
  }

  Future<void> updateAccountCurrency(String currency) async {
    await updateSettings(_settings.copyWith(accountCurrency: currency));
    final active = activeAccount.copyWith(currency: currency);
    await updateAccount(active);
  }

  Future<void> updateExchangeCurrency(String currency) async {
    await updateSettings(_settings.copyWith(exchangeCurrency: currency));
  }

  Future<void> updateExchangeRate(double rate) async {
    await updateSettings(_settings.copyWith(exchangeRate: rate));
  }

  Future<void> recordCloudBackup() async {
    final now = DateTime.now().toIso8601String();
    await updateSettings(_settings.copyWith(lastBackupDate: now));
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
    double eq = activeAccount.initialCapital;
    for (final t in trades) {
      eq += t.pl;
    }
    return eq;
  }

  double get totalProfitLoss => currentEquity - activeAccount.initialCapital;

  double get totalProfitLossPercentage {
    if (activeAccount.initialCapital <= 0) return 0.0;
    return totalProfitLoss / activeAccount.initialCapital;
  }

  double get currentEquityExchange {
    if (activeAccount.currency == _settings.exchangeCurrency) {
      return currentEquity;
    }
    return currentEquity * _settings.exchangeRate;
  }

  double get currentEquityIDR => currentEquityExchange;

  /// Chronological equity history points for chart sparkline & equity curve
  List<double> get equityHistory {
    final points = <double>[activeAccount.initialCapital];
    double eq = activeAccount.initialCapital;
    for (final t in trades) {
      eq += t.pl;
      points.add(eq);
    }
    return points;
  }

  /// Filtered list of trades for Journal screen (reverse chronological)
  List<Trade> getFilteredTrades({String query = '', String filter = 'ALL'}) {
    final q = query.trim().toLowerCase();
    final f = filter.toUpperCase();

    final activeTrades = trades;
    final filtered = activeTrades.where((t) {
      if (f == 'WIN' && t.result != TradeResult.win) return false;
      if (f == 'LOSE' && t.result != TradeResult.lose) return false;
      if (f == 'BE' && t.result != TradeResult.be) return false;

      if (q.isNotEmpty) {
        final fullText = '${t.sym} ${t.why ?? ''} ${t.note ?? ''} ${t.tags ?? ''}'.toLowerCase();
        if (!fullText.contains(q)) return false;
      }
      return true;
    }).toList();

    return filtered.reversed.toList();
  }

  /// Trades filtered for a specific calendar day
  List<Trade> getTradesForDay(DateTime day) {
    return trades.where((t) =>
        t.date.year == day.year &&
        t.date.month == day.month &&
        t.date.day == day.day).toList();
  }

  /// Summary statistics calculation for 'all', '30', or '7' days (with caching)
  PeriodSummary getSummaryStats(String period) {
    if (_summaryCache.containsKey(period)) {
      return _summaryCache[period]!;
    }
    final summary = _computeSummaryStats(period);
    _summaryCache[period] = summary;
    return summary;
  }

  PeriodSummary _computeSummaryStats(String period) {
    final activeTrades = trades;
    List<Trade> filtered;
    final now = DateTime.now();

    if (period == '7') {
      final cutoff = now.subtract(const Duration(days: 7));
      filtered = activeTrades.where((t) => t.date.isAfter(cutoff)).toList();
    } else if (period == '30') {
      final cutoff = now.subtract(const Duration(days: 30));
      filtered = activeTrades.where((t) => t.date.isAfter(cutoff)).toList();
    } else {
      filtered = List.from(activeTrades);
    }

    final total = filtered.length;
    if (total == 0) {
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
        maxDrawdownAmount: 0.0,
        avgRR: 0.0,
        actualRR: null,
        streakCount: 0,
        streakType: '-',
        equityPoints: [activeAccount.initialCapital],
        symbolStats: [],
        trades: [],
        setupStats: [],
        emotionStats: [],
      );
    }

    int wins = 0;
    int loses = 0;
    int bes = 0;
    double grossP = 0.0;
    double grossL = 0.0;
    double best = filtered.first.pl;
    double worst = filtered.first.pl;

    double totalPlannedRR = 0.0;
    int plannedRRCount = 0;

    for (final t in filtered) {
      if (t.pl > 0) {
        wins++;
        grossP += t.pl;
      } else if (t.pl < 0) {
        loses++;
        grossL += t.pl.abs();
      } else {
        bes++;
      }

      if (t.pl > best) best = t.pl;
      if (t.pl < worst) worst = t.pl;

      final rr = t.riskRewardRatio;
      if (rr != null && rr > 0) {
        totalPlannedRR += rr;
        plannedRRCount++;
      }
    }

    final winRate = total > 0 ? wins / total : 0.0;
    final netP = grossP - grossL;
    final profitFactor = grossL > 0 ? grossP / grossL : (grossP > 0 ? null : 0.0);
    final avgWin = wins > 0 ? grossP / wins : 0.0;
    final avgLoss = loses > 0 ? grossL / loses : 0.0;
    final expectancy = total > 0 ? (grossP - grossL) / total : 0.0;
    final actualRR = avgLoss > 0 ? avgWin / avgLoss : null;
    final avgRR = plannedRRCount > 0 ? totalPlannedRR / plannedRRCount : 0.0;

    // Equity Curve & Max Drawdown
    double peak = activeAccount.initialCapital;
    double maxDDAmount = 0.0;
    double maxDDPct = 0.0;
    double runningEq = activeAccount.initialCapital;
    final eqPoints = <double>[runningEq];

    for (final t in filtered) {
      runningEq += t.pl;
      eqPoints.add(runningEq);

      if (runningEq > peak) {
        peak = runningEq;
      } else if (peak > 0) {
        final ddAmt = peak - runningEq;
        final ddPct = ddAmt / peak;
        if (ddAmt > maxDDAmount) maxDDAmount = ddAmt;
        if (ddPct > maxDDPct) maxDDPct = ddPct;
      }
    }

    // Win/Lose Streaks
    int currentStreak = 0;
    String streakType = '-';
    if (filtered.isNotEmpty) {
      final lastTrade = filtered.last;
      if (lastTrade.result == TradeResult.win) {
        streakType = 'WIN';
      } else if (lastTrade.result == TradeResult.lose) {
        streakType = 'LOSE';
      }

      if (streakType != '-') {
        for (int i = filtered.length - 1; i >= 0; i--) {
          final t = filtered[i];
          if ((streakType == 'WIN' && t.result == TradeResult.win) ||
              (streakType == 'LOSE' && t.result == TradeResult.lose)) {
            currentStreak++;
          } else {
            break;
          }
        }
      }
    }

    // Symbol Breakdown
    final Map<String, List<Trade>> symMap = {};
    for (final t in filtered) {
      symMap.putIfAbsent(t.sym, () => []).add(t);
    }
    final List<SymbolStat> symStats = [];
    for (final entry in symMap.entries) {
      final tradesForSym = entry.value;
      final winC = tradesForSym.where((t) => t.result == TradeResult.win).length;
      final plSum = tradesForSym.fold<double>(0.0, (acc, t) => acc + t.pl);
      symStats.add(SymbolStat(
        symbol: entry.key,
        count: tradesForSym.length,
        winCount: winC,
        totalPL: plSum,
      ));
    }
    symStats.sort((a, b) => b.totalPL.compareTo(a.totalPL));

    // Recognized Tag Sets to prevent arbitrary notes from corrupting analytics
    const recognizedSetups = {
      'BOS', 'CHOCH', 'FVG', 'Liquidity', 'Supply/Demand', 'Trendline', 'S&R', 'News', 'Fibonacci'
    };
    const recognizedEmotions = {
      'Disiplin', 'FOMO', 'Revenge Trade', 'Overlot', 'Sabar', 'Greedy', 'Hesitant', 'Plan Executed', 'Early Exit'
    };

    final Map<String, List<Trade>> setupMap = {};
    final Map<String, List<Trade>> emotionMap = {};

    for (final t in filtered) {
      // 1. Check t.tags
      if (t.tags != null && t.tags!.isNotEmpty) {
        final tags = t.tags!.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty);
        for (final tag in tags) {
          if (recognizedSetups.contains(tag)) {
            setupMap.putIfAbsent(tag, () => []).add(t);
          } else if (recognizedEmotions.contains(tag)) {
            emotionMap.putIfAbsent(tag, () => []).add(t);
          } else {
            setupMap.putIfAbsent(tag, () => []).add(t);
          }
        }
      } else {
        // Fallback for legacy trades: only extract exact recognized tags
        if (t.why != null && t.why!.isNotEmpty) {
          for (final tag in recognizedSetups) {
            if (t.why!.contains(tag)) {
              setupMap.putIfAbsent(tag, () => []).add(t);
            }
          }
        }
        if (t.note != null && t.note!.isNotEmpty) {
          for (final tag in recognizedEmotions) {
            if (t.note!.contains(tag)) {
              emotionMap.putIfAbsent(tag, () => []).add(t);
            }
          }
        }
      }
    }

    final List<TagStat> setupStats = [];
    for (final entry in setupMap.entries) {
      final tradesForTag = entry.value;
      final winC = tradesForTag.where((t) => t.result == TradeResult.win).length;
      final plSum = tradesForTag.fold<double>(0.0, (acc, t) => acc + t.pl);
      setupStats.add(TagStat(
        tag: entry.key,
        count: tradesForTag.length,
        winCount: winC,
        totalPL: plSum,
      ));
    }
    setupStats.sort((a, b) => b.totalPL.compareTo(a.totalPL));

    final List<TagStat> emotionStats = [];
    for (final entry in emotionMap.entries) {
      final tradesForTag = entry.value;
      final winC = tradesForTag.where((t) => t.result == TradeResult.win).length;
      final plSum = tradesForTag.fold<double>(0.0, (acc, t) => acc + t.pl);
      emotionStats.add(TagStat(
        tag: entry.key,
        count: tradesForTag.length,
        winCount: winC,
        totalPL: plSum,
      ));
    }
    emotionStats.sort((a, b) => b.totalPL.compareTo(a.totalPL));

    return PeriodSummary(
      totalTrades: total,
      winCount: wins,
      loseCount: loses,
      beCount: bes,
      winRate: winRate,
      grossProfit: grossP,
      grossLoss: grossL,
      netProfit: netP,
      profitFactor: profitFactor,
      avgWin: avgWin,
      avgLoss: avgLoss,
      expectancy: expectancy,
      bestTrade: best,
      worstTrade: worst,
      maxDrawdown: maxDDPct,
      maxDrawdownAmount: maxDDAmount,
      avgRR: avgRR,
      actualRR: actualRR,
      streakCount: currentStreak,
      streakType: streakType,
      equityPoints: eqPoints,
      symbolStats: symStats,
      trades: filtered,
      setupStats: setupStats,
      emotionStats: emotionStats,
    );
  }

  void _safeDeleteFile(String? path) {
    if (path == null || path.isEmpty) return;
    try {
      final file = File(path);
      if (file.existsSync()) {
        file.deleteSync();
      }
    } catch (_) {}
  }
}
