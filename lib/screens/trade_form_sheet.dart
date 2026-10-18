import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/trade.dart';
import '../providers/trade_provider.dart';
import '../utils/app_strings.dart';
import '../utils/formatters.dart';
import '../utils/pnl_calculator.dart';
import '../utils/trade_analytics.dart';

class TradeFormSheet extends StatefulWidget {
  final Trade? tradeToEdit;
  final Trade? initialTrade;

  const TradeFormSheet({
    super.key,
    this.tradeToEdit,
    this.initialTrade,
  });

  static Future<void> show(
    BuildContext context, {
    Trade? tradeToEdit,
    Trade? initialTrade,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TradeFormSheet(
        tradeToEdit: tradeToEdit,
        initialTrade: initialTrade,
      ),
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
  final _exitController = TextEditingController();
  final _slController = TextEditingController();
  final _tpController = TextEditingController();
  final _lotController = TextEditingController();
  final _plController = TextEditingController();
  final _whyController = TextEditingController();
  final _noteController = TextEditingController();

  PnlResult? _lastCalculatedPnl;

  String get _accountCurrency =>
      context.read<TradeProvider>().activeAccount.currency;
  PnlResult? _plannedRisk;
  PnlResult? _plannedReward;
  bool _isUserEditedPl = false;

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
    final init = widget.initialTrade;
    final provider = context.read<TradeProvider>();

    _selectedDate = t?.date ?? DateTime.now();
    _side = t?.side ?? init?.side ?? TradeSide.buy;

    final symbols = provider.settings.symbols;
    final activeSym = t?.sym ?? init?.sym;
    if (activeSym != null && activeSym.isNotEmpty) {
      _selectedSymbol = activeSym;
    } else if (symbols.isNotEmpty) {
      _selectedSymbol = symbols.first;
    } else {
      _selectedSymbol = 'XAU/USD';
    }

    if (t != null) {
      if (t.entry != null) _entryController.text = t.entry.toString();
      if (t.exit != null) _exitController.text = t.exit.toString();
      if (t.sl != null) _slController.text = t.sl.toString();
      if (t.tp != null) _tpController.text = t.tp.toString();
      if (t.lot != null) _lotController.text = t.lot.toString();
      _plController.text = t.pl.toString();
      if (t.why != null) _whyController.text = t.why!;
      if (t.note != null) _noteController.text = t.note!;
      _imagePath = t.imagePath;
      _imagePathAfter = t.imagePathAfter;
    } else if (init != null) {
      if (init.entry != null) _entryController.text = init.entry.toString();
      if (init.sl != null) _slController.text = init.sl.toString();
      if (init.tp != null) _tpController.text = init.tp.toString();
      if (init.lot != null) _lotController.text = init.lot.toString();
      if (init.why != null) _whyController.text = init.why!;
    }

    // Prefill default lot for brand-new trades only
    if (t == null &&
        _lotController.text.isEmpty &&
        provider.settings.defaultLot > 0) {
      _lotController.text = provider.settings.defaultLot.toString();
    }

    _entryController.addListener(_onPriceOrLotChanged);
    _exitController.addListener(_onPriceOrLotChanged);
    _lotController.addListener(_onPriceOrLotChanged);
    _slController.addListener(_onPriceOrLotChanged);
    _tpController.addListener(_onPriceOrLotChanged);
    _plController.addListener(_onPlManualChanged);

    // Initial calculation if editing
    _onPriceOrLotChanged(isInitial: true);
  }

  @override
  void dispose() {
    _entryController.removeListener(_onPriceOrLotChanged);
    _exitController.removeListener(_onPriceOrLotChanged);
    _lotController.removeListener(_onPriceOrLotChanged);
    _slController.removeListener(_onPriceOrLotChanged);
    _tpController.removeListener(_onPriceOrLotChanged);
    _plController.removeListener(_onPlManualChanged);

    _entryController.dispose();
    _exitController.dispose();
    _slController.dispose();
    _tpController.dispose();
    _lotController.dispose();
    _plController.dispose();
    _whyController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onPlManualChanged() {
    final autoPnl = _lastCalculatedPnl?.pnl;
    if (autoPnl != null) {
      final current = double.tryParse(_plController.text.trim());
      if (current != null && (current - autoPnl).abs() > 0.009) {
        if (!_isUserEditedPl) {
          setState(() {
            _isUserEditedPl = true;
          });
        }
      }
    }
  }

  void _onPriceOrLotChanged({bool isInitial = false, bool forceAutoPl = false}) {
    final entry = double.tryParse(_entryController.text.trim());
    final exit = double.tryParse(_exitController.text.trim());
    final lot = double.tryParse(_lotController.text.trim());
    final sl = double.tryParse(_slController.text.trim());
    final tp = double.tryParse(_tpController.text.trim());

    if (entry != null && exit != null && lot != null && lot > 0) {
      final calc = PnlCalculator.calculate(
        symbol: _selectedSymbol,
        side: _side,
        entry: entry,
        exit: exit,
        lot: lot,
        accountCurrency: _accountCurrency,
      );
      _lastCalculatedPnl = calc;
      final autoPnl = calc?.pnl;
      // When the P/L cannot be derived reliably (cross pairs, non-USD
      // account) the field is left untouched for the user to fill in.
      if (autoPnl != null && (!isInitial || widget.tradeToEdit == null || forceAutoPl)) {
        if (!_isUserEditedPl || forceAutoPl) {
          _plController.text = autoPnl.toStringAsFixed(2);
          _isUserEditedPl = false;
        }
      }
    } else {
      _lastCalculatedPnl = null;
    }

    if (entry != null && sl != null && lot != null && lot > 0) {
      _plannedRisk = PnlCalculator.calculateRisk(
        symbol: _selectedSymbol,
        side: _side,
        entry: entry,
        sl: sl,
        lot: lot,
        accountCurrency: _accountCurrency,
      );
    } else {
      _plannedRisk = null;
    }

    if (entry != null && tp != null && lot != null && lot > 0) {
      _plannedReward = PnlCalculator.calculateReward(
        symbol: _selectedSymbol,
        side: _side,
        entry: entry,
        tp: tp,
        lot: lot,
        accountCurrency: _accountCurrency,
      );
    } else {
      _plannedReward = null;
    }

    if (mounted) setState(() {});
  }

  void _applyTpToExit() {
    final tp = _tpController.text.trim();
    if (tp.isNotEmpty) {
      _exitController.text = tp;
      _onPriceOrLotChanged(forceAutoPl: true);
    }
  }

  void _applySlToExit() {
    final sl = _slController.text.trim();
    if (sl.isNotEmpty) {
      _exitController.text = sl;
      _onPriceOrLotChanged(forceAutoPl: true);
    }
  }

  void _applyBeToExit() {
    final entry = _entryController.text.trim();
    if (entry.isNotEmpty) {
      _exitController.text = entry;
      _onPriceOrLotChanged(forceAutoPl: true);
    }
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

  String _calculateRealizedRR() {
    final entry = double.tryParse(_entryController.text.trim());
    final exit = double.tryParse(_exitController.text.trim());
    final sl = double.tryParse(_slController.text.trim());

    if (entry != null && exit != null && sl != null && entry != sl) {
      final risk = (entry - sl).abs();
      final reward = (_side == TradeSide.buy) ? (exit - entry) : (entry - exit);
      if (risk > 0) {
        final rr = reward / risk;
        if (rr >= 0) {
          return '1:${rr.toStringAsFixed(2)}';
        } else {
          return '-1:${rr.abs().toStringAsFixed(2)}';
        }
      }
    }
    return '-';
  }

  void _safeDeleteFile(String? path) {
    if (path != null && path.trim().isNotEmpty) {
      try {
        final f = File(path);
        if (f.existsSync()) {
          f.deleteSync();
        }
      } catch (e) {
        debugPrint('Failed to delete file at $path: $e');
      }
    }
  }

  Future<void> _pickImage(ImageSource source, {bool isAfter = false}) async {
    final provider = context.read<TradeProvider>();
    provider.setSystemPickerActive(true);
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        final appDir = await getApplicationDocumentsDirectory();
        final ext = pickedFile.path.contains('.') ? pickedFile.path.split('.').last : 'jpg';
        final fileName = 'chart_${DateTime.now().millisecondsSinceEpoch}_${isAfter ? 'after' : 'before'}.$ext';
        final savedFile = await File(pickedFile.path).copy('${appDir.path}/$fileName');

        setState(() {
          if (isAfter) {
            _imagePathAfter = savedFile.path;
          } else {
            _imagePath = savedFile.path;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memilih gambar: $e')),
        );
      }
    } finally {
      Future.delayed(const Duration(milliseconds: 600), () {
        provider.setSystemPickerActive(false);
      });
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
    final exit = double.tryParse(_exitController.text.trim());
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
      exit: exit,
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
      if (widget.tradeToEdit!.imagePath != null &&
          widget.tradeToEdit!.imagePath != _imagePath) {
        _safeDeleteFile(widget.tradeToEdit!.imagePath);
      }
      if (widget.tradeToEdit!.imagePathAfter != null &&
          widget.tradeToEdit!.imagePathAfter != _imagePathAfter) {
        _safeDeleteFile(widget.tradeToEdit!.imagePathAfter);
      }
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

    _showRiskWarning(provider, trade, lang);
    Navigator.of(context).pop();
  }

  void _showRiskWarning(TradeProvider provider, Trade trade, String lang) {
    final account = provider.activeAccount;
    final limit = account.maxRiskPercent;
    if (limit == null) return;

    // Ganti versi lama trade ini (bila edit) dengan versi yang baru disimpan.
    final all = [...provider.trades.where((t) => t.id != trade.id), trade];
    final ratio = TradeAnalytics.riskFor(all, account, trade.id)?.riskRatio;
    if (ratio == null || ratio * 100 <= limit) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.lose,
        behavior: SnackBarBehavior.floating,
        content: Text(
          AppStrings.tr(
            'risk_over_limit',
            lang,
            params: {
              'pct': (ratio * 100).toStringAsFixed(2),
              'limit': limit.toStringAsFixed(2),
            },
          ),
        ),
      ),
    );
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

              // Entry & Exit Price (Auto PnL inputs)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildLabel(
                                AppStrings.tr('exit_price', lang), mutedColor),
                            // Quick chips to copy TP, SL, or BE
                            Wrap(
                              spacing: 3,
                              children: [
                                if (_tpController.text.trim().isNotEmpty)
                                  InkWell(
                                    onTap: _applyTpToExit,
                                    borderRadius: BorderRadius.circular(4),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: AppColors.winText.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        AppStrings.tr('use_tp', lang),
                                        style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: AppColors.winText),
                                      ),
                                    ),
                                  ),
                                if (_slController.text.trim().isNotEmpty)
                                  InkWell(
                                    onTap: _applySlToExit,
                                    borderRadius: BorderRadius.circular(4),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: AppColors.loseText.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        AppStrings.tr('use_sl', lang),
                                        style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: AppColors.loseText),
                                      ),
                                    ),
                                  ),
                                if (_entryController.text.trim().isNotEmpty)
                                  InkWell(
                                    onTap: _applyBeToExit,
                                    borderRadius: BorderRadius.circular(4),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: mutedColor.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        AppStrings.tr('use_be', lang),
                                        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: mutedColor),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        _buildTextField(
                          controller: _exitController,
                          hint: lang == 'en' ? 'e.g. 2375.00' : 'mis. 2375.00',
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

              // Lot Size & R:R Summary
              Row(
                children: [
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
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      height: 50,
                      margin: const EdgeInsets.only(top: 20),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: softColor,
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                AppStrings.tr('risk_reward', lang),
                                style: TextStyle(fontSize: 11, color: mutedColor, fontWeight: FontWeight.w600),
                              ),
                              Text(
                                _calculateLiveRR(),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primaryLight),
                              ),
                            ],
                          ),
                          if (_exitController.text.trim().isNotEmpty && _entryController.text.trim().isNotEmpty && _slController.text.trim().isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  AppStrings.tr('realized_rr', lang),
                                  style: TextStyle(fontSize: 10.5, color: mutedColor, fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  _calculateRealizedRR(),
                                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.winText),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // SL & TP Inputs
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
              const SizedBox(height: 10),

              // Planned Risk & Reward Management Card (Live Position Sizing)
              if (_plannedRisk?.pnl != null || _plannedReward?.pnl != null) ...[
                Builder(builder: (context) {
                  final capital = provider.activeAccount.initialCapital;
                  final riskNominal = _plannedRisk?.pnl?.abs() ?? 0.0;
                  final riskPct = capital > 0 ? (riskNominal / capital) * 100 : 0.0;
                  final isOverlot = riskPct > 5.0;

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isOverlot ? AppColors.lose.withOpacity(0.08) : softColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isOverlot ? AppColors.lose.withOpacity(0.4) : borderColor,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (_plannedRisk?.pnl != null)
                              Row(
                                children: [
                                  const Icon(Icons.shield_outlined, size: 14, color: AppColors.loseText),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${AppStrings.tr('risk_planned', lang)}: ${Formatters.formatAmountSigned(_plannedRisk!.pnl!, currency: provider.activeAccount.currency)} (${riskPct.toStringAsFixed(1)}%)',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: isOverlot ? AppColors.loseText : mutedColor,
                                    ),
                                  ),
                                ],
                              ),
                            if (_plannedReward?.pnl != null)
                              Row(
                                children: [
                                  const Icon(Icons.flag_outlined, size: 14, color: AppColors.winText),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${AppStrings.tr('reward_planned', lang)}: ${Formatters.formatAmountSigned(_plannedReward!.pnl!, currency: provider.activeAccount.currency)}',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.winText,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        if (isOverlot) ...[
                          const SizedBox(height: 4),
                          Text(
                            AppStrings.tr('risk_warn_overlot', lang),
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.loseText,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
              ],

              // Profit / Loss with Real-time Auto-Calculation
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildLabel(
                    AppStrings.tr(
                      'pl_label',
                      lang,
                      params: {'curr': provider.activeAccount.currency},
                    ),
                    mutedColor,
                  ),
                  if (_lastCalculatedPnl != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: (_lastCalculatedPnl!.pips >= 0 ? AppColors.winText : AppColors.loseText).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${_lastCalculatedPnl!.pips >= 0 ? '⚡ +' : '⚡ '}${_lastCalculatedPnl!.formattedPips}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: _lastCalculatedPnl!.pips >= 0 ? AppColors.winText : AppColors.loseText,
                            ),
                          ),
                        ),
                        if (_isUserEditedPl) ...[
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: () => _onPriceOrLotChanged(forceAutoPl: true),
                            borderRadius: BorderRadius.circular(6),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              child: Row(
                                children: [
                                  const Icon(Icons.sync_rounded, size: 13, color: AppColors.primary),
                                  const SizedBox(width: 2),
                                  Text(
                                    AppStrings.tr('sync_calc', lang),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                ],
              ),
              _buildTextField(
                controller: _plController,
                hint: AppStrings.tr('pl_hint', lang),
                softColor: softColor,
                borderColor: _lastCalculatedPnl?.pnl != null && !_isUserEditedPl
                    ? (_lastCalculatedPnl!.pnl! >= 0 ? AppColors.winText.withOpacity(0.5) : AppColors.loseText.withOpacity(0.5))
                    : borderColor,
                textColor: textColor,
                keyboardType: const TextInputType.numberWithOptions(
                  signed: true,
                  decimal: true,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 12),
                child: Text(
                  (_lastCalculatedPnl != null && _lastCalculatedPnl!.pnl == null)
                      ? AppStrings.tr('manual_pl_needed', lang)
                      : AppStrings.tr('auto_calc_active', lang),
                  style: TextStyle(
                    fontSize: 11,
                    color: mutedColor.withOpacity(0.7),
                    fontStyle: FontStyle.italic,
                  ),
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
