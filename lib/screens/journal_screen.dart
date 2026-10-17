import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/trade.dart';
import '../providers/trade_provider.dart';
import '../utils/app_strings.dart';
import '../utils/formatters.dart';
import '../widgets/hero_summary_card.dart';
import '../widgets/trade_card.dart';
import '../widgets/trade_detail_sheet.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'ALL';
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final softColor = isDark ? AppColors.darkSoft : AppColors.lightSoft;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final mutedColor = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;

    final provider = context.watch<TradeProvider>();
    final allTrades = provider.trades; // chronologically sorted (oldest first)
    final initialCapital = provider.settings.initialCapital;

    // Calculate chronological cumulative equity & balance for each trade
    double runningEquity = initialCapital;
    final Map<String, double> tradeEquityMap = {};
    final Map<String, double> tradeChangeMap = {};
    final Map<String, int> tradeIndexMap = {};

    for (int i = 0; i < allTrades.length; i++) {
      final t = allTrades[i];
      final startingBal = runningEquity;
      runningEquity += t.pl;
      tradeEquityMap[t.id] = runningEquity;
      tradeChangeMap[t.id] = startingBal > 0 ? (t.pl / startingBal) : 0.0;
      tradeIndexMap[t.id] = i + 1;
    }

    final filteredTrades = provider.getFilteredTrades(
      query: _searchQuery,
      filter: _selectedFilter,
    );

    // Group filtered trades by Month Year
    final Map<String, List<Trade>> monthlyTrades = {};
    final Map<String, double> monthlyTotalPL = {};

    for (final t in filteredTrades) {
      final monthKey = Formatters.formatMonthYear(t.date);
      monthlyTrades.putIfAbsent(monthKey, () => []).add(t);
      monthlyTotalPL[monthKey] = (monthlyTotalPL[monthKey] ?? 0.0) + t.pl;
    }

    final lang = provider.settings.languageCode;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => provider.loadData(),
          color: AppColors.primary,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 120),
            children: [
              // Hero Summary Card
              const HeroSummaryCard(),

              // Search Box
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() => _searchQuery = val);
                  },
                  style: TextStyle(
                    fontSize: 15,
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: AppStrings.tr('search_hint', lang),
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: mutedColor,
                      fontWeight: FontWeight.normal,
                    ),
                    prefixIcon: Icon(Icons.search, color: mutedColor, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: mutedColor, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: softColor,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: AppColors.primary, width: 1.8),
                    ),
                  ),
                ),
              ),

              // Segmented Filter Bar: ALL | WIN | LOSE | BE
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: softColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    _buildFilterButton('ALL', AppStrings.tr('filter_all', lang), cardColor, textColor, mutedColor),
                    _buildFilterButton('WIN', AppStrings.tr('filter_win', lang), cardColor, AppColors.winText, mutedColor),
                    _buildFilterButton('LOSE', AppStrings.tr('filter_lose', lang), cardColor, AppColors.loseText, mutedColor),
                    _buildFilterButton('BE', AppStrings.tr('filter_be', lang), cardColor, AppColors.beText, mutedColor),
                  ],
                ),
              ),

              // Empty State
              if (allTrades.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Icon(
                        Icons.library_books_outlined,
                        size: 48,
                        color: mutedColor.withOpacity(0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        AppStrings.tr('empty_trades_title', lang),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppStrings.tr('empty_trades_sub', lang),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: mutedColor,
                        ),
                      ),
                    ],
                  ),
                )
              else if (filteredTrades.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Icon(
                        Icons.search_off_outlined,
                        size: 44,
                        color: mutedColor.withOpacity(0.5),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        AppStrings.tr('no_filtered_trades', lang),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: mutedColor,
                        ),
                      ),
                    ],
                  ),
                )
              else
                // Monthly Grouped Trade List
                ...monthlyTrades.entries.map((entry) {
                  final monthTitle = entry.key;
                  final tradesInMonth = entry.value;
                  final totalMonthPL = monthlyTotalPL[monthTitle] ?? 0.0;
                  final plColor = totalMonthPL > 0
                      ? AppColors.winText
                      : (totalMonthPL < 0 ? AppColors.loseText : mutedColor);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Month Header with Subtotal
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              monthTitle,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: mutedColor,
                              ),
                            ),
                            Text(
                              Formatters.formatAmountSigned(
                                totalMonthPL,
                                currency: provider.settings.accountCurrency,
                              ),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: plColor,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Trade Cards in Month
                      ...tradesInMonth.map((trade) {
                        return TradeCard(
                          trade: trade,
                          tradeIndex: tradeIndexMap[trade.id] ?? 1,
                          cumulativeEquity:
                              tradeEquityMap[trade.id] ?? initialCapital,
                          changePercentage: tradeChangeMap[trade.id] ?? 0.0,
                          onTap: () {
                            TradeDetailSheet.show(
                              context: context,
                              trade: trade,
                              tradeIndex: tradeIndexMap[trade.id] ?? 1,
                              cumulativeEquity:
                                  tradeEquityMap[trade.id] ?? initialCapital,
                              changePercentage: tradeChangeMap[trade.id] ?? 0.0,
                            );
                          },
                        );
                      }),
                    ],
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterButton(
    String filterValue,
    String label,
    Color activeBg,
    Color activeText,
    Color mutedText,
  ) {
    final isSelected = _selectedFilter == filterValue;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedFilter = filterValue);
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
}
