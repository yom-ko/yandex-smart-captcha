# Task completion checks

- Run package unit/native widget suite: `flutter test` (CI form: `flutter test --no-pub --coverage`).
- Run browser adapter suite separately: `flutter test --platform chrome` (CI form: `flutter test --no-pub --platform chrome`); do not count VM-skipped browser tests as coverage.
- Run static analysis: `flutter analyze` (CI includes `flutter analyze --no-pub`).
- For example app changes, run its relevant tests/builds separately and provide the real client key through `--dart-define-from-file=.env`; do not commit the key.