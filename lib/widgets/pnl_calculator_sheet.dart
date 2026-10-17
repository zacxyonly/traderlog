import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/trade.dart';
import '../utils/app_strings.dart';
import '../utils/formatters.dart';

class PnlCalculatorSheet extends StatefulWidget {
  final TradeSide side;
  final double? initialEntry;
  final double? initialExit;
  final double? initialLot;
  final String symbol;
  final String currency;
  final String lang;
  final ValueChanged<double> onApply;

  const PnlCalculatorSheet({
    super.key,
    required this.side,
    this.initialEntry,
    this.initialExit,
    this.initialLot,
    required this.symbol,
    required this.currency,
    required this.lang,
    required this.onApply,
  });

  static Future<void> show({
    required BuildContext context,
    required TradeSide side,
    double? initialEntry,
    double? initialExit,
    double? initialLot,
    required String symbol,
    required String currency,
    required String lang,
    required ValueChanged<double> onApply,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PnlCalculatorSheet(
        side: side,
        initialEntry: initialEntry,
        initialExit: initialExit,
        initialLot: initialLot,
        symbol: symbol,
        currency: currency,
        lang: lang,
        onApply: onApply,
      ),
    );
  }

  @override
  State<PnlCalculatorSheet> createState() => _PnlCalculatorSheetState();
}

class _PnlCalculatorSheetState extends State<PnlCalculatorSheet> {
  late TradeSide _side;
  late String _assetType; // 'forex', 'gold', 'crypto'

  final _entryCtrl = TextEditingController();
  final _exitCtrl = TextEditingController();
  final _lotCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _side = widget.side;

    final sym = widget.symbol.toUpperCase();
    if (sym.contains('XAU') || sym.contains('GOLD')) {
      _assetType = 'gold';
    } else if (sym.contains('BTC') || sym.contains('ETH') || sym.contains('US30') || sym.contains('USTEC') || sym.contains('US500') || sym.contains('NAS')) {
      _assetType = 'crypto';
    } else {
      _assetType = 'forex';
    }

    if (widget.initialEntry != null && widget.initialEntry! > 0) {
      _entryCtrl.text = widget.initialEntry.toString();
    }
    if (widget.initialExit != null && widget.initialExit! > 0) {
      _exitCtrl.text = widget.initialExit.toString();
    }
    _lotCtrl.text = (widget.initialLot != null && widget.initialLot! > 0)
        ? widget.initialLot.toString()
        : '0.1';

    _entryCtrl.addListener(_recalc);
    _exitCtrl.addListener(_recalc);
    _lotCtrl.addListener(_recalc);
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _exitCtrl.dispose();
    _lotCtrl.dispose();
    super.dispose();
  }

  void _recalc() {
    setState(() {});
  }

  double? _calculatePnL() {
    final entry = double.tryParse(_entryCtrl.text);
    final exit = double.tryParse(_exitCtrl.text);
    final lot = double.tryParse(_lotCtrl.text);

    if (entry == null || exit == null || lot == null || lot <= 0) {
      return null;
    }

    final priceDiff = (_side == TradeSide.buy) ? (exit - entry) : (entry - exit);

    switch (_assetType) {
      case 'gold':
        // 1 lot = 100 oz. $1 move in Gold = $100 per 1 standard lot
        return priceDiff * 100.0 * lot;
      case 'crypto':
        // Index / Crypto: 1 point price diff = $1 per 1 lot
        return priceDiff * lot;
      case 'forex':
      default:
        // Standard Forex:
        // If JPY pair, 1 pip = 0.01; else 0.0001
        final isJpy = widget.symbol.toUpperCase().contains('JPY');
        final pipSize = isJpy ? 0.01 : 0.0001;
        final pips = priceDiff / pipSize;
        // 1 pip standard lot = $10 (approximate USD base)
        return pips * 10.0 * lot;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final softColor = isDark ? AppColors.darkSoft : AppColors.lightSoft;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final mutedColor = isDark ? AppColors.darkMuted : AppColors.lightMuted;

    final estimated = _calculatePnL();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          border: Border.all(color: borderColor),
        ),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: mutedColor.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calculate_rounded, color: AppColors.primary, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      AppStrings.tr('calc_title', widget.lang),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                  color: mutedColor,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Asset Type Segment
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: softColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  _buildTypeBtn('forex', 'Forex', softColor, textColor, mutedColor),
                  _buildTypeBtn('gold', 'Gold (XAU)', softColor, textColor, mutedColor),
                  _buildTypeBtn('crypto', 'Crypto/Idx', softColor, textColor, mutedColor),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Position (BUY / SELL)
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _side = TradeSide.buy),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: _side == TradeSide.buy ? AppColors.primary : softColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _side == TradeSide.buy ? AppColors.primary : borderColor,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'BUY',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: _side == TradeSide.buy ? Colors.white : textColor,
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
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: _side == TradeSide.sell ? AppColors.lose : softColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _side == TradeSide.sell ? AppColors.lose : borderColor,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'SELL',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: _side == TradeSide.sell ? Colors.white : textColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Entry & Exit input row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.tr('entry_price', widget.lang),
                        style: TextStyle(fontSize: 11.5, color: mutedColor, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _entryCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textColor),
                        decoration: _inputDecoration(softColor, borderColor, '2650.00'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Harga Exit / Target',
                        style: TextStyle(fontSize: 11.5, color: mutedColor, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _exitCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textColor),
                        decoration: _inputDecoration(softColor, borderColor, '2680.00'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Lot Size input
            Text(
              AppStrings.tr('lot_size', widget.lang),
              style: TextStyle(fontSize: 11.5, color: mutedColor, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _lotCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textColor),
              decoration: _inputDecoration(softColor, borderColor, '0.10'),
            ),
            const SizedBox(height: 14),

            // Estimated Result Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: estimated != null
                    ? (estimated >= 0
                        ? AppColors.win.withOpacity(0.14)
                        : AppColors.lose.withOpacity(0.14))
                    : softColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: estimated != null
                      ? (estimated >= 0 ? AppColors.win.withOpacity(0.4) : AppColors.lose.withOpacity(0.4))
                      : borderColor,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.tr('calc_est_pnl', widget.lang),
                        style: TextStyle(fontSize: 11.5, color: mutedColor, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        estimated != null
                            ? Formatters.formatAmountSigned(estimated, currency: widget.currency)
                            : '-',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: estimated != null
                              ? (estimated > 0
                                  ? AppColors.winText
                                  : (estimated < 0 ? AppColors.loseText : textColor))
                              : mutedColor,
                        ),
                      ),
                    ],
                  ),
                  if (estimated != null)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                      label: Text(
                        AppStrings.tr('calc_apply', widget.lang),
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        widget.onApply(estimated);
                        Navigator.of(context).pop();
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeBtn(String type, String label, Color softColor, Color textColor, Color mutedColor) {
    final isSelected = _assetType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _assetType = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? Colors.white : mutedColor,
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(Color softColor, Color borderColor, String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: softColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }
}
