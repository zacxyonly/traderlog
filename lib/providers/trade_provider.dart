import 'dart:math';
import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/app_settings.dart';
import '../models/trade.dart';
import '../models/trading_account.dart';
import '../services/currency_service.dart';

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
  final double totalPipsGained;
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
    this.totalPipsGained = 0.0,
    this.setupStats = const [],
    this.emotionStats = const [],
  });
}

class TradeProvider extends ChangeNotifier {
  final DBHelper _db = DBHelper.instance;

  List<Trade> _trades = [];
  AppSettings _settings = AppSettings();
  bool _isLoading = true;
  bool _isSyncingRate = false;
  bool _isAppUnlocked = false;

  /// Active account's trades (chronological)
  List<Trade> get trades {
    final activeId = _settings.activeAccountId;
    return _trades.where((t) {
      final acc = t.accountId ?? 'acc_real';
      return acc == activeId;
    }).toList();
  }

  /// All trades across all accounts (for backup / CSV export)
  List<Trade> get allTrades => _trades;

  AppSettings get settings => _settings;
  TradingAccount get activeAccount => _settings.activeAccount;
  bool get isLoading => _isLoading;
  bool get isSyncingRate => _isSyncingRate;
  bool get isAppUnlocked => _isAppUnlocked;
  bool get isLocked => _settings.isPinSet && !_isAppUnlocked;

  TradeProvider() {
    loadData();
  }

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _settings = await _db.getSettings();
      _trades = await _db.getAllTrades();
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
    final tradeWithAccount =
        (trade.accountId != null && trade.accountId!.isNotEmpty)
            ? trade
            : trade.copyWith(accountId: _settings.activeAccountId);

    await _db.insertTrade(tradeWithAccount);
    _trades.add(tradeWithAccount);
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
    final activeId = _settings.activeAccountId;
    // Delete trades only for the active account
    for (final t in trades) {
      await _db.deleteTrade(t.id);
    }
    _trades.removeWhere((t) => (t.accountId ?? 'acc_real') == activeId);
    notifyListeners();
  }

  Future<void> importTrades(List<Trade> imported, {bool replace = false}) async {
    final activeId = _settings.activeAccountId;
    final importedWithAccount = imported.map((t) {
      return (t.accountId != null && t.accountId!.isNotEmpty)
          ? t
          : t.copyWith(accountId: activeId);
    }).toList();

    if (replace) {
      for (final t in trades) {
        await _db.deleteTrade(t.id);
      }
      _trades.removeWhere((t) => (t.accountId ?? 'acc_real') == activeId);
      _trades.addAll(importedWithAccount);
      await _db.insertTradesBatch(importedWithAccount, replace: false);
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
    if (_settings.activeAccountId != accountId) {
      await updateSettings(_settings.copyWith(activeAccountId: accountId));
    }
  }

  Future<void> addAccount(TradingAccount account) async {
    final updated = List<TradingAccount>.from(_settings.accounts)..add(account);
    await updateSettings(_settings.copyWith(
      accounts: updated,
      activeAccountId: account.id,
    ));
  }

  Future<void> updateAccount(TradingAccount account) async {
    final idx = _settings.accounts.indexWhere((a) => a.id == account.id);
    if (idx != -1) {
      final updated = List<TradingAccount>.from(_settings.accounts);
      updated[idx] = account;
      await updateSettings(_settings.copyWith(accounts: updated));
    }
  }

  Future<void> deleteAccount(String accountId) async {
    if (_settings.accounts.length <= 1) return;
    final updated = List<TradingAccount>.from(_settings.accounts)
      ..removeWhere((a) => a.id == accountId);
    final newActive = _settings.activeAccountId == accountId
        ? updated.first.id
        : _settings.activeAccountId;

    for (final t in _trades.where((t) => (t.accountId ?? 'acc_real') == accountId).toList()) {
      await _db.deleteTrade(t.id);
    }
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
    await updateSettings(_settings.copyWith(pinCode: pin));
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
    // Also sync the currency of active account
    final active = activeAccount.copyWith(currency: currency);
    await updateAccount(active);
    await syncExchangeRate();
  }

  Future<void> updateExchangeCurrency(String currency) async {
    await updateSettings(_settings.copyWith(exchangeCurrency: currency));
    await syncExchangeRate();
  }

  Future<void> recordCloudBackup() async {
    final now = DateTime.now().toIso8601String();
    await updateSettings(_settings.copyWith(lastBackupDate: now));
  }

  /// Automatically synchronizes the latest exchange rate from the live open FX API.
  Future<double?> syncExchangeRate({bool notify = true}) async {
    _isSyncingRate = true;
    if (notify) notifyListeners();

    try {
      final rate = await CurrencyService.fetchExchangeRate(
        baseCurrency: _settings.accountCurrency,
        targetCurrency: _settings.exchangeCurrency,
      );
      if (rate != null && rate > 0) {
        _settings = _settings.copyWith(usdToIdrRate: rate);
        await _db.saveSettings(_settings);
        return rate;
      }
    } catch (e) {
      debugPrint('Error syncing exchange rate: $e');
    } finally {
      _isSyncingRate = false;
      if (notify) notifyListeners();
    }
    return null;
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

  double get currentEquityIDR => currentEquity * _settings.usdToIdrRate;

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
    final list = trades.reversed.where((t) {
      if (filter != 'ALL' && t.resultString != filter) return false;
      if (q.isNotEmpty) {
        final fullText = '${t.sym} ${t.why ?? ''} ${t.note ?? ''}'.toLowerCase();
        if (!fullText.contains(q)) return false;
      }
      return true;
    }).toList();
    return list;
  }

  /// Daily net PnL mapped by 'YYYY-MM-DD' for the Heatmap Calendar
  Map<String, double> getDailyPnLMap() {
    final Map<String, double> pnlMap = {};
    for (final t in trades) {
      final key =
          '${t.date.year}-${t.date.month.toString().padLeft(2, '0')}-${t.date.day.toString().padLeft(2, '0')}';
      pnlMap[key] = (pnlMap[key] ?? 0.0) + t.pl;
    }
    return pnlMap;
  }

  /// Returns trades for a specific calendar date (DateTime)
  List<Trade> getTradesForDay(DateTime day) {
    return trades.where((t) =>
        t.date.year == day.year &&
        t.date.month == day.month &&
        t.date.day == day.day).toList();
  }

  /// Summary statistics calculation for 'all', '30', or '7' days
  PeriodSummary getSummaryStats(String period) {
    final activeTrades = trades;
    List<Trade> filtered;
    final now = DateTime.now();

    final initialCap = activeAccount.initialCapital;
    double startingEquity = initialCap;

    if (period == '30') {
      final threshold = now.subtract(const Duration(days: 30));
      filtered = activeTrades.where((t) => t.date.isAfter(threshold)).toList();
      final prior = activeTrades.where((t) => !t.date.isAfter(threshold)).toList();
      startingEquity = initialCap + prior.fold<double>(0.0, (sum, t) => sum + t.pl);
    } else if (period == '7') {
      final threshold = now.subtract(const Duration(days: 7));
      filtered = activeTrades.where((t) => t.date.isAfter(threshold)).toList();
      final prior = activeTrades.where((t) => !t.date.isAfter(threshold)).toList();
      startingEquity = initialCap + prior.fold<double>(0.0, (sum, t) => sum + t.pl);
    } else {
      filtered = List.from(activeTrades);
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
        maxDrawdownAmount: 0.0,
        avgRR: 0.0,
        actualRR: null,
        streakCount: 0,
        streakType: '-',
        equityPoints: [startingEquity],
        symbolStats: [],
        trades: const [],
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
    final equityPoints = <double>[startingEquity];
    double eq = startingEquity;
    for (final t in filtered) {
      eq += t.pl;
      equityPoints.add(eq);
    }

    double peak = equityPoints[0];
    double maxDD = 0.0;
    double maxDDAmount = 0.0;
    for (final v in equityPoints) {
      if (v > peak) peak = v;
      final nominalDD = peak - v;
      if (nominalDD > maxDDAmount) maxDDAmount = nominalDD;
      if (peak > 0) {
        final dd = (peak - v) / peak;
        if (dd > maxDD) maxDD = dd;
      }
    }

    // Average Planned Risk:Reward
    final rrList = filtered
        .map((t) => t.riskRewardRatio)
        .where((r) => r != null && r > 0)
        .map((r) => r!)
        .toList();
    final avgRR = rrList.isNotEmpty
        ? rrList.reduce((a, b) => a + b) / rrList.length
        : 0.0;

    // Actual Realized Payoff Ratio (Avg Win / Avg Loss)
    final double? actualRR = avgLoss.abs() > 0 ? (avgWin / avgLoss.abs()) : null;

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

    // Total Pips
    double totalPips = 0.0;
    for (final t in filtered) {
      if (t.pipsGained != null) {
        totalPips += t.pipsGained!;
      }
    }

    // Setup Tags Breakdown
    final Map<String, List<Trade>> setupMap = {};
    for (final t in filtered) {
      if (t.why != null && t.why!.isNotEmpty) {
        final tags = t.why!.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty);
        for (final tag in tags) {
          setupMap.putIfAbsent(tag, () => []).add(t);
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

    // Emotion Tags Breakdown
    final Map<String, List<Trade>> emotionMap = {};
    for (final t in filtered) {
      if (t.note != null && t.note!.isNotEmpty) {
        final tags = t.note!.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty);
        for (final tag in tags) {
          emotionMap.putIfAbsent(tag, () => []).add(t);
        }
      }
    }
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
      maxDrawdownAmount: maxDDAmount,
      avgRR: avgRR,
      actualRR: actualRR,
      streakCount: streakCount,
      streakType: streakType,
      equityPoints: equityPoints,
      symbolStats: symStats,
      trades: filtered,
      totalPipsGained: totalPips,
      setupStats: setupStats,
      emotionStats: emotionStats,
    );
  }
}
