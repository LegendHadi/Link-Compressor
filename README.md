# Link Compressor

## 1. What is this app?

`Link Compressor` is a Flutter application written in Dart. It is built with the Flutter framework and uses the following main packages:

- `flutter` (Material UI)
- `provider` for state management
- `shared_preferences` for local storage
- `qr_flutter` to generate QR codes

The app is designed to work on Flutter-supported platforms such as Android, iOS, web, Windows, Linux, and macOS.

## 2. What does this app do?

This app lets users create short, shareable links from long URLs.

Main features:

- Compress a full URL into a shorter generated link
- Add custom keywords to the short link
- Choose an expiration time for the link (optional)
- Display a QR code for the generated short link
- Copy the short link to the clipboard
- Save generated links locally on the device
- Search, view, and manage link history
- Delete links with undo support

The app stores generated links locally using shared preferences, so history remains available between app launches.

## 3. How to run this app

### Prerequisites

You need the following installed before running the app:

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (>=3.22.3)
- Dart SDK (bundled with Flutter)
- A supported editor such as Visual Studio Code, Android Studio, or IntelliJ IDEA
- Platform-specific tooling if you plan to run on mobile or desktop:
  - Android: Android SDK and an emulator or device
  - iOS: Xcode and a device or simulator (macOS only)
  - Web: Chrome or another supported browser
  - Windows: Visual Studio with Desktop development workload
  - Linux/macOS: Desktop support enabled in Flutter

### Setup steps

1. Open a terminal in the project folder:

   ```bash
   cd "~/link_compressor"
   ```

2. Install dependencies:

   ```bash
   flutter pub get
   ```

3. Run the app on your target device:
   - For Android:

     ```bash
     flutter run -d android
     ```

   - For iOS:

     ```bash
     flutter run -d ios
     ```

   - For Windows:

     ```bash
     flutter run -d windows
     ```

   - For web:
     ```bash
     flutter run -d chrome
     ```

### Notes

- If you have multiple devices connected, use `flutter devices` to list available devices.
- If you only want to run on the default device, simply use:

  ```bash
  flutter run
  ```

- To build a release version for Android:

  ```bash
  flutter build apk
  ```

- To build a release version for iOS:

  ```bash
  flutter build ios
  ```

## Additional information

The application entry point is `lib/main.dart`, and the key UI components are in the `lib/widgets/` folder:

- `lib/widgets/link_form.dart`: form for URL input, expiry selection, keywords, and QR code display
- `lib/widgets/link_history.dart`: history list, search, copy, and delete actions

The app persists data using `lib/stores/link_store.dart` and local storage via `lib/services/storage_service.dart`.

## In next updates

Right now, this app does not use a real API or backend service. Generated short links are created locally and do not actually resolve through a live link shortening backend.

In future updates, backend support will be added so the shortened links can work as real shareable URLs with server-side storage and redirection.
