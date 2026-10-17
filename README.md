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
    <img src="https://img.shields.io/badge/📲_Download_Release_APK-v1.4.0-10B981?style=for-the-badge&labelColor=121B2B" alt="Download APK" />
  </a>
  <a href="https://github.com/zacxyonly/traderlog/actions/workflows/build_apk.yml">
    <img src="https://img.shields.io/badge/⚙️_GitHub_Actions-CI_Build-6366F1?style=for-the-badge&labelColor=121B2B&logo=githubactions&logoColor=white" alt="Actions CI" />
  </a>
</p>

---

## 📖 Overview

**TraderLog** adalah aplikasi jurnal trading Android berkecepatan tinggi yang dirancang khusus untuk trader Forex, Komoditas (Gold/XAUUSD), Saham, Indeks, dan Crypto yang mengutamakan disiplin psikologi serta pembuktian statistik atas trading rule mereka.

Dibangun dengan arsitektur modern **Flutter** dan penyimpanan lokal **SQLite (SQFlite)**, TraderLog menjamin kerahasiaan 100% data akun dan transaksi Anda: **tanpa cloud tracking, tanpa registrasi akun, tanpa koneksi internet wajib, dan bebas latency**.

---

## 🌟 Fitur Unggulan (v1.4.0)

### 1. 📊 Analisis & Evaluasi (Tab Ringkasan)
* **📈 Grafik Equity Curve Interaktif**: Visualisasi garis pertumbuhan modal akumulatif yang dinamis dengan baseline modal awal, penanda titik tertinggi (*All-Time Peak*), garis *scrub* sentuh real-time, dan tooltip info PnL per trade.
* **🎯 Metrik Inti Kuantitatif Otomatis**: Perhitungan otomatis presisi untuk:
  - **Win Rate (%)** & Rasio Menang/Kalah/BE
  - **Profit Factor (PF)** (Gross Profit / Gross Loss)
  - **Rata-rata R:R Aktual (Payoff Ratio)** (Rata-rata profit transaksi menang dibanding rata-rata loss transaksi kalah)
  - **Max Drawdown** (Penurunan saldo terdalam dari puncak, ditampilkan dalam % dan nominal mata uang)
* **🗓️ Kalender PnL (Heatmap)**: Tampilan kisi kalender bulanan berwarna hijau (*Green Day / Profit*) dan merah (*Red Day / Loss*) per tanggal untuk memantau konsistensi harian secara visual. Dilengkapi bar ringkasan bulanan dan *bottom sheet* detail transaksi saat tanggal disentuh.

### 2. 📝 Optimalisasi Form Pencatatan (Tab Jurnal)
* **📸 Dua Slot Gambar (Before & After)**: Memisahkan foto analisis sebelum entry (*Setup*) dan sesudah trade selesai (*Outcome / Evaluasi Reaksi Harga*) untuk review trading yang objektif dan mendalam.
* **🏷️ Tag Cepat Setup & Emosi (Chips)**: Tombol pilihan sekali-klik untuk konfirmasi teknikal (*BOS, CHOCH, FVG, Liquidity, Breakout, SnR, Trendline*) serta kondisi psikologi trader (*Disiplin, FOMO, Revenge Trade, Overlot, Early Exit, Overtrading*).
* **🧮 Kalkulator PnL & Nilai Pip Otomatis**: Tombol kalkulator bantu untuk menghitung estimasi pip selisih harga dan profit/loss berdasarkan instrumen (Forex, Gold/XAU, Crypto/Index), posisi (Buy/Sell), lot size, entry, dan exit/TP/SL, lengkap dengan tombol 1-klik untuk memasukkan hasil langsung ke form.

### 3. 🛡️ Portofolio, Akun & Keamanan (Tab Atur)
* **👥 Multi-Akun (Switcher)**: Kemampuan memisahkan catatan transaksi antara akun **Real**, **Demo**, dan **Evaluasi / Prop Firm**, atau membuat akun kustom. Dilengkapi *switcher* 1-tap di kartu saldo utama maupun di pengaturan.
* **🔐 Kunci Biometrik & 4-Digit PIN**: Pengamanan layar pembuka (*SecurityLockScreen*) dengan 4-digit PIN dan sensor sidik jari perangkat via `local_auth` untuk menjaga kerahasiaan riwayat finansial Anda.
* **☁️ Cadangan Cloud Sederhana**: Selain ekspor berkas CSV lokal, sediakan opsi pencadangan instan ke **Google Drive** dengan panduan 3-langkah visual agar riwayat trading aman saat berganti perangkat.
* **💱 Kurs Otomatis & Multi-Currency**: Dukungan mata uang akun (USD, IDR, USDC, USDT, EUR, GBP, JPY, SGD, AUD) serta sinkronisasi kurs live otomatis via open FX market API.
* **🌐 Bilingual Lengkap (ID & EN)**: Beralih instan antara Bahasa Indonesia 🇮🇩 dan English 🇬🇧 di seluruh menu, grafik, kalender, dan pesan dialog.

---

## 📱 Tampilan & Antarmuka Aplikasi

```
┌─────────────────────────────────┐   ┌─────────────────────────────────┐   ┌─────────────────────────────────┐
│           JURNAL TRADE          │   │        RINGKASAN PERFORMA       │   │        PENGATURAN (ATUR)        │
├─────────────────────────────────┤   ├─────────────────────────────────┤   ├─────────────────────────────────┤
│ [ Akun Real Utama ▾ ]           │   │ Periode: [Semua] [30 Hari] [7h] │   │ [Profil] [Akun] [Keamanan] ...  │
│ [ Total Akun ]     $1,450.00    │   │                                 │   │                                 │
│ by Zacxy       Rp 26.097.100    │   │  Win Rate: 68%   PF: 2.14       │   │ Multi-Akun Portofolio:          │
│                                 │   │  R:R Aktual: 1:2.40  DD: -4.8%  │   │  [•] Akun Real Utama (Active)   │
│ 🔍 Cari symbol, setup, emosi... │   │                                 │   │  [ ] Akun Latihan Demo          │
│ [Semua] [WIN] [LOSE] [BE]       │   │ ── Grafik Equity Curve (Scrub) ─│   │  [ ] Evaluasi Prop Firm         │
│                                 │   │  Modal: $1,000 | Puncak: $1,620 │   │                                 │
│ ▾ Oktober 2026      +$320.00    │   │                                 │   │ Keamanan & Privasi:             │
│  • XAU/USD BUY       +$150.00   │   │ ── Kalender PnL Konsistensi ─── │   │  [x] Kunci Aplikasi dengan PIN  │
│    Entry: 2650 | Lot: 0.10      │   │   S  M  T  W  T  F  S           │   │  [x] Buka dengan Sidik Jari     │
│    Tags: [BOS] [FVG] [Disiplin] │   │  [+][+][-][+][+][-][+]          │   │                                 │
│    [📷 Setup]  [📷 Outcome]     │   │  Win Days: 14 | Lose Days: 5    │   │ Cadangan Google Drive & CSV:    │
│                                 │   │  Net PnL Bulan Ini: +$420.00    │   │  [ ☁️ Simpan ke Google Drive ]   │
└─────────────────────────────────┘   └─────────────────────────────────┘   └─────────────────────────────────┘
```

---

## 🛠️ Arsitektur & Teknologi

TraderLog dibangun menggunakan teknologi dan pustaka terbaik dalam ekosistem Flutter:

- **Framework**: [Flutter](https://flutter.dev) (v3.24.5 - Channel Stable)
- **Programming Language**: [Dart](https://dart.dev) (v3.5.4)
- **Local Database**: [sqflite](https://pub.dev/packages/sqflite) dengan engine SQLite native & automated migration schema
- **Biometric Security**: [local_auth](https://pub.dev/packages/local_auth) (Fingerprint & Face biometric prompt)
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
├── android/                       # Konfigurasi native Android, Manifest, FragmentActivity & Icon
│   └── app/src/main/res/
│       ├── icon_512.png           # Master artwork ikon resolusi tinggi
│       └── mipmap-*/              # Adaptive icon terkompilasi untuk seluruh DPI perangkat
├── lib/
│   ├── constants/
│   │   └── app_colors.dart        # Palet warna primer (Emerald, Navy, Wine Red, Amber)
│   ├── database/
│   │   └── db_helper.dart         # Skema SQLite v2, migrasi kolom multi-akun & foto after
│   ├── models/
│   │   ├── app_settings.dart      # Model konfigurasi akun, PIN, biometrik, kurs, & tema
│   │   ├── trade.dart             # Model data transaksi, foto before/after, & rasio RR
│   │   └── trading_account.dart   # Model multi-akun (Real, Demo, Prop Firm)
│   ├── providers/
│   │   └── trade_provider.dart    # Controller analitik, kurva equity, kalender PnL, & PIN lock
│   ├── screens/
│   │   ├── journal_screen.dart    # Jurnal transaksi bulanan, filter emosi, setup & pencarian
│   │   ├── main_navigation_screen.dart # Navigasi melayang dengan blur effect & Quick FAB
│   │   ├── security_lock_screen.dart # Layar pembuka PIN 4-digit & autentikasi sidik jari
│   │   ├── settings_screen.dart   # Pengaturan 6 kategori (Profil, Akun, Keamanan, Tampilan, Simbol, Data)
│   │   ├── summary_screen.dart    # Dashboard ringkasan: Equity Curve, Heatmap Kalender & Metrik
│   │   └── trade_form_sheet.dart  # Form input trade: Slot Before/After, Chip emosi, & Kalkulator PnL
│   ├── services/
│   │   ├── csv_service.dart       # Algoritma parser CSV, validasi data & deteksi duplikat
│   │   └── currency_service.dart  # Integrasi kurs live otomatis multi-currency
│   ├── utils/
│   │   ├── app_strings.dart       # Kamus lokalisasi dwibahasa (Indonesian & English)
│   │   └── formatters.dart        # Formatting mata uang (USD, IDR), persentase, & tanggal
│   ├── widgets/
│   │   ├── account_switcher_sheet.dart # Modal switcher akun real, demo, dan prop firm
│   │   ├── hero_summary_card.dart # Kartu hero saldo total akun & badge active account
│   │   ├── image_viewer_dialog.dart # Modal preview screenshot chart interaktif (zoom & pan)
│   │   ├── interactive_equity_curve.dart # Grafik equity interaktif dengan scrub & peak marker
│   │   ├── pnl_calculator_sheet.dart # Lembar kalkulator bantu PnL & nilai pip otomatis
│   │   ├── pnl_calendar_heatmap.dart # Kalender visual PnL bulanan (Green/Red days)
│   │   ├── stat_card.dart         # Komponen metrik ringkasan kartu statistik
│   │   └── trade_card.dart        # Komponen kartu detail histori trade & Before/After chips
│   └── main.dart                  # Entry point aplikasi Flutter, Lock check & MultiProvider
├── test/
│   └── widget_test.dart           # Unit test kalkulasi RR, multi-akun, CSV, PIN & lokalisasi
├── LICENSE                        # Lisensi open-source MIT
└── pubspec.yaml                   # Manifest paket dan dependensi Flutter v1.4.0+5
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

### 4. Menjalankan Unit Test & Analisis Kode
Verifikasi integritas kode, kalkulasi metrik kuantitatif, dan fungsi keamanan:
```bash
flutter test
flutter analyze
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
- **Biometric & PIN Lock**: Akses jurnal diamankan dengan 4-digit PIN dan sensor sidik jari lokal melalui Android BiometricPrompt API.
- **Full Ownership**: Anda memegang kendali 100% atas data jurnal Anda kapan pun melalui fitur ekspor CSV dan pencadangan Google Drive pribadi Anda.

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
