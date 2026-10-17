<p align="center">
  <img src="android/app/src/main/res/icon_512.png" width="128" height="128" alt="TraderLog Logo" style="border-radius: 28px; box-shadow: 0 10px 30px rgba(16, 185, 129, 0.3);" />
</p>

<h1 align="center">TraderLog</h1>

<p align="center">
  <strong>A Sleek, Offline-First Android Trading Journal & Quantitative Performance Tracker</strong>
</p>

<p align="center">
  <a href="https://github.com/zacxyonly/traderlog/releases/latest">
    <img src="https://img.shields.io/github/v/release/zacxyonly/traderlog?style=for-the-badge&color=10B981&labelColor=0A111C&logo=github&logoColor=white" alt="Latest Release" />
  </a>
  <a href="https://flutter.dev">
    <img src="https://img.shields.io/badge/Flutter-3.24.5-02569B?style=for-the-badge&labelColor=0A111C&logo=flutter&logoColor=white" alt="Flutter Version" />
  </a>
  <a href="https://www.android.com">
    <img src="https://img.shields.io/badge/Platform-Android_API_21+-3DDC84?style=for-the-badge&labelColor=0A111C&logo=android&logoColor=white" alt="Android Support" />
  </a>
  <a href="https://sqlite.org">
    <img src="https://img.shields.io/badge/Database-SQLite_Offline-003B57?style=for-the-badge&labelColor=0A111C&logo=sqlite&logoColor=white" alt="SQLite Offline" />
  </a>
  <a href="LICENSE">
    <img src="https://img.shields.io/badge/License-MIT-F59E0B?style=for-the-badge&labelColor=0A111C" alt="License MIT" />
  </a>
</p>

<p align="center">
  <a href="https://github.com/zacxyonly/traderlog/releases/download/v1.1.0/TraderLog-v1.0.0.apk">
    <img src="https://img.shields.io/badge/📲_Download_Release_APK-v1.1.0-10B981?style=for-the-badge&labelColor=121B2B" alt="Download APK" />
  </a>
  <a href="https://github.com/zacxyonly/traderlog/actions/workflows/build_apk.yml">
    <img src="https://img.shields.io/badge/⚙️_GitHub_Actions-Manual_Build-6366F1?style=for-the-badge&labelColor=121B2B&logo=githubactions&logoColor=white" alt="Actions CI" />
  </a>
</p>

---

## 📖 Overview

**TraderLog** adalah aplikasi jurnal trading Android berkecepatan tinggi yang dirancang khusus untuk trader Forex, Komoditas (Gold/XAUUSD), Saham, Indeks, dan Crypto yang mengutamakan disiplin psikologi serta pembuktian statistik atas trading rule mereka.

Dibangun dengan arsitektur modern **Flutter** dan penyimpanan lokal **SQLite (SQFlite)**, TraderLog menjamin kerahasiaan 100% data akun dan transaksi Anda: **tanpa cloud tracking, tanpa registrasi akun, tanpa koneksi internet wajib, dan bebas latency**.

---

## 🌟 Fitur Unggulan

| Modul | Deskripsi Kemampuan |
| :--- | :--- |
| **⚡ Live Risk:Reward Calculator** | Menghitung rasio Risk to Reward secara otomatis dan real-time saat Anda mengetik Entry Price, Stop Loss (SL), dan Take Profit (TP). |
| **📈 Kurva Modal & Analisis Mendalam** | Grafik kurva equity akumulatif interaktif dengan kalkulasi Win Rate, Profit Factor, Expectancy, Average Win/Loss, Max Drawdown, dan Streak beruntun. |
| **📸 Lampiran Screenshot Chart** | Sematkan gambar grafik chart analisis teknikal langsung dari Galeri perangkat atau Kamera, lengkap dengan image viewer zoomable layar penuh. |
| **🌐 Bilingual (ID & EN)** | Beralih instan antara **Bahasa Indonesia** 🇮🇩 dan **English** 🇬🇧 di seluruh menu, navigasi, dialog, dan formulir. |
| **⚙️ Tab Pengaturan Terkategori** | Menu pengaturan terbagi rapi ke 4 kategori: **Profil**, **Tampilan**, **Simbol**, dan **Data**. |
| **👤 Label Akun / Trader Dinamis** | Kustomisasi nama trader atau nama akun (tampil dinamis di kartu Hero, e.g. *by Zacxy*). |
| **🔄 Cadangan & Migrasi CSV** | Ekspor seluruh histori trading ke file CSV standar (kompatibel Excel & Google Sheets) serta fitur Impor cerdas dengan deteksi duplikat otomatis. |
| **🌙 Palet Desain Emerald & Dark Navy** | Desain bertema gelap elegan yang nyaman di mata untuk sesi trading maraton di malam hari, dilengkapi opsi mode terang (Light Mode) dan sistem otomatis. |

---

## 📱 Tampilan & Antarmuka Aplikasi

```
┌─────────────────────────────────┐   ┌─────────────────────────────────┐   ┌─────────────────────────────────┐
│           JURNAL TRADE          │   │        RINGKASAN PERFORMA       │   │        PENGATURAN (ATUR)        │
├─────────────────────────────────┤   ├─────────────────────────────────┤   ├─────────────────────────────────┤
│ [ Total Akun ]     $1,450.00    │   │ Periode: [Semua] [30 Hari] [7h] │   │ [Profil] [Tampilan] [Simbol] [Data]
│ by Zacxy       Rp 26.097.100    │   │                                 │   │                                 │
│                                 │   │  Total: 28      Win Rate: 68%   │   │ Nama Akun / Trader: [ Zacxy   ] │
│ 🔍 Cari symbol atau setup...    │   │  P/L: +$450     PF: 2.14        │   │ Modal Awal (USD)  : [ 1000    ] │
│ [Semua] [WIN] [LOSE] [BE]       │   │                                 │   │ Kurs IDR/USD      : [ 17998   ] │
│                                 │   │ ─── Kurva Equity (Sparkline) ── │   │                                 │
│ ▾ Oktober 2026      +$320.00    │   │  Expectancy: +$16.07 / trade    │   │ Pilihan Bahasa:                 │
│  • XAU/USD BUY       +$150.00   │   │  Max Drawdown: -5.2%            │   │  (•) Bahasa ID   ( ) English    │
│    Entry: 2650 | Lot: 0.10      │   │  Rata-rata RR: 1:2.45           │   │                                 │
│    Setup: M15 FVG Retest        │   │                                 │   │ Cadangan & Data:                │
│    [📷 Lihat Screenshot Chart]  │   │ ▾ Performa Per Symbol           │   │  [ 📤 Ekspor CSV ]               │
│                                 │   │  XAU/USD: 16 trades (75% Win)   │   │  [ 📥 Impor CSV  ]               │
└─────────────────────────────────┘   └─────────────────────────────────┘   └─────────────────────────────────┘
```

---

## 🛠️ Arsitektur & Teknologi

TraderLog dibangun menggunakan teknologi dan pustaka terbaik dalam ekosistem Flutter:

- **Framework**: [Flutter](https://flutter.dev) (v3.24.5 - Channel Stable)
- **Programming Language**: [Dart](https://dart.dev) (v3.5.4)
- **Local Database**: [sqflite](https://pub.dev/packages/sqflite) dengan engine SQLite native
- **State Management**: [provider](https://pub.dev/packages/provider) (arsitektur reaktif)
- **Path Resolution**: [path_provider](https://pub.dev/packages/path_provider) & [path](https://pub.dev/packages/path)
- **File System & Sharing**: [share_plus](https://pub.dev/packages/share_plus) & [file_picker](https://pub.dev/packages/file_picker)
- **Media Capture**: [image_picker](https://pub.dev/packages/image_picker)
- **CI / CD Pipeline**: GitHub Actions (`ubuntu-latest`, Temurin JDK 17, `workflow_dispatch`)

---

## 📂 Struktur Direktori Proyek

```plaintext
traderlog/
├── .github/
│   └── workflows/
│       └── build_apk.yml          # Otomasi kompilasi APK rilis via GitHub Actions (Manual)
├── android/                       # Konfigurasi native Android, Manifest & Resource icon
│   └── app/src/main/res/
│       ├── icon_512.png           # Master artwork ikon resolusi tinggi
│       └── mipmap-*/              # Launcher icon terkompilasi untuk seluruh DPI perangkat
├── lib/
│   ├── constants/
│   │   └── app_colors.dart        # Palet warna primer (Emerald, Navy, Wine Red, Amber)
│   ├── database/
│   │   └── db_helper.dart         # Skema tabel SQLite, migrasi kolom & query persistensi
│   ├── models/
│   │   ├── app_settings.dart      # Model konfigurasi akun, kurs mata uang, tema & simbol
│   │   └── trade.dart             # Model data transaksi, kalkulasi rasio RR & enum status
│   ├── providers/
│   │   └── trade_provider.dart    # State controller untuk kalkulasi analitik & manipulasi trade
│   ├── screens/
│   │   ├── journal_screen.dart    # Daftar transaksi per bulan, search bar & filter WIN/LOSE
│   │   ├── main_navigation_screen.dart # Navigasi melayang dengan blur effect & Quick FAB
│   │   ├── settings_screen.dart   # Pengaturan 4 kategori (Profil, Tampilan, Simbol, Data)
│   │   ├── summary_screen.dart    # Dashboard statistik, kurva modal & rincian per pair
│   │   └── trade_form_sheet.dart  # Modal bottom sheet input trade dengan live RR calculator
│   ├── services/
│   │   └── csv_service.dart       # Algoritma parser CSV, validasi data & deteksi duplikat
│   ├── utils/
│   │   ├── app_strings.dart       # Kamus lokalisasi dwibahasa (Indonesian & English)
│   │   └── formatters.dart        # Formatting mata uang (USD, IDR), persentase, & waktu
│   ├── widgets/
│   │   ├── equity_sparkline.dart  # CustomPainter rendering kurva modal bergradien halus
│   │   ├── hero_summary_card.dart # Kartu hero saldo total akun & konversi kurs IDR
│   │   ├── image_viewer_dialog.dart # Modal preview screenshot chart interaktif (zoom & pan)
│   │   ├── stat_card.dart         # Komponen metrik ringkasan kartu statistik
│   │   └── trade_card.dart        # Komponen kartu detail histori trade
│   └── main.dart                  # Entry point aplikasi Flutter & MultiProvider initialization
├── test/
│   └── widget_test.dart           # Unit test kalkulasi RR, model settings, CSV & lokalisasi
├── LICENSE                        # Lisensi open-source MIT
└── pubspec.yaml                   # Manifest paket dan aset dependensi Flutter
```

---

## 🚀 Panduan Instalasi & Pengembangan Lokal

### 1. Kebutuhan Sistem (Prerequisites)
Pastikan lingkungan pengembangan Anda telah terpasang:
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (versi 3.24.5 disarankan)
- [Android Studio](https://developer.android.com/studio) dengan Android SDK (API Level 34)
- Java Development Kit (JDK 17)

### 2. Kloning Repositori
```bash
git clone https://github.com/zacxyonly/traderlog.git
cd traderlog
```

### 3. Pasang Dependensi
```bash
flutter pub get
```

### 4. Menjalankan Unit Test
Verifikasi integritas kode dan kalkulasi matematis:
```bash
flutter test
```

### 5. Menjalankan Aplikasi di Emulator / HP
Hubungkan perangkat Android Anda melalui USB Debugging atau aktifkan emulator:
```bash
flutter run
```

### 6. Kompilasi APK Rilis Sendiri
```bash
flutter build apk --release
```
Hasil file APK siap install akan berada di direktori:
`build/app/outputs/flutter-apk/app-release.apk`

---

## ⚙️ Kompilasi Melalui GitHub Actions (Manual CI)

Untuk menghemat kuota build dan menjaga repositori tetap rapi, workflow GitHub Actions dikonfigurasi untuk berjalan **secara manual (On Demand)**:

1. Buka repositori di GitHub: [zacxyonly/traderlog](https://github.com/zacxyonly/traderlog).
2. Klik tab **Actions**.
3. Di panel sebelah kiri, klik **Build Android APK**.
4. Klik tombol dropdown **Run workflow**, pilih branch `main`, lalu klik **Run workflow**.
5. Sistem cloud GitHub akan otomatis mengompilasi APK rilis dan mengunggahnya ke bagian **Artifacts** serta membuat **GitHub Release** ketika ditag versi baru (`v*`).

---

## 📄 Format Ekspor / Impor CSV

Data cadangan trading disimpan dalam format `.csv` standar yang dapat langsung dibuka dan dianalisis di Excel atau Google Sheets:

```csv
No,Date,Symbol,Side,Entry,SL,TP,Lot,RR,Result,PL,Equity,Why,Note
1,2026-10-15T09:30:00.000,XAU/USD,BUY,2650.00,2640.00,2680.00,0.1,1:3.00,WIN,150.00,1150.00,M15 BOS + FVG retest,Eksekusi disiplin
2,2026-10-16T14:15:00.000,EUR/USD,SELL,1.0850,1.0880,1.0790,0.5,1:2.00,LOSE,-60.00,1090.00,Liquidity sweep,Kena stop loss
```

---

## 🛡️ Keamanan & Privasi

- **Zero Telemetry**: Aplikasi tidak mengirimkan analitik, pelacak, atau data apa pun ke server luar.
- **Offline Storage**: Database SQLite tersimpan di sandbox aplikasi lokal pada memori internal perangkat Android Anda.
- **Full Ownership**: Anda memegang kendali 100% atas data jurnal Anda kapan pun melalui fitur ekspor CSV.

---

## 🤝 Kontribusi

Kontribusi, pelaporan bug, dan saran fitur sangat diapresiasi!
1. Lakukan **Fork** pada repositori ini.
2. Buat branch fitur baru (`git checkout -b feature/FiturKeren`).
3. Commit perubahan Anda (`git commit -m "feat: Menambahkan fitur baru"`).
4. Push branch ke repository Anda (`git push origin feature/FiturKeren`).
5. Buat **Pull Request**.

---

## 📜 Lisensi

Proyek ini dilisensikan di bawah lisensi **MIT**. Silakan tinjau berkas [LICENSE](LICENSE) untuk informasi lebih lanjut.

<p align="center">
  Dibuat dengan ❤️ oleh <a href="https://github.com/zacxyonly"><strong>zacxyonly</strong></a>
</p>
