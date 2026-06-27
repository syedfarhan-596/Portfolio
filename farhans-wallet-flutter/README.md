# Pocket Flow — Flutter

A premium, **fully offline** personal finance app — a ground-up **Flutter** rewrite of
the original Android (Kotlin/Compose) wallet, with the same features and a new
**2026 glassmorphism design system**.

> Auto-scans bank/UPI SMS on every app open (incremental), auto-matches the bank from the
> SMS to the right account, and includes **Backup & restore** (export a JSON file to move
> your data to another phone) plus Android auto-backup.

> Feature parity with the original: multi-account balances, automatic UPI/bank SMS capture,
> manual transactions, lending/borrowing with contacts, credit-card bill payment (incl.
> reward points), an investment portfolio, reports, a daily reminder, and editable
> accounts & categories — all stored locally on device.

## ✨ Design highlights
- **Glassmorphism throughout** — frosted nav bar, cards, bottom sheets, dialogs and pickers
  (real `BackdropFilter` blur, translucent fills, hairline borders, soft depth).
- **Animated ambient background** with drifting colour blobs that the glass picks up.
- **Design tokens** — centralised colour / spacing (8pt) / radius / blur / motion / type
  tokens via a `ThemeExtension`; no hardcoded colours or magic numbers.
- **Handcrafted light & dark themes** (not simple inversions).
- **Micro-interactions** — press-scale feedback, animated balance counters, zoom page
  transitions, animated bottom-nav pills, animated report bars, spring FAB.
- **Reusable component library** — `GlassCard`, `PrimaryButton`, `AppTextField`,
  `AppSelectField`, `GlassSegmented`, `IconBadge`, `Pill`, `EmptyState`, glass sheets, etc.

## 🏗 Architecture (clean & modular)
```
lib/
  core/
    theme/      design tokens + ThemeData (light/dark)
    utils/      money & date formatting, icon map
    widgets/    reusable glass UI components
  data/         models, sqflite database + seed, repository
  services/     prefs, notifications, SMS, contacts, SMS parser
  state/        Riverpod providers + WalletNotifier (single source of truth)
  features/     dashboard / transactions / people / portfolio / reports /
                settings / credit  (each screen self-contained)
```
- **State management:** Riverpod (`AsyncNotifier`), one immutable `WalletData` snapshot with
  all derived figures (balances, dashboard totals, people summaries, portfolio).
- **Persistence:** `sqflite` (same schema/semantics as the original Room DB).
- **Device integrations:** `another_telephony` (SMS), `flutter_contacts`,
  `flutter_local_notifications` + `timezone` (daily reminder).

## 🔐 Credit-card semantics
A credit card's stored balance represents **outstanding owed**: spending/lending raises it,
bill payments & refunds reduce it (mirrors the fix shipped in the original app).

## ▶️ Run / build
Requires Flutter 3.44+ and the Android SDK.
```bash
flutter pub get
flutter run                 # debug
flutter build apk --release # -> build/app/outputs/flutter-apk/app-release.apk
```
The release build is signed with the included keystore (`android/app/farhanswallet.keystore`,
passwords in `android/key.properties`) so you can rebuild and reinstall over the same app.
For a personal sideloaded app this is fine; change it before publishing anywhere.

Package id: `com.farhan.farhans_wallet` · all data stays on device, no network code.
