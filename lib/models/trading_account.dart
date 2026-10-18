import 'dart:convert';

class TradingAccount {
  final String id;
  final String name;
  final String type; // 'real', 'demo', 'prop_firm'
  final double initialCapital;
  final String currency;

  /// Batas risiko per trade dalam persen (1.0 = 1%). null = tidak diatur.
  final double? maxRiskPercent;

  /// Batas kerugian harian dalam persen saldo awal hari. Khusus prop firm.
  final double? dailyLossLimitPercent;

  /// Batas drawdown total dalam persen dari modal awal. Khusus prop firm.
  final double? maxDrawdownPercent;

  const TradingAccount({
    required this.id,
    required this.name,
    this.type = 'real',
    this.initialCapital = 1000.0,
    this.currency = 'USD',
    this.maxRiskPercent,
    this.dailyLossLimitPercent,
    this.maxDrawdownPercent,
  });

  String get typeLabel {
    switch (type.toLowerCase()) {
      case 'demo':
        return 'DEMO';
      case 'prop_firm':
        return 'PROP FIRM';
      case 'real':
      default:
        return 'REAL';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'initialCapital': initialCapital,
      'currency': currency,
      'maxRiskPercent': maxRiskPercent,
      'dailyLossLimitPercent': dailyLossLimitPercent,
      'maxDrawdownPercent': maxDrawdownPercent,
    };
  }

  factory TradingAccount.fromMap(Map<String, dynamic> map) {
    return TradingAccount(
      id: map['id'] as String? ?? 'acc_real',
      name: map['name'] as String? ?? 'Akun Real',
      type: map['type'] as String? ?? 'real',
      initialCapital: (map['initialCapital'] as num?)?.toDouble() ?? 1000.0,
      currency: map['currency'] as String? ?? 'USD',
      maxRiskPercent: (map['maxRiskPercent'] as num?)?.toDouble(),
      dailyLossLimitPercent: (map['dailyLossLimitPercent'] as num?)?.toDouble(),
      maxDrawdownPercent: (map['maxDrawdownPercent'] as num?)?.toDouble(),
    );
  }

  TradingAccount copyWith({
    String? id,
    String? name,
    String? type,
    double? initialCapital,
    String? currency,
    double? maxRiskPercent,
    double? dailyLossLimitPercent,
    double? maxDrawdownPercent,
  }) {
    return TradingAccount(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      initialCapital: initialCapital ?? this.initialCapital,
      currency: currency ?? this.currency,
      maxRiskPercent: maxRiskPercent ?? this.maxRiskPercent,
      dailyLossLimitPercent:
          dailyLossLimitPercent ?? this.dailyLossLimitPercent,
      maxDrawdownPercent: maxDrawdownPercent ?? this.maxDrawdownPercent,
    );
  }

  /// Menetapkan seluruh aturan risiko sekaligus. Nilai null berarti dihapus.
  TradingAccount withRiskRules({
    double? maxRiskPercent,
    double? dailyLossLimitPercent,
    double? maxDrawdownPercent,
  }) {
    return TradingAccount(
      id: id,
      name: name,
      type: type,
      initialCapital: initialCapital,
      currency: currency,
      maxRiskPercent: maxRiskPercent,
      dailyLossLimitPercent: dailyLossLimitPercent,
      maxDrawdownPercent: maxDrawdownPercent,
    );
  }

  static List<TradingAccount> defaultAccounts() {
    return const [
      TradingAccount(
        id: 'acc_real',
        name: 'Akun Real Utama',
        type: 'real',
        initialCapital: 1000.0,
        currency: 'USD',
      ),
      TradingAccount(
        id: 'acc_demo',
        name: 'Akun Latihan Demo',
        type: 'demo',
        initialCapital: 10000.0,
        currency: 'USD',
      ),
      TradingAccount(
        id: 'acc_prop',
        name: 'Evaluasi Prop Firm',
        type: 'prop_firm',
        initialCapital: 50000.0,
        currency: 'USD',
      ),
    ];
  }

  static String encodeList(List<TradingAccount> accounts) {
    return jsonEncode(accounts.map((a) => a.toMap()).toList());
  }

  static List<TradingAccount> decodeList(String? jsonStr) {
    if (jsonStr == null || jsonStr.trim().isEmpty) {
      return defaultAccounts();
    }
    try {
      final decoded = jsonDecode(jsonStr) as List<dynamic>;
      final list = decoded
          .map((item) => TradingAccount.fromMap(item as Map<String, dynamic>))
          .toList();
      return list.isNotEmpty ? list : defaultAccounts();
    } catch (_) {
      return defaultAccounts();
    }
  }
}
