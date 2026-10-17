import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/trading_account.dart';
import '../providers/trade_provider.dart';
import '../utils/app_strings.dart';
import '../utils/formatters.dart';

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

  void _showAddAccountDialog(BuildContext context, String lang) {
    final nameCtrl = TextEditingController();
    final capCtrl = TextEditingController(text: '1000');
    String type = 'real';
    final activeCurr = context.read<TradeProvider>().settings.accountCurrency;
    String currency = activeCurr;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final softColor = isDark ? AppColors.darkSoft : AppColors.lightSoft;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final mutedColor = isDark ? AppColors.darkMuted : AppColors.lightMuted;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              backgroundColor: cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              title: Text(
                AppStrings.tr('add_new_account', lang),
                style: TextStyle(color: textColor, fontWeight: FontWeight.w800, fontSize: 17),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.tr('account_name', lang),
                      style: TextStyle(fontSize: 12, color: mutedColor, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: nameCtrl,
                      style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w700),
                      decoration: InputDecoration(
                        hintText: AppStrings.tr('account_name_hint', lang),
                        filled: true,
                        fillColor: softColor,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppStrings.tr('account_type', lang),
                      style: TextStyle(fontSize: 12, color: mutedColor, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: softColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: borderColor),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: type,
                          isExpanded: true,
                          dropdownColor: cardColor,
                          style: TextStyle(color: textColor, fontWeight: FontWeight.w700, fontSize: 14),
                          items: [
                            DropdownMenuItem(value: 'real', child: Text(AppStrings.tr('type_real', lang))),
                            DropdownMenuItem(value: 'demo', child: Text(AppStrings.tr('type_demo', lang))),
                            DropdownMenuItem(value: 'prop_firm', child: Text(AppStrings.tr('type_prop', lang))),
                          ],
                          onChanged: (val) {
                            if (val != null) setDialogState(() => type = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppStrings.tr('account_capital', lang),
                                style: TextStyle(fontSize: 12, color: mutedColor, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              TextField(
                                controller: capCtrl,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w700),
                                decoration: InputDecoration(
                                  hintText: '1000',
                                  filled: true,
                                  fillColor: softColor,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Currency',
                                style: TextStyle(fontSize: 12, color: mutedColor, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  color: softColor,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: borderColor),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: currency,
                                    isExpanded: true,
                                    dropdownColor: cardColor,
                                    style: TextStyle(color: textColor, fontWeight: FontWeight.w700, fontSize: 13),
                                    items: const [
                                      DropdownMenuItem(value: 'USD', child: Text('USD')),
                                      DropdownMenuItem(value: 'IDR', child: Text('IDR')),
                                      DropdownMenuItem(value: 'USDC', child: Text('USDC')),
                                      DropdownMenuItem(value: 'USDT', child: Text('USDT')),
                                      DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                                      DropdownMenuItem(value: 'GBP', child: Text('GBP')),
                                      DropdownMenuItem(value: 'JPY', child: Text('JPY')),
                                      DropdownMenuItem(value: 'SGD', child: Text('SGD')),
                                      DropdownMenuItem(value: 'AUD', child: Text('AUD')),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) setDialogState(() => currency = val);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(AppStrings.tr('cancel', lang)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    final cap = double.tryParse(capCtrl.text.trim()) ?? 1000.0;
                    if (name.isNotEmpty) {
                      final newAcc = TradingAccount(
                        id: 'acc_${DateTime.now().millisecondsSinceEpoch}',
                        name: name,
                        type: type,
                        initialCapital: cap,
                        currency: currency,
                      );
                      context.read<TradeProvider>().addAccount(newAcc);
                      Navigator.of(ctx).pop();
                    }
                  },
                  child: Text(AppStrings.tr('add_new_account', lang)),
                ),
              ],
            );
          },
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.account_balance_wallet_outlined, color: AppColors.primary, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    AppStrings.tr('switch_account', lang),
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
                tooltip: AppStrings.tr('add_new_account', lang),
                onPressed: () {
                  Navigator.of(context).pop();
                  _showAddAccountDialog(context, lang);
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
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                              ),
                            ),
                            Text(
                              'Modal: ${Formatters.formatAmount(acc.initialCapital, currency: acc.currency)}',
                              style: TextStyle(fontSize: 12, color: mutedColor),
                            ),
                          ],
                        ),
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
