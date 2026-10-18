import 'package:intl/intl.dart';

class Formatters {
  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  /// Returns the currency symbol for a given currency code
  static String getCurrencySymbol(String currencyCode) {
    switch (currencyCode.toUpperCase()) {
      case 'IDR':
        return 'Rp ';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'JPY':
        return '¥';
      case 'SGD':
        return 'S\$';
      case 'AUD':
        return 'A\$';
      case 'USDC':
        return 'USDC ';
      case 'USDT':
        return 'USDT ';
      case 'USD':
      default:
        return '\$';
    }
  }

  /// Formats amount in any currency: e.g. $1,250.00 or Rp 18.000.000
  static String formatAmount(double amount, {String currency = 'USD'}) {
    final cur = currency.toUpperCase();
    final symbol = getCurrencySymbol(cur);
    final isZeroDecimal = cur == 'IDR' || cur == 'JPY';

    final formatter = NumberFormat.currency(
      locale: cur == 'IDR' ? 'id_ID' : 'en_US',
      symbol: symbol,
      decimalDigits: isZeroDecimal ? 0 : 2,
    );

    if (amount < 0) {
      return '-${formatter.format(amount.abs())}';
    }
    return formatter.format(amount);
  }

  /// Formats amount with explicit +/- sign in any currency: +$1,250.00 or -Rp 50.000
  static String formatAmountSigned(double amount, {String currency = 'USD'}) {
    final cur = currency.toUpperCase();
    final symbol = getCurrencySymbol(cur);
    final isZeroDecimal = cur == 'IDR' || cur == 'JPY';

    final formatter = NumberFormat.currency(
      locale: cur == 'IDR' ? 'id_ID' : 'en_US',
      symbol: symbol,
      decimalDigits: isZeroDecimal ? 0 : 2,
    );

    if (amount > 0) {
      return '+${formatter.format(amount)}';
    } else if (amount < 0) {
      return '-${formatter.format(amount.abs())}';
    }
    return formatter.format(0.0);
  }

  /// Formats currency in USD: $1,250.00 or -$50.00
  static String formatUSD(double amount) {
    return formatAmount(amount, currency: 'USD');
  }

  /// Formats currency with explicit plus/minus: +$1,250.00 or -$50.00
  static String formatUSDSigned(double amount) {
    return formatAmountSigned(amount, currency: 'USD');
  }

  /// Formats currency in Indonesian Rupiah: Rp 22.497.500
  static String formatIDR(double amount) {
    return formatAmount(amount, currency: 'IDR');
  }

  /// Formats percentage: +2.50% or -1.20%
  static String formatPercent(double ratio, {bool signed = true}) {
    final pct = ratio * 100;
    if (signed && pct > 0) {
      return '+${pct.toStringAsFixed(2)}%';
    }
    return '${pct.toStringAsFixed(2)}%';
  }

  /// Formats date and time: 17 Okt 2026, 18:30 (or 17 Oct 2026, 18:30)
  static String formatDateTime(DateTime dateTime, {String? locale}) {
    try {
      final loc = locale == 'en' ? 'en_US' : 'id_ID';
      return DateFormat('dd MMM yyyy, HH:mm', loc).format(dateTime);
    } catch (_) {
      return DateFormat('dd MMM yyyy, HH:mm').format(dateTime);
    }
  }

  /// Formats month and year: Oktober 2026 (or October 2026)
  static String formatMonthYear(DateTime dateTime, {String? locale}) {
    try {
      final loc = locale == 'en' ? 'en_US' : 'id_ID';
      return DateFormat('MMMM yyyy', loc).format(dateTime);
    } catch (_) {
      return DateFormat('MMMM yyyy').format(dateTime);
    }
  }

  /// Formats date for CSV: 2026-10-17
  static String formatDate(DateTime dateTime) {
    return _dateFormat.format(dateTime);
  }
}
