import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/trading_account.dart';
import '../providers/trade_provider.dart';
import '../services/csv_service.dart';
import '../utils/app_strings.dart';
import '../utils/formatters.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _selectedCategoryIndex = 0; // 0: Profil, 1: Akun, 2: Keamanan, 3: Tampilan, 4: Simbol, 5: Data

  static const List<Map<String, String>> _accountCurrencies = [
    {'code': 'USD', 'symbol': '\$', 'name': 'US Dollar'},
    {'code': 'IDR', 'symbol': 'Rp', 'name': 'Indonesian Rupiah'},
    {'code': 'USDC', 'symbol': '\$', 'name': 'USD Coin'},
    {'code': 'USDT', 'symbol': '\$', 'name': 'Tether USD'},
    {'code': 'EUR', 'symbol': '€', 'name': 'Euro'},
    {'code': 'GBP', 'symbol': '£', 'name': 'British Pound'},
    {'code': 'JPY', 'symbol': '¥', 'name': 'Japanese Yen'},
    {'code': 'SGD', 'symbol': 'S\$', 'name': 'Singapore Dollar'},
    {'code': 'AUD', 'symbol': 'A\$', 'name': 'Australian Dollar'},
  ];

  static const List<Map<String, String>> _exchangeCurrencies = [
    {'code': 'IDR', 'symbol': 'Rp', 'name': 'Indonesian Rupiah'},
    {'code': 'USD', 'symbol': '\$', 'name': 'US Dollar'},
    {'code': 'EUR', 'symbol': '€', 'name': 'Euro'},
    {'code': 'SGD', 'symbol': 'S\$', 'name': 'Singapore Dollar'},
    {'code': 'JPY', 'symbol': '¥', 'name': 'Japanese Yen'},
  ];

  static const List<Map<String, String>> _languages = [
    {'code': 'id', 'name': '🇮🇩 Bahasa Indonesia'},
    {'code': 'en', 'name': '🇬🇧 English'},
  ];

  final _capController = TextEditingController();
  final _fxController = TextEditingController();
  final _newSymbolController = TextEditingController();

  String _formatRate(double rate) {
    if (rate >= 100) {
      return rate == rate.roundToDouble()
          ? rate.toStringAsFixed(0)
          : rate.toStringAsFixed(2);
    } else if (rate >= 1) {
      return rate
          .toStringAsFixed(4)
          .replaceAll(RegExp(r'0+$'), '')
          .replaceAll(RegExp(r'\.$'), '');
    } else {
      return rate
          .toStringAsFixed(6)
          .replaceAll(RegExp(r'0+$'), '')
          .replaceAll(RegExp(r'\.$'), '');
    }
  }

  @override
  void initState() {
    super.initState();
    final provider = context.read<TradeProvider>();
    final settings = provider.settings;
    _capController.text = provider.activeAccount.initialCapital.toStringAsFixed(0);
    _fxController.text = _formatRate(settings.usdToIdrRate);
  }

  Future<void> _syncRate(String lang) async {
    final provider = context.read<TradeProvider>();
    final newRate = await provider.syncExchangeRate();
    if (!mounted) return;
    if (newRate != null) {
      _fxController.text = _formatRate(newRate);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: Text(
            AppStrings.tr(
              'rate_synced',
              lang,
              params: {
                'base': provider.activeAccount.currency,
                'target': provider.settings.exchangeCurrency,
                'rate': _formatRate(newRate),
              },
            ),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: Text(AppStrings.tr('rate_sync_failed', lang)),
        ),
      );
    }
  }

  @override
  void dispose() {
    _capController.dispose();
    _fxController.dispose();
    _newSymbolController.dispose();
    super.dispose();
  }

  void _saveCapital() {
    final cap = double.tryParse(_capController.text.trim());
    if (cap != null && cap > 0) {
      final provider = context.read<TradeProvider>();
      final updated = provider.activeAccount.copyWith(initialCapital: cap);
      provider.updateAccount(updated);
    }
  }

  void _saveFx() {
    final fx = double.tryParse(_fxController.text.trim());
    if (fx != null && fx > 0) {
      final provider = context.read<TradeProvider>();
      provider.updateSettings(provider.settings.copyWith(usdToIdrRate: fx));
    }
  }

  void _setTheme(ThemeMode mode) {
    final provider = context.read<TradeProvider>();
    provider.updateSettings(provider.settings.copyWith(themeMode: mode));
  }

  void _setLanguage(String langCode) {
    final provider = context.read<TradeProvider>();
    provider.updateLanguage(langCode);
  }

  void _addSymbol() {
    final sym = _newSymbolController.text.trim().toUpperCase();
    if (sym.isNotEmpty) {
      context.read<TradeProvider>().addSymbol(sym);
      _newSymbolController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  void _confirmRemoveSymbol(String symbol, String lang) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.tr('delete_symbol_title', lang)),
        content: Text(
          AppStrings.tr(
            'delete_symbol_msg',
            lang,
            params: {'s': symbol},
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppStrings.tr('cancel', lang)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<TradeProvider>().removeSymbol(symbol);
            },
            child: Text(
              AppStrings.tr('delete', lang),
              style: const TextStyle(color: AppColors.lose),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportCSV(String lang) async {
    final provider = context.read<TradeProvider>();
    if (provider.trades.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.tr('no_trades_export', lang))),
      );
      return;
    }

    provider.setSystemPickerActive(true);
    try {
      await CSVService.exportTrades(
        trades: provider.trades,
        initialCapital: provider.activeAccount.initialCapital,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${provider.trades.length} ${AppStrings.tr("trades_exported", lang)}',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengekspor CSV: $e')),
        );
      }
    } finally {
      Future.delayed(const Duration(milliseconds: 600), () {
        provider.setSystemPickerActive(false);
      });
    }
  }

  Future<void> _backupToGoogleDrive(String lang) async {
    final provider = context.read<TradeProvider>();
    final trades = provider.allTrades;
    if (trades.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.tr('no_trades_export', lang))),
      );
      return;
    }

    provider.setSystemPickerActive(true);
    try {
      final nowStr = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final accountName = provider.activeAccount.name.replaceAll(' ', '_');
      final fileName = 'TraderLog_CloudBackup_${accountName}_$nowStr.csv';

      await CSVService.exportTrades(
        trades: trades,
        initialCapital: provider.activeAccount.initialCapital,
        customFileName: fileName,
        shareText: 'TraderLog Cloud Backup ($accountName)',
      );

      await provider.recordCloudBackup();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.primary,
            content: Text('Cadangan disiapkan. Pilih Google Drive pada menu berbagi.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuat cadangan cloud: $e')),
        );
      }
    } finally {
      Future.delayed(const Duration(milliseconds: 600), () {
        provider.setSystemPickerActive(false);
      });
    }
  }

  Future<void> _importCSV(String lang) async {
    final provider = context.read<TradeProvider>();
    provider.setSystemPickerActive(true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt'],
      );

      if (result == null || result.files.single.path == null) return;

      final file = File(result.files.single.path!);
      final content = await file.readAsString();

      if (!mounted) return;
      final parseResult = CSVService.parseCSV(
        content,
        existingTrades: provider.trades,
      );

      if (!mounted) return;

      if (parseResult.trades.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              parseResult.duplicates > 0
                  ? 'Semua data di file CSV sudah ada di jurnal (${parseResult.duplicates} duplikat).'
                  : 'Tidak ada data trade valid yang dapat diimpor.',
            ),
          ),
        );
        return;
      }

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(lang == 'en' ? 'Import Confirmation' : 'Konfirmasi Impor CSV'),
          content: Text(
            lang == 'en'
                ? 'Found ${parseResult.trades.length} new trades.\n(${parseResult.duplicates} duplicates skipped, ${parseResult.skipped} invalid rows skipped).\n\nChoose import method:'
                : 'Ditemukan ${parseResult.trades.length} trade baru.\n(${parseResult.duplicates} duplikat dilewati, ${parseResult.skipped} baris tidak valid dilewati).\n\nPilih metode impor:',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(AppStrings.tr('cancel', lang)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                context
                    .read<TradeProvider>()
                    .importTrades(parseResult.trades, replace: false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      lang == 'en'
                          ? 'Successfully imported ${parseResult.trades.length} trades'
                          : '${parseResult.trades.length} trade berhasil digabungkan ke jurnal',
                    ),
                  ),
                );
              },
              child: Text(lang == 'en' ? 'Merge' : 'Gabungkan'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.lose,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                _confirmReplaceAll(parseResult, lang);
              },
              child: Text(lang == 'en' ? 'Replace All' : 'Ganti Semua'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membaca file: $e')),
        );
      }
    } finally {
      Future.delayed(const Duration(milliseconds: 600), () {
        provider.setSystemPickerActive(false);
      });
    }
  }

  void _confirmReplaceAll(CSVImportResult parseResult, String lang) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(lang == 'en' ? 'Replace All Trades?' : 'Ganti Semua Trade?'),
        content: Text(
          lang == 'en'
              ? 'All currently saved trades will be removed and replaced with data from this CSV. Continue?'
              : 'Semua trade yang tersimpan saat ini akan dihapus dan digantikan dengan data dari CSV ini. Lanjutkan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppStrings.tr('cancel', lang)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context
                  .read<TradeProvider>()
                  .importTrades(parseResult.trades, replace: true);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    lang == 'en'
                        ? 'All trades replaced with ${parseResult.trades.length} new trades'
                        : 'Semua trade telah diganti dengan ${parseResult.trades.length} trade baru',
                  ),
                ),
              );
            },
            child: Text(
              lang == 'en' ? 'Replace All' : 'Ganti Semua',
              style: const TextStyle(color: AppColors.lose),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmResetTrades(String lang) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.tr('confirm_reset_title', lang)),
        content: Text(AppStrings.tr('confirm_reset_sub', lang)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppStrings.tr('cancel', lang)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<TradeProvider>().deleteAllTrades();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    lang == 'en'
                        ? 'All trade logs in this account have been cleared'
                        : 'Semua trade pada akun ini telah dihapus',
                  ),
                ),
              );
            },
            child: Text(
              AppStrings.tr('delete', lang),
              style: const TextStyle(color: AppColors.lose),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDisablePin(String lang) {
    final currentPinCtrl = TextEditingController();
    final expectedPin = context.read<TradeProvider>().settings.pinCode;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(AppStrings.tr('disable_pin', lang)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                lang == 'en'
                    ? 'Enter current 4-digit PIN to disable lock:'
                    : 'Masukkan 4 digit PIN saat ini untuk mematikan kunci:',
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: currentPinCtrl,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: lang == 'en' ? 'Current PIN' : 'PIN Saat Ini',
                  counterText: '',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(AppStrings.tr('cancel', lang)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.lose,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (currentPinCtrl.text.trim() == expectedPin) {
                  context.read<TradeProvider>().setPinCode(null);
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppStrings.tr('pin_disabled', lang))),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        lang == 'en' ? 'Incorrect PIN' : 'PIN salah. Gagal mematikan kunci.',
                      ),
                    ),
                  );
                }
              },
              child: Text(AppStrings.tr('disable_pin', lang)),
            ),
          ],
        );
      },
    );
  }

  void _showSetPinDialog(String lang, {bool isChanging = false}) {
    final curPinCtrl = TextEditingController();
    final pin1Ctrl = TextEditingController();
    final pin2Ctrl = TextEditingController();
    final currentExpected = context.read<TradeProvider>().settings.pinCode;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(AppStrings.tr(isChanging ? 'change_pin' : 'setup_pin_title', lang)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isChanging && currentExpected != null) ...[
                  TextField(
                    controller: curPinCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: lang == 'en' ? 'Current PIN' : 'PIN Saat Ini',
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: pin1Ctrl,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: AppStrings.tr('setup_pin_title', lang),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: pin2Ctrl,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: AppStrings.tr('confirm_pin_title', lang),
                    counterText: '',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(AppStrings.tr('cancel', lang)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (isChanging && currentExpected != null) {
                  if (curPinCtrl.text.trim() != currentExpected) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(lang == 'en' ? 'Current PIN is incorrect' : 'PIN saat ini salah')),
                    );
                    return;
                  }
                }
                final p1 = pin1Ctrl.text.trim();
                final p2 = pin2Ctrl.text.trim();
                if (p1.length == 4 && p1 == p2) {
                  context.read<TradeProvider>().setPinCode(p1);
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppStrings.tr(isChanging ? 'pin_changed' : 'pin_enabled', lang)),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppStrings.tr('pin_mismatch', lang)),
                    ),
                  );
                }
              },
              child: Text(AppStrings.tr('save_changes', lang)),
            ),
          ],
        );
      },
    );
  }

  void _showAddAccountDialog(BuildContext context, String lang) {
    final nameCtrl = TextEditingController();
    final capCtrl = TextEditingController(text: '1000');
    String type = 'real';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              title: Text(AppStrings.tr('add_new_account', lang)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: AppStrings.tr('account_name', lang),
                      hintText: AppStrings.tr('account_name_hint', lang),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: type,
                    decoration: InputDecoration(
                      labelText: AppStrings.tr('account_type', lang),
                    ),
                    items: [
                      DropdownMenuItem(value: 'real', child: Text(AppStrings.tr('type_real', lang))),
                      DropdownMenuItem(value: 'demo', child: Text(AppStrings.tr('type_demo', lang))),
                      DropdownMenuItem(value: 'prop_firm', child: Text(AppStrings.tr('type_prop', lang))),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => type = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: capCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: AppStrings.tr('account_capital', lang),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(AppStrings.tr('cancel', lang)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    final cap = double.tryParse(capCtrl.text.trim()) ?? 1000.0;
                    if (name.isNotEmpty) {
                      final provider = context.read<TradeProvider>();
                      final newAcc = TradingAccount(
                        id: 'acc_${DateTime.now().millisecondsSinceEpoch}',
                        name: name,
                        type: type,
                        initialCapital: cap,
                        currency: provider.settings.accountCurrency,
                      );
                      provider.addAccount(newAcc);
                      _capController.text = cap.toStringAsFixed(0);
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(AppStrings.tr('account_created', lang))),
                      );
                    }
                  },
                  child: Text(AppStrings.tr('add_symbol', lang)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final softColor = isDark ? AppColors.darkSoft : AppColors.lightSoft;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final mutedColor = isDark ? AppColors.darkMuted : AppColors.lightMuted;

    final tradeProvider = context.watch<TradeProvider>();
    final settings = tradeProvider.settings;
    final lang = settings.languageCode;
    final activeAcc = tradeProvider.activeAccount;

    final categories = [
      {'icon': Icons.tune_rounded, 'label': AppStrings.tr('cat_profile', lang)},
      {'icon': Icons.account_balance_wallet_outlined, 'label': AppStrings.tr('cat_accounts', lang)},
      {'icon': Icons.lock_outline_rounded, 'label': AppStrings.tr('cat_security', lang)},
      {'icon': Icons.palette_outlined, 'label': AppStrings.tr('cat_appearance', lang)},
      {'icon': Icons.candlestick_chart_outlined, 'label': AppStrings.tr('cat_symbols', lang)},
      {'icon': Icons.cloud_sync_outlined, 'label': AppStrings.tr('cat_data', lang)},
    ];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 120),
          children: [
            // Top Scrollable Category Tabs Bar
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: softColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(categories.length, (idx) {
                    final cat = categories[idx];
                    final isSelected = _selectedCategoryIndex == idx;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategoryIndex = idx),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: isSelected ? cardColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.12),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              cat['icon'] as IconData,
                              size: 16,
                              color: isSelected ? AppColors.primary : mutedColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              cat['label'] as String,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: isSelected ? textColor : mutedColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),

            // Category 0: Modal & Kurs
            if (_selectedCategoryIndex == 0)
              _buildCard(
                cardColor,
                borderColor,
                isDark,
                [
                  // Currency Akun (Dropdown)
                  _buildLabel(
                    AppStrings.tr('account_currency', lang),
                    mutedColor,
                  ),
                  _buildDropdown<String>(
                    value: _accountCurrencies
                            .any((c) => c['code'] == settings.accountCurrency)
                        ? settings.accountCurrency
                        : _accountCurrencies.first['code']!,
                    items: _accountCurrencies.map((c) {
                      return DropdownMenuItem<String>(
                        value: c['code'],
                        child: Text(
                          '${c['code']} (${c['symbol']}) · ${c['name']}',
                        ),
                      );
                    }).toList(),
                    onChanged: (val) async {
                      if (val != null) {
                        final provider = context.read<TradeProvider>();
                        await provider.updateAccountCurrency(val);
                        if (mounted) {
                          _fxController.text =
                              _formatRate(provider.settings.usdToIdrRate);
                        }
                      }
                    },
                    cardColor: cardColor,
                    softColor: softColor,
                    borderColor: borderColor,
                    textColor: textColor,
                  ),
                  const SizedBox(height: 14),

                  // Modal Awal (Akun Aktif)
                  _buildLabel(
                    '${AppStrings.tr("initial_capital_label", lang, params: {"curr": activeAcc.currency})} (${activeAcc.name})',
                    mutedColor,
                  ),
                  TextField(
                    controller: _capController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                    decoration: _inputDecoration(
                      softColor,
                      borderColor,
                      '1000',
                    ),
                    onSubmitted: (_) => _saveCapital(),
                    onChanged: (_) => _saveCapital(),
                  ),
                  const SizedBox(height: 14),

                  // Currency Exchange Rate (Dropdown)
                  _buildLabel(
                    AppStrings.tr('exchange_currency', lang),
                    mutedColor,
                  ),
                  _buildDropdown<String>(
                    value: _exchangeCurrencies
                            .any((c) => c['code'] == settings.exchangeCurrency)
                        ? settings.exchangeCurrency
                        : _exchangeCurrencies.first['code']!,
                    items: _exchangeCurrencies.map((c) {
                      return DropdownMenuItem<String>(
                        value: c['code'],
                        child: Text(
                          '${c['code']} (${c['symbol']}) · ${c['name']}',
                        ),
                      );
                    }).toList(),
                    onChanged: (val) async {
                      if (val != null) {
                        final provider = context.read<TradeProvider>();
                        await provider.updateExchangeCurrency(val);
                        if (mounted) {
                          _fxController.text =
                              _formatRate(provider.settings.usdToIdrRate);
                        }
                      }
                    },
                    cardColor: cardColor,
                    softColor: softColor,
                    borderColor: borderColor,
                    textColor: textColor,
                  ),
                  const SizedBox(height: 14),

                  // Nilai Kurs Header + Sinkronkan Kurs Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: _buildLabel(
                          AppStrings.tr(
                            'exchange_rate_label',
                            lang,
                            params: {
                              'target': settings.exchangeCurrency,
                              'base': activeAcc.currency,
                            },
                          ),
                          mutedColor,
                        ),
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: tradeProvider.isSyncingRate
                            ? null
                            : () => _syncRate(lang),
                        child: Padding(
                          padding: const EdgeInsets.only(
                            left: 8,
                            right: 4,
                            bottom: 6,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (tradeProvider.isSyncingRate)
                                const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primary,
                                  ),
                                )
                              else
                                const Icon(
                                  Icons.sync_rounded,
                                  size: 14,
                                  color: AppColors.primary,
                                ),
                              const SizedBox(width: 4),
                              Text(
                                AppStrings.tr(
                                  tradeProvider.isSyncingRate
                                      ? 'syncing_rate'
                                      : 'sync_rate',
                                  lang,
                                ),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  TextField(
                    controller: _fxController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                    decoration: _inputDecoration(
                      softColor,
                      borderColor,
                      '17998',
                    ).copyWith(
                      suffixIcon: IconButton(
                        icon: tradeProvider.isSyncingRate
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              )
                            : const Icon(
                                Icons.sync_rounded,
                                color: AppColors.primary,
                                size: 20,
                              ),
                        tooltip: AppStrings.tr('sync_rate', lang),
                        onPressed: tradeProvider.isSyncingRate
                            ? null
                            : () => _syncRate(lang),
                      ),
                    ),
                    onSubmitted: (_) => _saveFx(),
                    onChanged: (_) => _saveFx(),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Preview: 1,000 ${settings.accountCurrency} = ${Formatters.formatAmount(1000.0 * settings.usdToIdrRate, currency: settings.exchangeCurrency)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryLight,
                      ),
                    ),
                  ),
                ],
              ),

            // Category 1: Multi-Akun
            if (_selectedCategoryIndex == 1)
              _buildCard(
                cardColor,
                borderColor,
                isDark,
                [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppStrings.tr('cat_accounts', lang),
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textColor),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add, size: 16),
                        label: Text(AppStrings.tr('add_new_account', lang)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => _showAddAccountDialog(context, lang),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: settings.accounts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, idx) {
                      final acc = settings.accounts[idx];
                      final isActive = acc.id == settings.activeAccountId;

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isActive ? AppColors.primary.withOpacity(0.12) : softColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isActive ? AppColors.primary : borderColor,
                            width: isActive ? 1.6 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Radio<String>(
                              value: acc.id,
                              groupValue: settings.activeAccountId,
                              activeColor: AppColors.primary,
                              onChanged: (val) {
                                if (val != null) {
                                  tradeProvider.switchAccount(val);
                                  _capController.text = acc.initialCapital.toStringAsFixed(0);
                                }
                              },
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        acc.name,
                                        style: TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w800,
                                          color: textColor,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          acc.typeLabel,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Modal Awal: ${Formatters.formatAmount(acc.initialCapital, currency: acc.currency)}',
                                    style: TextStyle(fontSize: 12, color: mutedColor),
                                  ),
                                ],
                              ),
                            ),
                            if (settings.accounts.length > 1)
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppColors.lose, size: 20),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (dCtx) => AlertDialog(
                                      title: Text(AppStrings.tr('delete_account', lang)),
                                      content: Text(
                                        AppStrings.tr(
                                          'confirm_delete_account',
                                          lang,
                                          params: {'acc': acc.name},
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(dCtx).pop(),
                                          child: Text(AppStrings.tr('cancel', lang)),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(dCtx).pop();
                                            tradeProvider.deleteAccount(acc.id);
                                          },
                                          child: Text(
                                            AppStrings.tr('delete', lang),
                                            style: const TextStyle(color: AppColors.lose),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),

            // Category 2: Keamanan & PIN
            if (_selectedCategoryIndex == 2)
              _buildCard(
                cardColor,
                borderColor,
                isDark,
                [
                  Text(
                    AppStrings.tr('security_title', lang),
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textColor),
                  ),
                  const SizedBox(height: 14),

                  // PIN Lock Toggle & Options
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: softColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.pin_outlined, color: AppColors.primary, size: 22),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppStrings.tr('pin_lock_title', lang),
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textColor),
                                    ),
                                    Text(
                                      settings.isPinSet ? 'PIN Aktif' : 'PIN Tidak Aktif',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: settings.isPinSet ? AppColors.winText : mutedColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Switch(
                              value: settings.isPinSet,
                              activeColor: AppColors.primary,
                              onChanged: (val) {
                                if (val) {
                                  _showSetPinDialog(lang);
                                } else {
                                  _confirmDisablePin(lang);
                                }
                              },
                            ),
                          ],
                        ),
                        if (settings.isPinSet) ...[
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.spaceBetween,
                            children: [
                              TextButton.icon(
                                icon: const Icon(Icons.edit_outlined, size: 16),
                                label: Text(AppStrings.tr('change_pin', lang)),
                                onPressed: () => _showSetPinDialog(lang, isChanging: true),
                              ),
                              TextButton.icon(
                                icon: const Icon(Icons.lock_rounded, size: 16, color: AppColors.primary),
                                label: Text(
                                  AppStrings.tr('lock_now', lang),
                                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                                ),
                                onPressed: () => tradeProvider.lockApp(),
                              ),
                              TextButton.icon(
                                icon: const Icon(Icons.lock_open_rounded, size: 16, color: AppColors.lose),
                                label: Text(
                                  AppStrings.tr('disable_pin', lang),
                                  style: const TextStyle(color: AppColors.lose),
                                ),
                                onPressed: () => _confirmDisablePin(lang),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Biometric Toggle
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: softColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.fingerprint_rounded, color: AppColors.primary, size: 24),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppStrings.tr('biometric_title', lang),
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textColor),
                                ),
                                SizedBox(
                                  width: MediaQuery.of(context).size.width * 0.55,
                                  child: Text(
                                    AppStrings.tr('biometric_sub', lang),
                                    style: TextStyle(fontSize: 11.5, color: mutedColor),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Switch(
                          value: settings.isBiometricEnabled,
                          activeColor: AppColors.primary,
                          onChanged: settings.isPinSet
                              ? (val) => tradeProvider.setBiometricEnabled(val)
                              : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

            // Category 3: Tampilan & Bahasa
            if (_selectedCategoryIndex == 3)
              _buildCard(
                cardColor,
                borderColor,
                isDark,
                [
                  // Pilihan Bahasa (Dropdown)
                  _buildLabel(AppStrings.tr('language_title', lang), mutedColor),
                  _buildDropdown<String>(
                    value: lang == 'en' ? 'en' : 'id',
                    items: _languages.map((l) {
                      return DropdownMenuItem<String>(
                        value: l['code'],
                        child: Text(l['name']!),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) _setLanguage(val);
                    },
                    cardColor: cardColor,
                    softColor: softColor,
                    borderColor: borderColor,
                    textColor: textColor,
                  ),
                  const SizedBox(height: 16),

                  // Tema Tampilan (Segment)
                  _buildLabel(AppStrings.tr('theme_mode', lang), mutedColor),
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: softColor,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      children: [
                        _buildThemeButton(
                          ThemeMode.system,
                          AppStrings.tr('theme_system', lang),
                          settings.themeMode,
                          isDark ? AppColors.darkCard : AppColors.lightCard,
                          textColor,
                          mutedColor,
                        ),
                        _buildThemeButton(
                          ThemeMode.light,
                          AppStrings.tr('theme_light', lang),
                          settings.themeMode,
                          isDark ? AppColors.darkCard : AppColors.lightCard,
                          textColor,
                          mutedColor,
                        ),
                        _buildThemeButton(
                          ThemeMode.dark,
                          AppStrings.tr('theme_dark', lang),
                          settings.themeMode,
                          isDark ? AppColors.darkCard : AppColors.lightCard,
                          textColor,
                          mutedColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

            // Category 4: Simbol Trading
            if (_selectedCategoryIndex == 4)
              _buildCard(
                cardColor,
                borderColor,
                isDark,
                [
                  _buildLabel(AppStrings.tr('symbols_title', lang), mutedColor),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      AppStrings.tr('symbols_sub', lang),
                      style: TextStyle(fontSize: 12.5, color: mutedColor),
                    ),
                  ),

                  // Active Symbols Wrap
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: settings.symbols.map((sym) {
                      return Chip(
                        label: Text(
                          sym,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () => _confirmRemoveSymbol(sym, lang),
                        backgroundColor: softColor,
                        side: BorderSide(color: borderColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(99),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Add Symbol Input + Button
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _newSymbolController,
                          textCapitalization: TextCapitalization.characters,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                          decoration: _inputDecoration(
                            softColor,
                            borderColor,
                            AppStrings.tr('new_symbol_hint', lang),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                        ),
                        onPressed: _addSymbol,
                        child: Text(
                          AppStrings.tr('add_symbol', lang),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

            // Category 5: Data & Cloud (Google Drive)
            if (_selectedCategoryIndex == 5)
              Column(
                children: [
                  // Google Drive Cloud Backup Card
                  _buildCard(
                    cardColor,
                    borderColor,
                    isDark,
                    [
                      Row(
                        children: [
                          const Icon(Icons.cloud_upload_outlined, color: AppColors.primary, size: 24),
                          const SizedBox(width: 10),
                          Text(
                            AppStrings.tr('cloud_backup_title', lang),
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppStrings.tr('cloud_backup_sub', lang),
                        style: TextStyle(fontSize: 12.5, color: mutedColor),
                      ),
                      if (settings.lastBackupDate != null && settings.lastBackupDate!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          AppStrings.tr(
                            'last_backup_label',
                            lang,
                            params: {'date': DateFormat('d MMM yyyy, HH:mm').format(DateTime.parse(settings.lastBackupDate!))},
                          ),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryLight),
                        ),
                      ],
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.add_to_drive_rounded, size: 18),
                          label: Text(AppStrings.tr('backup_google_drive', lang)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => _backupToGoogleDrive(lang),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: softColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.tr('backup_guide_title', lang),
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: textColor),
                            ),
                            const SizedBox(height: 4),
                            Text(AppStrings.tr('backup_step_1', lang), style: TextStyle(fontSize: 11.5, color: mutedColor)),
                            Text(AppStrings.tr('backup_step_2', lang), style: TextStyle(fontSize: 11.5, color: mutedColor)),
                            Text(AppStrings.tr('backup_step_3', lang), style: TextStyle(fontSize: 11.5, color: mutedColor)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Local CSV Backup Card
                  _buildCard(
                    cardColor,
                    borderColor,
                    isDark,
                    [
                      _buildLabel(AppStrings.tr('data_backup_title', lang), mutedColor),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Text(
                          AppStrings.tr('data_backup_sub', lang),
                          style: TextStyle(fontSize: 12.5, color: mutedColor),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.file_upload_outlined, size: 18),
                              label: Text(AppStrings.tr('export_csv', lang)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 11),
                                side: BorderSide(color: borderColor),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () => _exportCSV(lang),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.file_download_outlined, size: 18),
                              label: Text(AppStrings.tr('import_csv', lang)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 11),
                                side: BorderSide(color: borderColor),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () => _importCSV(lang),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.delete_forever, size: 18, color: AppColors.lose),
                          label: Text(
                            AppStrings.tr('delete_all_trades', lang),
                            style: const TextStyle(color: AppColors.lose, fontWeight: FontWeight.w700),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            side: BorderSide(color: AppColors.lose.withOpacity(0.5)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => _confirmResetTrades(lang),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(
      Color cardColor, Color borderColor, bool isDark, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildLabel(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
      Color softColor, Color borderColor, String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: softColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    required Color cardColor,
    required Color softColor,
    required Color borderColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: softColor,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          dropdownColor: cardColor,
          icon: const Icon(
            Icons.arrow_drop_down_rounded,
            color: AppColors.primary,
            size: 28,
          ),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildThemeButton(
    ThemeMode mode,
    String label,
    ThemeMode currentMode,
    Color activeBg,
    Color textColor,
    Color mutedText,
  ) {
    final isSelected = currentMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => _setTheme(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? activeBg : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    )
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isSelected ? textColor : mutedText,
            ),
          ),
        ),
      ),
    );
  }
}
