# Example app

This app demonstrates the usage of the Yandex SmartCaptcha package on Android, iOS, and Web.

## Before you start

In this directory, rename `.env.example` to `.env` and set a real Yandex SmartCaptcha `CLIENT_KEY`. Keep `.env` local and never commit it.

Include `--dart-define-from-file=.env` in every command to load the local key.

## Android

Run the app on a connected Android device or emulator:

```bash
flutter run -d <android-device-id> --dart-define-from-file=.env
```

### Integration tests

Install [Patrol CLI](https://pub.dev/packages/patrol_cli) globally:

```bash
dart pub global activate patrol_cli
```

Run the integration tests on an Android device or emulator:

```bash
patrol test -d <android-device-id> --dart-define-from-file=.env
```

## iOS

The checked-in iOS project targets iOS 15.0. Install the full [Xcode](https://developer.apple.com/xcode/) application and an iOS 15 or later Simulator runtime.

Select Xcode as the active developer directory and complete its first-run setup:

```bash
sudo xcode-select --switch /path/to/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
```

Replace `/path/to/Xcode.app` with the installed Xcode application path.

Start a simulator and list the available Flutter devices:

```bash
open -a Simulator
flutter devices
```

Flutter uses Swift Package Manager for plugins that support it and CocoaPods for `flutter_inappwebview_ios`, which does not currently publish an iOS Swift package.

Run the app on an iOS simulator:

```bash
flutter run -d <ios-simulator-id> --dart-define-from-file=.env
```

## Web (Chrome)

Run the app in Chrome:

```bash
flutter run -d chrome --dart-define-from-file=.env
```
