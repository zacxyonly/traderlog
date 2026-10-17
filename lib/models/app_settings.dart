import 'dart:convert';
import 'package:flutter/material.dart';

class AppSettings {
  final double initialCapital;
  final double usdToIdrRate;
  final ThemeMode themeMode;
  final List<String> symbols;

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
    this.initialCapital = 1000.0,
    this.usdToIdrRate = 17998.0,
    this.themeMode = ThemeMode.system,
    List<String>? symbols,
  }) : symbols = symbols ?? List.from(defaultSymbols);

  AppSettings copyWith({
    double? initialCapital,
    double? usdToIdrRate,
    ThemeMode? themeMode,
    List<String>? symbols,
  }) {
    return AppSettings(
      initialCapital: initialCapital ?? this.initialCapital,
      usdToIdrRate: usdToIdrRate ?? this.usdToIdrRate,
      themeMode: themeMode ?? this.themeMode,
      symbols: symbols ?? List.from(this.symbols),
    );
  }

  Map<String, String> toDatabaseMap() {
    return {
      'initial_capital': initialCapital.toString(),
      'usd_to_idr_rate': usdToIdrRate.toString(),
      'theme_mode': themeMode.name,
      'symbols': jsonEncode(symbols),
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

    return AppSettings(
      initialCapital: double.tryParse(map['initial_capital'] ?? '') ?? 1000.0,
      usdToIdrRate: double.tryParse(map['usd_to_idr_rate'] ?? '') ?? 17998.0,
      themeMode: mode,
      symbols: syms,
    );
  }
}
