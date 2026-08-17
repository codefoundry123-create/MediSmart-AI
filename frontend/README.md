# MediSmart Flutter App
## Repo: medismart-app | Runs on: Android Phone

---

## What This Repo Does

Flutter mobile app for MediSmart patients. Runs on Android and handles:
- User login and signup (Firebase Auth)
- Browse and search medicines (Firestore)
- AI prescription scan (calls EC2 server)
- Upload prescription images (Amazon S3 via EC2)
- Shows CockroachDB search history to user
- Shows "Memory" badge when result recalled from CockroachDB
- Shows "Bedrock" badge when Amazon Bedrock AI was used
- Order medicines (Firestore)
- View order and prescription history

## What Was Changed From Original

| File | What Changed | Why |
|---|---|---|
| `lib/features/ai/screens/ai_screen.dart` | EC2 URLs, S3 upload, user_id, history panel, memory/bedrock badges | Connect to AWS backend + show CockroachDB memory visually |

---

## Architecture

```
Android Phone (this repo runs here)
    │
    │── Firebase Auth    (login/signup)
    │── Firestore        (medicines, orders, prescriptions)
    │── EC2 :5000/predict   (AI prediction — checks CockroachDB memory first)
    │── EC2 :5000/upload    (S3 image upload)
    └── EC2 :5000/history   (load user's CockroachDB search history)
```

---

## STEP 1 — Prerequisites on Your Windows PC

### Install Flutter
1. Go to https://flutter.dev/docs/get-started/install/windows
2. Download Flutter SDK
3. Extract to `C:\flutter`
4. Add `C:\flutter\bin` to Windows PATH
5. Verify:
```
flutter --version
```
Expected: `Flutter 3.x.x`

### Install Android Studio
1. Go to https://developer.android.com/studio
2. Download and install
3. Open Android Studio → SDK Manager → Install Android SDK
4. Verify:
```
flutter doctor
```
Expected: Android toolchain shows checkmark

---

## STEP 2 — Update EC2 IP Address

Before running the app you MUST update the EC2 IP.
Open this file:
```
lib/features/ai/screens/ai_screen.dart
```
Find these 3 lines (around line 36):
```dart
final String aiApiUrl = 'http://YOUR_EC2_PUBLIC_IP:5000/predict';
final String uploadUrl = 'http://YOUR_EC2_PUBLIC_IP:5000/upload';
final String historyUrl = 'http://YOUR_EC2_PUBLIC_IP:5000/history';
```
Replace `YOUR_EC2_PUBLIC_IP` with your actual EC2 IP.

Example:
```dart
final String aiApiUrl = 'http://54.123.45.67:5000/predict';
final String uploadUrl = 'http://54.123.45.67:5000/upload';
final String historyUrl = 'http://54.123.45.67:5000/history';
```

---

## STEP 3 — Install Dependencies

```
flutter pub get
```
Expected: `Got dependencies!`

---

## STEP 4 — Connect Android Phone

1. On your Android phone go to Settings
2. About Phone → Tap "Build Number" 7 times
3. Go back → Developer Options → Enable USB Debugging
4. Connect phone to PC via USB
5. Accept "Allow USB Debugging" popup on phone

Verify phone detected:
```
flutter devices
```
Expected: Shows your phone model

---

## STEP 5 — Run App

```
flutter run
```
Expected: App builds and launches on your phone (takes 2-3 minutes first time)

---

## STEP 6 — Build APK (To Share With Others)

```
flutter build apk --release
```
Expected: APK at `build/app/outputs/flutter-apk/app-release.apk`

---

## STEP 7 — Verify App Works

1. Open app on phone
2. Login with your account
3. Go to AI Scan tab
4. You will see your CockroachDB search history panel at the top (if any past searches)
5. Type "Panadol" → Tap "Analyze Prescription"
6. Should show: salt = paracetamol + alternatives
7. Search "Panadol" again → result card shows orange "Memory" badge (from CockroachDB)
8. Search an unknown medicine → result card shows purple "Bedrock" badge

---

## What the User Sees

| UI Element | What it means |
|---|---|
| History panel (orange border) | Past searches loaded from CockroachDB |
| "Memory" badge (orange) | This result was recalled from CockroachDB — not re-predicted |
| "Bedrock" badge (purple) | Amazon Bedrock AI identified this medicine |
| No badge | ML model or dataset identified this medicine |

---

## Troubleshooting

**App can't reach EC2:**
```
# Verify EC2 IP is correct in ai_screen.dart
# Verify EC2 server is running
# Test from PC: curl http://EC2_IP:5000/health
```

**History panel not showing:**
```
# Make at least one search first
# History loads from CockroachDB on screen open
# Check EC2 server is running
```

**flutter pub get fails:**
```
flutter clean
flutter pub get
```

**Phone not detected:**
```
# Enable USB Debugging on phone
# Try different USB cable
# Install phone USB drivers
```
