import '../models/trade.dart';

class PnlResult {
  /// Profit/loss in the account currency (USD). `null` when it cannot be
  /// computed reliably (e.g. a cross pair such as EUR/GBP, which needs a
  /// live GBP->USD rate that the app does not have). In that case [pips] is
  /// still valid and the user must type the P/L manually.
  final double? pnl;
  final double pips;
  final String pipUnit; // 'pips' or 'pts'

  const PnlResult({
    required this.pnl,
    required this.pips,
    required this.pipUnit,
  });

  bool get hasPnl => pnl != null;

  String get formattedPips {
    final prefix = pips > 0 ? '+' : '';
    return '$prefix${pips.toStringAsFixed(1)} $pipUnit';
  }
}

class PnlCalculator {
  /// Contract size of 1 standard forex lot (units of base currency).
  static const double forexContractSize = 100000.0;

  /// Account currencies that can be treated as USD for P/L purposes.
  static const Set<String> _usdLike = {'USD', 'USDT', 'USDC'};

  static const Set<String> _knownCurrencies = {
    'USD', 'EUR', 'GBP', 'JPY', 'CHF', 'CAD', 'AUD', 'NZD', //
    'SGD', 'HKD', 'SEK', 'NOK', 'DKK', 'PLN', 'CZK', 'HUF',
    'TRY', 'ZAR', 'MXN', 'CNH', 'CNY', 'THB', 'ILS',
  };

  static String _normalize(String symbol) =>
      symbol.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

  /// Determines asset type based on symbol.
  /// Returns 'gold', 'crypto' (crypto & indices), 'forex', or 'unknown'.
  /// 'unknown' means the app cannot derive pips/P&L safely (custom symbols,
  /// silver, exotic instruments ...).
  static String getAssetType(String symbol) {
    final sym = _normalize(symbol);
    if (sym.contains('XAU') || sym.contains('GOLD')) {
      return 'gold';
    }
    if (sym.contains('BTC') ||
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
    }
    if (_forexPair(sym) != null) return 'forex';
    return 'unknown';
  }

  /// Returns [base, quote] for a recognised forex pair, else null.
  static List<String>? _forexPair(String normalized) {
    if (normalized.length < 6) return null;
    final base = normalized.substring(0, 3);
    final quote = normalized.substring(3, 6);
    if (!_knownCurrencies.contains(base) || !_knownCurrencies.contains(quote)) {
      return null;
    }
    if (base == quote) return null;
    return [base, quote];
  }

  /// Unit label used for the symbol: 'pts' for crypto/indices, else 'pips'.
  static String unitFor(String symbol) =>
      getAssetType(symbol) == 'crypto' ? 'pts' : 'pips';

  /// Pips/points moved in the trade's favour (negative = against).
  /// Returns null when the symbol is not recognised.
  static double? pipsFor({
    required String symbol,
    required TradeSide side,
    required double entry,
    required double exit,
  }) {
    final diff = (side == TradeSide.buy) ? (exit - entry) : (entry - exit);
    switch (getAssetType(symbol)) {
      case 'gold':
        // 1 pip in gold = $0.10 move (10 pips = $1.00 move)
        return diff * 10.0;
      case 'crypto':
        return diff;
      case 'forex':
        final pair = _forexPair(_normalize(symbol))!;
        final pipSize = pair[1] == 'JPY' ? 0.01 : 0.0001;
        return diff / pipSize;
      default:
        return null;
    }
  }

  /// Calculates P&L (account currency) and pips/points between two prices.
  ///
  /// Assumptions (standard CFD/spot contract specs):
  ///  - Forex: 1 lot = 100,000 units of the base currency.
  ///  - Gold:  1 lot = 100 oz, quoted in USD.
  ///  - Crypto / indices: 1 point = $1 per 1.0 lot.
  ///  - The account currency is USD (or USDT/USDC). For any other account
  ///    currency, [PnlResult.pnl] is null.
  static PnlResult? calculate({
    required String symbol,
    required TradeSide side,
    required double? entry,
    required double? exit,
    required double? lot,
    String accountCurrency = 'USD',
  }) {
    if (entry == null || exit == null || lot == null || lot <= 0) {
      return null;
    }

    final pips = pipsFor(symbol: symbol, side: side, entry: entry, exit: exit);
    if (pips == null) return null;

    final diff = (side == TradeSide.buy) ? (exit - entry) : (entry - exit);
    final unit = unitFor(symbol);
    final usdAccount = _usdLike.contains(accountCurrency.toUpperCase());

    double? pnl;
    if (usdAccount) {
      switch (getAssetType(symbol)) {
        case 'gold':
          pnl = diff * 100.0 * lot;
          break;
        case 'crypto':
          pnl = diff * lot;
          break;
        case 'forex':
          final pair = _forexPair(_normalize(symbol))!;
          // P/L is first expressed in the quote currency.
          final inQuote = diff * forexContractSize * lot;
          if (pair[1] == 'USD') {
            // EUR/USD, GBP/USD, AUD/USD ... quote is already USD.
            pnl = inQuote;
          } else if (pair[0] == 'USD' && exit > 0) {
            // USD/JPY, USD/CHF, USD/CAD ... convert quote -> USD using the
            // USD/quote rate at the closing price.
            pnl = inQuote / exit;
          } else {
            // Cross pair (EUR/GBP, GBP/JPY ...): needs an external quote->USD
            // rate. Do not guess.
            pnl = null;
          }
          break;
      }
    }

    return PnlResult(pnl: pnl, pips: pips, pipUnit: unit);
  }

  /// Calculates planned risk from Entry to Stop Loss
  static PnlResult? calculateRisk({
    required String symbol,
    required TradeSide side,
    required double? entry,
    required double? sl,
    required double? lot,
    String accountCurrency = 'USD',
  }) {
    if (entry == null || sl == null || lot == null || lot <= 0) return null;
    return calculate(
      symbol: symbol,
      side: side,
      entry: entry,
      exit: sl,
      lot: lot,
      accountCurrency: accountCurrency,
    );
  }

  /// Calculates planned reward from Entry to Take Profit
  static PnlResult? calculateReward({
    required String symbol,
    required TradeSide side,
    required double? entry,
    required double? tp,
    required double? lot,
    String accountCurrency = 'USD',
  }) {
    if (entry == null || tp == null || lot == null || lot <= 0) return null;
    return calculate(
      symbol: symbol,
      side: side,
      entry: entry,
      exit: tp,
      lot: lot,
      accountCurrency: accountCurrency,
    );
  }
}
