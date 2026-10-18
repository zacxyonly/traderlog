import '../models/trade.dart';

class PnlResult {
  final double pnl;
  final double pips;
  final String pipUnit; // 'pips' or 'pts'
  final double? basePnl;
  final bool isEstimate;

  const PnlResult({
    required this.pnl,
    required this.pips,
    required this.pipUnit,
    this.basePnl,
    this.isEstimate = false,
  });

  String get formattedPips {
    final prefix = pips > 0 ? '+' : '';
    return '$prefix${pips.toStringAsFixed(1)} $pipUnit';
  }
}

class PnlCalculator {
  /// Determines asset type based on symbol: 'gold', 'indices', 'crypto', or 'forex'
  static String getAssetType(String symbol) {
    final sym = symbol.toUpperCase().replaceAll('/', '').replaceAll('-', '').trim();
    if (sym.contains('XAU') || sym.contains('GOLD')) {
      return 'gold';
    } else if (sym.contains('US30') ||
        sym.contains('USTEC') ||
        sym.contains('US500') ||
        sym.contains('NAS') ||
        sym.contains('SPX') ||
        sym.contains('DOW') ||
        sym.contains('NDX') ||
        sym.contains('DAX') ||
        sym.contains('GER40') ||
        sym.contains('UK100')) {
      return 'indices';
    } else if (sym.contains('BTC') ||
        sym.contains('ETH') ||
        sym.contains('SOL') ||
        sym.contains('BNB') ||
        sym.contains('XRP') ||
        sym.contains('DOGE')) {
      return 'crypto';
    } else {
      return 'forex';
    }
  }

  /// Returns unit name for price movement ('pips' for Gold & Forex, 'pts' for Indices & Crypto)
  static String getPipUnit(String symbol) {
    final type = getAssetType(symbol);
    return (type == 'indices' || type == 'crypto') ? 'pts' : 'pips';
  }

  /// Single source of truth to calculate raw pips or points movement
  static double? calculatePips({
    required String symbol,
    required TradeSide side,
    required double? entry,
    required double? exit,
  }) {
    if (entry == null || exit == null) return null;
    final priceDiff = (side == TradeSide.buy) ? (exit - entry) : (entry - exit);
    final assetType = getAssetType(symbol);

    switch (assetType) {
      case 'gold':
        // Gold: 1 pip = 0.10 price movement ($1 move = 10 pips)
        return priceDiff * 10.0;
      case 'indices':
      case 'crypto':
        // Indices and Crypto move in whole index / dollar points
        return priceDiff;
      case 'forex':
      default:
        final sym = symbol.toUpperCase();
        final isJpy = sym.contains('JPY');
        final pipSize = isJpy ? 0.01 : 0.0001;
        return priceDiff / pipSize;
    }
  }

  /// Formats pips or points nicely with prefix and appropriate unit
  static String formatPips({
    required String symbol,
    required TradeSide side,
    required double? entry,
    required double? exit,
  }) {
    final pips = calculatePips(symbol: symbol, side: side, entry: entry, exit: exit);
    if (pips == null) return '';
    final unit = getPipUnit(symbol);
    final prefix = pips > 0 ? '+' : '';
    return '$prefix${pips.toStringAsFixed(1)} $unit';
  }

  /// Calculates PnL and Pips/Points between two prices
  static PnlResult? calculate({
    required String symbol,
    required TradeSide side,
    required double? entry,
    required double? exit,
    required double? lot,
    double fxRate = 1.0,
  }) {
    if (entry == null || exit == null || lot == null || lot <= 0) {
      return null;
    }

    final pips = calculatePips(
      symbol: symbol,
      side: side,
      entry: entry,
      exit: exit,
    );
    if (pips == null) return null;

    final priceDiff = (side == TradeSide.buy) ? (exit - entry) : (entry - exit);
    final assetType = getAssetType(symbol);
    final pipUnit = getPipUnit(symbol);

    double basePnl = 0.0;
    bool isEstimate = false;

    switch (assetType) {
      case 'gold':
        // 1 standard lot = 100 oz. $1 move in Gold = $100 per 1.0 lot.
        basePnl = priceDiff * 100.0 * lot;
        isEstimate = false;
        break;

      case 'indices':
        // 1 standard contract of US30/USTEC/US500 = $1 per 1 point move
        basePnl = priceDiff * lot;
        isEstimate = false;
        break;

      case 'crypto':
        // 1 coin/contract: 1 point price diff = $1 per 1 lot
        basePnl = priceDiff * lot;
        isEstimate = false;
        break;

      case 'forex':
      default:
        final sym = symbol.toUpperCase();
        final isJpy = sym.contains('JPY');
        final isUsdQuote = sym.endsWith('USD') || sym.contains('/USD');

        if (isUsdQuote) {
          // Standard quote in USD (EUR/USD, GBP/USD, etc.): $10 per pip per 1.0 lot
          basePnl = pips * 10.0 * lot;
          isEstimate = false;
        } else if (isJpy && (sym.startsWith('USD') || sym.contains('USD/'))) {
          // USD/JPY: Pip value in USD = (0.01 / exit_price) * 100,000 * lot
          final denom = exit > 0 ? exit : (entry > 0 ? entry : 150.0);
          basePnl = (0.01 / denom) * 100000.0 * lot * pips;
          isEstimate = true;
        } else {
          // Non-USD quoted forex pairs (e.g. EUR/GBP, EUR/JPY)
          // Approximated at standard $10/pip base and tagged as estimation
          basePnl = pips * 10.0 * lot;
          isEstimate = true;
        }
        break;
    }

    final rate = (fxRate > 0) ? fxRate : 1.0;
    final convertedPnl = basePnl * rate;

    return PnlResult(
      pnl: convertedPnl,
      pips: pips,
      pipUnit: pipUnit,
      basePnl: rate != 1.0 ? basePnl : null,
      isEstimate: isEstimate,
    );
  }

  /// Calculates planned risk from Entry to Stop Loss
  static PnlResult? calculateRisk({
    required String symbol,
    required TradeSide side,
    required double? entry,
    required double? sl,
    required double? lot,
    double fxRate = 1.0,
  }) {
    if (entry == null || sl == null || lot == null || lot <= 0) return null;
    return calculate(
      symbol: symbol,
      side: side,
      entry: entry,
      exit: sl,
      lot: lot,
      fxRate: fxRate,
    );
  }

  /// Calculates planned reward from Entry to Take Profit
  static PnlResult? calculateReward({
    required String symbol,
    required TradeSide side,
    required double? entry,
    required double? tp,
    required double? lot,
    double fxRate = 1.0,
  }) {
    if (entry == null || tp == null || lot == null || lot <= 0) return null;
    return calculate(
      symbol: symbol,
      side: side,
      entry: entry,
      exit: tp,
      lot: lot,
      fxRate: fxRate,
    );
  }
}
