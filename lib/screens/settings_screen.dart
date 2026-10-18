import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/trade_provider.dart';
import '../services/backup_service.dart';
import '../services/csv_service.dart';
import '../utils/app_strings.dart';
import '../utils/formatters.dart';
import '../widgets/about_section.dart';
import '../widgets/account_form_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // -1 = menu utama. 0: Modal & Kurs, 1: Akun, 2: Keamanan, 3: Tampilan,
  // 4: Simbol, 5: Data, 6: Preferensi
  int _selectedCategoryIndex = -1;

  static const Map<int, String> _categoryTitleKeys = {
    0: 'cat_profile',
    1: 'cat_accounts',
    2: 'cat_security',
    3: 'cat_appearance',
    4: 'cat_symbols',
    5: 'cat_data',
    6: 'cat_prefs',
    7: 'cat_about',
  };

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
  final _lotController = TextEditingController();

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
    _lotController.text =
        settings.defaultLot > 0 ? settings.defaultLot.toString() : '';
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
    _lotController.dispose();
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

  Future<bool?> _showConfirmDialog({
    required BuildContext context,
    required String title,
    required String message,
    required String confirmLabel,
    String? cancelLabel,
    Color confirmColor = AppColors.lose,
    IconData icon = Icons.warning_amber_rounded,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final mutedColor = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: confirmColor.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: confirmColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  message,
                  softWrap: true,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: mutedColor,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: confirmColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: Text(
                      confirmLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: mutedColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: borderColor),
                      ),
                    ),
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: Text(
                      cancelLabel ?? AppStrings.tr('cancel', context.read<TradeProvider>().settings.languageCode),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmRemoveSymbol(String symbol, String lang) async {
    final confirmed = await _showConfirmDialog(
      context: context,
      title: AppStrings.tr('delete_symbol_title', lang),
      message: AppStrings.tr('delete_symbol_msg', lang, params: {'s': symbol}),
      confirmLabel: AppStrings.tr('delete', lang),
      icon: Icons.delete_outline_rounded,
    );
    if (confirmed == true && mounted) {
      context.read<TradeProvider>().removeSymbol(symbol);
    }
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

  /// Full backup (trades + screenshots + accounts + settings) as one ZIP.
  Future<void> _backupToGoogleDrive(String lang) async {
    final provider = context.read<TradeProvider>();

    provider.setSystemPickerActive(true);
    try {
      final nowStr = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final fileName = 'TraderLog_Backup_$nowStr.zip';

      await BackupService.exportBackup(
        trades: provider.allTrades,
        settings: provider.settings,
        fileName: fileName,
        shareText: 'TraderLog Backup',
      );

      await provider.recordCloudBackup();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primary,
            content: Text(AppStrings.tr('backup_zip_ready', lang)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppStrings.tr('backup_zip_failed', lang)}: $e')),
        );
      }
    } finally {
      Future.delayed(const Duration(milliseconds: 600), () {
        provider.setSystemPickerActive(false);
      });
    }
  }

  /// Restores everything from a ZIP created by [_backupToGoogleDrive].
  Future<void> _restoreFromZip(String lang) async {
    final provider = context.read<TradeProvider>();
    provider.setSystemPickerActive(true);
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );
      if (picked == null || picked.files.single.path == null) return;

      final bytes = await File(picked.files.single.path!).readAsBytes();
      final opened = BackupService.open(bytes);
      final preview = opened.preview;

      if (!mounted) return;
      final confirmed = await _showConfirmDialog(
        context: context,
        title: AppStrings.tr('restore_zip_title', lang),
        message: AppStrings.tr('restore_zip_confirm', lang, params: {
          'trades': '${preview.tradeCount}',
          'accounts': '${preview.accountCount}',
          'images': '${preview.imageCount}',
          'date': preview.createdAt == null
              ? '-'
              : DateFormat('d MMM yyyy, HH:mm').format(preview.createdAt!),
        }),
        confirmLabel: AppStrings.tr('restore_zip_action', lang),
        confirmColor: AppColors.lose,
        icon: Icons.restore_rounded,
      );
      if (confirmed != true || !mounted) return;

      final appDir = await getApplicationDocumentsDirectory();
      final data = await opened.materialize(appDir);
      await provider.restoreBackup(data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primary,
            content: Text(AppStrings.tr('restore_zip_done', lang, params: {
              'trades': '${data.trades.length}',
            })),
          ),
        );
      }
    } on BackupException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppStrings.tr('restore_zip_failed', lang)}: $e')),
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

      final isDark = Theme.of(context).brightness == Brightness.dark;
      final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
      final softColor = isDark ? AppColors.darkSoft : AppColors.lightSoft;
      final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
      final textColor = isDark ? AppColors.darkText : AppColors.lightText;
      final mutedColor = isDark ? AppColors.darkMuted : AppColors.lightMuted;

      String importMethod = 'merge';

      showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return Dialog(
              backgroundColor: cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.16),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.file_upload_outlined,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              AppStrings.tr('import_confirmation', lang),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close_rounded, color: mutedColor, size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            splashRadius: 20,
                            onPressed: () => Navigator.of(ctx).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Info stats container
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: softColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                lang == 'en'
                                    ? 'Found ${parseResult.trades.length} new trades.\n(${parseResult.duplicates} duplicates, ${parseResult.skipped} invalid rows skipped).'
                                    : 'Ditemukan ${parseResult.trades.length} trade baru.\n(${parseResult.duplicates} duplikat, ${parseResult.skipped} baris dilewati).',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: textColor,
                                  height: 1.4,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      Text(
                        lang == 'en' ? 'Choose Import Method:' : 'Pilih Metode Impor:',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: mutedColor,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Icon cards for import type selection
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setDialogState(() => importMethod = 'merge');
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                decoration: BoxDecoration(
                                  color: importMethod == 'merge'
                                      ? AppColors.primary.withOpacity(isDark ? 0.20 : 0.12)
                                      : softColor,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: importMethod == 'merge' ? AppColors.primary : borderColor,
                                    width: importMethod == 'merge' ? 2.0 : 1.0,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.call_merge_rounded,
                                      size: 22,
                                      color: importMethod == 'merge' ? AppColors.primary : mutedColor,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      AppStrings.tr('import_merge', lang),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w800,
                                        color: importMethod == 'merge' ? textColor : mutedColor,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      AppStrings.tr('import_merge_sub', lang),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w600,
                                        color: importMethod == 'merge' ? AppColors.primary : mutedColor.withOpacity(0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setDialogState(() => importMethod = 'replace');
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                decoration: BoxDecoration(
                                  color: importMethod == 'replace'
                                      ? AppColors.lose.withOpacity(isDark ? 0.20 : 0.12)
                                      : softColor,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: importMethod == 'replace' ? AppColors.lose : borderColor,
                                    width: importMethod == 'replace' ? 2.0 : 1.0,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.warning_amber_rounded,
                                      size: 22,
                                      color: importMethod == 'replace' ? AppColors.lose : mutedColor,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      AppStrings.tr('import_replace', lang),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w800,
                                        color: importMethod == 'replace' ? textColor : mutedColor,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      AppStrings.tr('import_replace_sub', lang),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w600,
                                        color: importMethod == 'replace' ? AppColors.lose : mutedColor.withOpacity(0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Wide main button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: importMethod == 'merge' ? AppColors.primary : AppColors.lose,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            if (importMethod == 'merge') {
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
                            } else {
                              _confirmReplaceAll(parseResult, lang);
                            }
                          },
                          child: Text(
                            AppStrings.tr('proceed_import', lang),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
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

  void _confirmReplaceAll(CSVImportResult parseResult, String lang) async {
    final confirmed = await _showConfirmDialog(
      context: context,
      title: lang == 'en' ? 'Replace All Trades?' : 'Ganti Semua Trade?',
      message: lang == 'en'
          ? 'All currently saved trades will be removed and replaced with data from this CSV. Continue?'
          : 'Semua trade yang tersimpan saat ini akan dihapus dan digantikan dengan data dari CSV ini. Lanjutkan?',
      confirmLabel: lang == 'en' ? 'Replace All' : 'Ganti Semua',
      confirmColor: AppColors.lose,
      icon: Icons.warning_amber_rounded,
    );
    if (confirmed == true && mounted) {
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
    }
  }

  void _confirmResetTrades(String lang) async {
    final confirmed = await _showConfirmDialog(
      context: context,
      title: AppStrings.tr('confirm_reset_title', lang),
      message: AppStrings.tr('confirm_reset_sub', lang),
      confirmLabel: AppStrings.tr('delete', lang),
      confirmColor: AppColors.lose,
      icon: Icons.delete_forever_rounded,
    );
    if (confirmed == true && mounted) {
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
    }
  }

  void _confirmDisablePin(String lang) {
    final currentPinCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final softColor = isDark ? AppColors.darkSoft : AppColors.lightSoft;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final mutedColor = isDark ? AppColors.darkMuted : AppColors.lightMuted;

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.lose.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.lock_open_rounded,
                            color: AppColors.lose,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            AppStrings.tr('disable_pin', lang),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close_rounded, color: mutedColor, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          splashRadius: 20,
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      lang == 'en'
                          ? 'Enter current 4-digit PIN to disable lock:'
                          : 'Masukkan 4 digit PIN saat ini untuk mematikan kunci:',
                      softWrap: true,
                      style: TextStyle(fontSize: 13, color: mutedColor),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: currentPinCtrl,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      obscureText: true,
                      autofocus: true,
                      style: TextStyle(color: textColor, fontWeight: FontWeight.w700),
                      decoration: InputDecoration(
                        labelText: lang == 'en' ? 'Current PIN' : 'PIN Saat Ini',
                        prefixIcon: Icon(Icons.lock_outline, color: mutedColor, size: 20),
                        counterText: '',
                        filled: true,
                        fillColor: softColor,
                        errorMaxLines: 2,
                        helperMaxLines: 2,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.lose, width: 1.4),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.lose, width: 1.8),
                        ),
                        errorStyle: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.lose,
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().length != 4) {
                          return AppStrings.tr('pin_required', lang);
                        }
                        if (!context.read<TradeProvider>().verifyPin(val.trim())) {
                          return lang == 'en' ? 'Current PIN is incorrect' : 'PIN saat ini salah';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.lose,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          if (formKey.currentState!.validate()) {
                            context.read<TradeProvider>().setPinCode(null);
                            Navigator.of(ctx).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(AppStrings.tr('pin_disabled', lang))),
                            );
                          }
                        },
                        child: Text(
                          AppStrings.tr('disable_pin', lang),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showSetPinDialog(String lang, {bool isChanging = false}) {
    final curPinCtrl = TextEditingController();
    final pin1Ctrl = TextEditingController();
    final pin2Ctrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final hasCurrentPin = context.read<TradeProvider>().settings.isPinSet;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final softColor = isDark ? AppColors.darkSoft : AppColors.lightSoft;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final mutedColor = isDark ? AppColors.darkMuted : AppColors.lightMuted;

    InputDecoration pinDeco(String label, IconData icon) {
      return InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: mutedColor, size: 20),
        counterText: '',
        filled: true,
        fillColor: softColor,
        errorMaxLines: 2,
        helperMaxLines: 2,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lose, width: 1.4),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lose, width: 1.8),
        ),
        errorStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.lose,
        ),
      );
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.16),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.lock_outline_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            AppStrings.tr(isChanging ? 'change_pin' : 'setup_pin_title', lang),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close_rounded, color: mutedColor, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          splashRadius: 20,
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    if (isChanging && hasCurrentPin) ...[
                      TextFormField(
                        controller: curPinCtrl,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        obscureText: true,
                        style: TextStyle(color: textColor, fontWeight: FontWeight.w700),
                        decoration: pinDeco(
                          lang == 'en' ? 'Current PIN' : 'PIN Saat Ini',
                          Icons.lock_clock_outlined,
                        ),
                        validator: (val) {
                          if (val == null || val.trim().length != 4) {
                            return AppStrings.tr('pin_required', lang);
                          }
                          if (!context.read<TradeProvider>().verifyPin(val.trim())) {
                            return lang == 'en' ? 'Current PIN is incorrect' : 'PIN saat ini salah';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextFormField(
                      controller: pin1Ctrl,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      obscureText: true,
                      style: TextStyle(color: textColor, fontWeight: FontWeight.w700),
                      decoration: pinDeco(
                        AppStrings.tr('setup_pin_title', lang),
                        Icons.lock_outline,
                      ),
                      validator: (val) {
                        if (val == null || val.trim().length != 4) {
                          return AppStrings.tr('pin_required', lang);
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: pin2Ctrl,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      obscureText: true,
                      style: TextStyle(color: textColor, fontWeight: FontWeight.w700),
                      decoration: pinDeco(
                        AppStrings.tr('confirm_pin_title', lang),
                        Icons.lock_reset_outlined,
                      ),
                      validator: (val) {
                        if (val == null || val.trim().length != 4) {
                          return AppStrings.tr('pin_required', lang);
                        }
                        if (val.trim() != pin1Ctrl.text.trim()) {
                          return AppStrings.tr('pin_mismatch_inline', lang);
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          if (formKey.currentState!.validate()) {
                            final p1 = pin1Ctrl.text.trim();
                            context.read<TradeProvider>().setPinCode(p1);
                            Navigator.of(ctx).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(AppStrings.tr(isChanging ? 'pin_changed' : 'pin_enabled', lang)),
                              ),
                            );
                          }
                        },
                        child: Text(
                          AppStrings.tr('save_changes', lang),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAddAccountDialog(BuildContext context, String lang) {
    AccountFormDialog.show(context);
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

    final inMenu = _selectedCategoryIndex == -1;

    return PopScope(
      canPop: inMenu,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _selectedCategoryIndex = -1);
      },
      child: Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          children: [
            if (inMenu)
              ..._buildMenu(tradeProvider, lang)
            else
              _buildDetailHeader(lang),

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
                      Expanded(
                        child: Text(
                          AppStrings.tr('cat_accounts', lang),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textColor),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add, size: 16),
                        label: Text(
                          AppStrings.tr('add_new_account', lang),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
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
                                      Flexible(
                                        child: Text(
                                          acc.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w800,
                                            color: textColor,
                                          ),
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
                                          maxLines: 1,
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
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 12, color: mutedColor),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
                              tooltip: AppStrings.tr('edit_account', lang),
                              onPressed: () => AccountFormDialog.show(context, accountToEdit: acc),
                            ),
                            if (settings.accounts.length > 1)
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppColors.lose, size: 20),
                                tooltip: AppStrings.tr('delete_account', lang),
                                onPressed: () async {
                                  final confirmed = await _showConfirmDialog(
                                    context: context,
                                    title: AppStrings.tr('delete_account', lang),
                                    message: AppStrings.tr(
                                      'confirm_delete_account',
                                      lang,
                                      params: {'acc': acc.name},
                                    ),
                                    confirmLabel: AppStrings.tr('delete', lang),
                                    confirmColor: AppColors.lose,
                                    icon: Icons.delete_outline_rounded,
                                  );
                                  if (confirmed == true && mounted) {
                                    tradeProvider.deleteAccount(acc.id);
                                  }
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
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.settings_backup_restore_rounded, size: 18),
                          label: Text(AppStrings.tr('restore_zip_button', lang)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: borderColor),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => _restoreFromZip(lang),
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
            // Category 6: Preferensi
            if (_selectedCategoryIndex == 7) ...[
              const AboutSection(),
            ],

            if (_selectedCategoryIndex == 6) ...[
              _buildCard(cardColor, borderColor, isDark, [
                _prefSwitch(
                  icon: Icons.visibility_off_outlined,
                  title: AppStrings.tr('pref_privacy_title', lang),
                  subtitle: AppStrings.tr('pref_privacy_sub', lang),
                  value: settings.hideBalance,
                  onChanged: (v) => tradeProvider.setHideBalance(v),
                ),
                Divider(height: 28, color: borderColor),
                _prefSwitch(
                  icon: Icons.vibration_rounded,
                  title: AppStrings.tr('pref_haptic_title', lang),
                  subtitle: AppStrings.tr('pref_haptic_sub', lang),
                  value: settings.hapticEnabled,
                  onChanged: (v) => tradeProvider.setHapticEnabled(v),
                ),
              ]),
              const SizedBox(height: 12),
              _buildCard(cardColor, borderColor, isDark, [
                _prefHeader(
                  Icons.timer_outlined,
                  AppStrings.tr('pref_autolock_title', lang),
                  AppStrings.tr('pref_autolock_sub', lang),
                ),
                const SizedBox(height: 14),
                _segmented<int>(
                  enabled: settings.isPinSet,
                  current: settings.autoLockSeconds,
                  options: [
                    MapEntry(0, AppStrings.tr('autolock_immediate', lang)),
                    MapEntry(30, AppStrings.tr('autolock_30s', lang)),
                    MapEntry(60, AppStrings.tr('autolock_1m', lang)),
                    MapEntry(300, AppStrings.tr('autolock_5m', lang)),
                  ],
                  onChanged: (v) => tradeProvider.setAutoLockSeconds(v),
                ),
                if (!settings.isPinSet)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      AppStrings.tr('pref_autolock_need_pin', lang),
                      style: TextStyle(fontSize: 12, color: mutedColor),
                    ),
                  ),
              ]),
              const SizedBox(height: 12),
              _buildCard(cardColor, borderColor, isDark, [
                _prefHeader(
                  Icons.calendar_month_outlined,
                  AppStrings.tr('pref_weekstart_title', lang),
                  null,
                ),
                const SizedBox(height: 14),
                _segmented<bool>(
                  current: settings.weekStartsMonday,
                  options: [
                    MapEntry(false, AppStrings.tr('week_sunday', lang)),
                    MapEntry(true, AppStrings.tr('week_monday', lang)),
                  ],
                  onChanged: (v) => tradeProvider.setWeekStartsMonday(v),
                ),
              ]),
              const SizedBox(height: 12),
              _buildCard(cardColor, borderColor, isDark, [
                _prefHeader(
                  Icons.tune_rounded,
                  AppStrings.tr('pref_lot_title', lang),
                  AppStrings.tr('pref_lot_sub', lang),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _lotController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                  decoration: _inputDecoration(softColor, borderColor, '0.01'),
                  onChanged: (txt) {
                    final v =
                        double.tryParse(txt.trim().replaceAll(',', '.')) ?? 0.0;
                    tradeProvider.setDefaultLot(v);
                  },
                ),
              ]),
            ],
          ],
        ),
      ),
    ),
    );
  }


  // ───────────────────────── Modern menu & helpers ─────────────────────────

  void _tap() {
    if (context.read<TradeProvider>().settings.hapticEnabled) {
      HapticFeedback.selectionClick();
    }
  }

  void _openCategory(int idx) {
    _tap();
    setState(() => _selectedCategoryIndex = idx);
  }

  void _showEditNameDialog(String lang) {
    final provider = context.read<TradeProvider>();
    final ctrl = TextEditingController(text: provider.settings.traderName);
    final formKey = GlobalKey<FormState>();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final softColor = isDark ? AppColors.darkSoft : AppColors.lightSoft;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final mutedColor = isDark ? AppColors.darkMuted : AppColors.lightMuted;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.16),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.person_outline_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          lang == 'en' ? 'Your Name' : 'Nama Anda',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: mutedColor, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        splashRadius: 20,
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: ctrl,
                    autofocus: true,
                    maxLength: 24,
                    textCapitalization: TextCapitalization.words,
                    style: TextStyle(color: textColor, fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      labelText: AppStrings.tr('trader_name', lang),
                      hintText: AppStrings.tr('trader_name_hint', lang),
                      prefixIcon: Icon(Icons.badge_outlined, color: mutedColor, size: 20),
                      counterText: '',
                      filled: true,
                      fillColor: softColor,
                      errorMaxLines: 2,
                      helperMaxLines: 2,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.lose, width: 1.4),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.lose, width: 1.8),
                      ),
                      errorStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.lose,
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return AppStrings.tr('name_required', lang);
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          final n = ctrl.text.trim();
                          provider.updateTraderName(n);
                          Navigator.of(ctx).pop();
                        }
                      },
                      child: Text(
                        AppStrings.tr('save_changes', lang),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildMenu(TradeProvider tp, String lang) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final mutedColor = isDark ? AppColors.darkMuted : AppColors.lightMuted;

    final settings = tp.settings;
    final acc = tp.activeAccount;
    final name = settings.traderName.trim();
    final initial = name.isEmpty ? 'T' : name.substring(0, 1).toUpperCase();
    final themeKey = settings.themeMode == ThemeMode.dark
        ? 'theme_dark'
        : settings.themeMode == ThemeMode.light
            ? 'theme_light'
            : 'theme_system';

    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 16),
        child: Text(
          AppStrings.tr('nav_settings', lang),
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: textColor,
          ),
        ),
      ),

      // Profile card
      Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
        ),
        child: Material(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _showEditNameDialog(lang),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      initial,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name.isEmpty ? 'TraderLog' : name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${acc.name} · ${acc.typeLabel}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12.5, color: mutedColor),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.edit_outlined, size: 18, color: mutedColor),
                ],
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 22),

      _menuGroup(AppStrings.tr('group_general', lang), [
        _menuTile(
          icon: Icons.account_balance_outlined,
          color: AppColors.primary,
          title: AppStrings.tr('cat_profile', lang),
          subtitle: AppStrings.tr('menu_capital_sub', lang),
          index: 0,
        ),
        _menuTile(
          icon: Icons.account_balance_wallet_outlined,
          color: const Color(0xFF6366F1),
          title: AppStrings.tr('cat_accounts', lang),
          subtitle: AppStrings.tr('menu_accounts_sub', lang, params: {
            'n': settings.accounts.length.toString(),
            'name': acc.name,
          }),
          index: 1,
        ),
        _menuTile(
          icon: Icons.candlestick_chart_outlined,
          color: const Color(0xFF0EA5E9),
          title: AppStrings.tr('cat_symbols', lang),
          subtitle: AppStrings.tr('menu_symbols_sub', lang,
              params: {'n': settings.symbols.length.toString()}),
          index: 4,
        ),
      ]),

      _menuGroup(AppStrings.tr('group_personal', lang), [
        _menuTile(
          icon: Icons.palette_outlined,
          color: const Color(0xFFEC4899),
          title: AppStrings.tr('cat_appearance', lang),
          subtitle: AppStrings.tr('menu_appearance_sub', lang, params: {
            'lang': lang == 'en' ? 'English' : 'Indonesia',
            'theme': AppStrings.tr(themeKey, lang),
          }),
          index: 3,
        ),
        _menuTile(
          icon: Icons.tune_rounded,
          color: const Color(0xFFF59E0B),
          title: AppStrings.tr('cat_prefs', lang),
          subtitle: AppStrings.tr('menu_prefs_sub', lang),
          index: 6,
        ),
      ]),

      _menuGroup(AppStrings.tr('group_privacy_data', lang), [
        _menuTile(
          icon: Icons.lock_outline_rounded,
          color: AppColors.lose,
          title: AppStrings.tr('cat_security', lang),
          subtitle: AppStrings.tr(
              settings.isPinSet ? 'menu_security_on' : 'menu_security_off',
              lang),
          index: 2,
        ),
        _menuTile(
          icon: Icons.cloud_sync_outlined,
          color: const Color(0xFF14B8A6),
          title: AppStrings.tr('cat_data', lang),
          subtitle: AppStrings.tr('menu_data_sub', lang),
          index: 5,
        ),
      ]),

      _menuGroup(AppStrings.tr('group_info', lang), [
        _menuTile(
          icon: Icons.info_outline_rounded,
          color: AppColors.primary,
          title: AppStrings.tr('cat_about', lang),
          subtitle: AppStrings.tr('menu_about_sub', lang),
          index: 7,
        ),
      ]),
    ];
  }

  Widget _menuGroup(String label, List<Widget> tiles) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final mutedColor = isDark ? AppColors.darkMuted : AppColors.lightMuted;

    final rows = <Widget>[];
    for (int i = 0; i < tiles.length; i++) {
      rows.add(tiles[i]);
      if (i != tiles.length - 1) {
        rows.add(Divider(height: 1, indent: 64, color: borderColor));
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.9,
                color: mutedColor,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor),
            ),
            child: Material(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              clipBehavior: Clip.antiAlias,
              child: Column(children: rows),
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required int index,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final mutedColor = isDark ? AppColors.darkMuted : AppColors.lightMuted;

    return InkWell(
      onTap: () => _openCategory(index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withOpacity(0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: mutedColor),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: mutedColor),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailHeader(String lang) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final title =
        AppStrings.tr(_categoryTitleKeys[_selectedCategoryIndex] ?? 'nav_settings', lang);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              _tap();
              setState(() => _selectedCategoryIndex = -1);
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Icon(Icons.arrow_back_ios_new_rounded,
                  size: 16, color: textColor),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _prefHeader(IconData icon, String title, String? subtitle) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final mutedColor = isDark ? AppColors.darkMuted : AppColors.lightMuted;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.14),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, size: 19, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, height: 1.35, color: mutedColor),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _prefSwitch({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(child: _prefHeader(icon, title, subtitle)),
        const SizedBox(width: 8),
        Switch(
          value: value,
          activeColor: AppColors.primary,
          onChanged: (v) {
            if (context.read<TradeProvider>().settings.hapticEnabled) {
              HapticFeedback.selectionClick();
            }
            onChanged(v);
          },
        ),
      ],
    );
  }

  Widget _segmented<T>({
    required List<MapEntry<T, String>> options,
    required T current,
    required ValueChanged<T> onChanged,
    bool enabled = true,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final softColor = isDark ? AppColors.darkSoft : AppColors.lightSoft;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final mutedColor = isDark ? AppColors.darkMuted : AppColors.lightMuted;

    return Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: softColor,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: options.map((opt) {
            final selected = opt.key == current;
            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: enabled
                    ? () {
                        _tap();
                        onChanged(opt.key);
                      }
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? cardColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.10),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    opt.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: selected ? textColor : mutedColor,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
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
