import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/trade_provider.dart';
import '../utils/app_strings.dart';
import '../utils/formatters.dart';
import 'equity_sparkline.dart';

class HeroSummaryCard extends StatelessWidget {
  const HeroSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TradeProvider>();
    final equity = provider.currentEquity;
    final equityIDR = provider.currentEquityIDR;
    final pl = provider.totalProfitLoss;
    final plPct = provider.totalProfitLossPercentage;
    final history = provider.equityHistory;

    final isProfit = pl >= 0;
    final plColor = isProfit ? const Color(0xFF6EE7B7) : const Color(0xFFFCA5A5);

    final lang = provider.settings.languageCode;
    final trader = provider.settings.traderName.trim().isNotEmpty
        ? provider.settings.traderName.trim()
        : 'Zacxy';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.heroGradient,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Subtitle with dynamic Trader Name
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'by $trader',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.heroSubtitle,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                    Text(
                      AppStrings.tr('hero_app_name', lang),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.heroSubtitle,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Label
                Text(
                  AppStrings.tr('hero_total_equity', lang),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.heroLabel,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),

                // Large Equity
                Text(
                  Formatters.formatAmount(equity, currency: provider.settings.accountCurrency),
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),

                // Meta Row: Converted Currency + P/L Pill
                Row(
                  children: [
                    Text(
                      Formatters.formatAmount(equityIDR, currency: provider.settings.exchangeCurrency),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFFC5D3DE),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        '${Formatters.formatAmountSigned(pl, currency: provider.settings.accountCurrency)} · ${Formatters.formatPercent(plPct)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: plColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),

          // Sparkline
          if (history.length > 1)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(26),
                bottomRight: Radius.circular(26),
              ),
              child: EquitySparkline(
                points: history,
                height: 56,
              ),
            )
          else
            const SizedBox(height: 16),
        ],
      ),
    );
  }
}
