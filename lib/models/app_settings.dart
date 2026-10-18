import 'dart:convert';
import 'package:flutter/material.dart';
import '../utils/pin_hasher.dart';
import 'trading_account.dart';

class AppSettings {
  final String traderName;
  final String languageCode;
  final String accountCurrency;
  final String exchangeCurrency;
  final double initialCapital;
  final double usdToIdrRate;
  final ThemeMode themeMode;
  final List<String> symbols;

  // Multi-Account & Security
  final String activeAccountId;
  final List<TradingAccount> accounts;
  /// Salted hash of the PIN (see [PinHasher]). Never the PIN itself.
  final String? pinHash;
  final bool isBiometricEnabled;
  final String? lastBackupDate;

  // Preferences
  final bool hideBalance; // privacy mode: mask balance & P/L
  final bool hapticEnabled; // light vibration feedback
  final int autoLockSeconds; // 0 = lock immediately when app goes to background
  final bool weekStartsMonday; // calendar week start
  final double defaultLot; // prefilled lot in new trade form (0 = off)

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
    this.usdToIdrRate = 17998.0,
    this.themeMode = ThemeMode.system,
    List<String>? symbols,
    this.activeAccountId = 'acc_real',
    List<TradingAccount>? accounts,
    this.pinHash,
    this.isBiometricEnabled = false,
    this.lastBackupDate,
    this.hideBalance = false,
    this.hapticEnabled = true,
    this.autoLockSeconds = 0,
    this.weekStartsMonday = false,
    this.defaultLot = 0.0,
  })  : symbols = symbols ?? List.from(defaultSymbols),
        accounts = accounts ?? TradingAccount.defaultAccounts();

  TradingAccount get activeAccount {
    return accounts.firstWhere(
      (a) => a.id == activeAccountId,
      orElse: () => accounts.isNotEmpty ? accounts.first : TradingAccount.defaultAccounts().first,
    );
  }

  bool get isPinSet => pinHash != null && pinHash!.trim().isNotEmpty;

  /// True when the stored PIN is still a plaintext value from an old version.
  bool get hasLegacyPlainPin => isPinSet && !PinHasher.isHashed(pinHash);

  AppSettings copyWith({
    String? traderName,
    String? languageCode,
    String? accountCurrency,
    String? exchangeCurrency,
    double? initialCapital,
    double? usdToIdrRate,
    ThemeMode? themeMode,
    List<String>? symbols,
    String? activeAccountId,
    List<TradingAccount>? accounts,
    String? pinHash,
    bool? isBiometricEnabled,
    String? lastBackupDate,
    bool? hideBalance,
    bool? hapticEnabled,
    int? autoLockSeconds,
    bool? weekStartsMonday,
    double? defaultLot,
    bool clearPin = false,
  }) {
    return AppSettings(
      traderName: traderName ?? this.traderName,
      languageCode: languageCode ?? this.languageCode,
      accountCurrency: accountCurrency ?? this.accountCurrency,
      exchangeCurrency: exchangeCurrency ?? this.exchangeCurrency,
      initialCapital: initialCapital ?? this.initialCapital,
      usdToIdrRate: usdToIdrRate ?? this.usdToIdrRate,
      themeMode: themeMode ?? this.themeMode,
      symbols: symbols ?? List.from(this.symbols),
      activeAccountId: activeAccountId ?? this.activeAccountId,
      accounts: accounts ?? List.from(this.accounts),
      pinHash: clearPin ? null : (pinHash ?? this.pinHash),
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      lastBackupDate: lastBackupDate ?? this.lastBackupDate,
      hideBalance: hideBalance ?? this.hideBalance,
      hapticEnabled: hapticEnabled ?? this.hapticEnabled,
      autoLockSeconds: autoLockSeconds ?? this.autoLockSeconds,
      weekStartsMonday: weekStartsMonday ?? this.weekStartsMonday,
      defaultLot: defaultLot ?? this.defaultLot,
    );
  }

  Map<String, String> toDatabaseMap() {
    return {
      'trader_name': traderName,
      'language_code': languageCode,
      'account_currency': accountCurrency,
      'exchange_currency': exchangeCurrency,
      'initial_capital': initialCapital.toString(),
      'usd_to_idr_rate': usdToIdrRate.toString(),
      'theme_mode': themeMode.name,
      'symbols': jsonEncode(symbols),
      'active_account_id': activeAccountId,
      'accounts': TradingAccount.encodeList(accounts),
      // Key name kept for compatibility with existing databases.
      'pin_code': pinHash ?? '',
      'is_biometric_enabled': isBiometricEnabled ? 'true' : 'false',
      'last_backup_date': lastBackupDate ?? '',
      'hide_balance': hideBalance ? 'true' : 'false',
      'haptic_enabled': hapticEnabled ? 'true' : 'false',
      'auto_lock_seconds': autoLockSeconds.toString(),
      'week_starts_monday': weekStartsMonday ? 'true' : 'false',
      'default_lot': defaultLot.toString(),
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
      usdToIdrRate: double.tryParse(map['usd_to_idr_rate'] ?? '') ?? 17998.0,
      themeMode: mode,
      symbols: syms,
      activeAccountId: activeAccId,
      accounts: accounts,
      pinHash: pin,
      isBiometricEnabled: isBio,
      lastBackupDate: map['last_backup_date'],
      hideBalance: map['hide_balance'] == 'true',
      hapticEnabled: map['haptic_enabled'] != 'false',
      autoLockSeconds: const [0, 30, 60, 300]
              .contains(int.tryParse(map['auto_lock_seconds'] ?? ''))
          ? int.parse(map['auto_lock_seconds']!)
          : 0,
      weekStartsMonday: map['week_starts_monday'] == 'true',
      defaultLot: (double.tryParse(map['default_lot'] ?? '') ?? 0.0) > 0
          ? double.parse(map['default_lot']!)
          : 0.0,
    );
  }
}
