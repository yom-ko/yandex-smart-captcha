# Example app

This app demonstrates the Yandex SmartCaptcha Flutter package on Android, iOS, and web.

## Before you start

Copy `.env.example` to `.env` in this directory and set `CLIENT_KEY` to a valid Yandex SmartCaptcha client key. Keep `.env` local and never commit it. Ensure `.env` is listed in `.gitignore`.

Run example app commands from this directory. Include `--dart-define-from-file=.env` when building or running the app.

### Platform setup

The published archive omits the `android/`, `ios/`, and `web/` folders. If you downloaded the package from pub.dev, generate them with:

```bash
flutter create --empty --platforms=android,ios,web .
```

`--empty` keeps the existing `lib/main.dart` and skips Flutter's sample test.

Then add the temporary [Android support](https://pub.dev/packages/yandex_smart_captcha#android-support) workaround to `android/gradle.properties`:

```bash
echo 'android.r8.proguardAndroidTxt.disallowed=false' >> android/gradle.properties
```

## Android

Run the app on an Android emulator or connected physical device:

```bash
flutter run -d <android-device-id> --dart-define-from-file=.env
```

Flutter's generated project grants internet access only to debug and profile builds. For release builds, add `<uses-permission android:name="android.permission.INTERNET" />` to `android/app/src/main/AndroidManifest.xml`.

## iOS

Install [Xcode](https://developer.apple.com/xcode/) and a compatible iOS Simulator runtime.

Select Xcode as the active developer directory and complete its first-run setup:

```bash
sudo xcode-select --switch /path/to/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
sudo xcodebuild -license
xcodebuild -downloadPlatform iOS
```

Flutter uses Swift Package Manager by default and falls back to CocoaPods for plugins that do not support it.

Boot an iOS simulator and list the available Flutter devices:

```bash
# List available simulators
xcrun simctl list devices available

# Boot a simulator (skip if already booted)
xcrun simctl boot <ios-simulator-udid>
xcrun simctl bootstatus <ios-simulator-udid> -b

# Optional: open Device Hub to view the simulator (Xcode 27)
open -a DeviceHub

# List available Flutter devices
flutter devices
```

Run the app on an iOS simulator:

```bash
flutter run -d <ios-simulator-id> --dart-define-from-file=.env
```

## Web (Chrome)

Run the app in Chrome:

```bash
flutter run -d chrome --dart-define-from-file=.env
```

## Tests (repository only)

The published archive also omits the test files available in the [GitHub repository](https://github.com/yom-ko/yandex-smart-captcha).

From this `example/` directory, run the example app's widget tests:

```bash
flutter test
```

The Patrol integration tests rely on the repository's platform folders (the iOS deployment target is 15.0). Install [Patrol CLI](https://pub.dev/packages/patrol_cli) globally and make sure the Pub cache's `bin` directory is on your `PATH`:

```bash
dart pub global activate patrol_cli
patrol doctor
```

Run the tests on an Android emulator, an Android device, or an iOS simulator:

```bash
patrol test -d <device-id> --dart-define-from-file=.env
```
