import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/trade_provider.dart';
import '../utils/app_strings.dart';
import '../utils/formatters.dart';
import '../widgets/equity_sparkline.dart';
import '../widgets/hero_summary_card.dart';
import '../widgets/stat_card.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  String _selectedPeriod = 'all'; // 'all', '30', '7'

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final softColor = isDark ? AppColors.darkSoft : AppColors.lightSoft;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final mutedColor = isDark ? AppColors.darkMuted : AppColors.lightMuted;

    final provider = context.watch<TradeProvider>();
    final summary = provider.getSummaryStats(_selectedPeriod);

    final lang = provider.settings.languageCode;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 120),
          children: [
            // Hero Summary Card
            const HeroSummaryCard(),

            // Period Selector Segment
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: softColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  _buildPeriodButton('all', AppStrings.tr('period_all', lang), cardColor, textColor, mutedColor),
                  _buildPeriodButton('30', AppStrings.tr('period_30', lang), cardColor, textColor, mutedColor),
                  _buildPeriodButton('7', AppStrings.tr('period_7', lang), cardColor, textColor, mutedColor),
                ],
              ),
            ),

            if (summary.totalTrades == 0)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Icon(
                      Icons.analytics_outlined,
                      size: 48,
                      color: mutedColor.withOpacity(0.5),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppStrings.tr('empty_period', lang),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: mutedColor,
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              // 2x2 Grid of Key Metrics
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      label: AppStrings.tr('total_trades', lang),
                      value: summary.totalTrades.toString(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatCard(
                      label: AppStrings.tr('win_rate', lang),
                      value: Formatters.formatPercent(summary.winRate, signed: false),
                      progressBarPercentage: summary.winRate,
                      progressBarColor: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      label: AppStrings.tr('profit_loss', lang),
                      value: Formatters.formatUSDSigned(summary.netProfit),
                      valueColor: summary.netProfit > 0
                          ? AppColors.winText
                          : (summary.netProfit < 0
                              ? AppColors.loseText
                              : textColor),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatCard(
                      label: AppStrings.tr('profit_factor', lang),
                      value: summary.profitFactor != null
                          ? (summary.profitFactor!.isInfinite
                              ? '∞'
                              : summary.profitFactor!.toStringAsFixed(2))
                          : '-',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Equity Curve Card (if more than 1 trade)
              if (summary.equityPoints.length > 1) ...[
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
                        AppStrings.tr('equity_curve', lang),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: mutedColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      EquitySparkline(
                        points: summary.equityPoints,
                        height: 110,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],

              // Detailed Performance Table Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  children: [
                    _buildRow(
                      AppStrings.tr('win_be_loss', lang),
                      '${summary.winCount} / ${summary.beCount} / ${summary.loseCount}',
                      textColor,
                      borderColor,
                    ),
                    _buildRow(
                      AppStrings.tr('avg_win', lang),
                      summary.winCount > 0
                          ? Formatters.formatUSD(summary.avgWin)
                          : '-',
                      AppColors.winText,
                      borderColor,
                    ),
                    _buildRow(
                      AppStrings.tr('avg_loss', lang),
                      summary.loseCount > 0
                          ? Formatters.formatUSD(summary.avgLoss)
                          : '-',
                      summary.loseCount > 0 ? AppColors.loseText : textColor,
                      borderColor,
                    ),
                    _buildRow(
                      AppStrings.tr('expectancy', lang),
                      Formatters.formatUSDSigned(summary.expectancy),
                      summary.expectancy > 0
                          ? AppColors.winText
                          : (summary.expectancy < 0
                              ? AppColors.loseText
                              : textColor),
                      borderColor,
                    ),
                    _buildRow(
                      AppStrings.tr('best_trade', lang),
                      Formatters.formatUSDSigned(summary.bestTrade),
                      summary.bestTrade > 0
                          ? AppColors.winText
                          : (summary.bestTrade < 0
                              ? AppColors.loseText
                              : textColor),
                      borderColor,
                    ),
                    _buildRow(
                      AppStrings.tr('worst_trade', lang),
                      Formatters.formatUSDSigned(summary.worstTrade),
                      summary.worstTrade > 0
                          ? AppColors.winText
                          : (summary.worstTrade < 0
                              ? AppColors.loseText
                              : textColor),
                      borderColor,
                    ),
                    _buildRow(
                      AppStrings.tr('max_drawdown', lang),
                      Formatters.formatPercent(summary.maxDrawdown, signed: false),
                      summary.maxDrawdown > 0 ? AppColors.loseText : textColor,
                      borderColor,
                    ),
                    _buildRow(
                      AppStrings.tr('avg_rr', lang),
                      summary.avgRR > 0
                          ? '1:${summary.avgRR.toStringAsFixed(2)}'
                          : '-',
                      textColor,
                      borderColor,
                    ),
                    _buildRow(
                      AppStrings.tr('current_streak', lang),
                      summary.streakCount > 0
                          ? '${summary.streakCount} ${summary.streakType.toLowerCase()}'
                          : '-',
                      summary.streakType == 'WIN'
                          ? AppColors.winText
                          : (summary.streakType == 'LOSE'
                              ? AppColors.loseText
                              : textColor),
                      borderColor,
                      isLast: true,
                    ),
                  ],
                ),
              ),

              // Breakdown Per Symbol
              if (summary.symbolStats.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 20, 4, 10),
                  child: Text(
                    AppStrings.tr('per_symbol', lang),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: mutedColor,
                    ),
                  ),
                ),
                ...summary.symbolStats.map((sym) {
                  final maxPL = summary.symbolStats
                      .map((s) => s.totalPL.abs())
                      .reduce(max);
                  final barFactor =
                      maxPL > 0 ? (sym.totalPL.abs() / maxPL) : 0.0;
                  final isProfit = sym.totalPL >= 0;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              sym.symbol,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                              ),
                            ),
                            Text(
                              Formatters.formatUSDSigned(sym.totalPL),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: isProfit
                                    ? AppColors.winText
                                    : AppColors.loseText,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${sym.count} ${AppStrings.tr("trades_count", lang)} · win rate ${Formatters.formatPercent(sym.winRate, signed: false)}',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: mutedColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            height: 6,
                            width: double.infinity,
                            color: isDark ? AppColors.darkSoft : AppColors.lightSoft,
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: barFactor.clamp(0.02, 1.0),
                              child: Container(
                                color: isProfit
                                    ? AppColors.primary
                                    : AppColors.lose,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodButton(
    String periodValue,
    String label,
    Color activeBg,
    Color activeText,
    Color mutedText,
  ) {
    final isSelected = _selectedPeriod == periodValue;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedPeriod = periodValue);
        },
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
              color: isSelected ? activeText : mutedText,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRow(
    String title,
    String value,
    Color valueColor,
    Color borderColor, {
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(color: borderColor, width: 0.8),
              ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
