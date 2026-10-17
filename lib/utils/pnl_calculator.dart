import '../models/trade.dart';

class PnlResult {
  final double pnl;
  final double pips;
  final String pipUnit; // 'pips' or 'pts'

  const PnlResult({
    required this.pnl,
    required this.pips,
    required this.pipUnit,
  });

  String get formattedPips {
    final prefix = pips > 0 ? '+' : '';
    return '$prefix${pips.toStringAsFixed(1)} $pipUnit';
  }
}

class PnlCalculator {
  /// Determines asset type based on symbol
  /// returns 'gold', 'crypto', 'forex', or 'stock'
  static String getAssetType(String symbol) {
    final sym = symbol.toUpperCase().replaceAll('/', '').replaceAll('-', '').trim();
    if (sym.contains('XAU') || sym.contains('GOLD')) {
      return 'gold';
    } else if (sym.contains('BTC') ||
        sym.contains('ETH') ||
        sym.contains('US30') ||
        sym.contains('USTEC') ||
        sym.contains('US500') ||
        sym.contains('NAS') ||
        sym.contains('SPX') ||
        sym.contains('DOW') ||
        sym.contains('NDX') ||
        sym.contains('SOL') ||
        sym.contains('BNB')) {
      return 'crypto';
    } else {
      return 'forex';
    }
  }

  /// Calculates PnL and Pips/Points between two prices
  static PnlResult? calculate({
    required String symbol,
    required TradeSide side,
    required double? entry,
    required double? exit,
    required double? lot,
  }) {
    if (entry == null || exit == null || lot == null || lot <= 0) {
      return null;
    }

    final priceDiff = (side == TradeSide.buy) ? (exit - entry) : (entry - exit);
    final assetType = getAssetType(symbol);

    switch (assetType) {
      case 'gold':
        // 1 standard lot = 100 oz. $1 move in Gold = $100 per 1.0 lot.
        // 1 pip in gold = $0.10 move (10 pips = $1.00 move)
        final pnl = priceDiff * 100.0 * lot;
        final pips = priceDiff * 10.0;
        return PnlResult(pnl: pnl, pips: pips, pipUnit: 'pips');

      case 'crypto':
        // 1 point price diff = $1 per 1 lot
        final pnl = priceDiff * lot;
        final pips = priceDiff;
        return PnlResult(pnl: pnl, pips: pips, pipUnit: 'pts');

      case 'forex':
      default:
        // Forex:
        // JPY pairs: 1 pip = 0.01; non-JPY pairs: 1 pip = 0.0001
        final isJpy = symbol.toUpperCase().contains('JPY');
        final pipSize = isJpy ? 0.01 : 0.0001;
        final pips = priceDiff / pipSize;
        // 1 pip standard lot = $10 (approximate USD base)
        final pnl = pips * 10.0 * lot;
        return PnlResult(pnl: pnl, pips: pips, pipUnit: 'pips');
    }
  }

  /// Calculates planned risk from Entry to Stop Loss
  static PnlResult? calculateRisk({
    required String symbol,
    required TradeSide side,
    required double? entry,
    required double? sl,
    required double? lot,
  }) {
    if (entry == null || sl == null || lot == null || lot <= 0) return null;
    // For Risk, the loss occurs if price moves to SL
    return calculate(
      symbol: symbol,
      side: side,
      entry: entry,
      exit: sl,
      lot: lot,
    );
  }

  /// Calculates planned reward from Entry to Take Profit
  static PnlResult? calculateReward({
    required String symbol,
    required TradeSide side,
    required double? entry,
    required double? tp,
    required double? lot,
  }) {
    if (entry == null || tp == null || lot == null || lot <= 0) return null;
    return calculate(
      symbol: symbol,
      side: side,
      entry: entry,
      exit: tp,
      lot: lot,
    );
  }
}
