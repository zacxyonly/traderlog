import 'dart:convert';
import 'dart:io';

class CurrencyService {
  /// Fetches the latest live exchange rate between [baseCurrency] and [targetCurrency]
  /// using open.er-api.com (free, reliable, no API key required).
  ///
  /// Returns `null` if the device is offline or if an error occurs.
  static Future<double?> fetchExchangeRate({
    required String baseCurrency,
    required String targetCurrency,
  }) async {
    final base = _normalizeCurrency(baseCurrency);
    final target = _normalizeCurrency(targetCurrency);

    if (base == target) {
      return 1.0;
    }

    HttpClient? client;
    try {
      client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
      final uri = Uri.parse('https://open.er-api.com/v6/latest/$base');
      final request = await client.getUrl(uri);
      final response = await request.close();

      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final Map<String, dynamic> data = jsonDecode(body);

        if (data['result'] == 'success' && data['rates'] is Map) {
          final rates = data['rates'] as Map<String, dynamic>;
          final dynamic rateVal = rates[target];

          if (rateVal is num) {
            return rateVal.toDouble();
          }
        }
      }
    } catch (_) {
      // Offline, network timeout, or socket exception
    } finally {
      client?.close(force: true);
    }

    return null;
  }

  /// Maps stablecoins (USDC, USDT) to USD for FX market lookups
  static String _normalizeCurrency(String currency) {
    final upper = currency.trim().toUpperCase();
    if (upper == 'USDC' || upper == 'USDT') {
      return 'USD';
    }
    return upper;
  }
}
