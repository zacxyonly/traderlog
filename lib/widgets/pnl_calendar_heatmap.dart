import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/trade.dart';
import '../providers/trade_provider.dart';
import '../utils/app_strings.dart';
import '../utils/formatters.dart';

class PnlCalendarHeatmap extends StatefulWidget {
  const PnlCalendarHeatmap({super.key});

  @override
  State<PnlCalendarHeatmap> createState() => _PnlCalendarHeatmapState();
}

class _PnlCalendarHeatmapState extends State<PnlCalendarHeatmap> {
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month, 1);
  }

  void _prevMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
  }

  void _showDayDetails(BuildContext context, DateTime day, List<Trade> trades, double dailyNet, String currency, String lang) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final mutedColor = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final dateStr = DateFormat('EEEE, d MMMM yyyy', lang == 'en' ? 'en_US' : 'id_ID').format(day);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            border: Border.all(color: borderColor),
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateStr,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${trades.length} ${AppStrings.tr("trades_count", lang)}',
                          style: TextStyle(fontSize: 12.5, color: mutedColor),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: dailyNet > 0
                          ? AppColors.win.withOpacity(0.15)
                          : (dailyNet < 0
                              ? AppColors.lose.withOpacity(0.15)
                              : mutedColor.withOpacity(0.1)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      Formatters.formatAmountSigned(dailyNet, currency: currency),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: dailyNet > 0
                            ? AppColors.winText
                            : (dailyNet < 0 ? AppColors.loseText : textColor),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 10),
              if (trades.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      AppStrings.tr('no_trades_on_day', lang),
                      style: TextStyle(color: mutedColor, fontSize: 13),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: trades.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, idx) {
                    final t = trades[idx];
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSoft : AppColors.lightSoft,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: t.side == TradeSide.buy
                                  ? AppColors.primary.withOpacity(0.18)
                                  : AppColors.lose.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              t.sideString,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: t.side == TradeSide.buy
                                    ? AppColors.primary
                                    : AppColors.lose,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            t.sym,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                          if (t.why != null && t.why!.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                t.why!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 11.5, color: mutedColor),
                              ),
                            ),
                          ] else
                            const Spacer(),
                          Text(
                            Formatters.formatAmountSigned(t.pl, currency: currency),
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: t.pl > 0
                                  ? AppColors.winText
                                  : (t.pl < 0 ? AppColors.loseText : textColor),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
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
    final lang = provider.settings.languageCode;
    final currency = provider.activeAccount.currency;

    final monthName = DateFormat('MMMM yyyy', lang == 'en' ? 'en_US' : 'id_ID').format(_currentMonth);

    // Days calculation for current month
    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final firstWeekday = _currentMonth.weekday % 7; // 0 = Sunday, 1 = Monday...

    final pnlMap = provider.getDailyPnLMap();

    // Stats for current month
    int winDays = 0;
    int loseDays = 0;
    int beDays = 0;
    double monthNetPnL = 0.0;

    for (int day = 1; day <= daysInMonth; day++) {
      final key = '${_currentMonth.year}-${_currentMonth.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
      if (pnlMap.containsKey(key)) {
        final val = pnlMap[key]!;
        monthNetPnL += val;
        if (val > 0) {
          winDays++;
        } else if (val < 0) {
          loseDays++;
        } else {
          beDays++;
        }
      }
    }

    final totalActiveDays = winDays + loseDays + beDays;
    final dayWinRate = totalActiveDays > 0 ? (winDays / totalActiveDays) * 100 : 0.0;

    final dayHeaders = lang == 'en'
        ? ['S', 'M', 'T', 'W', 'T', 'F', 'S']
        : ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];

    return Container(
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
          // Header with Month Navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.tr('calendar_title', lang),
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: mutedColor,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                    onPressed: _prevMonth,
                    color: textColor,
                  ),
                  Text(
                    monthName,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                    onPressed: _nextMonth,
                    color: textColor,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Day of week column headers
          Row(
            children: List.generate(7, (i) {
              return Expanded(
                child: Center(
                  child: Text(
                    dayHeaders[i],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: i == 0 || i == 6 ? AppColors.lose.withOpacity(0.8) : mutedColor,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 6),

          // Calendar Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: firstWeekday + daysInMonth,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 5,
              crossAxisSpacing: 5,
              childAspectRatio: 0.95,
            ),
            itemBuilder: (ctx, index) {
              if (index < firstWeekday) {
                return const SizedBox.shrink();
              }

              final day = index - firstWeekday + 1;
              final dateKey = '${_currentMonth.year}-${_currentMonth.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
              final hasTrade = pnlMap.containsKey(dateKey);
              final dailyNet = pnlMap[dateKey] ?? 0.0;

              final now = DateTime.now();
              final isToday = now.year == _currentMonth.year &&
                  now.month == _currentMonth.month &&
                  now.day == day;

              Color bg = softColor.withOpacity(0.5);
              Color numColor = textColor.withOpacity(0.85);

              if (hasTrade) {
                if (dailyNet > 0) {
                  bg = AppColors.win.withOpacity(isDark ? 0.28 : 0.22);
                  numColor = AppColors.winText;
                } else if (dailyNet < 0) {
                  bg = AppColors.lose.withOpacity(isDark ? 0.28 : 0.20);
                  numColor = AppColors.loseText;
                } else {
                  bg = mutedColor.withOpacity(0.2);
                  numColor = textColor;
                }
              }

              return InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  final targetDate = DateTime(_currentMonth.year, _currentMonth.month, day);
                  final dayTrades = provider.getTradesForDay(targetDate);
                  _showDayDetails(context, targetDate, dayTrades, dailyNet, currency, lang);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isToday
                          ? AppColors.primary
                          : (hasTrade
                              ? (dailyNet > 0
                                  ? AppColors.win.withOpacity(0.5)
                                  : AppColors.lose.withOpacity(0.5))
                              : borderColor.withOpacity(0.6)),
                      width: isToday ? 1.5 : 0.8,
                    ),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$day',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isToday ? FontWeight.w900 : FontWeight.w700,
                          color: numColor,
                        ),
                      ),
                      if (hasTrade) ...[
                        const SizedBox(height: 1),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            dailyNet >= 1000 || dailyNet <= -1000
                                ? '${dailyNet > 0 ? "+" : ""}${(dailyNet / 1000).toStringAsFixed(1)}k'
                                : (dailyNet > 0
                                    ? '+${dailyNet.toStringAsFixed(0)}'
                                    : dailyNet.toStringAsFixed(0)),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: dailyNet > 0
                                  ? AppColors.winText
                                  : (dailyNet < 0 ? AppColors.loseText : textColor),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          // Monthly Summary Stats Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: softColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryStat(
                  AppStrings.tr('win_days', lang),
                  '$winDays',
                  AppColors.winText,
                ),
                Container(width: 1, height: 22, color: borderColor),
                _buildSummaryStat(
                  AppStrings.tr('lose_days', lang),
                  '$loseDays',
                  AppColors.loseText,
                ),
                Container(width: 1, height: 22, color: borderColor),
                _buildSummaryStat(
                  AppStrings.tr('day_win_rate', lang),
                  '${dayWinRate.toStringAsFixed(0)}%',
                  AppColors.primaryLight,
                ),
                Container(width: 1, height: 22, color: borderColor),
                _buildSummaryStat(
                  AppStrings.tr('month_net_pnl', lang),
                  Formatters.formatAmountSigned(monthNetPnL, currency: currency),
                  monthNetPnL > 0
                      ? AppColors.winText
                      : (monthNetPnL < 0 ? AppColors.loseText : textColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStat(String label, String value, Color valueColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: valueColor,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: AppColors.darkMuted,
          ),
        ),
      ],
    );
  }
}
