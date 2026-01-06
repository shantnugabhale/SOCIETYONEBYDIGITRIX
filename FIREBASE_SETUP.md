# Firebase Phone Authentication Setup Guide

This guide explains how Firebase Phone Authentication is configured for Android, iOS, and Web platforms.

## ✅ What's Already Configured

1. **Firebase Dependencies**: Added to `pubspec.yaml`
   - `firebase_core: ^4.2.0`
   - `firebase_auth: ^6.1.1`

2. **Firebase Initialization**: 
   - Firebase is initialized in `lib/main.dart`
   - Uses platform-specific options from `lib/firebase_options.dart`

3. **Authentication Service**: 
   - Created `lib/services/auth_service.dart` with:
     - `sendOTP()` - Sends OTP to phone number
     - `verifyOTP()` - Verifies the OTP code
     - `resendOTP()` - Resends OTP
     - `signOut()` - Signs out the user

4. **UI Integration**:
   - Login screen sends OTP via Firebase
   - OTP verification screen verifies code via Firebase
   - Automatic handling of new vs existing users

## 📱 Platform-Specific Setup

### Android ✅
- `google-services.json` is present in `android/app/`
- Google Services plugin is configured in `android/app/build.gradle.kts`
- Phone authentication works automatically

### iOS ⚠️
**Important**: You need to add `GoogleService-Info.plist` to your iOS project:

1. Download `GoogleService-Info.plist` from Firebase Console
2. Place it in `ios/Runner/` directory
3. Add it to Xcode project (drag and drop into Runner folder)
4. Ensure it's added to the target

### Web ⚠️
For web platform, Firebase Phone Auth requires reCAPTCHA. The current implementation should work, but ensure:

1. Your Firebase project has reCAPTCHA configured
2. The domain is authorized in Firebase Console:
   - Go to Firebase Console → Authentication → Settings → Authorized domains
   - Add your web domain (localhost for development)

## 🔧 Firebase Console Setup

1. **Enable Phone Authentication**:
   - Go to Firebase Console → Authentication → Sign-in method
   - Enable "Phone" provider
   - For testing, you can add test phone numbers

2. **Configure Phone Numbers** (for testing):
   - Add test phone numbers in Firebase Console
   - These numbers will receive OTP without actual SMS

3. **Quota & Billing**:
   - Phone authentication uses SMS service
   - Check your Firebase quota limits
   - Ensure billing is enabled if needed

## 📝 Usage Example

```dart
// Send OTP
final authService = AuthService();
await authService.sendOTP('+911234567890');

// Verify OTP
final userCredential = await authService.verifyOTP('123456');

// Check if user is new
final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;
```

## 🔍 Error Handling

The implementation includes comprehensive error handling for:
- Invalid phone numbers
- Invalid OTP codes
- Session expiration
- Network errors
- Quota exceeded
- Too many requests

## 🚀 Testing

### Testing Phone Numbers
You can use Firebase's test phone numbers in development:
- Add test numbers in Firebase Console
- These won't send actual SMS
- Format: `+911234567890` with verification code `123456`

### Production
- Ensure proper phone number validation
- Monitor SMS quota usage
- Handle rate limiting appropriately

## 📚 Additional Resources

- [Firebase Phone Auth Documentation](https://firebase.google.com/docs/auth/flutter/phone-auth)
- [FlutterFire Auth](https://firebase.flutter.dev/docs/auth/phone-auth)
- [Firebase Console](https://console.firebase.google.com/)

## ⚠️ Important Notes

1. **Phone Number Format**: Must include country code (e.g., +91)
2. **SMS Costs**: Real SMS messages cost money (Free tier has limits)
3. **Rate Limiting**: Firebase enforces rate limits on phone auth
4. **Security**: Always validate phone numbers on backend for production
5. **Privacy**: Handle phone numbers according to privacy regulations (GDPR, etc.)

