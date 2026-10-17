class AppStrings {
  static const Map<String, Map<String, String>> _localizedValues = {
    'id': {
      // Navigation
      'nav_journal': 'Jurnal',
      'nav_summary': 'Ringkasan',
      'nav_settings': 'Atur',

      // Hero Card
      'hero_by': 'by',
      'hero_app_name': 'Traderlog',
      'hero_total_equity': 'Total akun',

      // Journal Screen
      'search_hint': 'Cari symbol atau alasan...',
      'filter_all': 'Semua',
      'filter_win': 'WIN',
      'filter_lose': 'LOSE',
      'filter_be': 'BE',
      'empty_trades_title': 'Belum ada trade.',
      'empty_trades_sub': 'Tekan tombol + di pojok kanan bawah untuk mencatat trade pertama Anda.',
      'no_filtered_trades': 'Tidak ada trade yang cocok dengan filter.',
      'view_chart_screenshot': 'Lihat Screenshot Chart',
      'equity_label': 'Equity',
      'lot_label': 'lot',

      // Trade Form
      'new_trade': 'Trade Baru',
      'edit_trade': 'Edit Trade',
      'date_time': 'Tanggal & Waktu',
      'symbol_pair': 'Symbol / Pair',
      'position': 'Posisi',
      'entry_price': 'Entry Price',
      'lot_size': 'Lot Size',
      'stop_loss': 'Stop Loss (SL)',
      'take_profit': 'Take Profit (TP)',
      'risk_reward': 'Risk to Reward',
      'pl_label': 'Profit / Loss ({curr}, gunakan minus jika loss)',
      'pl_hint': 'mis. 120 atau -50',
      'why_label': 'Alasan Ambil Trade (Setup / Konfirmasi)',
      'why_hint': 'mis. Break of structure di M15 + retest FVG',
      'note_label': 'Catatan Tambahan',
      'note_hint': 'mis. Eksekusi disiplin, trailing stop di BE',
      'chart_screenshot': 'Screenshot Chart Analisis',
      'from_gallery': 'Dari Galeri',
      'open_camera': 'Buka Kamera',
      'save_trade': 'Simpan Trade',
      'save_changes': 'Simpan Perubahan',
      'delete_trade': 'Hapus Trade',
      'confirm_delete_trade': 'Apakah Anda yakin ingin menghapus trade ini?',
      'cancel': 'Batal',
      'delete': 'Hapus',
      'trade_saved': 'Trade berhasil disimpan',
      'trade_updated': 'Trade berhasil diperbarui',
      'trade_deleted': 'Trade telah dihapus',
      'fill_pl_first': 'Isi profit/loss terlebih dahulu',
      'invalid_pl': 'Format profit/loss tidak valid',

      // Summary Screen
      'period_all': 'Semua',
      'period_30': '30 hari',
      'period_7': '7 hari',
      'empty_period': 'Belum ada trade pada periode ini.',
      'total_trades': 'Total trade',
      'win_rate': 'Win rate',
      'profit_loss': 'Profit / loss',
      'profit_factor': 'Profit factor',
      'equity_curve': 'Kurva Equity',
      'win_be_lose': 'Win / Break even / Loss',
      'avg_win': 'Rata-rata win',
      'avg_loss': 'Rata-rata loss',
      'expectancy': 'Expectancy per trade',
      'best_trade': 'Trade terbaik',
      'worst_trade': 'Trade terburuk',
      'max_drawdown': 'Max drawdown',
      'avg_rr': 'Rata-rata RR',
      'current_streak': 'Streak saat ini',
      'per_symbol': 'Per Symbol',
      'trades_count': 'trade',

      // Settings Categories
      'cat_profile': 'Profil',
      'cat_appearance': 'Tampilan',
      'cat_symbols': 'Simbol',
      'cat_data': 'Data',

      // Profile & Account Settings
      'trader_name': 'Nama Trader / Akun',
      'trader_name_hint': 'mis. Zacxy',
      'account_currency': 'Currency Akun (Mata Uang Utama)',
      'account_currency_hint': 'Pilih mata uang utama akun Anda',
      'exchange_currency': 'Currency Nilai Tukar (Exchange Rate)',
      'exchange_currency_hint': 'Pilih mata uang kurs pembanding (sementara IDR)',
      'initial_capital': 'Modal awal',
      'initial_capital_label': 'Modal awal ({curr})',
      'usd_idr_rate': 'Kurs Nilai Tukar',
      'exchange_rate_label': 'Kurs {target} per 1 {base}',
      'sync_rate': 'Sinkronkan Kurs',
      'syncing_rate': 'Mengambil kurs terkini...',
      'rate_synced': 'Kurs berhasil diperbarui: 1 {base} = {rate} {target}',
      'rate_sync_failed': 'Gagal mengambil kurs online. Menggunakan nilai tersimpan.',

      // Appearance Settings
      'appearance_title': 'Tampilan & Tema',
      'language_title': 'Pilihan Bahasa',
      'theme_mode': 'Tema Tampilan',
      'theme_system': 'Otomatis',
      'theme_light': 'Terang',
      'theme_dark': 'Gelap',
      'lang_id': 'Bahasa Indonesia',
      'lang_en': 'English',

      // Symbols Settings
      'symbols_title': 'Daftar Symbol Trading',
      'symbols_sub': 'Simbol yang tersedia untuk dipilih cepat saat mencatat trade baru.',
      'new_symbol_hint': 'Symbol baru, mis. NAS100',
      'add_symbol': 'Tambah',
      'delete_symbol_title': 'Hapus Symbol',
      'delete_symbol_msg': 'Hapus symbol {s} dari daftar cepat? Trade lama dengan symbol ini tetap aman.',

      // Data Settings
      'data_backup_title': 'Data & Cadangan (CSV)',
      'data_backup_sub': 'Data tersimpan di database SQLite lokal perangkat ini. Ekspor ke file CSV untuk cadangan atau dibuka di Excel / Google Sheets, lalu impor kembali kapan saja.',
      'export_csv': 'Ekspor CSV',
      'import_csv': 'Impor CSV',
      'delete_all_trades': 'Hapus Semua Trade',
      'confirm_reset_title': 'Hapus SEMUA Trade?',
      'confirm_reset_sub': 'Tindakan ini akan menghapus seluruh data jurnal trading. Pastikan Anda sudah mengekspor ke CSV jika memerlukan cadangan.',
      'no_trades_export': 'Belum ada trade untuk diekspor',
      'trades_exported': 'trade berhasil disiapkan untuk diekspor',
    },
    'en': {
      // Navigation
      'nav_journal': 'Journal',
      'nav_summary': 'Summary',
      'nav_settings': 'Settings',

      // Hero Card
      'hero_by': 'by',
      'hero_app_name': 'Traderlog',
      'hero_total_equity': 'Total Equity',

      // Journal Screen
      'search_hint': 'Search symbol or reason...',
      'filter_all': 'All',
      'filter_win': 'WIN',
      'filter_lose': 'LOSE',
      'filter_be': 'BE',
      'empty_trades_title': 'No trades recorded yet.',
      'empty_trades_sub': 'Tap the + button at the bottom right to record your first trade.',
      'no_filtered_trades': 'No trades match the current filter.',
      'view_chart_screenshot': 'View Chart Screenshot',
      'equity_label': 'Equity',
      'lot_label': 'lot',

      // Trade Form
      'new_trade': 'New Trade',
      'edit_trade': 'Edit Trade',
      'date_time': 'Date & Time',
      'symbol_pair': 'Symbol / Pair',
      'position': 'Position',
      'entry_price': 'Entry Price',
      'lot_size': 'Lot Size',
      'stop_loss': 'Stop Loss (SL)',
      'take_profit': 'Take Profit (TP)',
      'risk_reward': 'Risk to Reward',
      'pl_label': 'Profit / Loss ({curr}, use minus for loss)',
      'pl_hint': 'e.g. 120 or -50',
      'why_label': 'Trade Reason (Setup / Confirmation)',
      'why_hint': 'e.g. M15 break of structure + FVG retest',
      'note_label': 'Additional Notes',
      'note_hint': 'e.g. Disciplined execution, trailed SL to BE',
      'chart_screenshot': 'Chart Analysis Screenshot',
      'from_gallery': 'From Gallery',
      'open_camera': 'Open Camera',
      'save_trade': 'Save Trade',
      'save_changes': 'Save Changes',
      'delete_trade': 'Delete Trade',
      'confirm_delete_trade': 'Are you sure you want to delete this trade?',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'trade_saved': 'Trade saved successfully',
      'trade_updated': 'Trade updated successfully',
      'trade_deleted': 'Trade deleted',
      'fill_pl_first': 'Please fill in profit/loss first',
      'invalid_pl': 'Invalid profit/loss format',

      // Summary Screen
      'period_all': 'All',
      'period_30': '30 Days',
      'period_7': '7 Days',
      'empty_period': 'No trades recorded in this period.',
      'total_trades': 'Total trades',
      'win_rate': 'Win rate',
      'profit_loss': 'Profit / loss',
      'profit_factor': 'Profit factor',
      'equity_curve': 'Equity Curve',
      'win_be_lose': 'Win / Break even / Loss',
      'avg_win': 'Average win',
      'avg_loss': 'Average loss',
      'expectancy': 'Expectancy per trade',
      'best_trade': 'Best trade',
      'worst_trade': 'Worst trade',
      'max_drawdown': 'Max drawdown',
      'avg_rr': 'Average RR',
      'current_streak': 'Current streak',
      'per_symbol': 'Per Symbol',
      'trades_count': 'trades',

      // Settings Categories
      'cat_profile': 'Profile',
      'cat_appearance': 'Display',
      'cat_symbols': 'Symbols',
      'cat_data': 'Data',

      // Profile & Account Settings
      'trader_name': 'Trader / Account Name',
      'trader_name_hint': 'e.g. Zacxy',
      'account_currency': 'Account Currency (Base Currency)',
      'account_currency_hint': 'Select your primary account currency',
      'exchange_currency': 'Exchange Rate Currency',
      'exchange_currency_hint': 'Select comparison exchange currency (default IDR)',
      'initial_capital': 'Initial Capital',
      'initial_capital_label': 'Initial Capital ({curr})',
      'usd_idr_rate': 'Exchange Rate',
      'exchange_rate_label': 'Exchange rate: {target} per 1 {base}',
      'sync_rate': 'Sync Exchange Rate',
      'syncing_rate': 'Fetching live rate...',
      'rate_synced': 'Rate updated: 1 {base} = {rate} {target}',
      'rate_sync_failed': 'Could not fetch live rate. Using stored value.',

      // Appearance Settings
      'appearance_title': 'Theme & Display',
      'language_title': 'Language Selection',
      'theme_mode': 'Theme Mode',
      'theme_system': 'System',
      'theme_light': 'Light',
      'theme_dark': 'Dark',
      'lang_id': 'Bahasa Indonesia',
      'lang_en': 'English',

      // Symbols Settings
      'symbols_title': 'Active Trading Symbols',
      'symbols_sub': 'Pairs and instruments available for quick selection when creating trades.',
      'new_symbol_hint': 'New symbol, e.g. NAS100',
      'add_symbol': 'Add',
      'delete_symbol_title': 'Delete Symbol',
      'delete_symbol_msg': 'Remove {s} from the quick list? Existing trades will remain safe.',

      // Data Settings
      'data_backup_title': 'Data & Backup (CSV)',
      'data_backup_sub': 'Data is saved in this device\'s local SQLite database. Export to CSV for backups or Excel analysis, and restore anytime.',
      'export_csv': 'Export CSV',
      'import_csv': 'Import CSV',
      'delete_all_trades': 'Delete All Trades',
      'confirm_reset_title': 'Delete ALL Trades?',
      'confirm_reset_sub': 'This will permanently remove all trade records. Ensure you export a CSV backup beforehand if needed.',
      'no_trades_export': 'No trades to export',
      'trades_exported': 'trades prepared for export',
    },
  };

  /// Retrieves a localized string for given key and language code ('id' or 'en')
  static String tr(String key, String langCode, {Map<String, String>? params}) {
    final lang = _localizedValues.containsKey(langCode) ? langCode : 'id';
    String value = _localizedValues[lang]?[key] ?? _localizedValues['id']?[key] ?? key;

    if (params != null) {
      params.forEach((paramKey, paramVal) {
        value = value.replaceAll('{$paramKey}', paramVal);
      });
    }

    return value;
  }
}
