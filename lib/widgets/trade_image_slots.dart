import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/app_strings.dart';

class TradeImageSlots extends StatelessWidget {
  final String? imagePathBefore;
  final String? imagePathAfter;
  final void Function(ImageSource source, bool isAfter) onPickImage;
  final VoidCallback onClearBefore;
  final VoidCallback onClearAfter;
  final String lang;
  final Color softColor;
  final Color borderColor;
  final Color mutedColor;

  const TradeImageSlots({
    super.key,
    required this.imagePathBefore,
    required this.imagePathAfter,
    required this.onPickImage,
    required this.onClearBefore,
    required this.onClearAfter,
    required this.lang,
    required this.softColor,
    required this.borderColor,
    required this.mutedColor,
  });

  Widget _buildSlot({
    required String title,
    required String? imagePath,
    required ValueChanged<ImageSource> onPick,
    required VoidCallback onClear,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: mutedColor,
            ),
          ),
        ),
        if (imagePath != null && imagePath.isNotEmpty) ...[
          Stack(
            alignment: Alignment.topRight,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: Container(
                  height: 140,
                  width: double.infinity,
                  color: Colors.black12,
                  child: Image.file(
                    File(imagePath),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              IconButton(
                icon: const CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.black87,
                  child: Icon(Icons.close, size: 16, color: Colors.white),
                ),
                onPressed: onClear,
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.photo_library_outlined, size: 16),
                label: Text(
                  AppStrings.tr('from_gallery', lang),
                  style: const TextStyle(fontSize: 12),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  side: BorderSide(color: borderColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
                onPressed: () => onPick(ImageSource.gallery),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.camera_alt_outlined, size: 16),
                label: Text(
                  AppStrings.tr('open_camera', lang),
                  style: const TextStyle(fontSize: 12),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  side: BorderSide(color: borderColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
                onPressed: () => onPick(ImageSource.camera),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSlot(
          title: AppStrings.tr('slot_before', lang),
          imagePath: imagePathBefore,
          onPick: (src) => onPickImage(src, false),
          onClear: onClearBefore,
        ),
        const SizedBox(height: 14),
        _buildSlot(
          title: AppStrings.tr('slot_after', lang),
          imagePath: imagePathAfter,
          onPick: (src) => onPickImage(src, true),
          onClear: onClearAfter,
        ),
      ],
    );
  }
}
