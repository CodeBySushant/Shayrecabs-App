# shayreCabs — Flutter App (iOS + Android)

Native mobile app for shayreCabs, at full feature parity with the React web app.
Reuses the existing Node/Express backend — **zero backend changes**: same JWT,
same `/api/*` endpoints, same Razorpay order → verify flow.

## Stack

Flutter (stable) · Riverpod · GoRouter · Dio · flutter_secure_storage ·
razorpay_flutter · image_picker · google_fonts (Inter + Outfit) ·
flutter_animate · shimmer · connectivity_plus · url_launcher · share_plus · intl

Clean architecture, feature-first:

```
lib/
  core/            config · network (Dio client) · storage · theme · router · utils · widgets
  features/
    auth/          data (repository) · domain (models) · presentation (login, signup, forgot, provider)
    rides/         live rides board, ride details, ride card
    booking/       book flow + Razorpay, my bookings (pay-later / cancel / rate), confirmed screen
    profile/       edit, verifications (email/WhatsApp OTP), selfie KYC, theme, logout
    community/     WhatsApp groups + live activity
    support/       contact form, safety, about, help/FAQ, terms, refund policy
    home/          home + bottom-nav shell
    splash/        animated splash
  shared/data/     fares.dart — GENERATED from backend src/data/fares.js
```

## First-time setup

The repo ships `lib/`, `assets/`, and `pubspec.yaml`. Generate the platform
folders once, then add the permissions below.

```bash
cd shayrecabs_app
flutter create --platforms=android,ios --org com.shayrecabs --project-name shayrecabs .
flutter pub get
```

### Android — `android/app/src/main/AndroidManifest.xml`

Inside `<manifest>` (above `<application>`):

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.CAMERA" />
```

In `android/app/build.gradle` set `minSdkVersion 21` (Razorpay requirement).

### iOS — `ios/Runner/Info.plist`

Add inside the top-level `<dict>`:

```xml
<key>NSCameraUsageDescription</key>
<string>shayreCabs uses your camera to take a verification selfie.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>shayreCabs lets you pick a selfie from your photos for verification.</string>
<key>LSApplicationQueriesSchemes</key>
<array>
  <string>whatsapp</string>
  <string>https</string>
</array>
```

iOS minimum platform: 12.0 (set in `ios/Podfile`: `platform :ios, '12.0'`).

### Branding (optional, one-time)

```bash
dart run flutter_native_splash:create
dart run flutter_launcher_icons
```

## Running

```bash
# against production
flutter run --dart-define=API_URL=https://shayrecabs.com/api

# against a local backend (Android emulator reaches host via 10.0.2.2)
flutter run --dart-define=API_URL=http://10.0.2.2:5000/api
```

Release builds:

```bash
flutter build apk --release --dart-define=API_URL=https://shayrecabs.com/api
flutter build appbundle --release --dart-define=API_URL=https://shayrecabs.com/api   # Play Store
flutter build ipa --release --dart-define=API_URL=https://shayrecabs.com/api        # App Store
```

## Backend contract (unchanged)

- Auth: `Authorization: Bearer <jwt>` — token stored in Keychain/Keystore
- Responses: `{ ok: true, ... }` / `{ ok: false, error }` — handled centrally in `core/network/api_client.dart`
- Payments: `POST /payments/create-order` → native Razorpay Checkout → `POST /payments/verify`
- Fares: `lib/shared/data/fares.dart` is **generated from** `backend/src/data/fares.js`.
  Whenever fares change on the server, regenerate this file (it is display-only;
  the amount charged is always computed server-side).

## Feature parity checklist (web → app)

- [x] Email signup / login · WhatsApp phone-OTP login · forgot password (email OTP)
- [x] Session persistence (secure storage) · guest browsing, auth-gated booking
- [x] Live rides board with route / women-only / open filters · pull-to-refresh
- [x] Ride details: driver, co-riders, drop & pickup hotspots, fare split + projection
- [x] Booking: terminal/flight/airline (airport) · pickup hotspot (intercity) · 2/3-share (airport = 2-share only) · women-only toggle · fare preview from the server's own table
- [x] Razorpay checkout + server signature verification · 1-hour seat-hold messaging
- [x] My bookings: pay-later retry · cancel with refund-band preview (>24h ₹200 / 12–24h 50% / <12h none) · rate + feedback after departure
- [x] Profile: edit (gender locked post-KYC, phone change resets verification) · email OTP · WhatsApp phone OTP · selfie KYC (camera/gallery, ≤5MB) · change password
- [x] Community: WhatsApp groups by category, join via deep link, live activity feed
- [x] Contact form · Safety · About · Help/FAQ · Terms · Refund policy
- [x] Light/dark/system theme with persistence · Material 3 · brand palette (#5B5FFF / #1C9CF6, Inter + Outfit)
- [x] Shimmer loading · empty states · error states with retry · offline detection
- [x] Booking-confirmed screen with ticket share

Deliberately not in v1 (decisions from planning): admin panel (web-only),
maps (web barely uses them — needs a Google Maps key to add), push
notifications (backend has no push infra yet).
