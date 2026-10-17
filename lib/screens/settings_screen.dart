import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/trade_provider.dart';
import '../services/csv_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _capController = TextEditingController();
  final _fxController = TextEditingController();
  final _newSymbolController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final settings = context.read<TradeProvider>().settings;
    _capController.text = settings.initialCapital.toStringAsFixed(0);
    _fxController.text = settings.usdToIdrRate.toStringAsFixed(0);
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

  void _addSymbol() {
    final sym = _newSymbolController.text.trim().toUpperCase();
    if (sym.isNotEmpty) {
      context.read<TradeProvider>().addSymbol(sym);
      _newSymbolController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  void _confirmRemoveSymbol(String symbol) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Symbol'),
        content: Text(
            'Hapus symbol $symbol dari daftar cepat? Trade lama dengan symbol ini tetap aman.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<TradeProvider>().removeSymbol(symbol);
            },
            child: const Text(
              'Hapus',
              style: TextStyle(color: AppColors.lose),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportCSV() async {
    final provider = context.read<TradeProvider>();
    if (provider.trades.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Belum ada trade untuk diekspor')),
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
              '${provider.trades.length} trade berhasil disiapkan untuk diekspor',
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
    }
  }

  Future<void> _importCSV() async {
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
              'Tidak ada trade baru yang valid. Dilewati: ${parseResult.skipped}, duplikat: ${parseResult.duplicates}',
            ),
          ),
        );
        return;
      }

      // Show Import Confirmation Dialog
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Impor Data CSV'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Terbaca ${parseResult.trades.length} trade valid.\n'
                '${parseResult.duplicates > 0 ? "• Duplikat: ${parseResult.duplicates}\n" : ""}'
                '${parseResult.skipped > 0 ? "• Baris dilewati: ${parseResult.skipped}\n" : ""}',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              const Text(
                'Pilih metode impor:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                provider.importTrades(parseResult.trades, replace: false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${parseResult.trades.length} trade berhasil digabungkan',
                    ),
                  ),
                );
              },
              child: const Text('Gabungkan'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.lose,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                _confirmReplaceAll(parseResult);
              },
              child: const Text('Ganti Semua'),
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

  void _confirmReplaceAll(CSVImportResult parseResult) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ganti Semua Trade?'),
        content: const Text(
          'Semua trade yang tersimpan saat ini akan dihapus dan digantikan dengan data dari CSV ini. Lanjutkan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
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
                    'Semua trade telah diganti dengan ${parseResult.trades.length} trade baru',
                  ),
                ),
              );
            },
            child: const Text(
              'Ganti Semua',
              style: TextStyle(color: AppColors.lose),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmResetTrades() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus SEMUA Trade?'),
        content: const Text(
          'Tindakan ini akan menghapus seluruh data jurnal trading. '
          'Pastikan Anda sudah mengekspor ke CSV jika memerlukan cadangan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<TradeProvider>().deleteAllTrades();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Semua trade telah dihapus')),
              );
            },
            child: const Text(
              'Hapus Semua',
              style: TextStyle(color: AppColors.lose),
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

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 120),
          children: [
            // Section 1: Modal Awal, Kurs, & Tema
            Container(
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
                children: [
                  _buildLabel('Modal awal (USD)', mutedColor),
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
                        softColor, borderColor, '1000'),
                    onSubmitted: (_) => _saveCapital(),
                    onChanged: (_) => _saveCapital(),
                  ),
                  const SizedBox(height: 14),

                  _buildLabel('Kurs IDR per 1 USD', mutedColor),
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
                        softColor, borderColor, '17998'),
                    onSubmitted: (_) => _saveFx(),
                    onChanged: (_) => _saveFx(),
                  ),
                  const SizedBox(height: 14),

                  _buildLabel('Tema Tampilan', mutedColor),
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
                          'Otomatis',
                          settings.themeMode,
                          cardColor,
                          textColor,
                          mutedColor,
                        ),
                        _buildThemeButton(
                          ThemeMode.light,
                          'Terang',
                          settings.themeMode,
                          cardColor,
                          textColor,
                          mutedColor,
                        ),
                        _buildThemeButton(
                          ThemeMode.dark,
                          'Gelap',
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
            ),
            const SizedBox(height: 14),

            // Section 2: Daftar Symbol
            Container(
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
                children: [
                  Text(
                    'Daftar Symbol',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: mutedColor,
                    ),
                  ),
                  const SizedBox(height: 10),

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
                        onDeleted: () => _confirmRemoveSymbol(sym),
                        backgroundColor: softColor,
                        side: BorderSide(color: borderColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(99),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

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
                            'Symbol baru, mis. NAS100',
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
                        child: const Text(
                          'Tambah',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Section 3: Data Management (CSV)
            Container(
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
                children: [
                  Text(
                    'Data & Cadangan (CSV)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: mutedColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Data tersimpan di database SQLite lokal perangkat ini. Ekspor ke file CSV untuk cadangan atau dibuka di Excel / Google Sheets, lalu impor kembali kapan saja.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: mutedColor,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Export Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.download_outlined, size: 20),
                      label: const Text(
                        'Ekspor CSV',
                        style: TextStyle(
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
                      onPressed: _exportCSV,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Import Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.upload_outlined, size: 20),
                      label: Text(
                        'Impor CSV',
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
                      onPressed: _importCSV,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Reset All Trades
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: _confirmResetTrades,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        foregroundColor: AppColors.lose,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: borderColor),
                        ),
                      ),
                      child: const Text(
                        'Hapus Semua Trade',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
