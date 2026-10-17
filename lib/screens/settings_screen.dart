import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
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
  int _selectedCategoryIndex = 0; // 0: Profil, 1: Tampilan, 2: Simbol, 3: Data

  final _nameController = TextEditingController();
  final _capController = TextEditingController();
  final _fxController = TextEditingController();
  final _newSymbolController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final settings = context.read<TradeProvider>().settings;
    _nameController.text = settings.traderName;
    _capController.text = settings.initialCapital.toStringAsFixed(0);
    _fxController.text = settings.usdToIdrRate.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _capController.dispose();
    _fxController.dispose();
    _newSymbolController.dispose();
    super.dispose();
  }

  void _saveTraderName() {
    final name = _nameController.text.trim();
    final provider = context.read<TradeProvider>();
    provider.updateTraderName(name.isNotEmpty ? name : 'Trader');
  }

  void _saveCapital() {
    final cap = double.tryParse(_capController.text.trim());
    if (cap != null && cap > 0) {
      final provider = context.read<TradeProvider>();
      provider.updateSettings(provider.settings.copyWith(initialCapital: cap));
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

    try {
      await CSVService.exportTrades(
        trades: provider.trades,
        initialCapital: provider.settings.initialCapital,
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
          SnackBar(content: Text('Error export CSV: $e')),
        );
      }
    }
  }

  Future<void> _importCSV(String lang) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt'],
      );

      if (result == null || result.files.single.path == null) return;

      final file = File(result.files.single.path!);
      final content = await file.readAsString();

      if (!mounted) return;
      final provider = context.read<TradeProvider>();

      final parseResult = CSVService.parseCSV(
        content,
        existingTrades: provider.trades,
      );

      if (parseResult.trades.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              lang == 'en'
                  ? 'No new valid trades. Skipped: ${parseResult.skipped}, duplicates: ${parseResult.duplicates}'
                  : 'Tidak ada trade baru yang valid. Dilewati: ${parseResult.skipped}, duplikat: ${parseResult.duplicates}',
            ),
          ),
        );
        return;
      }

      // Show Import Confirmation Dialog
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(AppStrings.tr('import_csv', lang)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lang == 'en'
                    ? 'Found ${parseResult.trades.length} valid trades.\n'
                        '${parseResult.duplicates > 0 ? "• Duplicates: ${parseResult.duplicates}\n" : ""}'
                        '${parseResult.skipped > 0 ? "• Skipped rows: ${parseResult.skipped}\n" : ""}'
                    : 'Terbaca ${parseResult.trades.length} trade valid.\n'
                        '${parseResult.duplicates > 0 ? "• Duplikat: ${parseResult.duplicates}\n" : ""}'
                        '${parseResult.skipped > 0 ? "• Baris dilewati: ${parseResult.skipped}\n" : ""}',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                lang == 'en' ? 'Select import method:' : 'Pilih metode impor:',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(AppStrings.tr('cancel', lang)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                provider.importTrades(parseResult.trades, replace: false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      lang == 'en'
                          ? '${parseResult.trades.length} trades merged successfully'
                          : '${parseResult.trades.length} trade berhasil digabungkan',
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
                        ? 'All trade logs have been cleared'
                        : 'Semua trade telah dihapus',
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final softColor = isDark ? AppColors.darkSoft : AppColors.lightSoft;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final mutedColor = isDark ? AppColors.darkMuted : AppColors.lightMuted;

    final settings = context.watch<TradeProvider>().settings;
    final lang = settings.languageCode;

    final categories = [
      {'icon': Icons.person_outline_rounded, 'label': AppStrings.tr('cat_profile', lang)},
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
            // Top Category Tabs
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: softColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: List.generate(categories.length, (idx) {
                  final cat = categories[idx];
                  final isSelected = _selectedCategoryIndex == idx;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedCategoryIndex = idx),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(vertical: 9),
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
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              cat['icon'] as IconData,
                              size: 18,
                              color: isSelected ? AppColors.primary : mutedColor,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              cat['label'] as String,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: isSelected
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: isSelected ? textColor : mutedColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Category 0: Profil & Akun
            if (_selectedCategoryIndex == 0)
              _buildCard(
                cardColor,
                borderColor,
                isDark,
                [
                  _buildLabel(AppStrings.tr('trader_name', lang), mutedColor),
                  TextField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                    decoration: _inputDecoration(
                      softColor,
                      borderColor,
                      AppStrings.tr('trader_name_hint', lang),
                    ),
                    onChanged: (_) => _saveTraderName(),
                    onSubmitted: (_) => _saveTraderName(),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 14),
                    child: Text(
                      lang == 'en'
                          ? 'This name will be displayed in the hero chart header ("by ${settings.traderName}").'
                          : 'Nama ini akan ditampilkan pada header kartu grafik utama ("by ${settings.traderName}").',
                      style: TextStyle(fontSize: 12, color: mutedColor),
                    ),
                  ),

                  _buildLabel(AppStrings.tr('initial_capital', lang), mutedColor),
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

                  _buildLabel(AppStrings.tr('usd_idr_rate', lang), mutedColor),
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
                    ),
                    onSubmitted: (_) => _saveFx(),
                    onChanged: (_) => _saveFx(),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Preview: \$1,000 = ${Formatters.formatIDR(1000.0 * settings.usdToIdrRate)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryLight,
                      ),
                    ),
                  ),
                ],
              ),

            // Category 1: Tampilan & Bahasa
            if (_selectedCategoryIndex == 1)
              _buildCard(
                cardColor,
                borderColor,
                isDark,
                [
                  _buildLabel(AppStrings.tr('language_title', lang), mutedColor),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: softColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        _buildToggleButton(
                          'id',
                          '🇮🇩 Bahasa Indonesia',
                          lang,
                          cardColor,
                          textColor,
                          mutedColor,
                          (v) => _setLanguage(v),
                        ),
                        _buildToggleButton(
                          'en',
                          '🇬🇧 English',
                          lang,
                          cardColor,
                          textColor,
                          mutedColor,
                          (v) => _setLanguage(v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  _buildLabel(AppStrings.tr('theme_mode', lang), mutedColor),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: softColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        _buildThemeButton(
                          ThemeMode.system,
                          AppStrings.tr('theme_system', lang),
                          settings.themeMode,
                          cardColor,
                          textColor,
                          mutedColor,
                        ),
                        _buildThemeButton(
                          ThemeMode.light,
                          AppStrings.tr('theme_light', lang),
                          settings.themeMode,
                          cardColor,
                          textColor,
                          mutedColor,
                        ),
                        _buildThemeButton(
                          ThemeMode.dark,
                          AppStrings.tr('theme_dark', lang),
                          settings.themeMode,
                          cardColor,
                          textColor,
                          mutedColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

            // Category 2: Simbol Trading
            if (_selectedCategoryIndex == 2)
              _buildCard(
                cardColor,
                borderColor,
                isDark,
                [
                  Text(
                    AppStrings.tr('symbols_title', lang),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppStrings.tr('symbols_sub', lang),
                    style: TextStyle(fontSize: 12.5, color: mutedColor),
                  ),
                  const SizedBox(height: 12),

                  // Chips List
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
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _addSymbol,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          AppStrings.tr('add_symbol', lang),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

            // Category 3: Data & Cadangan
            if (_selectedCategoryIndex == 3)
              _buildCard(
                cardColor,
                borderColor,
                isDark,
                [
                  Text(
                    AppStrings.tr('data_backup_title', lang),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AppStrings.tr('data_backup_sub', lang),
                    style: TextStyle(
                      fontSize: 12.5,
                      color: mutedColor,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Export Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.download_outlined, size: 20),
                      label: Text(
                        AppStrings.tr('export_csv', lang),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () => _exportCSV(lang),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Import Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.upload_outlined, size: 20),
                      label: Text(
                        AppStrings.tr('import_csv', lang),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        side: BorderSide(color: borderColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => _importCSV(lang),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Reset All Trades
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => _confirmResetTrades(lang),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        foregroundColor: AppColors.lose,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: borderColor),
                        ),
                      ),
                      child: Text(
                        AppStrings.tr('delete_all_trades', lang),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(
    Color cardColor,
    Color borderColor,
    bool isDark,
    List<Widget> children,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
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

  Widget _buildToggleButton(
    String val,
    String label,
    String currentVal,
    Color activeBg,
    Color textColor,
    Color mutedText,
    ValueChanged<String> onChanged,
  ) {
    final isSelected = currentVal == val;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(val),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 9),
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
