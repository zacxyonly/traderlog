import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/trade.dart';
import '../providers/trade_provider.dart';
import '../utils/app_strings.dart';
import '../utils/formatters.dart';
import '../widgets/pnl_calculator_sheet.dart';

class TradeFormSheet extends StatefulWidget {
  final Trade? tradeToEdit;

  const TradeFormSheet({super.key, this.tradeToEdit});

  static Future<void> show(BuildContext context, {Trade? tradeToEdit}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TradeFormSheet(tradeToEdit: tradeToEdit),
    );
  }

  @override
  State<TradeFormSheet> createState() => _TradeFormSheetState();
}

class _TradeFormSheetState extends State<TradeFormSheet> {
  late DateTime _selectedDate;
  late String _selectedSymbol;
  late TradeSide _side;

  final _entryController = TextEditingController();
  final _slController = TextEditingController();
  final _tpController = TextEditingController();
  final _lotController = TextEditingController();
  final _plController = TextEditingController();
  final _whyController = TextEditingController();
  final _noteController = TextEditingController();

  String? _imagePath;
  String? _imagePathAfter;
  final ImagePicker _picker = ImagePicker();

  static const List<String> _setupTags = [
    'BOS',
    'CHOCH',
    'FVG',
    'Liquidity',
    'Supply/Demand',
    'Trendline',
    'S&R',
    'News',
    'Fibonacci',
  ];

  static const List<String> _emotionTags = [
    'Disiplin',
    'FOMO',
    'Revenge Trade',
    'Overlot',
    'Sabar',
    'Greedy',
    'Hesitant',
    'Plan Executed',
    'Early Exit',
  ];

  @override
  void initState() {
    super.initState();
    final t = widget.tradeToEdit;
    final provider = context.read<TradeProvider>();

    _selectedDate = t?.date ?? DateTime.now();
    _side = t?.side ?? TradeSide.buy;

    final symbols = provider.settings.symbols;
    if (t != null && t.sym.isNotEmpty) {
      _selectedSymbol = t.sym;
    } else if (symbols.isNotEmpty) {
      _selectedSymbol = symbols.first;
    } else {
      _selectedSymbol = 'XAU/USD';
    }

    if (t != null) {
      if (t.entry != null) _entryController.text = t.entry.toString();
      if (t.sl != null) _slController.text = t.sl.toString();
      if (t.tp != null) _tpController.text = t.tp.toString();
      if (t.lot != null) _lotController.text = t.lot.toString();
      _plController.text = t.pl.toString();
      if (t.why != null) _whyController.text = t.why!;
      if (t.note != null) _noteController.text = t.note!;
      _imagePath = t.imagePath;
      _imagePathAfter = t.imagePathAfter;
    }

    _entryController.addListener(_updateRR);
    _slController.addListener(_updateRR);
    _tpController.addListener(_updateRR);
  }

  @override
  void dispose() {
    _entryController.removeListener(_updateRR);
    _slController.removeListener(_updateRR);
    _tpController.removeListener(_updateRR);
    _entryController.dispose();
    _slController.dispose();
    _tpController.dispose();
    _lotController.dispose();
    _plController.dispose();
    _whyController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _updateRR() {
    setState(() {});
  }

  void _toggleSetupTag(String tag) {
    final current = _whyController.text;
    if (current.contains(tag)) {
      final updated = current
          .replaceAll(tag, '')
          .replaceAll(', ,', ',')
          .replaceAll(RegExp(r'^[,\s]+|[,\s]+$'), '');
      _whyController.text = updated;
    } else {
      if (current.trim().isEmpty) {
        _whyController.text = tag;
      } else {
        _whyController.text = '${current.trim()}, $tag';
      }
    }
    setState(() {});
  }

  void _toggleEmotionTag(String tag) {
    final current = _noteController.text;
    if (current.contains(tag)) {
      final updated = current
          .replaceAll(tag, '')
          .replaceAll(', ,', ',')
          .replaceAll(RegExp(r'^[,\s]+|[,\s]+$'), '');
      _noteController.text = updated;
    } else {
      if (current.trim().isEmpty) {
        _noteController.text = tag;
      } else {
        _noteController.text = '${current.trim()}, $tag';
      }
    }
    setState(() {});
  }

  void _openCalculator() {
    final entry = double.tryParse(_entryController.text);
    final exit = double.tryParse(_tpController.text) ?? double.tryParse(_slController.text);
    final lot = double.tryParse(_lotController.text);
    final provider = context.read<TradeProvider>();

    PnlCalculatorSheet.show(
      context: context,
      side: _side,
      initialEntry: entry,
      initialExit: exit,
      initialLot: lot,
      symbol: _selectedSymbol,
      currency: provider.settings.accountCurrency,
      lang: provider.settings.languageCode,
      onApply: (estimated) {
        setState(() {
          _plController.text = estimated.toStringAsFixed(2);
        });
      },
    );
  }

  String _calculateLiveRR() {
    final entry = double.tryParse(_entryController.text);
    final sl = double.tryParse(_slController.text);
    final tp = double.tryParse(_tpController.text);

    if (entry != null && sl != null && tp != null && entry != sl) {
      final risk = (entry - sl).abs();
      final reward = (tp - entry).abs();
      if (risk > 0) {
        final rr = reward / risk;
        return '1:${rr.toStringAsFixed(2)}';
      }
    }
    return '-';
  }

  Future<void> _pickImage(ImageSource source, {bool isAfter = false}) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          if (isAfter) {
            _imagePathAfter = pickedFile.path;
          } else {
            _imagePath = pickedFile.path;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memilih gambar: $e')),
        );
      }
    }
  }

  Future<void> _selectDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  void _saveTrade() {
    final lang = context.read<TradeProvider>().settings.languageCode;
    final plText = _plController.text.trim();
    if (plText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.tr('fill_pl_first', lang))),
      );
      return;
    }

    final pl = double.tryParse(plText);
    if (pl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.tr('invalid_pl', lang))),
      );
      return;
    }

    final provider = context.read<TradeProvider>();
    final entry = double.tryParse(_entryController.text.trim());
    final sl = double.tryParse(_slController.text.trim());
    final tp = double.tryParse(_tpController.text.trim());
    final lot = double.tryParse(_lotController.text.trim());
    final why = _whyController.text.trim();
    final note = _noteController.text.trim();

    final trade = Trade(
      id: widget.tradeToEdit?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      date: _selectedDate,
      sym: _selectedSymbol,
      side: _side,
      entry: entry,
      sl: sl,
      tp: tp,
      lot: lot,
      pl: pl,
      why: why.isNotEmpty ? why : null,
      note: note.isNotEmpty ? note : null,
      imagePath: _imagePath,
      imagePathAfter: _imagePathAfter,
      accountId: widget.tradeToEdit?.accountId ?? provider.settings.activeAccountId,
    );

    if (widget.tradeToEdit != null) {
      provider.updateTrade(trade);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.tr('trade_updated', lang))),
      );
    } else {
      provider.addTrade(trade);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.tr('trade_saved', lang))),
      );
    }

    Navigator.of(context).pop();
  }

  void _deleteTrade() {
    final lang = context.read<TradeProvider>().settings.languageCode;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.tr('delete_trade', lang)),
        content: Text(AppStrings.tr('confirm_delete_trade', lang)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppStrings.tr('cancel', lang)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop(); // Close dialog
              if (widget.tradeToEdit != null) {
                context
                    .read<TradeProvider>()
                    .deleteTrade(widget.tradeToEdit!.id);
                Navigator.of(context).pop(); // Close sheet
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppStrings.tr('trade_deleted', lang))),
                );
              }
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

    final provider = context.watch<TradeProvider>();
    final symbols = provider.settings.symbols;
    final lang = provider.settings.languageCode;
    final isEdit = widget.tradeToEdit != null;

    final allSymbols = List<String>.from(symbols);
    if (!allSymbols.contains(_selectedSymbol)) {
      allSymbols.insert(0, _selectedSymbol);
    }

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(26),
          topRight: Radius.circular(26),
        ),
      ),
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        top: 18,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEdit
                        ? AppStrings.tr('edit_trade', lang)
                        : AppStrings.tr('new_trade', lang),
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: mutedColor),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Tanggal & Waktu
              _buildLabel(AppStrings.tr('date_time', lang), mutedColor),
              InkWell(
                onTap: _selectDateTime,
                borderRadius: BorderRadius.circular(13),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: softColor,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        Formatters.formatDateTime(_selectedDate),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      Icon(Icons.calendar_today_outlined,
                          size: 18, color: mutedColor),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Symbol
              _buildLabel(AppStrings.tr('symbol_pair', lang), mutedColor),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: softColor,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: borderColor),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedSymbol,
                    isExpanded: true,
                    dropdownColor: cardColor,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                    items: allSymbols
                        .map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(s),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedSymbol = val);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Posisi (BUY / SELL)
              _buildLabel(AppStrings.tr('position', lang), mutedColor),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _side = TradeSide.buy),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _side == TradeSide.buy
                              ? AppColors.primary
                              : softColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _side == TradeSide.buy
                                ? AppColors.primary
                                : borderColor,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'BUY',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: _side == TradeSide.buy
                                ? Colors.white
                                : textColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _side = TradeSide.sell),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _side == TradeSide.sell
                              ? AppColors.lose
                              : softColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _side == TradeSide.sell
                                ? AppColors.lose
                                : borderColor,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'SELL',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: _side == TradeSide.sell
                                ? Colors.white
                                : textColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Entry & Lot Size
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel(
                            AppStrings.tr('entry_price', lang), mutedColor),
                        _buildTextField(
                          controller: _entryController,
                          hint: lang == 'en' ? 'e.g. 2350.50' : 'mis. 2350.50',
                          softColor: softColor,
                          borderColor: borderColor,
                          textColor: textColor,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel(
                            AppStrings.tr('lot_size', lang), mutedColor),
                        _buildTextField(
                          controller: _lotController,
                          hint: lang == 'en' ? 'e.g. 0.10' : 'mis. 0.10',
                          softColor: softColor,
                          borderColor: borderColor,
                          textColor: textColor,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // SL & TP
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel(
                            AppStrings.tr('stop_loss', lang), mutedColor),
                        _buildTextField(
                          controller: _slController,
                          hint: lang == 'en' ? 'e.g. 2340.00' : 'mis. 2340.00',
                          softColor: softColor,
                          borderColor: borderColor,
                          textColor: textColor,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel(
                            AppStrings.tr('take_profit', lang), mutedColor),
                        _buildTextField(
                          controller: _tpController,
                          hint: lang == 'en' ? 'e.g. 2370.00' : 'mis. 2370.00',
                          softColor: softColor,
                          borderColor: borderColor,
                          textColor: textColor,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Live RR Indicator
              Text(
                '${AppStrings.tr('risk_reward', lang)}: ${_calculateLiveRR()}',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryLight,
                ),
              ),
              const SizedBox(height: 12),

              // Profit / Loss with Calculator Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildLabel(
                    AppStrings.tr(
                      'pl_label',
                      lang,
                      params: {'curr': provider.settings.accountCurrency},
                    ),
                    mutedColor,
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: _openCalculator,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 6, right: 4, bottom: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calculate_outlined, size: 15, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            AppStrings.tr('calc_pnl_button', lang),
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
              _buildTextField(
                controller: _plController,
                hint: AppStrings.tr('pl_hint', lang),
                softColor: softColor,
                borderColor: borderColor,
                textColor: textColor,
                keyboardType: const TextInputType.numberWithOptions(
                  signed: true,
                  decimal: true,
                ),
              ),
              const SizedBox(height: 12),

              // Alasan ("Why") + Quick Setup Chips
              _buildLabel(AppStrings.tr('why_label', lang), mutedColor),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _setupTags.map((tag) {
                    final isSelected = _whyController.text.contains(tag);
                    return GestureDetector(
                      onTap: () => _toggleSetupTag(tag),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 140),
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary.withOpacity(0.18) : softColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : borderColor,
                            width: isSelected ? 1.3 : 1.0,
                          ),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? AppColors.primary : mutedColor,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              _buildTextField(
                controller: _whyController,
                hint: AppStrings.tr('why_hint', lang),
                softColor: softColor,
                borderColor: borderColor,
                textColor: textColor,
                maxLines: 2,
              ),
              const SizedBox(height: 12),

              // Catatan ("Note") + Quick Emotion Chips
              _buildLabel(AppStrings.tr('note_label', lang), mutedColor),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _emotionTags.map((tag) {
                    final isSelected = _noteController.text.contains(tag);
                    final isNegative = tag == 'FOMO' || tag == 'Revenge Trade' || tag == 'Overlot' || tag == 'Greedy' || tag == 'Hesitant';
                    final highlightColor = isNegative ? AppColors.lose : AppColors.primary;

                    return GestureDetector(
                      onTap: () => _toggleEmotionTag(tag),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 140),
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(
                          color: isSelected ? highlightColor.withOpacity(0.18) : softColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? highlightColor : borderColor,
                            width: isSelected ? 1.3 : 1.0,
                          ),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? highlightColor : mutedColor,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              _buildTextField(
                controller: _noteController,
                hint: AppStrings.tr('note_hint', lang),
                softColor: softColor,
                borderColor: borderColor,
                textColor: textColor,
                maxLines: 2,
              ),
              const SizedBox(height: 14),

              // Dua Slot Gambar: Slot 1 (Sebelum Entry / Setup) & Slot 2 (Sesudah Selesai / Eksekusi)
              _buildImageSlot(
                title: AppStrings.tr('slot_before', lang),
                imagePath: _imagePath,
                onPick: (src) => _pickImage(src, isAfter: false),
                onClear: () => setState(() => _imagePath = null),
                lang: lang,
                softColor: softColor,
                borderColor: borderColor,
                mutedColor: mutedColor,
              ),
              const SizedBox(height: 14),
              _buildImageSlot(
                title: AppStrings.tr('slot_after', lang),
                imagePath: _imagePathAfter,
                onPick: (src) => _pickImage(src, isAfter: true),
                onClear: () => setState(() => _imagePathAfter = null),
                lang: lang,
                softColor: softColor,
                borderColor: borderColor,
                mutedColor: mutedColor,
              ),
              const SizedBox(height: 18),

              // Primary Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveTrade,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    isEdit
                        ? AppStrings.tr('save_changes', lang)
                        : AppStrings.tr('save_trade', lang),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),

              // Delete Button (if edit)
              if (isEdit) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: _deleteTrade,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      foregroundColor: AppColors.lose,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: borderColor),
                      ),
                    ),
                    child: Text(
                      AppStrings.tr('delete_trade', lang),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required Color softColor,
    required Color borderColor,
    required Color textColor,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: textColor.withOpacity(0.4),
        ),
        filled: true,
        fillColor: softColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
      ),
    );
  }

  Widget _buildImageSlot({
    required String title,
    required String? imagePath,
    required ValueChanged<ImageSource> onPick,
    required VoidCallback onClear,
    required String lang,
    required Color softColor,
    required Color borderColor,
    required Color mutedColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(title, mutedColor),
        if (imagePath != null && imagePath.isNotEmpty) ...[
          Stack(
            alignment: Alignment.topRight,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: Container(
                  height: 140,
                  width: double.infinity,
                  color: Colors.black12,
                  child: Image.file(
                    File(imagePath),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              IconButton(
                icon: const CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.black87,
                  child: Icon(Icons.close, size: 16, color: Colors.white),
                ),
                onPressed: onClear,
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.photo_library_outlined, size: 16),
                label: Text(
                  AppStrings.tr('from_gallery', lang),
                  style: const TextStyle(fontSize: 12),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  side: BorderSide(color: borderColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
                onPressed: () => onPick(ImageSource.gallery),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.camera_alt_outlined, size: 16),
                label: Text(
                  AppStrings.tr('open_camera', lang),
                  style: const TextStyle(fontSize: 12),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  side: BorderSide(color: borderColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
                onPressed: () => onPick(ImageSource.camera),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
