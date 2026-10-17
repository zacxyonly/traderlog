enum TradeSide { buy, sell }

enum TradeResult { win, lose, be }

class Trade {
  final String id;
  final DateTime date;
  final String sym;
  final TradeSide side;
  final double? entry;
  final double? sl;
  final double? tp;
  final double? lot;
  final double pl;
  final String? why;
  final String? note;
  final String? imagePath;

  Trade({
    required this.id,
    required this.date,
    required this.sym,
    required this.side,
    this.entry,
    this.sl,
    this.tp,
    this.lot,
    required this.pl,
    this.why,
    this.note,
    this.imagePath,
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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'sym': sym,
      'side': sideString,
      'entry': entry,
      'sl': sl,
      'tp': tp,
      'lot': lot,
      'pl': pl,
      'why': why,
      'note': note,
      'image_path': imagePath,
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
      sl: map['sl'] != null ? (map['sl'] as num).toDouble() : null,
      tp: map['tp'] != null ? (map['tp'] as num).toDouble() : null,
      lot: map['lot'] != null ? (map['lot'] as num).toDouble() : null,
      pl: (map['pl'] as num).toDouble(),
      why: map['why'] as String?,
      note: map['note'] as String?,
      imagePath: map['image_path'] as String?,
    );
  }

  Trade copyWith({
    String? id,
    DateTime? date,
    String? sym,
    TradeSide? side,
    double? entry,
    double? sl,
    double? tp,
    double? lot,
    double? pl,
    String? why,
    String? note,
    String? imagePath,
  }) {
    return Trade(
      id: id ?? this.id,
      date: date ?? this.date,
      sym: sym ?? this.sym,
      side: side ?? this.side,
      entry: entry ?? this.entry,
      sl: sl ?? this.sl,
      tp: tp ?? this.tp,
      lot: lot ?? this.lot,
      pl: pl ?? this.pl,
      why: why ?? this.why,
      note: note ?? this.note,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}
