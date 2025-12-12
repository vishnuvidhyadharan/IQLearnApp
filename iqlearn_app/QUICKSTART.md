# Quick Start Guide - IQ Learn

A step-by-step guide to get the IQ Learn MCQ examination app up and running.

## Prerequisites Check

Before you begin, ensure you have:

```bash
# Check Flutter installation
flutter doctor

# Expected: Flutter SDK >=3.0.0, all platforms ready
```

## Option 1: Quick Test (No Firebase)

You can test the MCQ parser and UI without Firebase setup:

### 1. Install Dependencies

```bash
cd /home/vishnu/IQLearn/iqlearn_app
flutter pub get
```

### 2. Run the App

```bash
# For Android emulator or connected device
flutter run

# For web (limited features)
flutter run -d chrome
```

### 3. Bypass Login (Temporary)

**Option A:** Comment out authentication check in `main.dart`:

```dart
// Replace in _SplashScreenState._checkLoginStatus()
Navigator.of(context).pushReplacement(
  MaterialPageRoute(
    builder: (context) => const HomeScreen(), // Always go to home
  ),
);
```

**Option B:** Use Firebase test credentials (see Option 2)

### 4. Test Features

- Add exam using the "Add Exam" button
- Paste content from `sample_questions.txt`
- Preview and save questions
- View exams on home screen

## Option 2: Full Setup (With Firebase)

For complete functionality including authentication:

### 1. Firebase Setup

Follow the detailed guide: [FIREBASE_SETUP.md](FIREBASE_SETUP.md)

Quick summary:
1. Create Firebase project at https://console.firebase.google.com/
2. Add Android app
3. Download `google-services.json` → `android/app/`
4. Enable Phone and Email authentication
5. Add test phone number (e.g., +911234567890 → 123456)

### 2. Enable Firebase in Code

Edit `lib/main.dart`:

```dart
// Uncomment this line (around line 13)
await Firebase.initializeApp();
```

### 3. Configure Android Build

Edit `android/build.gradle`:
```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.3.15'
    }
}
```

Edit `android/app/build.gradle`:
```gradle
// Add at the bottom
apply plugin: 'com.google.gms.google-services'

android {
    defaultConfig {
        multiDexEnabled true
    }
}
```

### 4. Run the App

```bash
flutter clean
flutter pub get
flutter run
```

### 5. Test Login Flow

1. Select "Mobile" on login screen
2. Enter test number: `1234567890` (or +911234567890)
3. Click "Send OTP"
4. Enter test code: `123456`
5. Should navigate to home screen

## Option 3: Test with Gemini AI

To enable AI features (explanations and chat):

### 1. Get Gemini API Key

- Visit: https://makersuite.google.com/app/apikey
- Sign in with Google account
- Click "Get API Key"
- Copy the key

### 2. Add API Key in App

1. Complete login (Option 1 or 2)
2. Tap profile icon (top-right)
3. Tap edit icon next to "Gemini API Key"
4. Paste your API key
5. Click "Save"

### 3. Test AI Features

**Test Explanations:**
1. Take an exam
2. Submit and view results
3. Click "Review Incorrect Answers"
4. Click "Explain" button on any question
5. View AI-generated explanation

**Test Chat:**
1. From home screen, tap chat icon
2. Type a question (e.g., "Explain photosynthesis")
3. Get AI response

## Common Commands

```bash
# Clean build
flutter clean

# Get dependencies
flutter pub get

# Run on specific device
flutter devices
flutter run -d <device-id>

# Run in release mode (faster)
flutter run --release

# Check for errors
flutter analyze

# View logs
flutter logs

# Hot reload (press 'r' while app is running)
# Hot restart (press 'R' while app is running)
```

## Quick Troubleshooting

### "Firebase not configured"
- Make sure `google-services.json` is in `android/app/`
- Uncomment `Firebase.initializeApp()` in `main.dart`
- Run `flutter clean && flutter pub get`

### "OTP not received"
- Use test phone numbers configured in Firebase Console
- Check Firebase Console → Authentication → Sign-in method → Phone → Test numbers
- Make sure phone number includes country code (+91 for India)

### "Gemini API error"
- Verify API key is correct (no spaces)
- Check quota limits in Google AI Studio
- Ensure internet connection is active

### "Build failed"
- Run `flutter clean`
- Run `flutter pub get`
- Check `flutter doctor` for issues
- Update Flutter: `flutter upgrade`

### "Database error"
- Clear app data from device settings
- Uninstall and reinstall app
- Check phone storage permissions

## Sample Data for Testing

Use the provided `sample_questions.txt`:

```bash
# Copy content
cat sample_questions.txt

# Paste in app's "Add Exam" screen
```

## Project Files Overview

| File | Purpose |
|------|---------|
| `pubspec.yaml` | Dependencies |
| `lib/main.dart` | App entry point |
| `lib/services/database_service.dart` | SQLite operations |
| `lib/services/auth_service.dart` | Authentication |
| `lib/services/gemini_service.dart` | AI integration |
| `lib/screens/home/home_screen.dart` | Main screen |
| `lib/screens/exam/exam_screen.dart` | Exam interface |
| `lib/screens/admin/add_questions_screen.dart` | Add questions |
| `README.md` | Full documentation |
| `FIREBASE_SETUP.md` | Firebase guide |

## Next Steps

After getting the app running:

1. **Add More Questions**
   - Create question sets in MCQ format
   - Use the admin interface to upload

2. **Customize**
   - Change app name in `pubspec.yaml`
   - Update theme colors in `main.dart`
   - Modify timer duration in `exam.dart`

3. **Deploy**
   - Build APK: `flutter build apk --release`
   - Build for iOS: `flutter build ios --release`
   - Publish to Play Store / App Store

## Getting Help

- **Documentation**: See `README.md` and `FIREBASE_SETUP.md`
- **Flutter Docs**: https://docs.flutter.dev/
- **Firebase Docs**: https://firebase.google.com/docs
- **Gemini API**: https://ai.google.dev/

## Summary

**Fastest path to test:**
1. `flutter pub get`
2. Bypass login temporarily
3. Test MCQ parser with sample data

**Full experience:**
1. Set up Firebase (30 minutes)
2. Get Gemini API key (5 minutes)
3. Test all features

Enjoy building with IQ Learn! 🎓
