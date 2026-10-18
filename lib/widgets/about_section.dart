import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';
import '../constants/app_info.dart';
import '../providers/trade_provider.dart';
import '../services/update_service.dart';
import '../utils/app_strings.dart';

/// Isi kategori "Tentang" di Pengaturan.
class AboutSection extends StatefulWidget {
  const AboutSection({super.key});

  @override
  State<AboutSection> createState() => _AboutSectionState();
}

class _AboutSectionState extends State<AboutSection> {
  bool _checking = false;
  String? _statusText;
  bool _updateAvailable = false;
  String? _releaseUrl;

  Future<void> _checkUpdate(String lang) async {
    setState(() {
      _checking = true;
      _statusText = null;
      _updateAvailable = false;
    });

    String status;
    bool available = false;
    String? url;
    try {
      final info = await UpdateService.checkLatest()
          .timeout(const Duration(seconds: 15));
      url = info.releaseUrl;
      if (info.isNewer) {
        available = true;
        status = AppStrings.tr(
          'about_update_available',
          lang,
          params: {'v': info.latestVersion},
        );
      } else {
        status = AppStrings.tr('about_up_to_date', lang);
      }
    } on UpdateException catch (e) {
      status = AppStrings.tr(
        e.code == 'no_release' ? 'about_no_release' : 'about_check_failed',
        lang,
      );
    } catch (_) {
      status = AppStrings.tr('about_check_failed', lang);
    }

    if (!mounted) return;
    setState(() {
      _checking = false;
      _statusText = status;
      _updateAvailable = available;
      _releaseUrl = url;
    });
  }

  Future<void> _open(String url, String lang) async {
    try {
      final ok = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!ok && mounted) _showError(lang);
    } catch (_) {
      if (mounted) _showError(lang);
    }
  }

  void _showError(String lang) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(AppStrings.tr('about_open_failed', lang)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final mutedColor = isDark ? AppColors.darkMuted : AppColors.lightMuted;

    final lang = context.watch<TradeProvider>().settings.languageCode;

    final cardDeco = BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: borderColor),
    );

    Widget linkRow({
      required IconData icon,
      required Color color,
      required String title,
      String? subtitle,
      VoidCallback? onTap,
    }) {
      return InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 12, color: mutedColor),
                      ),
                    ],
                  ],
                ),
              ),
              if (onTap != null)
                Icon(Icons.open_in_new_rounded, size: 16, color: mutedColor),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Identitas aplikasi
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: cardDeco,
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: AppColors.heroGradient),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.show_chart_rounded,
                  color: Colors.white,
                  size: 34,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                AppInfo.appName,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AppStrings.tr('about_tagline', lang),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: mutedColor),
              ),
              const SizedBox(height: 8),
              Text(
                '${AppStrings.tr('about_version', lang)} ${AppInfo.version} '
                '(build ${AppInfo.buildNumber})',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: mutedColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Cek pembaruan
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: cardDeco,
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _checking ? null : () => _checkUpdate(lang),
                  icon: _checking
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.system_update_alt_rounded),
                  label: Text(
                    AppStrings.tr(
                      _checking ? 'about_checking' : 'about_check_update',
                      lang,
                    ),
                  ),
                ),
              ),
              if (_statusText != null) ...[
                const SizedBox(height: 10),
                Text(
                  _statusText!,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: mutedColor),
                ),
              ],
              if (_updateAvailable && _releaseUrl != null) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _open(_releaseUrl!, lang),
                    child: Text(AppStrings.tr('about_open_release', lang)),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Pembuat, kode sumber, lisensi
        Container(
          decoration: cardDeco,
          child: Column(
            children: [
              linkRow(
                icon: Icons.person_outline_rounded,
                color: AppColors.primary,
                title: AppStrings.tr('about_creator', lang),
                subtitle: AppInfo.authorName,
                onTap: () => _open(AppInfo.authorUrl, lang),
              ),
              Divider(height: 1, indent: 62, color: borderColor),
              linkRow(
                icon: Icons.code_rounded,
                color: const Color(0xFF6366F1),
                title: AppStrings.tr('about_repo', lang),
                subtitle: 'GitHub',
                onTap: () => _open(AppInfo.repoUrl, lang),
              ),
              Divider(height: 1, indent: 62, color: borderColor),
              linkRow(
                icon: Icons.gavel_rounded,
                color: const Color(0xFFF59E0B),
                title: AppStrings.tr('about_license', lang),
                subtitle: AppInfo.license,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Donasi
        Container(
          decoration: cardDeco,
          child: linkRow(
            icon: Icons.favorite_rounded,
            color: const Color(0xFFE11D48),
            title: AppStrings.tr('about_donate', lang),
            subtitle: AppStrings.tr('about_donate_sub', lang),
            onTap: () => _open(AppInfo.donationUrl, lang),
          ),
        ),
      ],
    );
  }
}
