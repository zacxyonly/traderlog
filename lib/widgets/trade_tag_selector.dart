import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../utils/app_strings.dart';

class TradeTagSelector extends StatelessWidget {
  final Set<String> selectedTags;
  final ValueChanged<String> onTagToggled;
  final String lang;
  final Color softColor;
  final Color borderColor;
  final Color textColor;
  final Color mutedColor;

  static const List<String> setupTags = [
    'BOS',
    'CHOCH',
    'FVG',
    'Liquidity',
    'Supply/Demand',
    'Trendline',
    'S&R',
    'News',
    'Fibonacci',
  ];

  static const List<String> emotionTags = [
    'Disiplin',
    'FOMO',
    'Revenge Trade',
    'Overlot',
    'Sabar',
    'Greedy',
    'Hesitant',
    'Plan Executed',
    'Early Exit',
  ];

  const TradeTagSelector({
    super.key,
    required this.selectedTags,
    required this.onTagToggled,
    required this.lang,
    required this.softColor,
    required this.borderColor,
    required this.textColor,
    required this.mutedColor,
  });

  Widget _buildChip(String tag, bool isNegative) {
    final isSelected = selectedTags.contains(tag);
    final highlightColor = isNegative ? AppColors.lose : AppColors.primary;

    return GestureDetector(
      onTap: () => onTagToggled(tag),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? highlightColor.withOpacity(0.18) : softColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? highlightColor : borderColor,
            width: isSelected ? 1.3 : 1.0,
          ),
        ),
        child: Text(
          tag,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? highlightColor : mutedColor,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Setup Tags
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            AppStrings.tr('quick_tags', lang),
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: mutedColor),
          ),
        ),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: setupTags.map((tag) => _buildChip(tag, false)).toList(),
        ),
        const SizedBox(height: 14),

        // Emotion Tags
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            AppStrings.tr('emotion_quick_tags', lang),
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: mutedColor),
          ),
        ),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: emotionTags.map((tag) {
            final isNegative = tag == 'FOMO' ||
                tag == 'Revenge Trade' ||
                tag == 'Overlot' ||
                tag == 'Greedy' ||
                tag == 'Hesitant';
            return _buildChip(tag, isNegative);
          }).toList(),
        ),
      ],
    );
  }
}
