import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/trading_account.dart';
import '../providers/trade_provider.dart';
import '../utils/app_strings.dart';

class AccountFormDialog extends StatefulWidget {
  final TradingAccount? accountToEdit;

  const AccountFormDialog({
    super.key,
    this.accountToEdit,
  });

  static Future<void> show(
    BuildContext context, {
    TradingAccount? accountToEdit,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AccountFormDialog(accountToEdit: accountToEdit),
    );
  }

  @override
  State<AccountFormDialog> createState() => _AccountFormDialogState();
}

class _AccountFormDialogState extends State<AccountFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _capCtrl;
  late String _selectedType;
  late String _selectedCurrency;
  bool _submitted = false;

  static const List<String> _currencies = [
    'USD',
    'IDR',
    'USDC',
    'USDT',
    'EUR',
    'GBP',
    'JPY',
    'SGD',
    'AUD',
  ];

  @override
  void initState() {
    super.initState();
    final edit = widget.accountToEdit;
    final provider = context.read<TradeProvider>();
    _selectedType = edit?.type ?? 'real';
    _selectedCurrency = edit?.currency ?? provider.settings.accountCurrency;
    _nameCtrl = TextEditingController(text: edit?.name ?? '');

    String capText = '1000';
    if (edit != null) {
      capText = edit.initialCapital == edit.initialCapital.roundToDouble()
          ? edit.initialCapital.toStringAsFixed(0)
          : edit.initialCapital.toString();
    }
    _capCtrl = TextEditingController(text: capText);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _capCtrl.dispose();
    super.dispose();
  }

  void _saveAccount() {
    setState(() => _submitted = true);
    if (!_formKey.currentState!.validate()) return;

    final name = _nameCtrl.text.trim();
    final cap = double.tryParse(_capCtrl.text.trim().replaceAll(',', '.')) ?? 1000.0;
    final provider = context.read<TradeProvider>();
    final lang = provider.settings.languageCode;

    if (widget.accountToEdit != null) {
      final updated = widget.accountToEdit!.copyWith(
        name: name,
        type: _selectedType,
        initialCapital: cap,
        currency: _selectedCurrency,
      );
      provider.updateAccount(updated);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.tr('account_updated', lang)),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      final newAcc = TradingAccount(
        id: 'acc_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        type: _selectedType,
        initialCapital: cap,
        currency: _selectedCurrency,
      );
      provider.addAccount(newAcc);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.tr('account_created', lang)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildTypeCard({
    required String type,
    required String label,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required bool isDark,
    required Color softColor,
    required Color borderColor,
    required Color textColor,
    required Color mutedColor,
  }) {
    final isSelected = _selectedType == type;

    return Expanded(
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedType = type);
        },
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? accentColor.withOpacity(isDark ? 0.20 : 0.12)
                : softColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? accentColor : borderColor,
              width: isSelected ? 2.0 : 1.0,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? accentColor.withOpacity(isDark ? 0.25 : 0.18)
                          : (isDark ? AppColors.darkBg : AppColors.lightCard),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: 20,
                      color: isSelected ? accentColor : mutedColor,
                    ),
                  ),
                  if (isSelected)
                    Positioned(
                      top: -3,
                      right: -5,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: accentColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 7),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? textColor : mutedColor,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isSelected
                      ? accentColor.withOpacity(0.18)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? accentColor
                        : mutedColor.withOpacity(0.85),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String labelText,
    String? hintText,
    Widget? prefixIcon,
    required Color softColor,
    required Color borderColor,
    required Color mutedColor,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      labelStyle: TextStyle(
        fontSize: 13,
        color: mutedColor,
        fontWeight: FontWeight.w600,
      ),
      hintStyle: TextStyle(
        fontSize: 13,
        color: mutedColor.withOpacity(0.65),
      ),
      filled: true,
      fillColor: softColor,
      prefixIcon: prefixIcon,
      errorMaxLines: 2,
      helperMaxLines: 2,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.lose, width: 1.4),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.lose, width: 1.8),
      ),
      errorStyle: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.lose,
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

    final lang = context.watch<TradeProvider>().settings.languageCode;
    final isEdit = widget.accountToEdit != null;

    return Dialog(
      backgroundColor: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Form(
            key: _formKey,
            autovalidateMode: _submitted
                ? AutovalidateMode.onUserInteraction
                : AutovalidateMode.disabled,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Title, Icon badge, and Close Button
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isEdit
                            ? Icons.edit_note_rounded
                            : Icons.account_balance_wallet_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEdit
                                ? AppStrings.tr('edit_account', lang)
                                : AppStrings.tr('add_new_account', lang),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                            ),
                          ),
                          Text(
                            lang == 'en'
                                ? 'Configure trading portfolio'
                                : 'Konfigurasi akun & modal trading',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: mutedColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: mutedColor, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 20,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // 1. Pemilih Tipe Berupa Kartu Ikon
                Text(
                  AppStrings.tr('account_type', lang),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: mutedColor,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildTypeCard(
                      type: 'real',
                      label: 'Real',
                      subtitle: lang == 'en' ? 'Live' : 'Live Real',
                      icon: Icons.trending_up_rounded,
                      accentColor: AppColors.primary,
                      isDark: isDark,
                      softColor: softColor,
                      borderColor: borderColor,
                      textColor: textColor,
                      mutedColor: mutedColor,
                    ),
                    const SizedBox(width: 8),
                    _buildTypeCard(
                      type: 'demo',
                      label: 'Demo',
                      subtitle: lang == 'en' ? 'Practice' : 'Simulasi',
                      icon: Icons.science_rounded,
                      accentColor: const Color(0xFF6366F1),
                      isDark: isDark,
                      softColor: softColor,
                      borderColor: borderColor,
                      textColor: textColor,
                      mutedColor: mutedColor,
                    ),
                    const SizedBox(width: 8),
                    _buildTypeCard(
                      type: 'prop_firm',
                      label: 'Prop Firm',
                      subtitle: lang == 'en' ? 'Challenge' : 'Evaluasi',
                      icon: Icons.emoji_events_rounded,
                      accentColor: const Color(0xFFF59E0B),
                      isDark: isDark,
                      softColor: softColor,
                      borderColor: borderColor,
                      textColor: textColor,
                      mutedColor: mutedColor,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 2. Field Berisi Dengan Validasi Inline (Nama Akun)
                TextFormField(
                  controller: _nameCtrl,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: _fieldDecoration(
                    labelText: AppStrings.tr('account_name', lang),
                    hintText: AppStrings.tr('account_name_hint', lang),
                    prefixIcon: Icon(
                      Icons.badge_outlined,
                      size: 20,
                      color: mutedColor,
                    ),
                    softColor: softColor,
                    borderColor: borderColor,
                    mutedColor: mutedColor,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return AppStrings.tr('account_name_required', lang);
                    }
                    if (value.trim().length > 30) {
                      return lang == 'en'
                          ? 'Max 30 characters'
                          : 'Maksimal 30 karakter';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // 3. Field Berisi Dengan Validasi Inline (Modal Awal & Mata Uang)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 6,
                      child: TextFormField(
                        controller: _capCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: TextStyle(
                          color: textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: _fieldDecoration(
                          labelText: AppStrings.tr('account_capital', lang),
                          hintText: '1000',
                          prefixIcon: Icon(
                            Icons.attach_money_rounded,
                            size: 20,
                            color: mutedColor,
                          ),
                          softColor: softColor,
                          borderColor: borderColor,
                          mutedColor: mutedColor,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return AppStrings.tr(
                              'account_capital_required',
                              lang,
                            );
                          }
                          final parsed = double.tryParse(
                            value.trim().replaceAll(',', '.'),
                          );
                          if (parsed == null || parsed <= 0) {
                            return AppStrings.tr(
                              'account_capital_invalid',
                              lang,
                            );
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 4,
                      child: DropdownButtonFormField<String>(
                        value: _selectedCurrency,
                        dropdownColor: cardColor,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: _fieldDecoration(
                          labelText: AppStrings.tr('currency', lang),
                          softColor: softColor,
                          borderColor: borderColor,
                          mutedColor: mutedColor,
                        ),
                        items: _currencies.map((curr) {
                          return DropdownMenuItem<String>(
                            value: curr,
                            child: Text(
                              curr,
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedCurrency = val);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                // 4. Tombol Utama Lebar
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _saveAccount,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      isEdit
                          ? AppStrings.tr('save_changes', lang)
                          : AppStrings.tr('add_new_account', lang),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
