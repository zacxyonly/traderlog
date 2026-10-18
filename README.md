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
  <a href="https://github.com/zacxyonly/traderlog/releases/latest">
    <img src="https://img.shields.io/badge/📲_Download_Release_APK-v1.0.0-10B981?style=for-the-badge&labelColor=121B2B" alt="Download APK" />
  </a>
  <a href="https://github.com/zacxyonly/traderlog/actions/workflows/build_apk.yml">
    <img src="https://img.shields.io/badge/⚙️_GitHub_Actions-CI_Build-6366F1?style=for-the-badge&labelColor=121B2B&logo=githubactions&logoColor=white" alt="Actions CI" />
  </a>
</p>

<p align="center">
  🌐 <strong>Language / Bahasa:</strong>
  <a href="#-english">English</a> | <a href="#-bahasa-indonesia">Bahasa Indonesia</a>
</p>

---

# 🇬🇧 English

## 📖 Overview

**TraderLog** is a high-performance Android trading journal built for traders across Forex, Commodities (Gold/XAUUSD), Crypto, Stocks, and Indices who prioritize psychological discipline and statistical validation of their trading edge.

Engineered with **Flutter** and local **SQLite (SQFlite)**, TraderLog guarantees 100% data privacy and zero latency: **no cloud tracking, no mandatory sign-ups, offline-first architecture, and complete data ownership**.

---

## 🌟 Core Features (v1.0.0)

### 1. 📊 Analytics & Performance Evaluation (Summary Tab)
* **📈 Interactive Equity Curve**: Dynamic capital growth visualization featuring baseline initial capital, all-time peak marker, real-time touch-scrub cursor, and per-trade PnL tooltips.
* **🎯 Automated Quantitative Core Metrics**:
  - **Win Rate (%)** & Win/Loss/BE trade counts.
  - **Profit Factor (PF)** (Gross Profit / Gross Loss).
  - **Average Realized R:R (Payoff Ratio)** (Average win size vs average loss size).
  - **Max Drawdown** (Deepest capital drop from peak, formatted in percentage and currency).
* **🗓️ Monthly PnL Calendar Heatmap**: Visual grid highlighting Green Days (Profit) and Red Days (Loss) per date for effortless consistency tracking. Includes monthly summary metrics and trade detail bottom sheets on date tap.

### 2. 📝 Journaling & Trade Logging (Journal Tab)
* **📸 Dual Screenshot Slots (Before & After)**: Dedicated slots for pre-entry chart analysis (*Setup*) and post-exit review (*Outcome / Price Reaction*) for thorough post-trade reviews.
* **🏷️ Fast Setup & Emotion Chips**: Single-tap chips for technical confirmation (*BOS, CHOCH, FVG, Liquidity, Breakout, SnR, Trendline*) and emotional discipline tracking (*Discipline, FOMO, Revenge Trade, Overlot, Early Exit, Overtrading*).
* **🧮 Built-in Automated PnL Calculator**: Instant pip/points calculation and profit/loss estimates based on asset class (Forex USD-quote, Gold/XAU, Indices, Crypto), position side (Buy/Sell), lot size, entry, and exit. One-tap button populates calculated PnL directly into the trade form.

### 3. 🛡️ Portfolio, Multi-Account & Security (Settings Tab)
* **👥 Multi-Account Portfolio Switcher**: Separate records seamlessly between **Real**, **Demo**, and **Prop Firm / Evaluation** accounts, or create custom accounts with independent starting capital.
* **🔐 Salted HMAC-SHA256 PIN & Biometrics**: Screen lock powered by a 4-digit PIN stored as a salted, iterated HMAC-SHA256 hash, alongside native Android biometric authentication (`local_auth`).
* **📦 Full ZIP Backup & Restore**: Export an entire ZIP archive containing your SQLite database (`traderlog.db`), all trade chart screenshots, and manifest metadata. Restore effortlessly across devices or back up to Google Drive.
* **💱 Multi-Currency & Live Exchange Rates**: Support for account currencies (USD, IDR, USDC, USDT, EUR, GBP, JPY, SGD, AUD) with real-time exchange rate sync via Open FX Market API.
* **🌐 Complete Bilingual Support (EN & ID)**: Instant toggle between English 🇬🇧 and Bahasa Indonesia 🇮🇩 across all dialogs, analytics, and navigation.

---

## 📱 Application Interface Mockup

```
┌─────────────────────────────────┐   ┌─────────────────────────────────┐   ┌─────────────────────────────────┐
│           TRADE JOURNAL         │   │       PERFORMANCE SUMMARY       │   │        SETTINGS & PRIVACY       │
├─────────────────────────────────┤   ├─────────────────────────────────┤   ├─────────────────────────────────┤
│ [ Primary Real Account ▾ ]      │   │ Range: [All] [30 Days] [7 Days] │   │ [Capital & FX] [Accounts] [Lock]│
│ [ Account Balance ]   $1,450.00 │   │                                 │   │                                 │
│ TraderLog         Rp 26.097.100 │   │  Win Rate: 68%   PF: 2.14       │   │ Multi-Account Portfolio:        │
│                                 │   │  Realized RR: 1:2.40  DD: -4.8% │   │  [•] Primary Real (Active)      │
│ 🔍 Search symbol, tag, note...  │   │                                 │   │  [ ] Demo Practice Account      │
│ [All] [WIN] [LOSE] [BE]         │   │ ── Interactive Equity Curve ────│   │  [ ] Prop Firm Evaluation       │
│                                 │   │  Capital: $1,000 | Peak: $1,620 │   │                                 │
│ ▾ October 2026        +$320.00  │   │                                 │   │ Security & Privacy:             │
│  • XAU/USD BUY         +$150.00 │   │ ── Consistency PnL Heatmap ──── │   │  [x] App Lock with PIN          │
│    Entry: 2650 | Lot: 0.10      │   │   S  M  T  W  T  F  S           │   │  [x] Fingerprint Biometrics     │
│    Tags: [BOS] [FVG] [Discipline│   │  [+][+][-][+][+][-][+]          │   │                                 │
│    [📷 Setup]  [📷 Outcome]     │   │  Win Days: 14 | Lose Days: 5    │   │ Backup & CSV Export:            │
│                                 │   │  Month Net PnL: +$420.00        │   │  [ ☁️ Full ZIP Backup ]         │
└─────────────────────────────────┘   └─────────────────────────────────┘   └─────────────────────────────────┘
```

---

## 🛠️ Tech Stack & Dependencies

* **Framework**: [Flutter](https://flutter.dev) (v3.24.5 - Stable Channel)
* **Language**: [Dart](https://dart.dev) (v3.5.4)
* **Local Database**: [sqflite](https://pub.dev/packages/sqflite) (SQLite native engine with schema migrations)
* **Security & Cryptography**: [crypto](https://pub.dev/packages/crypto) (HMAC-SHA256 PIN hashing) & [local_auth](https://pub.dev/packages/local_auth) (Biometric Fingerprint / Face prompt)
* **State Management**: [provider](https://pub.dev/packages/provider) (Reactive MVVM architecture)
* **Full Backup Archive**: [archive](https://pub.dev/packages/archive) (ZIP package generation & extraction)
* **Media & File Picker**: [image_picker](https://pub.dev/packages/image_picker) & [file_picker](https://pub.dev/packages/file_picker)
* **Export & Sharing**: [csv](https://pub.dev/packages/csv) & [share_plus](https://pub.dev/packages/share_plus)
* **CI/CD**: GitHub Actions (`workflow_dispatch` with release keystore validation)

---

## 📂 Project Directory Structure

```plaintext
traderlog/
├── .github/
│   └── workflows/
│       └── build_apk.yml          # GitHub Actions automated release APK build
├── android/                       # Native Android configuration, Manifest, & Icons
│   └── app/src/main/res/
│       ├── icon_512.png           # Master high-resolution app icon
│       └── mipmap-*/              # Adaptive compiled launcher icons
├── assets/
│   └── icon/                      # Adaptive launcher icon assets
├── lib/
│   ├── constants/
│   │   └── app_colors.dart        # Unified theme palette (Emerald, Navy, Wine Red, Amber)
│   ├── database/
│   │   └── db_helper.dart         # SQLite database helper & schema transactions
│   ├── models/
│   │   ├── app_settings.dart      # App settings, theme, PIN hash, and exchange rate model
│   │   ├── trade.dart             # Trade entity model, Before/After image paths & R:R calculations
│   │   └── trading_account.dart   # Portfolio multi-account model (Real, Demo, Prop Firm)
│   ├── providers/
│   │   └── trade_provider.dart    # Business logic controller for trades, stats, and auth lock
│   ├── screens/
│   │   ├── journal_screen.dart    # Monthly trade list, search, and emotion/setup filters
│   │   ├── main_navigation_screen.dart # Floating blur bottom navigation bar with quick FAB
│   │   ├── security_lock_screen.dart # Salted PIN entry and biometric verification
│   │   ├── settings_screen.dart   # Settings categories (Capital, Accounts, Security, Data, Theme)
│   │   ├── summary_screen.dart    # Performance dashboard: Equity curve, metrics & calendar
│   │   └── trade_form_sheet.dart  # Trade editor modal with PnL calculator & image slots
│   ├── services/
│   │   ├── backup_service.dart    # Full ZIP archive backup & restore service
│   │   ├── csv_service.dart       # CSV parsing, export, import, and duplicate validation
│   │   └── currency_service.dart  # Multi-currency live exchange rate synchronization
│   ├── utils/
│   │   ├── app_strings.dart       # Bilingual localization strings (English & Indonesian)
│   │   ├── formatters.dart        # Number, currency, percentage, and date formatters
│   │   ├── pin_hasher.dart        # Salted iterated HMAC-SHA256 PIN hasher & verifier
│   │   └── pnl_calculator.dart    # Precision PnL and pip calculation engine
│   ├── widgets/
│   │   ├── account_switcher_sheet.dart # Modal sheet to switch active trading account
│   │   ├── equity_sparkline.dart  # Lightweight sparkline graph
│   │   ├── hero_summary_card.dart # Capital balance hero card with quick account switcher
│   │   ├── image_viewer_dialog.dart # Interactive zoom and pan chart screenshot viewer
│   │   ├── interactive_equity_curve.dart # Interactive equity curve with scrub cursor
│   │   ├── pnl_calendar_heatmap.dart # Monthly visual calendar heatmap of trading days
│   │   ├── stat_card.dart         # Statistical metric cards
│   │   ├── trade_card.dart        # Trade list item card with Before/After indicators
│   │   └── trade_detail_sheet.dart # In-depth trade inspection modal
│   └── main.dart                  # Flutter entry point, auth gate, and provider registration
├── test/
│   ├── backup_service_test.dart   # Unit tests for ZIP backup generation, verification & restore
│   ├── pin_hasher_test.dart       # Unit tests for salted HMAC-SHA256 hashing and legacy migration
│   └── widget_test.dart           # Integration and unit tests for models, math & CSV
├── tools/
│   └── generate_keystore.sh       # Release keystore generation script for local & CI signing
├── pubspec.yaml                   # Flutter package manifest (v1.0.0+1)
├── LICENSE                        # MIT Open Source License
└── README.md                      # Project documentation
```

---

## 🚀 Installation & Local Development

### 1. Prerequisites
Ensure you have installed:
* [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.24.5 recommended)
* [Android Studio](https://developer.android.com/studio) with Android SDK (API Level 34)
* Java Development Kit (JDK 17)

### 2. Clone the Repository
```bash
git clone https://github.com/zacxyonly/traderlog.git
cd traderlog
```

### 3. Install Dependencies
```bash
flutter pub get
```

### 4. Run Unit Tests & Linter
```bash
flutter test
flutter analyze
```

### 5. Run on Device / Emulator
```bash
flutter run
```

### 6. Build Release APK Locally
```bash
flutter build apk --release
```
The compiled APK will be located at:
`build/app/outputs/flutter-apk/app-release.apk`

---

## 🔑 APK Release Signing

Release keystores are **never stored in the repository**. Generate a private keystore on your local machine:

```bash
bash tools/generate_keystore.sh          # Outputs to: ~/traderlog-signing/
```

The script outputs `traderlog-release.jks` and prints values for **GitHub → Settings → Secrets and variables → Actions**:

| Secret Name | Value |
|---|---|
| `TRADERLOG_KEYSTORE_BASE64` | Base64-encoded string of `.jks` file |
| `TRADERLOG_KEYSTORE_PASSWORD` | Keystore password |
| `TRADERLOG_KEY_ALIAS` | `traderlog` |
| `TRADERLOG_KEY_PASSWORD` | Key alias password |

For local release signing, copy the generated `key.properties` to `android/key.properties` (git-ignored).

---

## 🗜️ ZIP Backup Archive Format

```
TraderLog_Backup_yyyyMMdd_HHmm.zip
├── manifest.json     # App identifier, format version, and creation timestamp
├── data.json         # Encoded trades, accounts, and settings
└── images/           # All attached chart screenshots
```

*Note: Security PIN, biometric status, and device-specific flags are intentionally omitted from backup archives to protect sensitive authentication data when stored in cloud providers.*

---

## 📄 CSV Export & Import Format

Standard CSV files (trades only) can be imported or exported for external spreadsheet analysis:

```csv
No,Date,Symbol,Side,Entry,SL,TP,Lot,RR,Result,PL,Equity,Why,Note
1,2026-10-15T09:30:00.000,XAU/USD,BUY,2650.00,2640.00,2680.00,0.1,1:3.00,WIN,150.00,1150.00,M15 BOS + FVG retest,Disciplined execution
2,2026-10-16T14:15:00.000,EUR/USD,SELL,1.0850,1.0880,1.0790,0.5,1:2.00,LOSE,-60.00,1090.00,Liquidity sweep,Hit stop loss
```

---

<br />

# 🇮🇩 Bahasa Indonesia

## 📖 Ringkasan

**TraderLog** adalah aplikasi jurnal trading Android berkecepatan tinggi yang dirancang khusus untuk trader Forex, Komoditas (Gold/XAUUSD), Saham, Indeks, dan Crypto yang mengutamakan disiplin psikologi serta pembuktian statistik atas trading rule mereka.

Dibangun dengan arsitektur modern **Flutter** dan penyimpanan lokal **SQLite (SQFlite)**, TraderLog menjamin kerahasiaan 100% data akun dan transaksi Anda: **tanpa cloud tracking pihak ketiga, tanpa registrasi akun, arsitektur offline-first, dan kendali data penuh di tangan Anda**.

---

## 🌟 Fitur Unggulan (v1.0.0)

### 1. 📊 Analisis & Evaluasi (Tab Ringkasan)
* **📈 Grafik Equity Curve Interaktif**: Visualisasi garis pertumbuhan modal akumulatif yang dinamis dengan baseline modal awal, penanda titik tertinggi (*All-Time Peak*), garis *scrub* sentuh real-time, dan tooltip info PnL per trade.
* **🎯 Metrik Inti Kuantitatif Otomatis**:
  - **Win Rate (%)** & Rasio Menang/Kalah/BE.
  - **Profit Factor (PF)** (Gross Profit / Gross Loss).
  - **Rata-rata R:R Aktual (Payoff Ratio)** (Rata-rata profit transaksi menang dibanding rata-rata loss transaksi kalah).
  - **Max Drawdown** (Penurunan saldo terdalam dari puncak, ditampilkan dalam % dan nominal mata uang).
* **🗓️ Kalender PnL (Heatmap)**: Tampilan kisi kalender bulanan berwarna hijau (*Green Day / Profit*) dan merah (*Red Day / Loss*) per tanggal untuk memantau konsistensi harian secara visual. Dilengkapi bar ringkasan bulanan dan *bottom sheet* detail transaksi saat tanggal disentuh.

### 2. 📝 Optimalisasi Form Pencatatan (Tab Jurnal)
* **📸 Dua Slot Gambar (Before & After)**: Memisahkan foto analisis sebelum entry (*Setup*) dan sesudah trade selesai (*Outcome / Evaluasi Reaksi Harga*) untuk review trading yang objektif dan mendalam.
* **🏷️ Tag Cepat Setup & Emosi (Chips)**: Tombol pilihan sekali-klik untuk konfirmasi teknikal (*BOS, CHOCH, FVG, Liquidity, Breakout, SnR, Trendline*) serta kondisi psikologi trader (*Disiplin, FOMO, Revenge Trade, Overlot, Early Exit, Overtrading*).
* **🧮 Kalkulator PnL & Nilai Pip Otomatis**: Tombol kalkulator bantu untuk menghitung estimasi pip selisih harga dan profit/loss berdasarkan instrumen (Forex USD-quote, Gold/XAU, Crypto/Index), posisi (Buy/Sell), lot size, entry, dan exit/TP/SL, lengkap dengan tombol 1-klik untuk memasukkan hasil langsung ke form.

### 3. 🛡️ Portofolio, Multi-Akun & Keamanan (Tab Atur)
* **👥 Multi-Akun (Switcher)**: Kemampuan memisahkan catatan transaksi antara akun **Real**, **Demo**, dan **Evaluasi / Prop Firm**, atau membuat akun kustom. Dilengkapi *switcher* 1-tap di kartu saldo utama maupun di pengaturan.
* **🔐 Kunci Biometrik & PIN 4-Digit Salted SHA-256**: Pengamanan layar pembuka (*SecurityLockScreen*) dengan 4-digit PIN yang disimpan menggunakan algoritma hash *iterated salted* HMAC-SHA256 (melalui `PinHasher`) serta sensor sidik jari perangkat via `local_auth`.
* **📦 Cadangan & Pemulihan Lengkap (ZIP)**: Satu file ZIP utuh berisi semua transaksi, screenshot chart analisis, data akun, dan preferensi pengaturan. Simpan langsung ke penyimpanan internal atau unggah ke **Google Drive**.
* **💱 Kurs Otomatis & Multi-Currency**: Dukungan mata uang akun (USD, IDR, USDC, USDT, EUR, GBP, JPY, SGD, AUD) serta sinkronisasi kurs live otomatis via open FX market API.
* **🌐 Bilingual Lengkap (ID & EN)**: Beralih instan antara Bahasa Indonesia 🇮🇩 dan English 🇬🇧 di seluruh menu, grafik, kalender, dan pesan dialog.

---

## 🛠️ Arsitektur & Teknologi

* **Framework**: [Flutter](https://flutter.dev) (v3.24.5 - Channel Stable)
* **Programming Language**: [Dart](https://dart.dev) (v3.5.4)
* **Local Database**: [sqflite](https://pub.dev/packages/sqflite) dengan engine SQLite native & sistem migrasi tabel
* **Keamanan & Kriptografi**: [crypto](https://pub.dev/packages/crypto) (Salted HMAC-SHA256 hashing) & [local_auth](https://pub.dev/packages/local_auth) (Sidik Jari / Biometrik Android)
* **State Management**: [provider](https://pub.dev/packages/provider) (Arsitektur reaktif)
* **Manajemen Arsip ZIP**: [archive](https://pub.dev/packages/archive) (Kompresi & ekstraksi cadangan utuh)
* **File System & Sharing**: [share_plus](https://pub.dev/packages/share_plus) & [file_picker](https://pub.dev/packages/file_picker)
* **Media Capture**: [image_picker](https://pub.dev/packages/image_picker)
* **CI / CD Pipeline**: GitHub Actions (`workflow_dispatch` dengan verifikasi keystore rilis otomatis)

---

## 🚀 Panduan Instalasi & Pengembangan Lokal

### 1. Kebutuhan Sistem
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

### 4. Menjalankan Unit Test & Analisis Kode
Verifikasi integritas logika kalkulasi, enkripsi PIN, dan cadangan data:
```bash
flutter test
flutter analyze
```

### 5. Menjalankan Aplikasi di HP / Emulator
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

## 🔑 Penandatanganan APK Rilis (Signing)

Keystore rilis **tidak pernah disimpan di repositori**. Buat sekali di komputer Anda dengan skrip otomatis:

```bash
bash tools/generate_keystore.sh          # Hasil direktori: ~/traderlog-signing/
```

Skrip tersebut menghasilkan file `traderlog-release.jks` (RSA 4096, password acak kuat) dan mencetak 4 konfigurasi untuk dimasukkan ke **GitHub → Settings → Secrets and variables → Actions**:

| Secret | Keterangan |
|---|---|
| `TRADERLOG_KEYSTORE_BASE64` | String isi berkas `.jks` dalam format base64 |
| `TRADERLOG_KEYSTORE_PASSWORD` | Password keystore |
| `TRADERLOG_KEY_ALIAS` | `traderlog` |
| `TRADERLOG_KEY_PASSWORD` | Password alias kunci |

Untuk build rilis di lokal komputer Anda, salin `key.properties` hasil skrip ke dalam `android/key.properties` (sudah dilindungi *.gitignore*).

---

## 🗜️ Format Cadangan ZIP

```
TraderLog_Backup_yyyyMMdd_HHmm.zip
├── manifest.json     # Penanda identitas aplikasi, versi format, dan tanggal pembuatan
├── data.json         # Transaksi trade, daftar akun portofolio, dan preferensi pengaturan
└── images/           # Seluruh foto screenshot chart analisis (Before & After)
```

*Catatan: PIN keamanan dan status biometrik sengaja tidak disertakan dalam arsip cadangan untuk mencegah kebocoran otentikasi saat berkas cadangan disimpan di cloud publik.*

---

## 🛡️ Jaminan Privasi & Keamanan

- **Zero Telemetry**: Aplikasi tidak mengirimkan analitik, pelacak, atau data apa pun ke server luar.
- **Offline Storage**: Database SQLite tersimpan di sandbox aplikasi lokal pada memori internal perangkat Android Anda.
- **Biometric & PIN Lock**: Akses jurnal diamankan dengan 4-digit PIN dan sensor sidik jari lokal melalui Android BiometricPrompt API. PIN disimpan sebagai hash ber-salt HMAC-SHA256 (bukan teks asli).
- **Tanpa Auto-Backup Google**: `android:allowBackup="false"`, sehingga database dan hash PIN tidak ikut ke cadangan otomatis Android/Google yang tidak terenkripsi.
- **Full Ownership**: Anda memegang kendali 100% atas data jurnal Anda kapan pun melalui fitur ekspor CSV dan pencadangan ZIP mandiri.

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
