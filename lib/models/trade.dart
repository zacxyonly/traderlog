import '../utils/pnl_calculator.dart';

enum TradeSide { buy, sell }

enum TradeResult { win, lose, be }

class Trade {
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

  /// Approximate pips / points gained or lost based on entry and exit.
  /// Returns null for symbols whose pip size is unknown (custom symbols).
  double? get pipsGained {
    if (entry == null || exit == null) return null;
    return PnlCalculator.pipsFor(
      symbol: sym,
      side: side,
      entry: entry!,
      exit: exit!,
    );
  }

  String get formattedPips {
    final pips = pipsGained;
    if (pips == null) return '';
    final unit = PnlCalculator.unitFor(sym);
    final prefix = pips > 0 ? '+' : '';
    return '$prefix${pips.toStringAsFixed(1)} $unit';
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
    double? entry,
    double? exit,
    double? sl,
    double? tp,
    double? lot,
    double? pl,
    String? why,
    String? note,
    String? imagePath,
    String? imagePathAfter,
    String? accountId,
  }) {
    return Trade(
      id: id ?? this.id,
      date: date ?? this.date,
      sym: sym ?? this.sym,
      side: side ?? this.side,
      entry: entry ?? this.entry,
      exit: exit ?? this.exit,
      sl: sl ?? this.sl,
      tp: tp ?? this.tp,
      lot: lot ?? this.lot,
      pl: pl ?? this.pl,
      why: why ?? this.why,
      note: note ?? this.note,
      imagePath: imagePath ?? this.imagePath,
      imagePathAfter: imagePathAfter ?? this.imagePathAfter,
      accountId: accountId ?? this.accountId,
    );
  }
}
