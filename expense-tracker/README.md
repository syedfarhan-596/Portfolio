# Farhan's Wallet — Personal Expense, Lending & Investment Tracker (Android)

A fully **offline**, on-device money manager built for the way you actually spend:
multiple bank accounts + cash + a credit card, money lent to and borrowed from friends,
expenses split with people from your contacts, an investment portfolio, and automatic
capture of UPI / bank transactions from your SMS alerts.

> **Download the ready-to-install app:** [`Farhans-Wallet-v1.3.apk`](./Farhans-Wallet-v1.3.apk)

### What's new in v1.4
- **SMS matching now respects the bank/card in the message** — a charge on your SBI credit
  card no longer lands in your SBI savings account (or whatever the default account was);
  it's matched to the right account by bank name and account type (credit card vs bank).
  Applies to both live SMS capture and "Scan SMS inbox now".
- **Marketing/promotional bank SMS are filtered out** — messages like cashback offers,
  loan pre-approvals and "flat X% off" promos are no longer mistaken for transactions.
- **Tap an account to see its summary** — balance, this month's spend/income, and the full
  transaction history for that account (edit is still one tap away, via the pencil icon).
- **Daily reminder is now reliable** — switched from a WorkManager job (which Doze/App
  Standby could silently delay for hours) to an exact `AlarmManager` alarm, so the nightly
  "log your expenses" notification actually fires at the time you set.

### What's new in v1.1
- **Portfolio** section — add stocks / mutual funds / gold / any asset, money is deducted
  from the account you pick, see total invested, current value and returns. Sell/redeem
  credits the proceeds back to an account.
- **Settle dues into an account** — when settling a lending/borrowing, pick the bank and
  enter 50% / 100% / any amount; it posts a real transaction so balances update.
- **Pay credit-card bill** — pay part from a bank account and part with reward points;
  outstanding reduces accordingly.
- **More categories** (25+ expense + income), new icons, smoother animations, and the app
  is now named **Farhan's Wallet**.

---

## ⬇️ Install on your Android phone

1. Copy **`PaisaTrack-v1.0.apk`** to your phone (or download it from GitHub on the phone).
2. Tap the file. Android will ask to allow installing from this source — enable
   **"Allow from this source"** (Settings → Apps → Special access → Install unknown apps).
3. Install and open **PaisaTrack**.
4. On first launch, grant the permissions it asks for (all optional, see below).

> Minimum Android version: **8.0 (Oreo)**. The app is self-signed for personal sideloading.

---

## ✨ Features

- **Multiple accounts** — comes pre-seeded with 3 banks, Cash, and an SBI PhonePe
  credit card. Add/edit/delete any account, pick colors & icons, set opening balances.
- **Overall balance including cash** — the home screen shows your available balance
  (cash + banks), credit-card outstanding, and net worth at a glance.
- **Automatic UPI / bank tracking from SMS** — the app reads your bank/UPI **SMS alerts**
  and turns them into transactions you can confirm & categorize. (Android has no public
  "UPI API"; SMS parsing is how this works reliably and locally.)
  - Auto-captures new alerts in the background (optional).
  - "Scan SMS inbox now" in Settings backfills past transactions.
- **Add more detail to any transaction** — notes, merchant, category, account, and a
  **person** attached from your contacts.
- **Manual transactions** — add expense / income / transfer between accounts anytime.
- **Lending & borrowing** — track who owes you and whom you owe, with partial payments,
  settle button, and a **"pay after salary"** flag.
- **Split with friends** — while adding an expense, tick *"Someone owes me part of this"*,
  attach a contact, and it creates a linked lending entry automatically.
- **Reports** — month-by-month income vs expense, spending by category, spending by account.
- **Daily reminder** — a notification every night (default **11:00 PM**, configurable) to
  log your expenses.
- **Beautiful Material 3 UI** — light & dark themes, smooth Compose UI.
- **100% local** — all data stays in the app's local database. Nothing is uploaded anywhere.

---

## 🔐 Permissions (all optional)

| Permission | Why |
|---|---|
| SMS (read/receive) | Auto-detect UPI / bank transactions from alert messages |
| Contacts | Attach a friend to an expense or a lending entry |
| Notifications | Daily reminder + "new transaction detected" alerts |

The app works fully without any of them — you can just add transactions manually.

---

## 🛠 Building from source

Requirements: JDK 17+, Android SDK (platform 34, build-tools 34.0.0).

```bash
cd expense-tracker
# point the build at your SDK:
echo "sdk.dir=/path/to/Android/sdk" > local.properties

# debug build:
./gradlew assembleDebug      # -> app/build/outputs/apk/debug/app-debug.apk

# release build (signed with the included keystore):
./gradlew assembleRelease    # -> app/build/outputs/apk/release/app-release.apk
```

The release keystore (`app/paisatrack-release.keystore`) is included for convenience so you
can rebuild and reinstall over the same app. Keystore/key password: `paisatrack123`.
(For a personal sideloaded app this is fine; change it if you publish anywhere.)

## Tech stack

Kotlin · Jetpack Compose (Material 3) · Room · AlarmManager · Navigation Compose ·
single-module MVVM, no network code.
