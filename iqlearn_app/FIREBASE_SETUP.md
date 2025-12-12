# Firebase Setup Guide for IQ Learn

This guide will help you set up Firebase Authentication for the IQ Learn app.

## Step 1: Create a Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Enter project name: "IQ Learn" (or any name you prefer)
4. Click "Continue"
5. (Optional) Enable Google Analytics
6. Click "Create project"
7. Wait for the project to be created, then click "Continue"

## Step 2: Add Android App

1. In the Firebase Console, click the Android icon to add an Android app
2. Enter the Android package name: `com.example.iqlearn_app`
   - You can find this in `android/app/build.gradle` under `applicationId`
3. (Optional) Enter app nickname: "IQ Learn Android"
4. (Optional) Enter SHA-1 certificate (needed for phone auth)
   - Get SHA-1 with: `cd android && ./gradlew signingReport`
5. Click "Register app"
6. Download `google-services.json`
7. Place `google-services.json` in `android/app/` directory
8. Follow the configuration steps displayed on screen:
   - Add classpath to project-level build.gradle
   - Add plugin to app-level build.gradle
9. Click "Next" and then "Continue to console"

## Step 3: Add iOS App (Optional)

1. In the Firebase Console, click the iOS icon to add an iOS app
2. Enter iOS bundle ID: `com.example.iqlearnApp`
   - You can find this in `ios/Runner.xcodeproj/project.pbxproj`
3. (Optional) Enter app nickname: "IQ Learn iOS"
4. Click "Register app"
5. Download `GoogleService-Info.plist`
6. Open `ios/Runner.xcworkspace` in Xcode
7. Drag `GoogleService-Info.plist` into the Runner folder in Xcode
8. Click "Next" and then "Continue to console"

## Step 4: Enable Authentication Methods

### Enable Phone Authentication

1. In Firebase Console, go to "Authentication" → "Sign-in method"
2. Click "Phone" in the providers list
3. Toggle "Enable"
4. Click "Save"

**For Production:**
- You may need to verify your app with Google Play Console (Android)
- Add your app to App Store Connect (iOS)
- Enable reCAPTCHA verification

**For Testing:**
- Go to "Phone numbers for testing" section
- Add test phone numbers and verification codes (e.g., +911234567890 → 123456)

### Enable Email Link Authentication

1. In Firebase Console, go to "Authentication" → "Sign-in method"
2. Click "Email/Password" in the providers list
3. Toggle "Enable"
4. Make sure "Email link (passwordless sign-in)" is also enabled
5. Click "Save"

**Configure Action URL:**
1. Go to "Templates" tab
2. Click on "Email address verification" template
3. Customize the action URL if needed
4. Click "Save"

### Configure Authorized Domains

1. In "Authentication" → "Settings" → "Authorized domains"
2. Make sure your app's domain is listed
3. For local testing, `localhost` should already be there
4. Add any custom domains you'll use

## Step 5: Set Up Dynamic Links (for Email Authentication)

1. In Firebase Console, go to "Dynamic Links"
2. Click "Get started"
3. Set up a URL prefix (e.g., `iqlearn.page.link`)
4. Follow the setup wizard

**Update in code:**
Open `lib/services/auth_service.dart` and update the URL in `sendEmailOTP`:
```dart
url: 'https://YOUR_PROJECT.page.link/finishSignIn',
```

## Step 6: Update Flutter App

### 1. Add Google Services Plugin (Android)

Edit `android/build.gradle`:
```gradle
buildscript {
    dependencies {
        // Add this line
        classpath 'com.google.gms:google-services:4.3.15'
    }
}
```

Edit `android/app/build.gradle`:
```gradle
// Add at the bottom of the file
apply plugin: 'com.google.gms.google-services'
```

### 2. Enable Multidex (Android)

Edit `android/app/build.gradle`:
```gradle
android {
    defaultConfig {
        multiDexEnabled true
    }
}
```

### 3. Enable Firebase in main.dart

Open `lib/main.dart` and uncomment this line:
```dart
await Firebase.initializeApp();
```

## Step 7: Test the Setup

### Test Phone Authentication

1. Run the app: `flutter run`
2. On login screen, select "Mobile"
3. Enter a test phone number (e.g., +911234567890)
4. Click "Send OTP"
5. Enter the test verification code (e.g., 123456)
6. Verify login is successful

### Test Email Authentication

1. On login screen, select "Email"
2. Enter your email address
3. Click "Send OTP"
4. Check your email for the verification link
5. Click the link to verify
6. Verify login is successful

## Troubleshooting

### Issue: "google-services.json not found"
**Solution:** Make sure `google-services.json` is in `android/app/` directory

### Issue: "SHA-1 fingerprint not found"
**Solution:** 
1. Generate SHA-1: `cd android && ./gradlew signingReport`
2. Copy the SHA-1 from the output
3. Add it to Firebase Console → Project Settings → Your apps → Android app

### Issue: "Phone authentication not working"
**Solution:**
1. Ensure Phone authentication is enabled in Firebase Console
2. Check that you've added SHA-1 certificate
3. For testing, use test phone numbers configured in Firebase
4. Check Logcat for detailed error messages

### Issue: "Email link not working"
**Solution:**
1. Ensure Email/Password authentication is enabled
2. Check that Dynamic Links are set up correctly
3. Update the action URL in `auth_service.dart`
4. Check spam folder for verification email

### Issue: "Firebase not initialized"
**Solution:**
1. Make sure you uncommented `await Firebase.initializeApp();` in `main.dart`
2. Verify `google-services.json` (Android) or `GoogleService-Info.plist` (iOS) is in the correct location
3. Run `flutter clean` and `flutter pub get`

### Issue: "Dependencies conflict"
**Solution:**
1. Check that all Firebase packages are compatible versions
2. Run `flutter pub upgrade`
3. If issues persist, check the [FlutterFire documentation](https://firebase.flutter.dev/)

## Security Best Practices

1. **Never commit Firebase config files to public repositories**
   - Add to `.gitignore`:
     ```
     android/app/google-services.json
     ios/Runner/GoogleService-Info.plist
     ```

2. **Use Firebase App Check** (for production)
   - Protects your backend from abuse
   - Verifies requests come from your authentic app

3. **Set up Firebase Security Rules**
   - Limit access to authenticated users only
   - Add rate limiting to prevent abuse

4. **Monitor Usage**
   - Check Firebase Console regularly
   - Set up billing alerts
   - Monitor for unusual activity

## Additional Resources

- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Firebase Authentication Docs](https://firebase.google.com/docs/auth)
- [Phone Authentication Guide](https://firebase.google.com/docs/auth/flutter/phone-auth)
- [Email Link Authentication Guide](https://firebase.google.com/docs/auth/flutter/email-link-auth)

## Support

If you encounter issues not covered here:
1. Check the [Firebase Console logs](https://console.firebase.google.com/)
2. Review Flutter error messages in the console
3. Check [StackOverflow](https://stackoverflow.com/questions/tagged/flutter+firebase)
4. Visit [FlutterFire GitHub Issues](https://github.com/firebase/flutterfire/issues)
