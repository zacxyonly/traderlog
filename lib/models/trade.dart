import '../utils/pnl_calculator.dart';

enum TradeSide { buy, sell }

enum TradeResult { win, lose, be }

class Trade {
  static const Object _sentinel = Object();

  final String id;
  final DateTime date;
  final String sym;
  final TradeSide side;
  final double? entry;
  final double? exit;
  final double? sl;
  final double? tp;
  final double? lot;
  final double pl;
  final String? why;
  final String? note;
  final String? tags; // Separated setup and emotion tags (e.g. "BOS, FOMO")
  final String? imagePath; // Slot 1: Sebelum Entry (Setup)
  final String? imagePathAfter; // Slot 2: Sesudah Selesai (Eksekusi / Reaksi Harga)
  final String? accountId; // Multi-Account ID

  Trade({
    required this.id,
    required this.date,
    required this.sym,
    required this.side,
    this.entry,
    this.exit,
    this.sl,
    this.tp,
    this.lot,
    required this.pl,
    this.why,
    this.note,
    this.tags,
    this.imagePath,
    this.imagePathAfter,
    this.accountId = 'acc_real',
  });

  TradeResult get result {
    if (pl > 0) return TradeResult.win;
    if (pl < 0) return TradeResult.lose;
    return TradeResult.be;
  }

  String get resultString {
    switch (result) {
      case TradeResult.win:
        return 'WIN';
      case TradeResult.lose:
        return 'LOSE';
      case TradeResult.be:
        return 'BE';
    }
  }

  String get sideString => side == TradeSide.buy ? 'BUY' : 'SELL';

  /// Planned Risk-to-Reward ratio from Entry, SL, and TP
  double? get riskRewardRatio {
    if (entry != null && sl != null && tp != null && entry != sl) {
      final risk = (entry! - sl!).abs();
      final reward = (tp! - entry!).abs();
      if (risk > 0) {
        return reward / risk;
      }
    }
    return null;
  }

  String get formattedRR {
    final rr = riskRewardRatio;
    if (rr != null && rr > 0) {
      return '1:${rr.toStringAsFixed(2)}';
    }
    return '-';
  }

  /// Realized Risk-to-Reward ratio (R-Multiple) from Entry, SL, and actual Exit
  double? get realizedRR {
    if (entry != null && exit != null && sl != null && entry != sl) {
      final risk = (entry! - sl!).abs();
      final reward = (side == TradeSide.buy) ? (exit! - entry!) : (entry! - exit!);
      if (risk > 0) {
        return reward / risk;
      }
    }
    return null;
  }

  String get formattedRealizedRR {
    final rrr = realizedRR;
    if (rrr != null) {
      if (rrr >= 0) {
        return '1:${rrr.toStringAsFixed(2)}';
      } else {
        return '-1:${rrr.abs().toStringAsFixed(2)}';
      }
    }
    return '-';
  }

  /// Approximate pips / points gained or lost based on entry and exit (shared with PnlCalculator)
  double? get pipsGained {
    return PnlCalculator.calculatePips(
      symbol: sym,
      side: side,
      entry: entry,
      exit: exit,
    );
  }

  String get formattedPips {
    return PnlCalculator.formatPips(
      symbol: sym,
      side: side,
      entry: entry,
      exit: exit,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'sym': sym,
      'side': sideString,
      'entry': entry,
      'exit': exit,
      'sl': sl,
      'tp': tp,
      'lot': lot,
      'pl': pl,
      'why': why,
      'note': note,
      'tags': tags,
      'image_path': imagePath,
      'image_path_after': imagePathAfter,
      'account_id': accountId ?? 'acc_real',
    };
  }

  factory Trade.fromMap(Map<String, dynamic> map) {
    return Trade(
      id: map['id'] as String,
      date: DateTime.parse(map['date'] as String),
      sym: map['sym'] as String,
      side: (map['side'] as String).toUpperCase() == 'SELL'
          ? TradeSide.sell
          : TradeSide.buy,
      entry: map['entry'] != null ? (map['entry'] as num).toDouble() : null,
      exit: map['exit'] != null ? (map['exit'] as num).toDouble() : null,
      sl: map['sl'] != null ? (map['sl'] as num).toDouble() : null,
      tp: map['tp'] != null ? (map['tp'] as num).toDouble() : null,
      lot: map['lot'] != null ? (map['lot'] as num).toDouble() : null,
      pl: (map['pl'] as num).toDouble(),
      why: map['why'] as String?,
      note: map['note'] as String?,
      tags: map['tags'] as String?,
      imagePath: map['image_path'] as String?,
      imagePathAfter: map['image_path_after'] as String?,
      accountId: map['account_id'] as String? ?? 'acc_real',
    );
  }

  Trade copyWith({
    String? id,
    DateTime? date,
    String? sym,
    TradeSide? side,
    Object? entry = _sentinel,
    Object? exit = _sentinel,
    Object? sl = _sentinel,
    Object? tp = _sentinel,
    Object? lot = _sentinel,
    double? pl,
    Object? why = _sentinel,
    Object? note = _sentinel,
    Object? tags = _sentinel,
    Object? imagePath = _sentinel,
    Object? imagePathAfter = _sentinel,
    String? accountId,
  }) {
    return Trade(
      id: id ?? this.id,
      date: date ?? this.date,
      sym: sym ?? this.sym,
      side: side ?? this.side,
      entry: identical(entry, _sentinel) ? this.entry : entry as double?,
      exit: identical(exit, _sentinel) ? this.exit : exit as double?,
      sl: identical(sl, _sentinel) ? this.sl : sl as double?,
      tp: identical(tp, _sentinel) ? this.tp : tp as double?,
      lot: identical(lot, _sentinel) ? this.lot : lot as double?,
      pl: pl ?? this.pl,
      why: identical(why, _sentinel) ? this.why : why as String?,
      note: identical(note, _sentinel) ? this.note : note as String?,
      tags: identical(tags, _sentinel) ? this.tags : tags as String?,
      imagePath: identical(imagePath, _sentinel) ? this.imagePath : imagePath as String?,
      imagePathAfter: identical(imagePathAfter, _sentinel) ? this.imagePathAfter : imagePathAfter as String?,
      accountId: accountId ?? this.accountId,
    );
  }
}
