# Suggested commands

- Package tests: `flutter test`.
- Browser-only web adapter tests: `flutter test --platform chrome`; VM test runs do not establish browser coverage.
- Static analysis: `flutter analyze`. CI also uses `flutter analyze --no-pub` and `flutter analyze --no-pub --no-fatal-infos lib test`.
- CI package checks use `flutter test --no-pub --coverage` and `flutter test --no-pub --platform chrome` (see `.github/workflows/main.yml`).
- Example builds/tests needing a client key should read it from `example/.env` via `--dart-define-from-file=.env`; never add real keys to source or generated output.