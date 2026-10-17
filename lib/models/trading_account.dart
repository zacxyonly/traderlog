import 'dart:convert';

class TradingAccount {
  final String id;
  final String name;
  final String type; // 'real', 'demo', 'prop_firm'
  final double initialCapital;
  final String currency;

  const TradingAccount({
    required this.id,
    required this.name,
    this.type = 'real',
    this.initialCapital = 1000.0,
    this.currency = 'USD',
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
    };
  }

  factory TradingAccount.fromMap(Map<String, dynamic> map) {
    return TradingAccount(
      id: map['id'] as String? ?? 'acc_real',
      name: map['name'] as String? ?? 'Akun Real',
      type: map['type'] as String? ?? 'real',
      initialCapital: (map['initialCapital'] as num?)?.toDouble() ?? 1000.0,
      currency: map['currency'] as String? ?? 'USD',
    );
  }

  TradingAccount copyWith({
    String? id,
    String? name,
    String? type,
    double? initialCapital,
    String? currency,
  }) {
    return TradingAccount(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      initialCapital: initialCapital ?? this.initialCapital,
      currency: currency ?? this.currency,
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
