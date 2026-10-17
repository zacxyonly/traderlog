import 'package:intl/intl.dart';

class Formatters {
  static final NumberFormat _usdFormat = NumberFormat.currency(
    locale: 'en_US',
    symbol: '\$',
    decimalDigits: 2,
  );

  static final NumberFormat _idrFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static final DateFormat _dateTimeFormat = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');
  static final DateFormat _monthYearFormat = DateFormat('MMMM yyyy', 'id_ID');
  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  /// Formats currency in USD: $1,250.00 or -$50.00
  static String formatUSD(double amount) {
    if (amount < 0) {
      return '-${_usdFormat.format(amount.abs())}';
    }
    return _usdFormat.format(amount);
  }

  /// Formats currency with explicit plus/minus: +$1,250.00 or -$50.00
  static String formatUSDSigned(double amount) {
    if (amount > 0) {
      return '+${_usdFormat.format(amount)}';
    } else if (amount < 0) {
      return '-${_usdFormat.format(amount.abs())}';
    }
    return _usdFormat.format(0.0);
  }

  /// Formats currency in Indonesian Rupiah: Rp 22.497.500
  static String formatIDR(double amount) {
    return _idrFormat.format(amount.round());
  }

  /// Formats percentage: +2.50% or -1.20%
  static String formatPercent(double ratio, {bool signed = true}) {
    final pct = ratio * 100;
    if (signed && pct > 0) {
      return '+${pct.toStringAsFixed(2)}%';
    }
    return '${pct.toStringAsFixed(2)}%';
  }

  /// Formats date and time: 17 Okt 2026, 18:30
  static String formatDateTime(DateTime dateTime) {
    try {
      return _dateTimeFormat.format(dateTime);
    } catch (_) {
      return DateFormat('dd MMM yyyy, HH:mm').format(dateTime);
    }
  }

  /// Formats month and year: Oktober 2026
  static String formatMonthYear(DateTime dateTime) {
    try {
      return _monthYearFormat.format(dateTime);
    } catch (_) {
      return DateFormat('MMMM yyyy').format(dateTime);
    }
  }

  /// Formats date for CSV: 2026-10-17
  static String formatDate(DateTime dateTime) {
    return _dateFormat.format(dateTime);
  }
}
