import 'dart:convert';
import 'dart:io';
import '../constants/app_info.dart';

class UpdateInfo {
  final String latestVersion;
  final String releaseUrl;
  final bool isNewer;

  const UpdateInfo({
    required this.latestVersion,
    required this.releaseUrl,
    required this.isNewer,
  });
}

class UpdateException implements Exception {
  /// 'no_release' bila repo belum punya rilis, 'http' untuk error lainnya.
  final String code;
  UpdateException(this.code);
}

/// Mengecek rilis terbaru di GitHub. Tidak memakai paket HTTP tambahan.
class UpdateService {
  UpdateService._();

  static const String _latestApi =
      'https://api.github.com/repos/zacxyonly/traderlog/releases/latest';
  static const String _releasesPage =
      'https://github.com/zacxyonly/traderlog/releases';

  static Future<UpdateInfo> checkLatest({
    String currentVersion = AppInfo.version,
  }) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      final req = await client.getUrl(Uri.parse(_latestApi));
      req.headers.set(HttpHeaders.acceptHeader, 'application/vnd.github+json');
      req.headers.set(HttpHeaders.userAgentHeader, 'TraderLog-App');

      final res = await req.close();
      if (res.statusCode == 404) throw UpdateException('no_release');
      if (res.statusCode != 200) throw UpdateException('http');

      final body = await res.transform(utf8.decoder).join();
      final json = jsonDecode(body) as Map<String, dynamic>;
      final tag = (json['tag_name'] as String?) ?? '';
      final url = (json['html_url'] as String?) ?? _releasesPage;
      final latest = tag.replaceFirst(RegExp(r'^[vV]'), '');

      return UpdateInfo(
        latestVersion: latest,
        releaseUrl: url,
        isNewer: compareVersions(latest, currentVersion) > 0,
      );
    } finally {
      client.close(force: true);
    }
  }

  /// Membandingkan "1.10.0" dengan "1.9.0" secara numerik per segmen.
  /// Bagian build setelah '+' diabaikan. Hasil > 0 jika [a] lebih baru.
  static int compareVersions(String a, String b) {
    List<int> parse(String v) => v
        .split('+')
        .first
        .split('.')
        .map((p) => int.tryParse(p.trim()) ?? 0)
        .toList();

    final pa = parse(a);
    final pb = parse(b);
    for (int i = 0; i < 3; i++) {
      final x = i < pa.length ? pa[i] : 0;
      final y = i < pb.length ? pb[i] : 0;
      if (x != y) return x.compareTo(y);
    }
    return 0;
  }
}
