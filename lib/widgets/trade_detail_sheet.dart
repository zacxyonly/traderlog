import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../constants/app_colors.dart';
import '../models/trade.dart';
import '../providers/trade_provider.dart';
import '../screens/trade_form_sheet.dart';
import '../utils/app_strings.dart';
import '../utils/formatters.dart';
import 'image_viewer_dialog.dart';

class TradeDetailSheet extends StatelessWidget {
  final Trade trade;
  final int tradeIndex;
  final double cumulativeEquity;
  final double changePercentage;

  const TradeDetailSheet({
    super.key,
    required this.trade,
    required this.tradeIndex,
    required this.cumulativeEquity,
    required this.changePercentage,
  });

  static Future<void> show({
    required BuildContext context,
    required Trade trade,
    required int tradeIndex,
    required double cumulativeEquity,
    required double changePercentage,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TradeDetailSheet(
        trade: trade,
        tradeIndex: tradeIndex,
        cumulativeEquity: cumulativeEquity,
        changePercentage: changePercentage,
      ),
    );
  }

  void _shareTrade(BuildContext context) {
    final currency = context.read<TradeProvider>().settings.accountCurrency;
    final emoji = trade.pl > 0 ? '🟢' : (trade.pl < 0 ? '🔴' : '⚪');
    final formattedDate = Formatters.formatDateTime(trade.date);

    final sb = StringBuffer();
    sb.writeln('$emoji TRADERLOG - TRADE #$tradeIndex');
    sb.writeln('━━━━━━━━━━━━━━━━━━━━');
    sb.writeln('📊 Symbol: ${trade.sym} (${trade.sideString})');
    sb.writeln('📅 Waktu: $formattedDate');
    sb.writeln('💰 Hasil: ${Formatters.formatAmountSigned(trade.pl, currency: currency)} (${Formatters.formatPercent(changePercentage)})');
    if (trade.formattedPips.isNotEmpty) {
      sb.writeln('⚡ Pergerakan: ${trade.formattedPips}');
    }
    if (trade.entry != null) {
      sb.writeln('🎯 Entry: ${trade.entry}${trade.exit != null ? ' ➔ Exit: ${trade.exit}' : ''}');
    }
    if (trade.sl != null || trade.tp != null) {
      sb.writeln('🛡️ SL: ${trade.sl ?? '-'} | TP: ${trade.tp ?? '-'}');
    }
    if (trade.lot != null) {
      sb.writeln('📦 Ukuran: ${trade.lot} Lot');
    }
    if (trade.formattedRR != '-') {
      sb.writeln('⚖️ Planned RR: ${trade.formattedRR}');
    }
    if (trade.formattedRealizedRR != '-') {
      sb.writeln('🏆 Realized RR: ${trade.formattedRealizedRR}');
    }
    if (trade.why != null && trade.why!.isNotEmpty) {
      sb.writeln('💡 Setup: ${trade.why}');
    }
    if (trade.note != null && trade.note!.isNotEmpty) {
      sb.writeln('📝 Evaluasi: ${trade.note}');
    }
    sb.writeln('━━━━━━━━━━━━━━━━━━━━');
    sb.writeln('Jurnal Trading Profesional by TraderLog');

    final text = sb.toString();
    Share.share(text);
  }

  void _duplicateTrade(BuildContext context) {
    Navigator.of(context).pop();
    TradeFormSheet.show(
      context,
      initialTrade: trade,
    );
  }

  void _editTrade(BuildContext context) {
    Navigator.of(context).pop();
    TradeFormSheet.show(
      context,
      tradeToEdit: trade,
    );
  }

  void _deleteTrade(BuildContext context) {
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
              Navigator.of(ctx).pop(); // dialog
              Navigator.of(context).pop(); // sheet
              context.read<TradeProvider>().deleteTrade(trade.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppStrings.tr('trade_deleted', lang))),
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

    final provider = context.watch<TradeProvider>();
    final currency = provider.settings.accountCurrency;
    final lang = provider.settings.languageCode;

    final isWin = trade.result == TradeResult.win;
    final isLose = trade.result == TradeResult.lose;
    final statusColor = isWin
        ? AppColors.winText
        : (isLose ? AppColors.loseText : AppColors.beText);
    final statusBgColor = isWin
        ? AppColors.winBg
        : (isLose ? AppColors.loseBg : AppColors.beBg);

    final isBuy = trade.side == TradeSide.buy;
    final sideColor = isBuy ? AppColors.winText : AppColors.loseText;
    final sideBgColor = isBuy ? AppColors.winBg : AppColors.loseBg;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pull Bar Indicator
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: mutedColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header: #Index, Symbol, Side & Result
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        '#$tradeIndex ${trade.sym}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: sideBgColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          trade.sideString,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: sideColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      trade.resultString,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // PnL Hero Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: statusBgColor.withOpacity(isDark ? 0.35 : 0.6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Formatters.formatAmountSigned(trade.pl, currency: currency),
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: statusColor,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${Formatters.formatPercent(changePercentage)} saldo · Equity ${Formatters.formatAmount(cumulativeEquity, currency: currency)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: textColor.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                    if (trade.formattedPips.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.bolt, size: 16, color: statusColor),
                            const SizedBox(width: 4),
                            Text(
                              trade.formattedPips,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Key Execution Metrics (Entry, Exit, SL, TP, Lots, R:R)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: softColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricTile(
                            AppStrings.tr('entry_price', lang),
                            trade.entry != null ? trade.entry.toString() : '-',
                            textColor,
                            mutedColor,
                          ),
                        ),
                        Expanded(
                          child: _buildMetricTile(
                            AppStrings.tr('exit_price', lang),
                            trade.exit != null ? trade.exit.toString() : '-',
                            textColor,
                            mutedColor,
                          ),
                        ),
                        Expanded(
                          child: _buildMetricTile(
                            AppStrings.tr('lot_size', lang),
                            trade.lot != null ? trade.lot.toString() : '-',
                            textColor,
                            mutedColor,
                          ),
                        ),
                      ],
                    ),
                    Divider(color: borderColor, height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricTile(
                            AppStrings.tr('stop_loss', lang),
                            trade.sl != null ? trade.sl.toString() : '-',
                            trade.sl != null ? AppColors.loseText : textColor,
                            mutedColor,
                          ),
                        ),
                        Expanded(
                          child: _buildMetricTile(
                            AppStrings.tr('take_profit', lang),
                            trade.tp != null ? trade.tp.toString() : '-',
                            trade.tp != null ? AppColors.winText : textColor,
                            mutedColor,
                          ),
                        ),
                        Expanded(
                          child: _buildMetricTile(
                            AppStrings.tr('risk_reward', lang),
                            trade.formattedRR,
                            AppColors.primaryLight,
                            mutedColor,
                          ),
                        ),
                      ],
                    ),
                    if (trade.formattedRealizedRR != '-') ...[
                      Divider(color: borderColor, height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppStrings.tr('realized_rr', lang),
                            style: TextStyle(fontSize: 12, color: mutedColor, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            trade.formattedRealizedRR,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.winText),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Date & Time
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 14, color: mutedColor),
                  const SizedBox(width: 6),
                  Text(
                    Formatters.formatDateTime(trade.date),
                    style: TextStyle(fontSize: 13, color: mutedColor, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Setup / Why Reason
              if (trade.why != null && trade.why!.isNotEmpty) ...[
                Text(
                  AppStrings.tr('why_label', lang),
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: mutedColor),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: softColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: Text(
                    trade.why!,
                    style: TextStyle(fontSize: 14, color: textColor, fontWeight: FontWeight.w500, height: 1.35),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Notes / Psychology
              if (trade.note != null && trade.note!.isNotEmpty) ...[
                Text(
                  AppStrings.tr('note_label', lang),
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: mutedColor),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: softColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: Text(
                    trade.note!,
                    style: TextStyle(fontSize: 14, color: textColor, fontWeight: FontWeight.w500, height: 1.35),
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Chart Screenshots (Before & After)
              if ((trade.imagePath != null && trade.imagePath!.isNotEmpty) ||
                  (trade.imagePathAfter != null && trade.imagePathAfter!.isNotEmpty)) ...[
                Text(
                  AppStrings.tr('chart_screenshot', lang),
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: mutedColor),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (trade.imagePath != null && trade.imagePath!.isNotEmpty)
                      Expanded(
                        child: GestureDetector(
                          onTap: () => ImageViewerDialog.show(
                            context,
                            trade.imagePath!,
                            '${trade.sym} (Setup / Before)',
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Stack(
                              children: [
                                Image.file(
                                  File(trade.imagePath!),
                                  height: 110,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                                Positioned(
                                  bottom: 6,
                                  left: 6,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.black87,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'Before (Setup)',
                                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    if (trade.imagePath != null &&
                        trade.imagePath!.isNotEmpty &&
                        trade.imagePathAfter != null &&
                        trade.imagePathAfter!.isNotEmpty)
                      const SizedBox(width: 8),
                    if (trade.imagePathAfter != null && trade.imagePathAfter!.isNotEmpty)
                      Expanded(
                        child: GestureDetector(
                          onTap: () => ImageViewerDialog.show(
                            context,
                            trade.imagePathAfter!,
                            '${trade.sym} (Outcome / After)',
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Stack(
                              children: [
                                Image.file(
                                  File(trade.imagePathAfter!),
                                  height: 110,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                                Positioned(
                                  bottom: 6,
                                  left: 6,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.black87,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'After (Outcome)',
                                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
              ],

              // Action Buttons: Edit | Duplicate | Share | Delete
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: Text(AppStrings.tr('edit_trade', lang)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _editTrade(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.copy_outlined, size: 16),
                      label: Text(AppStrings.tr('duplicate_trade', lang)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: borderColor),
                        foregroundColor: textColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _duplicateTrade(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.share_outlined, size: 20),
                    tooltip: AppStrings.tr('share_trade', lang),
                    onPressed: () => _shareTrade(context),
                    style: IconButton.styleFrom(
                      backgroundColor: softColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: borderColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.lose),
                    tooltip: AppStrings.tr('delete_trade', lang),
                    onPressed: () => _deleteTrade(context),
                    style: IconButton.styleFrom(
                      backgroundColor: softColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: borderColor),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, Color valueColor, Color labelColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 10.5, color: labelColor, fontWeight: FontWeight.w600),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: valueColor),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
