import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

/// Salted, iterated HMAC-SHA256 hashing for the app-lock PIN.
///
/// Stored format: `v1:<base64 salt>:<base64 hash>`.
///
/// Values that do not start with `v1:` are treated as legacy plaintext PINs
/// (written by app versions <= 1.5.2) and are migrated on first load.
///
/// NOTE: a 4-digit PIN only has 10,000 possibilities, so hashing cannot make
/// it strong against someone who has a copy of the database. It prevents the
/// PIN from being readable as-is (e.g. in a backup or a rooted-device dump).
class PinHasher {
  static const String _prefix = 'v1';
  static const String _sep = ':';
  static const int _iterations = 10000;
  static const int _saltLength = 16;

  static bool isHashed(String? stored) =>
      stored != null && stored.startsWith('$_prefix$_sep');

  static String hash(String pin, {List<int>? salt}) {
    final s = salt ?? _randomBytes(_saltLength);
    final digest = _derive(pin, s);
    return '$_prefix$_sep${base64.encode(s)}$_sep${base64.encode(digest)}';
  }

  static bool verify(String pin, String? stored) {
    if (stored == null || stored.isEmpty) return false;

    if (!isHashed(stored)) {
      // Legacy plaintext PIN.
      return _constantTimeEquals(utf8.encode(pin), utf8.encode(stored));
    }

    final parts = stored.split(_sep);
    if (parts.length != 3) return false;
    try {
      final salt = base64.decode(parts[1]);
      final expected = base64.decode(parts[2]);
      return _constantTimeEquals(_derive(pin, salt), expected);
    } catch (_) {
      return false;
    }
  }

  static List<int> _derive(String pin, List<int> salt) {
    final hmac = Hmac(sha256, salt);
    var digest = hmac.convert(utf8.encode(pin)).bytes;
    for (var i = 1; i < _iterations; i++) {
      digest = hmac.convert(digest).bytes;
    }
    return digest;
  }

  static List<int> _randomBytes(int n) {
    final rnd = Random.secure();
    return List<int>.generate(n, (_) => rnd.nextInt(256));
  }

  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
