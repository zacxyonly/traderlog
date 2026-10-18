import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/trade_provider.dart';
import '../utils/app_strings.dart';
import '../utils/formatters.dart';
import '../utils/trade_analytics.dart';

/// Ringkasan manajemen risiko dan status aturan prop firm untuk akun aktif.
class RiskPropSection extends StatelessWidget {
  const RiskPropSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final mutedColor = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    final softColor = isDark ? AppColors.darkSoft : AppColors.lightSoft;

    final provider = context.watch<TradeProvider>();
    final lang = provider.settings.languageCode;
    final account = provider.activeAccount;
    final isProp = account.type == 'prop_firm';

    final risks = TradeAnalytics.riskProfile(provider.trades, account);
    final withRisk = risks.where((r) => r.riskRatio != null).toList();
    final avgRatio = withRisk.isEmpty
        ? null
        : withRisk.fold<double>(0.0, (s, r) => s + r.riskRatio!) /
            withRisk.length;

    final limit = account.maxRiskPercent;
    int overCount = 0;
    if (limit != null) {
      for (final r in withRisk) {
        if (r.riskRatio! * 100 > limit) overCount++;
      }
    }

    final prop = isProp
        ? TradeAnalytics.propFirmStatus(
            provider.trades,
            account,
            DateTime.now(),
          )
        : null;

    final cardDeco = BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: borderColor),
    );

    Widget header(IconData icon, String title, {Widget? trailing}) => Padding(
          padding: const EdgeInsets.fromLTRB(4, 20, 4, 10),
          child: Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primaryLight),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: mutedColor,
                ),
              ),
              const Spacer(),
              if (trailing != null) trailing,
            ],
          ),
        );

    Widget kv(String label, String value, Color valueColor) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 13, color: mutedColor)),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: valueColor,
              ),
            ),
          ],
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header(
          Icons.shield_outlined,
          AppStrings.tr('risk_title', lang),
          trailing: TextButton(
            onPressed: () => _openRules(context, provider, lang),
            child: Text(
              AppStrings.tr('risk_set_rules', lang),
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: cardDeco,
          child: Column(
            children: [
              kv(
                AppStrings.tr('risk_avg', lang),
                avgRatio == null
                    ? '-'
                    : Formatters.formatPercent(avgRatio, signed: false),
                textColor,
              ),
              if (limit != null) ...[
                const SizedBox(height: 10),
                kv(
                  AppStrings.tr('risk_limit', lang),
                  '${limit.toStringAsFixed(2)}%',
                  textColor,
                ),
                const SizedBox(height: 10),
                kv(
                  AppStrings.tr('risk_over_count', lang),
                  '$overCount',
                  overCount > 0 ? AppColors.loseText : textColor,
                ),
              ],
              if (withRisk.isEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  AppStrings.tr('risk_no_data', lang),
                  style: TextStyle(fontSize: 12, color: mutedColor),
                ),
              ],
            ],
          ),
        ),
        if (prop != null) ...[
          header(Icons.flag_outlined, AppStrings.tr('prop_title', lang)),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: cardDeco,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _RuleBar(
                  label: AppStrings.tr('prop_daily', lang),
                  used: prop.dailyLossRatio,
                  limit: prop.dailyLimitRatio,
                  lang: lang,
                  textColor: textColor,
                  mutedColor: mutedColor,
                  softColor: softColor,
                ),
                const SizedBox(height: 16),
                _RuleBar(
                  label: AppStrings.tr('prop_total_dd', lang),
                  used: prop.totalDrawdownRatio,
                  limit: prop.maxDrawdownRatio,
                  lang: lang,
                  textColor: textColor,
                  mutedColor: mutedColor,
                  softColor: softColor,
                ),
                const SizedBox(height: 12),
                Text(
                  AppStrings.tr('prop_note', lang),
                  style: TextStyle(fontSize: 11, color: mutedColor),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _openRules(
    BuildContext context,
    TradeProvider provider,
    String lang,
  ) {
    return showDialog<void>(
      context: context,
      builder: (_) => _RiskRulesDialog(provider: provider, lang: lang),
    );
  }
}

class _RuleBar extends StatelessWidget {
  final String label;
  final double used;
  final double? limit;
  final String lang;
  final Color textColor;
  final Color mutedColor;
  final Color softColor;

  const _RuleBar({
    required this.label,
    required this.used,
    required this.limit,
    required this.lang,
    required this.textColor,
    required this.mutedColor,
    required this.softColor,
  });

  @override
  Widget build(BuildContext context) {
    final lim = limit;
    if (lim == null || lim <= 0) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          Text(
            AppStrings.tr('prop_no_limit', lang),
            style: TextStyle(fontSize: 12, color: mutedColor),
          ),
        ],
      );
    }

    final progress = used / lim;
    final clamped = progress < 0 ? 0.0 : (progress > 1 ? 1.0 : progress);
    final breached = progress >= 1;
    final color = breached
        ? AppColors.lose
        : (progress >= 0.8 ? Colors.orange : AppColors.primary);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ),
            Text(
              '${(used * 100).toStringAsFixed(2)}% / ${(lim * 100).toStringAsFixed(2)}%',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: clamped,
            minHeight: 8,
            backgroundColor: softColor,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        if (breached) ...[
          const SizedBox(height: 6),
          Text(
            AppStrings.tr('prop_breached', lang),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.lose,
            ),
          ),
        ],
      ],
    );
  }
}

class _RiskRulesDialog extends StatefulWidget {
  final TradeProvider provider;
  final String lang;

  const _RiskRulesDialog({required this.provider, required this.lang});

  @override
  State<_RiskRulesDialog> createState() => _RiskRulesDialogState();
}

class _RiskRulesDialogState extends State<_RiskRulesDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _riskCtl;
  late final TextEditingController _dailyCtl;
  late final TextEditingController _ddCtl;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    final acc = widget.provider.activeAccount;
    _riskCtl = TextEditingController(text: _fmt(acc.maxRiskPercent));
    _dailyCtl = TextEditingController(text: _fmt(acc.dailyLossLimitPercent));
    _ddCtl = TextEditingController(text: _fmt(acc.maxDrawdownPercent));
  }

  @override
  void dispose() {
    _riskCtl.dispose();
    _dailyCtl.dispose();
    _ddCtl.dispose();
    super.dispose();
  }

  void _save() {
    setState(() => _submitted = true);
    if (!_formKey.currentState!.validate()) return;

    final acc = widget.provider.activeAccount;
    final isProp = acc.type == 'prop_firm';
    widget.provider.updateRiskRules(
      maxRiskPercent: _parse(_riskCtl.text),
      dailyLossLimitPercent:
          isProp ? _parse(_dailyCtl.text) : acc.dailyLossLimitPercent,
      maxDrawdownPercent: isProp ? _parse(_ddCtl.text) : acc.maxDrawdownPercent,
    );
    Navigator.of(context).pop();
  }

  Widget _field(
    TextEditingController c,
    String label,
    Color softColor,
    Color borderColor,
    Color mutedColor,
    Color textColor,
    String lang,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: c,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: TextStyle(
          color: textColor,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: AppStrings.tr('risk_hint_empty', lang),
          suffixText: '%',
          suffixStyle: TextStyle(
            fontWeight: FontWeight.w800,
            color: mutedColor,
          ),
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
        ),
        validator: (val) {
          if (val == null || val.trim().isEmpty) return null;
          final v = double.tryParse(val.trim().replaceAll(',', '.'));
          if (v == null || v <= 0 || v > 100) {
            return lang == 'en'
                ? 'Enter a valid percent (0.1 - 100)'
                : 'Rentang persentase harus antara 0.1% - 100%';
          }
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final softColor = isDark ? AppColors.darkSoft : AppColors.lightSoft;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final mutedColor = isDark ? AppColors.darkMuted : AppColors.lightMuted;

    final acc = widget.provider.activeAccount;
    final isProp = acc.type == 'prop_firm';

    IconData typeIcon;
    Color typeColor;
    switch (acc.type) {
      case 'prop_firm':
        typeIcon = Icons.emoji_events_rounded;
        typeColor = const Color(0xFFF59E0B);
        break;
      case 'demo':
        typeIcon = Icons.science_rounded;
        typeColor = const Color(0xFF6366F1);
        break;
      case 'real':
      default:
        typeIcon = Icons.trending_up_rounded;
        typeColor = AppColors.primary;
        break;
    }

    return Dialog(
      backgroundColor: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.shield_outlined,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        AppStrings.tr('risk_rules_title', lang),
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
                      icon: Icon(Icons.close_rounded, color: mutedColor, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 20,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Account type card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(isDark ? 0.18 : 0.10),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: typeColor.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: typeColor.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(typeIcon, size: 20, color: typeColor),
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
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                              ),
                            ),
                            Text(
                              acc.typeLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: typeColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                _field(_riskCtl, AppStrings.tr('risk_max_per_trade', lang), softColor, borderColor, mutedColor, textColor, lang),
                if (isProp) ...[
                  _field(_dailyCtl, AppStrings.tr('risk_daily_limit', lang), softColor, borderColor, mutedColor, textColor, lang),
                  _field(_ddCtl, AppStrings.tr('risk_max_dd', lang), softColor, borderColor, mutedColor, textColor, lang),
                ],
                const SizedBox(height: 10),

                // Wide main button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      AppStrings.tr('save_rules', lang),
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

String _fmt(double? v) {
  if (v == null) return '';
  return v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
}

/// Mengembalikan null untuk input kosong, tidak valid, atau di luar 0-100.
double? _parse(String raw) {
  final v = double.tryParse(raw.trim().replaceAll(',', '.'));
  if (v == null || v <= 0 || v > 100) return null;
  return v;
}
