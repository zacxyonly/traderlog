# Traderlog - Aplikasi Android Jurnal Trading (Flutter)

[![Build Android APK](https://github.com/zacxyonly/traderlog/actions/workflows/build_apk.yml/badge.svg)](https://github.com/zacxyonly/traderlog/actions/workflows/build_apk.yml)

Aplikasi Android jurnal trading profesional dengan antarmuka modern (Dark Navy & Emerald Green) terinspirasi dari prototipe `Trading Journal.html`. Dibangun menggunakan **Flutter**, database relasional lokal **SQFlite (SQLite)**, dan arsitektur state management **Provider**.

---

## ✨ Fitur Utama

1. **Jurnal & Log Trade**:
   - Pencatatan lengkap: Tanggal & waktu, Symbol/Pair, Posisi (BUY/SELL), Entry price, Stop Loss (SL), Take Profit (TP), Lot size, Profit/Loss (USD), Alasan ambil trade (Setup), dan Catatan.
   - **Kalkulator Risk:Reward (RR) Live**: Menghitung rasio RR secara otomatis dan interaktif saat Anda mengetik Entry, SL, dan TP.
   - **Lampiran Screenshot Chart**: Simpan gambar atau tangkapan layar analisis teknikal langsung dari Galeri HP atau Kamera, lengkap dengan viewer full screen zoomable.
   - **Pengelompokan Bulanan**: Daftar trade dikelompokkan per bulan dengan subtotal Profit/Loss bulanan.
   - **Filter Cepat & Pencarian**: Filter trade berdasarkan status (`Semua`, `WIN`, `LOSE`, `BE`) dan pencarian instan berdasarkan simbol atau alasan.

2. **Ringkasan & Analisis Mendalam**:
   - Filter periode: **Semua**, **30 Hari Terakhir**, **7 Hari Terakhir**.
   - Kartu Metrik Utama: Total Trade, Win Rate (dengan progress bar), Profit / Loss, Profit Factor.
   - **Kurva Equity Dinamis**: Visualisasi grafik kurva modal akumulatif dengan gradien halus.
   - Statistik Lanjutan:
     - Rasio Win / Break Even / Loss
     - Rata-rata Win & Rata-rata Loss
     - Expectancy per trade
     - Trade Terbaik & Terburuk
     - Max Drawdown (%)
     - Rata-rata Risk to Reward (RR)
     - Streak saat ini (mis. *3 win* beruntun)
   - **Performa Per Simbol**: Analisis performa per pair/instrumen dengan persentase win rate dan progress bar visual.

3. **Pengaturan & Manajemen Data**:
   - **Modal Awal (USD)**: Atur modal awal akun untuk kalkulasi persentase pertumbuhan dan drawdown.
   - **Kurs IDR/USD**: Konversi saldo akun dan profit/loss ke Rupiah Indonesia (IDR) secara instan.
   - **Dukungan Tema**: Mode Gelap (Dark Mode khas Dark Navy), Mode Terang (Light Mode), dan Otomatis (mengikuti sistem HP).
   - **Kelola Simbol**: Tambah simbol/pair kustom baru dan hapus simbol yang tidak dipakai.
   - **Ekspor CSV**: Cadangkan seluruh riwayat trade ke file `.csv` standar (didukung Excel dan Google Sheets) melalui native Share Sheet Android.
   - **Impor CSV**: Pulihkan data trading dari file CSV dengan deteksi otomatis duplikat dan validasi baris.
   - **Database Lokal Offline**: Menggunakan SQLite lokal perangkat tanpa memerlukan koneksi internet, menjamin privasi dan keamanan data trading Anda.

---

## 📁 Struktur Direktori

```
/root/tradelog/
├── android/                         # Konfigurasi native Android (Gradle, Manifest, Permissions)
├── lib/
│   ├── constants/
│   │   └── app_colors.dart          # Palet warna tema (Dark Navy, Emerald, Wine Red, Amber)
│   ├── database/
│   │   └── db_helper.dart           # SQLite helper untuk tabel trades & settings
│   ├── models/
│   │   ├── app_settings.dart        # Model pengaturan (modal, kurs, tema, simbol)
│   │   └── trade.dart               # Model trade (kalkulasi RR, status WIN/LOSE/BE)
│   ├── providers/
│   │   └── trade_provider.dart      # Provider manajemen state & analitik
│   ├── screens/
│   │   ├── journal_screen.dart      # Halaman utama jurnal trading & pencarian
│   │   ├── main_navigation_screen.dart # Navigasi melayang dengan efek blur & FAB
│   │   ├── settings_screen.dart     # Pengaturan modal, kurs, tema, simbol & CSV
│   │   ├── summary_screen.dart      # Analisis performa trading & breakdown pair
│   │   └── trade_form_sheet.dart    # Bottom sheet input & edit trade
│   ├── services/
│   │   └── csv_service.dart         # Layanan ekspor & impor file CSV
│   ├── utils/
│   │   └── formatters.dart          # Pemformat mata uang (USD, IDR), tanggal, dan persen
│   ├── widgets/
│   │   ├── equity_sparkline.dart    # Custom painter grafik kurva modal (equity)
│   │   ├── hero_summary_card.dart   # Kartu hero saldo akun & IDR di bagian atas
│   │   ├── image_viewer_dialog.dart # Dialog preview gambar chart zoomable
│   │   ├── stat_card.dart           # Komponen kartu statistik metrik
│   │   └── trade_card.dart          # Komponen kartu riwayat trade
│   └── main.dart                    # Entry point aplikasi Flutter
├── test/
│   └── widget_test.dart             # Unit test kalkulasi RR, CSV parsing, & model
├── pubspec.yaml                     # Konfigurasi dependensi Flutter
└── Trading Journal.html             # Mockup & prototipe HTML asli
```

---

## 🚀 Cara Menjalankan & Build APK

### 1. Menjalankan di Perangkat Android / Emulator
```bash
# Pastikan perangkat/emulator Android terhubung
flutter devices

# Jalankan aplikasi dalam mode debug
flutter run
```

### 2. Membangun File APK Android (Release)
```bash
# Build file APK siap install di HP Android
flutter build apk --release
```
File APK yang dihasilkan akan berada di:
`build/app/outputs/flutter-apk/app-release.apk`

### 3. Menjalankan Unit Test
```bash
flutter test
```
