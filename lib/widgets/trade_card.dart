import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/trade.dart';
import '../providers/trade_provider.dart';
import '../utils/formatters.dart';
import 'image_viewer_dialog.dart';

class TradeCard extends StatelessWidget {
  final Trade trade;
  final int tradeIndex;
  final double cumulativeEquity;
  final double changePercentage;
  final VoidCallback onTap;

  const TradeCard({
    super.key,
    required this.trade,
    required this.tradeIndex,
    required this.cumulativeEquity,
    required this.changePercentage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final mutedColor = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final currency = context.watch<TradeProvider>().settings.accountCurrency;

    Color statusColor;
    Color statusBgColor;
    switch (trade.result) {
      case TradeResult.win:
        statusColor = AppColors.winText;
        statusBgColor = AppColors.winBg;
        break;
      case TradeResult.lose:
        statusColor = AppColors.loseText;
        statusBgColor = AppColors.loseBg;
        break;
      case TradeResult.be:
        statusColor = AppColors.beText;
        statusBgColor = AppColors.beBg;
        break;
    }

    final isBuy = trade.side == TradeSide.buy;
    final sideColor = isBuy ? AppColors.winText : AppColors.loseText;
    final sideBgColor = isBuy ? AppColors.winBg : AppColors.loseBg;

    final plColor = trade.pl > 0
        ? AppColors.winText
        : (trade.pl < 0 ? AppColors.loseText : textColor);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left Status Border Bar
            Container(
              width: 5,
              color: statusColor,
            ),

            // Card Main Content
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top row: #Index + Symbol + Side & Result Badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '#$tradeIndex ${trade.sym}',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: sideBgColor,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    trade.sideString,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: sideColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: statusBgColor,
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                trade.resultString,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Middle row: P/L amount & % Change · RR
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  Formatters.formatAmountSigned(trade.pl, currency: currency),
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: plColor,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                if (trade.formattedPips.isNotEmpty) ...[
                                  const SizedBox(width: 6),
                                  Text(
                                    trade.formattedPips,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: plColor.withOpacity(0.85),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            Text(
                              '${Formatters.formatPercent(changePercentage)} · RR ${trade.formattedRealizedRR != '-' ? trade.formattedRealizedRR : trade.formattedRR}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: mutedColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Sub row: Entry -> Exit & Date · Cumulative Equity · Lot
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${Formatters.formatDateTime(trade.date)} · Eq ${Formatters.formatAmount(cumulativeEquity, currency: currency)}${trade.lot != null ? ' · ${trade.lot} lot' : ''}',
                              style: TextStyle(
                                fontSize: 12,
                                color: mutedColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (trade.entry != null)
                              Text(
                                '${trade.entry}${trade.exit != null ? ' ➔ ${trade.exit}' : ''}',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: textColor.withOpacity(0.7),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),

                        // Setup / Reason ("Why")
                        if (trade.why != null && trade.why!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            trade.why!,
                            style: TextStyle(
                              fontSize: 13,
                              color: textColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],

                        // Image attachments (Before & After)
                        if ((trade.imagePath != null && trade.imagePath!.isNotEmpty) ||
                            (trade.imagePathAfter != null && trade.imagePathAfter!.isNotEmpty)) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              if (trade.imagePath != null && trade.imagePath!.isNotEmpty)
                                GestureDetector(
                                  onTap: () {
                                    ImageViewerDialog.show(
                                      context,
                                      trade.imagePath!,
                                      '${trade.sym} (Before Entry)',
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 9,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark ? AppColors.darkSoft : AppColors.lightSoft,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: borderColor),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.photo_camera_back_outlined,
                                          size: 14,
                                          color: AppColors.primary,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          'Setup (Before)',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w700,
                                            color: isDark
                                                ? AppColors.primaryLight
                                                : AppColors.primaryDark,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              if (trade.imagePathAfter != null && trade.imagePathAfter!.isNotEmpty)
                                GestureDetector(
                                  onTap: () {
                                    ImageViewerDialog.show(
                                      context,
                                      trade.imagePathAfter!,
                                      '${trade.sym} (After Trade)',
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 9,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark ? AppColors.darkSoft : AppColors.lightSoft,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: borderColor),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.check_circle_outline_rounded,
                                          size: 14,
                                          color: AppColors.winText,
                                        ),
                                        SizedBox(width: 5),
                                        Text(
                                          'Outcome (After)',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.winText,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
