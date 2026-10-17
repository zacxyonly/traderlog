import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/trade.dart';
import '../utils/formatters.dart';

class CSVImportResult {
  final List<Trade> trades;
  final int totalRows;
  final int skipped;
  final int duplicates;

  CSVImportResult({
    required this.trades,
    required this.totalRows,
    required this.skipped,
    required this.duplicates,
  });
}

class CSVService {
  /// Generate CSV string with UTF-8 BOM
  static String generateCSV({
    required List<Trade> trades,
    required double initialCapital,
  }) {
    final List<List<dynamic>> rows = [];

    // Header
    rows.add([
      'No',
      'Date',
      'Symbol',
      'Side',
      'Entry',
      'Exit',
      'SL',
      'TP',
      'Lot',
      'RR',
      'Result',
      'PL',
      'Equity',
      'Why',
      'Note'
    ]);

    double equity = initialCapital;
    final sortedTrades = List<Trade>.from(trades)
      ..sort((a, b) => a.date.compareTo(b.date));

    for (int i = 0; i < sortedTrades.length; i++) {
      final t = sortedTrades[i];
      equity += t.pl;

      rows.add([
        i + 1,
        t.date.toIso8601String(),
        t.sym,
        t.sideString,
        t.entry?.toString() ?? '',
        t.exit?.toString() ?? '',
        t.sl?.toString() ?? '',
        t.tp?.toString() ?? '',
        t.lot?.toString() ?? '',
        t.formattedRR,
        t.resultString,
        t.pl,
        equity.toStringAsFixed(2),
        t.why ?? '',
        t.note ?? '',
      ]);
    }

    final csvData = const ListToCsvConverter().convert(rows);
    return '\uFEFF$csvData';
  }

  /// Export trades to CSV and prompt native Share Sheet / Save dialog
  static Future<String> exportTrades({
    required List<Trade> trades,
    required double initialCapital,
    String? customFileName,
    String? shareText,
  }) async {
    final csvWithBom = generateCSV(trades: trades, initialCapital: initialCapital);

    final tempDir = await getTemporaryDirectory();
    final fileName = customFileName ??
        'traderlog_${Formatters.formatDate(DateTime.now())}.csv';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsString(csvWithBom);

    // Share the file
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/csv')],
      text: shareText,
      subject: 'Traderlog Backup CSV',
    );

    return file.path;
  }

  /// Parse CSV content from string
  static CSVImportResult parseCSV(
    String content, {
    required List<Trade> existingTrades,
    bool replace = false,
  }) {
    String cleanContent = content.replaceAll('\uFEFF', '').trim();
    if (cleanContent.isEmpty) {
      return CSVImportResult(trades: [], totalRows: 0, skipped: 0, duplicates: 0);
    }

    // Detect delimiter
    final firstLine = cleanContent.split(RegExp(r'\r?\n')).first;
    final commaCount = firstLine.split(',').length;
    final semiCount = firstLine.split(';').length;
    final fieldDelimiter = semiCount > commaCount ? ';' : ',';

    // Normalize newlines to \n
    final normalized = cleanContent.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

    final converter = CsvToListConverter(
      fieldDelimiter: fieldDelimiter,
      eol: '\n',
      shouldParseNumbers: false,
    );

    final List<List<dynamic>> rows = converter.convert(normalized);
    if (rows.length < 2) {
      return CSVImportResult(trades: [], totalRows: 0, skipped: 0, duplicates: 0);
    }

    final header = rows[0]
        .map((e) => e.toString().trim().toLowerCase())
        .toList();

    // Map column aliases
    final Map<String, List<String>> aliases = {
      'date': ['date', 'date and time', 'tanggal', 'waktu'],
      'sym': ['symbol', 'symbol/pair', 'pair', 'simbol'],
      'side': ['side', 'buy/sell', 'posisi', 'arah'],
      'entry': ['entry', 'open', 'harga masuk'],
      'exit': ['exit', 'close', 'harga keluar', 'harga tutup', 'target exit'],
      'sl': ['sl', 'stop loss', 'stoploss'],
      'tp': ['tp', 'take profit', 'takeprofit'],
      'lot': ['lot', 'lot size', 'ukuran lot'],
      'pl': ['pl', 'profit or loss', 'profit/loss', 'profit', 'untung/rugi'],
      'why': ['why', 'alasan', 'alasan ambil trade', 'setup', 'analisis'],
      'note': ['note', 'trade note', 'catatan', 'keterangan'],
    };

    final Map<String, int> colIdx = {};
    for (final entry in aliases.entries) {
      final idx = header.indexWhere((h) => entry.value.contains(h));
      colIdx[entry.key] = idx;
    }

    if (colIdx['date'] == -1 || colIdx['pl'] == -1) {
      throw Exception(
        'Format CSV tidak valid. Harus memiliki kolom "Date" dan "PL" (Profit/Loss).',
      );
    }

    String getVal(List<dynamic> row, String key) {
      final idx = colIdx[key];
      if (idx == null || idx < 0 || idx >= row.length) return '';
      return row[idx].toString().trim().replaceAll(RegExp(r"^'"), '');
    }

    double? parseNum(String val) {
      var s = val.replaceAll(RegExp(r'[\$\s]'), '');
      if (s.isEmpty) return null;
      // Handle parentheses for negative numbers, e.g. (50.0) -> -50.0
      if (s.startsWith('(') && s.endsWith(')')) {
        s = '-${s.substring(1, s.length - 1)}';
      }
      // Handle commas and periods
      if (s.contains(',') && s.contains('.')) {
        if (s.lastIndexOf(',') > s.lastIndexOf('.')) {
          s = s.replaceAll('.', '').replaceAll(',', '.');
        } else {
          s = s.replaceAll(',', '');
        }
      } else {
        s = s.replaceAll(',', '.');
      }
      return double.tryParse(s);
    }

    DateTime? parseDate(String val) {
      if (val.isEmpty) return null;
      try {
        return DateTime.parse(val);
      } catch (_) {}

      // Try dd/MM/yyyy HH:mm or yyyy/MM/dd HH:mm
      final match = RegExp(
              r'^(\d{1,4})[./-](\d{1,2})[./-](\d{1,4})(?:[ T]+(\d{1,2}):(\d{2}))?')
          .firstMatch(val);
      if (match != null) {
        int p1 = int.parse(match.group(1)!);
        int p2 = int.parse(match.group(2)!);
        int p3 = int.parse(match.group(3)!);
        int hour = int.tryParse(match.group(4) ?? '0') ?? 0;
        int min = int.tryParse(match.group(5) ?? '0') ?? 0;

        int year = p1 > 1000 ? p1 : p3;
        int month = p1 > 1000 ? p2 : p2;
        int day = p1 > 1000 ? p3 : p1;

        if (month >= 1 && month <= 12 && day >= 1 && day <= 31) {
          return DateTime(year, month, day, hour, min);
        }
      }
      return null;
    }

    final Set<String> existingKeys = replace
        ? {}
        : existingTrades
            .map((t) =>
                '${t.date.toIso8601String()}|${t.sym}|${t.pl}|${t.entry ?? 0}')
            .toSet();

    final List<Trade> importedTrades = [];
    int skipped = 0;
    int duplicates = 0;
    final int nowMs = DateTime.now().millisecondsSinceEpoch;

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty || row.every((c) => c.toString().trim().isEmpty)) {
        continue;
      }

      final dateStr = getVal(row, 'date');
      final plStr = getVal(row, 'pl');

      final date = parseDate(dateStr);
      final pl = parseNum(plStr);

      if (date == null || pl == null) {
        skipped++;
        continue;
      }

      final sym = getVal(row, 'sym').toUpperCase();
      final sideStr = getVal(row, 'side').toUpperCase();
      final side = sideStr == 'SELL' ? TradeSide.sell : TradeSide.buy;
      final entry = parseNum(getVal(row, 'entry'));
      final exit = parseNum(getVal(row, 'exit'));
      final sl = parseNum(getVal(row, 'sl'));
      final tp = parseNum(getVal(row, 'tp'));
      final lot = parseNum(getVal(row, 'lot'));
      final why = getVal(row, 'why');
      final note = getVal(row, 'note');

      final key = '${date.toIso8601String()}|$sym|$pl|${entry ?? 0}';
      if (existingKeys.contains(key)) {
        duplicates++;
        continue;
      }
      existingKeys.add(key);

      importedTrades.add(Trade(
        id: '${nowMs}_$i',
        date: date,
        sym: sym.isEmpty ? 'CUSTOM' : sym,
        side: side,
        entry: entry,
        exit: exit,
        sl: sl,
        tp: tp,
        lot: lot,
        pl: pl,
        why: why.isNotEmpty ? why : null,
        note: note.isNotEmpty ? note : null,
      ));
    }

    return CSVImportResult(
      trades: importedTrades,
      totalRows: rows.length - 1,
      skipped: skipped,
      duplicates: duplicates,
    );
  }
}
