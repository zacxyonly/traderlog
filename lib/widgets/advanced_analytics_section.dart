import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/trade_provider.dart';
import '../utils/app_strings.dart';
import '../utils/formatters.dart';
import '../utils/trade_analytics.dart';

/// Analisis lanjutan: streak maksimum, ekspektansi dalam R,
/// performa per hari, dan dampak emosi negatif.
class AdvancedAnalyticsSection extends StatelessWidget {
  final PeriodSummary summary;

  const AdvancedAnalyticsSection({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final mutedColor = isDark ? AppColors.darkMuted : AppColors.lightMuted;

    final provider = context.watch<TradeProvider>();
    final lang = provider.settings.languageCode;
    final currency = provider.activeAccount.currency;

    final trades = summary.trades;
    final streaks = TradeAnalytics.streaks(trades);
    final avgR = TradeAnalytics.averageR(trades);
    final weekdays = TradeAnalytics.weekdayStats(trades);
    final emotion = TradeAnalytics.emotionImpact(trades);

    final cardDeco = BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: borderColor),
    );

    Widget header(IconData icon, String title) => Padding(
          padding: const EdgeInsets.fromLTRB(4, 20, 4, 10),
          child: Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primaryLight),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: mutedColor,
                  ),
                ),
              ),
            ],
          ),
        );

    Widget tile(String label, String value, Color valueColor) => Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: cardDeco,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: mutedColor),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
        );

    Widget row({
      required String title,
      required String subtitle,
      required double totalPL,
    }) {
      final isProfit = totalPL >= 0;
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: cardDeco,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
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
            const SizedBox(width: 8),
            Text(
              Formatters.formatAmountSigned(totalPL, currency: currency),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: isProfit ? AppColors.winText : AppColors.loseText,
              ),
            ),
          ],
        ),
      );
    }

    String tradeSubtitle(int count, double winRate) => AppStrings.tr(
          'trade_wr',
          lang,
          params: {
            'n': '$count',
            'wr': Formatters.formatPercent(winRate, signed: false),
          },
        );

    final rText = avgR == null
        ? '-'
        : '${avgR >= 0 ? '+' : ''}${avgR.toStringAsFixed(2)}R';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header(Icons.insights_outlined, AppStrings.tr('adv_title', lang)),
        Row(
          children: [
            tile(
              AppStrings.tr('max_win_streak', lang),
              '${streaks.maxWinStreak}',
              AppColors.winText,
            ),
            const SizedBox(width: 10),
            tile(
              AppStrings.tr('max_loss_streak', lang),
              '${streaks.maxLossStreak}',
              AppColors.loseText,
            ),
            const SizedBox(width: 10),
            tile(
              AppStrings.tr('expectancy_r', lang),
              rText,
              (avgR ?? 0) >= 0 ? AppColors.winText : AppColors.loseText,
            ),
          ],
        ),
        if (weekdays.isNotEmpty) ...[
          header(
            Icons.calendar_view_week_outlined,
            AppStrings.tr('weekday_title', lang),
          ),
          ...weekdays.map((w) => row(
                title: AppStrings.tr('wd_${w.weekday}', lang),
                subtitle: tradeSubtitle(w.count, w.winRate),
                totalPL: w.totalPL,
              )),
        ],
        if (emotion != null && emotion.negative.count > 0) ...[
          header(
            Icons.psychology_alt_outlined,
            AppStrings.tr('emotion_impact', lang),
          ),
          row(
            title: AppStrings.tr('emotion_neg_label', lang),
            subtitle: tradeSubtitle(
              emotion.negative.count,
              emotion.negative.winRate,
            ),
            totalPL: emotion.negative.totalPL,
          ),
          row(
            title: AppStrings.tr('emotion_other_label', lang),
            subtitle: tradeSubtitle(
              emotion.others.count,
              emotion.others.winRate,
            ),
            totalPL: emotion.others.totalPL,
          ),
        ],
      ],
    );
  }
}
