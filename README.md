# Receipt Scanner

Scans receipt photos, learns per-store field layouts, and appends rows to a
Google Sheet. On-device OCR (free, no API cost). No AI/vision API calls.

## What you get out of the box

- Camera capture screen
- On-device OCR via Google ML Kit
- "Teach a store" flow the first time you scan a new merchant (tap the date
  line, tap the total line, optionally tap the tax line)
- Anchor-based matching, so it keeps working as item counts vary
- Review/edit screen before anything is written
- Append-only write to a Google Sheet you control

## One-time setup (do this before running)

### 1. Create the project's native scaffolding

This repo ships only the `lib/`, `pubspec.yaml`, and `assets/` — the parts
that matter. Generate the Android/iOS wrapper once:

```bash
cd receipt_app
flutter create . --platforms=android,ios
flutter pub get
```

### 2. Add camera permissions

**Android** — in `android/app/src/main/AndroidManifest.xml`, add inside `<manifest>`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-feature android:name="android.hardware.camera" android:required="true" />
```

Also make sure `minSdkVersion` is at least 21 in `android/app/build.gradle`.

**iOS** — in `ios/Runner/Info.plist`, add:

```xml
<key>NSCameraUsageDescription</key>
<string>Used to photograph receipts for OCR.</string>
```

### 3. Create a Google Sheets service account (free)

1. Go to [console.cloud.google.com](https://console.cloud.google.com), create
   or select a project.
2. Enable the **Google Sheets API** (APIs & Services → Library → search
   "Google Sheets API" → Enable).
3. Go to **APIs & Services → Credentials → Create Credentials → Service account**.
   Give it any name, no special roles needed.
4. Open the new service account → **Keys** tab → **Add Key → Create new key →
   JSON**. This downloads a `.json` file.
5. Replace `assets/service_account.json` in this project with that downloaded
   file (same filename).
6. Open the JSON file and copy the `client_email` value
   (looks like `something@your-project.iam.gserviceaccount.com`).
7. Open your target Google Sheet → **Share** → paste that email in → give it
   **Editor** access. This step is required — without it, writes will fail
   with a permissions error.

### 4. Point the app at your sheet

Edit `lib/config.dart`:

```dart
static const String spreadsheetId = 'YOUR_SPREADSHEET_ID_HERE';
static const String sheetName = 'Sheet1';
```

The spreadsheet ID is the long string in your sheet's URL:
`https://docs.google.com/spreadsheets/d/`**`THIS_PART`**`/edit`

### 5. Run it

```bash
flutter run
```

## How the first scan of a new store works

1. Tap **Scan Receipt**, photograph it.
2. If the store isn't recognized yet, you land on **Teach This Store**:
   confirm the store name, then tap the line with the date, then the line
   with the total, then optionally the tax line (or skip).
3. Tap **Save Template & Continue** — that store is now remembered for
   every future receipt from it, regardless of how many items it has.
4. You land on **Confirm Receipt** — edit anything that looks wrong, then
   **Save to Sheet**.

Subsequent receipts from an already-taught store skip straight to the
Confirm screen.

## Security note

The service account key ships inside the app bundle so it can call the
Sheets API directly with no backend. That's fine for a personal build you
install only on your own device. **Do not distribute this app to other
people or publish it publicly with the real key bundled** — anyone with the
compiled app could extract the key. If you want to share this with others,
move `SheetsService`'s logic to a small backend (Cloud Run/Render free tier)
and have the app call that instead.

## Customizing what gets written

Edit `AppConfig.columnHeaders` in `lib/config.dart` and the row-building
logic in `SheetsService.appendReceipt` (`lib/services/sheets_service.dart`)
if you want different or additional columns (e.g. splitting out items,
adding a notes field).

## Project structure

```
lib/
  config.dart               <- edit spreadsheet ID here
  main.dart
  models/
    receipt_template.dart   <- FieldRule / StoreTemplate data model
  services/
    ocr_service.dart        <- ML Kit -> OcrLine adapter
    receipt_matcher.dart     <- anchor-based field extraction
    teaching_helper.dart     <- turns a tapped line into a FieldRule
    template_store.dart      <- Hive-backed per-store template storage
    sheets_service.dart      <- Google Sheets write
  screens/
    home_screen.dart
    capture_screen.dart
    teach_screen.dart
    review_screen.dart
```
