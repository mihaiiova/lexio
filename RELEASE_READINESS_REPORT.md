# Release Tracking

Release progress is tracked in GitHub Issues. See the [release milestone](https://github.com/mihaiiova/lexio/issues) for current status.

## Key issues

| Issue | What |
|---|---|
| [#24](https://github.com/mihaiiova/lexio/issues/24) | Set up signing secrets |
| [#25](https://github.com/mihaiiova/lexio/issues/25) | Smoke test on real devices |
| [#26](https://github.com/mihaiiova/lexio/issues/26) | Editorial review of content |
| [#29](https://github.com/mihaiiova/lexio/issues/29) | Verify signed CI artifacts |
| [#35](https://github.com/mihaiiova/lexio/issues/35) | Submit to TestFlight & Play Store |

## CI verification (2026-08-06)

| Check | Result |
|---|---|
| `flutter analyze` | Passed |
| `flutter test` | 119 tests passed |
| `flutter build web --release` | Passed |
| Content structural validation | 849 items — all valid |
