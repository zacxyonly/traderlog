import 'dart:io';
import 'package:flutter/material.dart';

class ImageViewerDialog extends StatelessWidget {
  final String imagePath;
  final String title;

  const ImageViewerDialog({
    super.key,
    required this.imagePath,
    required this.title,
  });

  static void show(BuildContext context, String imagePath, String title) {
    showDialog(
      context: context,
      builder: (ctx) => ImageViewerDialog(
        imagePath: imagePath,
        title: title,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final file = File(imagePath);
    final exists = file.existsSync();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(12),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            constraints: const BoxConstraints(maxHeight: 650),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1B2A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 14, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: () => Navigator.of(context).pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  child: exists
                      ? InteractiveViewer(
                          panEnabled: true,
                          minScale: 0.8,
                          maxScale: 4.0,
                          child: Image.file(
                            file,
                            fit: BoxFit.contain,
                            errorBuilder: (ctx, err, stack) => Container(
                              height: 200,
                              color: Colors.black26,
                              alignment: Alignment.center,
                              child: const Text(
                                'Gagal memuat gambar (file rusak / tidak didukung).',
                                style: TextStyle(color: Colors.white60),
                              ),
                            ),
                          ),
                        )
                      : Container(
                          height: 200,
                          color: Colors.black26,
                          alignment: Alignment.center,
                          child: const Text(
                            'Gambar tidak ditemukan di penyimpanan.',
                            style: TextStyle(color: Colors.white60),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
