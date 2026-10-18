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
  <a href="https://github.com/zacxyonly/traderlog/actions/workflows/build_apk.yml">
    <img src="https://img.shields.io/badge/⚙️_GitHub_Actions-CI_Build-6366F1?style=for-the-badge&labelColor=121B2B&logo=githubactions&logoColor=white" alt="Actions CI" />
  </a>
  <a href="https://sociabuzz.com/zacxyonly/tribe">
    <img src="https://img.shields.io/badge/SociaBuzz-Support%20Project-fe5f55?style=for-the-badge&logo=heart" alt="Support via SociaBuzz" />
  </a>
</p>

<p align="center">
  🌐 <strong>Language:</strong>
  <strong>English 🇬🇧</strong> | <a href="README_ID.md">Bahasa Indonesia 🇮🇩</a>
</p>

---

## 📖 Overview

**TraderLog** is a high-performance Android trading journal engineered for traders across Forex, Commodities (Gold/XAUUSD), Crypto, Stocks, and Indices who prioritize psychological discipline and statistical validation of their trading edge.

Built with **Flutter** and local **SQLite (SQFlite)**, TraderLog guarantees 100% data sovereignty and zero latency: **no third-party cloud tracking, no mandatory sign-ups, offline-first architecture, and complete data privacy**.

---

## 🌟 Core Features

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
* **🔐 Salted HMAC-SHA256 PIN & Biometrics**: Screen lock powered by a 4-digit PIN stored as a salted, iterated HMAC-SHA256 hash (via `PinHasher`), alongside native Android biometric authentication (`local_auth`).
* **📦 Full ZIP Backup & Restore**: Export an entire ZIP archive containing your SQLite database (`traderlog.db`), all trade chart screenshots, and manifest metadata. Restore effortlessly across devices or back up to Google Drive.
* **💱 Multi-Currency & Live Exchange Rates**: Support for account currencies (USD, IDR, USDC, USDT, EUR, GBP, JPY, SGD, AUD) with real-time exchange rate sync via Open FX Market API.
* **🌐 Complete Bilingual Support (EN & ID)**: Instant toggle between English 🇬🇧 and Bahasa Indonesia 🇮🇩 across all dialogs, analytics, and navigation.

## 📱 App Screenshots

| 📱 Trade Journal | 📊 Performance Summary | ⚙️ Settings & Security |
| :---: | :---: | :---: |
| <img src="docs/screenshots/jurnal_tab.jpg" width="260" alt="Trade Journal" /> | <img src="docs/screenshots/summary_tab.jpg" width="260" alt="Performance Summary" /> | <img src="docs/screenshots/setting_tab.jpg" width="260" alt="Settings & Security" /> |
| *Balance Hero Card, Tags & History* | *Interactive Equity Curve & PnL Heatmap* | *Multi-Account Portfolio & Security Lock* |

---

## 🛠️ Tech Stack & Dependencies

* **Framework**: [Flutter](https://flutter.dev) (v3.24.5 - Stable Channel)
* **Language**: [Dart](https://dart.dev) (v3.5.4)
* **Local Database**: [sqflite](https://pub.dev/packages/sqflite) (SQLite native engine with schema migrations)
* **Security & Cryptography**: [crypto](https://pub.dev/packages/crypto) (Salted HMAC-SHA256 PIN hashing) & [local_auth](https://pub.dev/packages/local_auth) (Biometric Fingerprint / Face prompt)
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
├── docs/
│   └── screenshots/               # App preview screenshots (Journal, Summary, Settings)
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
├── pubspec.yaml                   # Flutter package manifest
├── LICENSE                        # MIT Open Source License
├── README.md                      # English documentation (default)
└── README_ID.md                   # Indonesian documentation
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

Release keystores are **never committed to the repository**. Generate a private keystore on your local machine:

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

## ⚙️ CI Compilation with GitHub Actions

The GitHub Actions workflow is configured for **manual on-demand runs (workflow_dispatch)**:

1. Open repository on GitHub: [zacxyonly/traderlog](https://github.com/zacxyonly/traderlog).
2. Click the **Actions** tab.
3. In the left panel, select **Build Android APK**.
4. Click **Run workflow**, choose branch `main` (optionally provide a release tag, e.g. `v1.0.0`), and run.
5. GitHub will compile the APK, verify signature integrity, attach the file to **Artifacts**, and automatically create a **GitHub Release** when a release tag is provided.

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

## 🛡️ Security & Privacy Guarantees

- **Zero Telemetry**: The app does not transmit analytics, tracking tags, or personal logs to external servers.
- **Offline Storage**: The SQLite database resides inside the app's local internal storage sandbox.
- **Biometric & PIN Lock**: Protected via 4-digit PIN stored as a salted, iterated HMAC-SHA256 digest (`PinHasher`) and native Android BiometricPrompt API.
- **No Google Auto-Backup**: `android:allowBackup="false"`, ensuring database and PIN hashes are never sent to unencrypted Android backup clouds.
- **Data Sovereignty**: Full control over journal data at any time via CSV export and full ZIP archives.

---

## 🤝 Contributing

Contributions, bug reports, and suggestions are welcome!
1. **Fork** this repository.
2. Create your feature branch (`git checkout -b feature/AmazingFeature`).
3. Commit your changes (`git commit -m "feat: Add AmazingFeature"`).
4. Push to your branch (`git push origin feature/AmazingFeature`).
5. Open a **Pull Request**.

---

## ☕ Support

If you find TraderLog helpful, consider supporting the project:

[![Support via SociaBuzz](https://img.shields.io/badge/SociaBuzz-Support%20Project-fe5f55?style=for-the-badge&logo=heart)](https://sociabuzz.com/zacxyonly/tribe)

---

## 📜 License

This project is licensed under the **MIT License**. See the [LICENSE](LICENSE) file for details.

<p align="center">
  Crafted with ❤️ by <a href="https://github.com/zacxyonly"><strong>zacxyonly</strong></a>
</p>
