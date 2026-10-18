import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/trading_account.dart';
import '../providers/trade_provider.dart';
import '../utils/app_strings.dart';
import '../utils/formatters.dart';
import 'account_form_dialog.dart';

class AccountSwitcherSheet extends StatelessWidget {
  const AccountSwitcherSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const AccountSwitcherSheet(),
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
    final accounts = provider.settings.accounts;
    final activeId = provider.settings.activeAccountId;
    final lang = provider.settings.languageCode;

    return Container(
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
            children: [
              const Icon(Icons.account_balance_wallet_outlined, color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppStrings.tr('switch_account', lang),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
                tooltip: AppStrings.tr('add_new_account', lang),
                onPressed: () {
                  Navigator.of(context).pop();
                  AccountFormDialog.show(context);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: accounts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, idx) {
              final acc = accounts[idx];
              final isActive = acc.id == activeId;

              Color typeBgColor;
              Color typeTextColor;
              switch (acc.type) {
                case 'prop_firm':
                  typeBgColor = const Color(0xFFF59E0B).withOpacity(0.18);
                  typeTextColor = const Color(0xFFF59E0B);
                  break;
                case 'demo':
                  typeBgColor = const Color(0xFF6366F1).withOpacity(0.18);
                  typeTextColor = const Color(0xFF818CF8);
                  break;
                case 'real':
                default:
                  typeBgColor = AppColors.primary.withOpacity(0.18);
                  typeTextColor = AppColors.primary;
                  break;
              }

              return InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  provider.switchAccount(acc.id);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${AppStrings.tr("account_switched", lang)}: ${acc.name}'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primary.withOpacity(0.10) : softColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isActive ? AppColors.primary : borderColor,
                      width: isActive ? 1.6 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: typeBgColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          acc.typeLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: typeTextColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              acc.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                              ),
                            ),
                            Text(
                              '${AppStrings.tr("account_capital", lang)}: ${Formatters.formatAmount(acc.initialCapital, currency: acc.currency)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, color: mutedColor),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.edit_outlined, size: 18, color: mutedColor),
                        tooltip: AppStrings.tr('edit_account', lang),
                        splashRadius: 18,
                        onPressed: () {
                          Navigator.of(context).pop();
                          AccountFormDialog.show(context, accountToEdit: acc);
                        },
                      ),
                      if (isActive)
                        const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
