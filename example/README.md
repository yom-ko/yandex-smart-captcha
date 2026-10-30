# Example app

This app demonstrates the Yandex SmartCaptcha Flutter package on Android, iOS, and web.

## Before you start

Copy `.env.example` to `.env` in this directory and set `CLIENT_KEY` to a valid Yandex SmartCaptcha client key. Keep `.env` local and never commit it. Ensure `.env` is listed in `.gitignore`.

Run project commands from this directory. Include `--dart-define-from-file=.env` in every command that builds or runs the app.

### Integration tests (optional)

Install [Patrol CLI](https://pub.dev/packages/patrol_cli) globally:

```bash
dart pub global activate patrol_cli
```

Ensure the Pub cache's `bin` directory is on your `PATH`. Verify the installation:

```bash
patrol doctor
```

## Android

Run the app on an Android emulator or connected physical device:

```bash
flutter run -d <android-device-id> --dart-define-from-file=.env
```

Run the Patrol integration tests on an Android emulator or connected physical device:

```bash
patrol test -d <android-device-id> --dart-define-from-file=.env
```

## iOS

The iOS deployment target is 15.0. Install [Xcode](https://developer.apple.com/xcode/) and a compatible iOS Simulator runtime.

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

Run the Patrol integration tests on an iOS simulator:

```bash
patrol test -d <ios-simulator-id> --dart-define-from-file=.env
```

## Web (Chrome)

Run the app in Chrome:

```bash
flutter run -d chrome --dart-define-from-file=.env
```
