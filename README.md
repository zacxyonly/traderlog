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

---

## 📖 Overview

**TraderLog** adalah aplikasi jurnal trading Android berkecepatan tinggi yang dirancang khusus untuk trader Forex, Komoditas (Gold/XAUUSD), Saham, Indeks, dan Crypto yang mengutamakan disiplin psikologi serta pembuktian statistik atas trading rule mereka.

Dibangun dengan arsitektur modern **Flutter** dan penyimpanan lokal **SQLite (SQFlite)**, TraderLog menjamin kerahasiaan 100% data akun dan transaksi Anda: **100% offline tanpa izin INTERNET, tanpa cloud tracking pihak ketiga, tanpa registrasi akun, dan bebas latency**.

---

## 🌟 Fitur Unggulan (v1.0.0)

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
* **🏷️ Kolom Tag Khusus Setup & Emosi (Chips)**: Tombol pilihan terisolasi untuk konfirmasi teknikal (*BOS, CHOCH, FVG, Liquidity, Breakout, SnR, Trendline*) serta psikologi (*Disiplin, FOMO, Revenge Trade, Overlot, Early Exit, Overtrading*). Catatan bebas (`why`/`note`) tetap bersih dan tidak tercampur dengan tag analitik.
* **🧮 Kalkulator PnL & Nilai Pip Akurat**: Menghitung estimasi pip/points selisih harga dan profit/loss berdasarkan instrumen (Forex USD-quote, Gold/XAU, Index pts, Crypto pts). Hasil diberi label estimasi jelas dan tidak menimpa angka PL riil yang dimasukkan manual oleh trader.

### 3. 🛡️ Portofolio, Akun & Keamanan (Tab Atur)
* **👥 Multi-Akun Bersih**: Manajemen portofolio independen dengan alur onboarding akun utama (*Primary Account*), isolasi modal, saldo, dan kalkulasi equity per akun.
* **🔐 Keamanan Berlapis (Salted SHA-256 & Lockout)**: Akses jurnal diamankan dengan PIN 4-digit yang di-hash menggunakan salt SHA-256, sensor sidik jari lokal via `local_auth`, penonaktifan auto-backup Google (`allowBackup="false"`), serta proteksi lockout otomatis 30 detik setelah 5 kali salah input.
* **📦 Cadangan & Pemulihan Lengkap (Full Backup & Restore .ZIP)**: Pencadangan satu berkas arsip ZIP utuh yang mencakup database SQLite (`traderlog.db`), seluruh screenshot chart analisis, dan metadata manifest akun. Mendukung juga ekspor/impor tabel CSV per akun.
* **💱 100% Offline Multi-Currency**: Kurs konversi manual langsung di pengaturan tanpa memerlukan akses jaringan internet.
* **🌐 Bilingual Lengkap (ID & EN)**: Beralih instan antara Bahasa Indonesia 🇮🇩 dan English 🇬🇧 di seluruh menu, grafik, kalender, dan pesan dialog.

---

## 📱 Tampilan & Antarmuka Aplikasi

```
┌─────────────────────────────────┐   ┌─────────────────────────────────┐   ┌─────────────────────────────────┐
│           JURNAL TRADE          │   │        RINGKASAN PERFORMA       │   │        PENGATURAN (ATUR)        │
├─────────────────────────────────┤   ├─────────────────────────────────┤   ├─────────────────────────────────┤
│ [ Akun Utama ▾ ]                │   │ Periode: [Semua] [30 Hari] [7h] │   │ [Modal & Kurs] [Akun] [Keamanan]│
│ [ Total Akun ]     $1,450.00    │   │                                 │   │                                 │
│ TraderLog      Rp 23.200.000    │   │  Win Rate: 68%   PF: 2.14       │   │ Multi-Akun Portofolio:          │
│                                 │   │  R:R Aktual: 1:2.40  DD: -4.8%  │   │  [•] Akun Utama (Active)        │
│ 🔍 Cari symbol, setup, emosi... │   │                                 │   │  [+] Tambah Akun Baru           │
│ [Semua] [WIN] [LOSE] [BE]       │   │ ── Grafik Equity Curve (Scrub) ─│   │                                 │
│                                 │   │  Modal: $1,000 | Puncak: $1,620 │   │ Keamanan & Privasi:             │
│ ▾ Oktober 2026      +$320.00    │   │                                 │   │  [x] Kunci Aplikasi dengan PIN  │
│  • XAU/USD BUY       +$150.00   │   │ ── Kalender PnL Konsistensi ─── │   │  [x] Buka dengan Sidik Jari     │
│    Entry: 2650 | Lot: 0.10      │   │   S  M  T  W  T  F  S           │   │                                 │
│    Tags: [BOS] [FVG] [Disiplin] │   │  [+][+][-][+][+][-][+]          │   │ Cadangan & Pemulihan:           │
│    [📷 Setup]  [📷 Outcome]     │   │  Win Days: 14 | Lose Days: 5    │   │  [ 📦 Ekspor Cadangan Lengkap ] │
│                                 │   │  Net PnL Bulan Ini: +$420.00    │   │  [ 📥 Pulihkan Cadangan ]       │
└─────────────────────────────────┘   └─────────────────────────────────┘   └─────────────────────────────────┘
```

---

## 🛠️ Arsitektur & Teknologi

TraderLog dibangun menggunakan teknologi dan pustaka terbaik dalam ekosistem Flutter:

- **Framework**: [Flutter](https://flutter.dev) (v3.24.5 - Channel Stable)
- **Programming Language**: [Dart](https://dart.dev) (v3.5.4)
- **Local Database**: [sqflite](https://pub.dev/packages/sqflite) dengan engine SQLite native & automated migration schema (v4)
- **Biometric Security**: [local_auth](https://pub.dev/packages/local_auth) (Fingerprint & Face biometric prompt)
- **Archive & Backup**: [archive](https://pub.dev/packages/archive) (Arsip ZIP mandiri untuk database + screenshot)
- **State Management**: [provider](https://pub.dev/packages/provider) (arsitektur reaktif)
- **Path Resolution**: [path_provider](https://pub.dev/packages/path_provider) & [path](https://pub.dev/packages/path)
- **File System & Sharing**: [share_plus](https://pub.dev/packages/share_plus) & [file_picker](https://pub.dev/packages/file_picker)
- **Media Capture**: [image_picker](https://pub.dev/packages/image_picker)
- **Build Optimization**: R8 / ProGuard `minifyEnabled true` dengan ABI split (arm64-v8a, armeabi-v7a, x86_64, universal)
- **CI / CD Pipeline**: GitHub Actions (`ubuntu-latest`, Temurin JDK 17, `workflow_dispatch` & Tag Release)

---

## 📂 Struktur Direktori Proyek

```plaintext
traderlog/
├── .github/
│   └── workflows/
│       └── build_apk.yml          # Otomasi kompilasi APK rilis & universal via GitHub Actions
├── android/                       # Konfigurasi native Android, Manifest, ProGuard & Keystore Secrets
│   ├── app/
│   │   ├── proguard-rules.pro     # Aturan obfuscation & shrinking R8/ProGuard
│   │   └── src/main/res/
│   │       ├── icon_512.png       # Master artwork ikon resolusi tinggi
│   │       └── mipmap-*/          # Adaptive icon terkompilasi untuk seluruh DPI perangkat
├── lib/
│   ├── constants/
│   │   └── app_colors.dart        # Palet warna primer (Emerald, Navy, Wine Red, Amber)
│   ├── database/
│   │   └── db_helper.dart         # Skema SQLite v4, transaksi atomik, migrasi tabel & kolom tags
│   ├── models/
│   │   ├── app_settings.dart      # Model konfigurasi akun, PIN hash tersalt, biometrik, kurs, & tema
│   │   ├── trade.dart             # Model data transaksi, foto before/after, tags & sentinel copyWith
│   │   └── trading_account.dart   # Model multi-akun (Primary Account onboarding)
│   ├── providers/
│   │   └── trade_provider.dart    # Controller analitik, cache active trades, kalkulasi PF/DD, & PIN lock
│   ├── screens/
│   │   ├── journal_screen.dart    # Jurnal transaksi bulanan, filter emosi, setup & pencarian
│   │   ├── main_navigation_screen.dart # Navigasi melayang dengan blur effect & Quick FAB
│   │   ├── security_lock_screen.dart # Layar pembuka PIN 4-digit, lockout 30 detik & sidik jari
│   │   ├── settings_screen.dart   # Pengaturan: Modal, Akun, Keamanan, Cadangan ZIP/CSV, Tampilan
│   │   ├── summary_screen.dart    # Dashboard ringkasan: Equity Curve, Heatmap Kalender & Metrik
│   │   └── trade_form_sheet.dart  # Form input trade: Slot Before/After terpisah & Tag Selector
│   ├── services/
│   │   ├── backup_service.dart    # Pencadangan & pemulihan arsip ZIP (database SQLite + screenshot)
│   │   └── csv_service.dart       # Algoritma parser CSV, validasi data & deteksi duplikat per akun
│   ├── utils/
│   │   ├── app_strings.dart       # Kamus lokalisasi dwibahasa (Indonesian & English)
│   │   ├── formatters.dart        # Formatting mata uang (USD, IDR), persentase, & tanggal
│   │   └── pnl_calculator.dart    # Kalkulasi pips/points & PnL instrumen terstandardisasi
│   ├── widgets/
│   │   ├── account_switcher_sheet.dart # Modal switcher akun portofolio
│   │   ├── hero_summary_card.dart # Kartu hero saldo total akun & badge active account
│   │   ├── image_viewer_dialog.dart # Modal preview screenshot chart interaktif (zoom & pan)
│   │   ├── interactive_equity_curve.dart # Grafik equity interaktif dengan scrub & peak marker
│   │   ├── pnl_calendar_heatmap.dart # Kalender visual PnL bulanan (Green/Red days)
│   │   ├── stat_card.dart         # Komponen metrik ringkasan kartu statistik
│   │   ├── trade_card.dart        # Komponen kartu detail histori trade & Before/After chips
│   │   ├── trade_detail_sheet.dart # Modal detail trade komprehensif, payoff ratio & pips
│   │   ├── trade_image_slots.dart # Komponen pemilih foto Before (Setup) & After (Outcome)
│   │   └── trade_tag_selector.dart # Komponen pemilih tag Setup & Emosi terisolasi
│   └── main.dart                  # Entry point aplikasi Flutter, Lock check & MultiProvider
├── test/
│   └── widget_test.dart           # Unit test kalkulasi RR, drawdown, profit factor, streaks, PIN & ZIP
├── LICENSE                        # Lisensi open-source MIT
└── pubspec.yaml                   # Manifest paket dan dependensi Flutter v1.0.0+1
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
No,Date,Symbol,Side,Entry,SL,TP,Lot,RR,Result,PL,Equity,Why,Note,Tags
1,2026-10-15T09:30:00.000,XAU/USD,BUY,2650.00,2640.00,2680.00,0.1,1:3.00,WIN,150.00,1150.00,M15 retest,Eksekusi terencana,BOS,FVG,Disiplin
2,2026-10-16T14:15:00.000,EUR/USD,SELL,1.0850,1.0880,1.0790,0.5,1:2.00,LOSE,-60.00,1090.00,Liquidity sweep,Kena stop loss,SnR,FOMO
```

---

## 🛡️ Keamanan & Privasi

- **100% Offline & Zero Telemetry**: Aplikasi tidak meminta izin internet (`android.permission.INTERNET` dihapus total). Tidak ada server pihak ketiga, pelacak, analitik, atau transmisi jaringan luar.
- **Offline Sandbox Storage**: Database SQLite dan foto analisis tersimpan secara eksklusif di sandbox direktori aplikasi internal perangkat Anda.
- **Nonaktifkan Auto-Backup OS (`allowBackup="false"`)**: Menghindari kebocoran data jurnal atau kredensial ke backup awan tidak terenkripsi milik Google/Android.
- **Salted SHA-256 PIN + 5-Attempt Lockout**: PIN 4-digit tidak pernah disimpan secara plaintext, melainkan melalui hash kriptografi SHA-256 dengan salt unik. Percobaan salah 5 kali berturut-turut memicu penguncian sementara (*lockout*) 30 detik.
- **Biometric Authentication**: Dukungan sidik jari lokal via Android BiometricPrompt API (`local_auth`).
- **Pencadangan Mandiri Lengkap (Full Backup .ZIP)**: Seluruh database, foto chart, dan manifest dapat diekspor menjadi 1 berkas `.zip` terkompresi untuk dipindahkan dengan aman antar perangkat secara manual.
- **Keystore CI Secrets**: Kunci penandatanganan rilis APK diamankan melalui GitHub Secrets dan tidak disimpan di dalam repositori publik.

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
