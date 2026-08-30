# Example app

This is a simple app demonstrating the usage of the Yandex SmartCaptcha package.

To run integration tests on Android:

1. Install [Patrol CLI](https://pub.dev/packages/patrol_cli) globally: `dart pub global activate patrol_cli`.
2. Add `.env` file with your `CLIENT_KEY` in the example root.
3. Run the tests:

```bash
patrol test -d <your-android-device-id> --dart-define-from-file=.env
```
