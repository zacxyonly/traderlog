import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'trading_account.dart';

class AppSettings {
  final String traderName;
  final String languageCode;
  final String accountCurrency;
  final String exchangeCurrency;
  final double initialCapital;
  static const Object _sentinel = Object();

  final double exchangeRate;
  double get usdToIdrRate => exchangeRate;
  final ThemeMode themeMode;
  final List<String> symbols;

  // Multi-Account & Security
  final String activeAccountId;
  final List<TradingAccount> accounts;
  final String? pinCode;
  final bool isBiometricEnabled;
  final String? lastBackupDate;

  static const List<String> defaultSymbols = [
    'XAU/USD',
    'EUR/USD',
    'GBP/USD',
    'USD/JPY',
    'BTC/USD',
    'ETH/USD',
    'USTEC',
    'US30',
    'US500',
  ];

  AppSettings({
    this.traderName = 'TraderLog',
    this.languageCode = 'id',
    this.accountCurrency = 'USD',
    this.exchangeCurrency = 'IDR',
    this.initialCapital = 1000.0,
    double? exchangeRate,
    double? usdToIdrRate,
    this.themeMode = ThemeMode.system,
    List<String>? symbols,
    this.activeAccountId = 'acc_real',
    List<TradingAccount>? accounts,
    this.pinCode,
    this.isBiometricEnabled = false,
    this.lastBackupDate,
  })  : exchangeRate = exchangeRate ?? usdToIdrRate ?? 16000.0,
        symbols = symbols ?? List.from(defaultSymbols),
        accounts = accounts ?? TradingAccount.defaultAccounts();

  TradingAccount get activeAccount {
    return accounts.firstWhere(
      (a) => a.id == activeAccountId,
      orElse: () => accounts.isNotEmpty ? accounts.first : TradingAccount.defaultAccounts().first,
    );
  }

  bool get isPinSet => pinCode != null && pinCode!.trim().isNotEmpty;

  /// Generates a salted SHA-256 hash for PIN code
  static String hashPin(String pin) {
    const salt = 'traderlog_pin_salt_v1';
    final bytes = utf8.encode('$salt$pin');
    return sha256.convert(bytes).toString();
  }

  /// Verifies entered PIN against stored PIN or Hash with backward compatibility
  static bool verifyPin(String enteredPin, String? storedPinOrHash) {
    if (storedPinOrHash == null || storedPinOrHash.isEmpty) return false;
    if (storedPinOrHash.length == 64 &&
        RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(storedPinOrHash)) {
      return hashPin(enteredPin) == storedPinOrHash.toLowerCase();
    }
    return enteredPin == storedPinOrHash;
  }

  AppSettings copyWith({
    String? traderName,
    String? languageCode,
    String? accountCurrency,
    String? exchangeCurrency,
    double? initialCapital,
    double? usdToIdrRate,
    double? exchangeRate,
    ThemeMode? themeMode,
    List<String>? symbols,
    String? activeAccountId,
    List<TradingAccount>? accounts,
    Object? pinCode = _sentinel,
    bool? isBiometricEnabled,
    Object? lastBackupDate = _sentinel,
  }) {
    final rate = exchangeRate ?? usdToIdrRate ?? this.exchangeRate;
    return AppSettings(
      traderName: traderName ?? this.traderName,
      languageCode: languageCode ?? this.languageCode,
      accountCurrency: accountCurrency ?? this.accountCurrency,
      exchangeCurrency: exchangeCurrency ?? this.exchangeCurrency,
      initialCapital: initialCapital ?? this.initialCapital,
      exchangeRate: rate,
      themeMode: themeMode ?? this.themeMode,
      symbols: symbols ?? List.from(this.symbols),
      activeAccountId: activeAccountId ?? this.activeAccountId,
      accounts: accounts ?? List.from(this.accounts),
      pinCode: identical(pinCode, _sentinel) ? this.pinCode : pinCode as String?,
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      lastBackupDate: identical(lastBackupDate, _sentinel)
          ? this.lastBackupDate
          : lastBackupDate as String?,
    );
  }

  Map<String, String> toDatabaseMap() {
    return {
      'trader_name': traderName,
      'language_code': languageCode,
      'account_currency': accountCurrency,
      'exchange_currency': exchangeCurrency,
      'initial_capital': initialCapital.toString(),
      'usd_to_idr_rate': exchangeRate.toString(),
      'exchange_rate': exchangeRate.toString(),
      'theme_mode': themeMode.name,
      'symbols': jsonEncode(symbols),
      'active_account_id': activeAccountId,
      'accounts': TradingAccount.encodeList(accounts),
      'pin_code': pinCode ?? '',
      'is_biometric_enabled': isBiometricEnabled ? 'true' : 'false',
      'last_backup_date': lastBackupDate ?? '',
    };
  }

  factory AppSettings.fromDatabaseMap(Map<String, String> map) {
    ThemeMode mode = ThemeMode.system;
    if (map['theme_mode'] == 'dark') {
      mode = ThemeMode.dark;
    } else if (map['theme_mode'] == 'light') {
      mode = ThemeMode.light;
    }

    List<String> syms = List.from(defaultSymbols);
    if (map['symbols'] != null && map['symbols']!.isNotEmpty) {
      try {
        final decoded = jsonDecode(map['symbols']!) as List<dynamic>;
        syms = decoded.map((e) => e.toString()).toList();
      } catch (_) {}
    }

    final accounts = TradingAccount.decodeList(map['accounts']);
    final activeAccId = map['active_account_id']?.isNotEmpty == true
        ? map['active_account_id']!
        : 'acc_real';

    final pin = (map['pin_code']?.trim().isNotEmpty == true)
        ? map['pin_code']!.trim()
        : null;

    final isBio = map['is_biometric_enabled'] == 'true';

    return AppSettings(
      traderName: map['trader_name']?.trim().isNotEmpty == true
          ? map['trader_name']!
          : 'TraderLog',
      languageCode: map['language_code'] ?? 'id',
      accountCurrency: (map['account_currency']?.trim().isNotEmpty == true)
          ? map['account_currency']!
          : 'USD',
      exchangeCurrency: (map['exchange_currency']?.trim().isNotEmpty == true)
          ? map['exchange_currency']!
          : 'IDR',
      initialCapital: double.tryParse(map['initial_capital'] ?? '') ?? 1000.0,
      exchangeRate: double.tryParse(map['exchange_rate'] ?? map['usd_to_idr_rate'] ?? '') ?? 16000.0,
      themeMode: mode,
      symbols: syms,
      activeAccountId: activeAccId,
      accounts: accounts,
      pinCode: pin,
      isBiometricEnabled: isBio,
      lastBackupDate: map['last_backup_date'],
    );
  }
}

