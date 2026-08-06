# Slove Release Readiness Report

**Assessment date:** 2026-07-29  
**Recommendation:** Do not submit to public app stores yet.

Slove has a coherent v1 product foundation: two playable Romanian-language games with working completion flows, local content, a polished visual system, and a successful web production build. Store submission is blocked by Android signing, educational content corrections, and missing platform/distribution assets.

## Release Distance

The app is approximately **70% of the way to a safe public v1 release**.

Since the prior assessment, three P0 gameplay bugs were fixed (grammar summary, spot timer, content-loading error handling), one widget test was added, and error diagnostics were improved. The remaining blockers are primarily platform/packaging and content review.

For a small team the remaining work is roughly **1-2 weeks**: a few days for content review, a few days for store assets/signing/metadata, then device validation. Assumes Apple/Google developer accounts are ready and a branded icon/splash design can be supplied promptly.

## What Is Ready

- Home screen routes to Grammar and Spot-the-error games.
- Grammar rounds complete and display a score summary with replay.
- Spot timer is a single 60-second session across all five texts.
- Content-loading failures show Romanian error screens with retry.
- Content is bundled locally — no backend, accounts, or analytics.
- `flutter analyze` — no issues.
- `flutter test` — 30 tests passed (includes a widget test for full grammar round completion).
- `flutter build web --release` — successful.
- App versioning centrally derived from `pubspec.yaml` (`1.0.0+1`).

## P0: Must Fix Before Any Public Release

### 1. ~~Grammar completion never reaches its summary~~ ✅ Fixed

The `_playAgain()` call inside `_advance()` was removed. Completing all 15 questions now renders the score summary with a replay button. Verified by `test/games/grammar/grammar_screen_test.dart`.

### 2. ~~Spot timer does not match the product promise~~ ✅ Fixed

`nextText()` no longer resets `remainingSeconds`. `tick()` finishes the session when time expires regardless of current text. The timer now spans all five texts as advertised. Updated tests in `test/games/spot/spot_game_test.dart`.

### 3. Educational content contains incorrect or contradictory corrections

Several exercises mark valid sentences as invalid, retain an invalid correction, or contradict their own explanation. Examples include grammar records at `lib/content/grammar_exercises.json:348-362`, `655-675`, and `689-709`, plus a Spot correction/explanation conflict at `lib/content/spot_texts.json:829-839`.

**Release impact:** incorrect language guidance undermines the product's core value and will cause trust/review problems.

### 4. ~~Content-loading failures are unhandled~~ ✅ Fixed

Both screens now wrap `_init()` in try/catch with `mounted` guards, show a `LexioFeedback` error screen with retry, and emit `debugPrint` diagnostics.

### 5. Android release signing is not configured

The Android `release` build uses the debug signing configuration.

- `android/app/build.gradle.kts:28-33`

**Release impact:** Google Play will reject a debug-signed release artifact.

## P1: Complete Before Store Submission

- Replace default Flutter launcher icons across Android, iOS, macOS, and web. The Android launcher reference is in `android/app/src/main/AndroidManifest.xml:2-5`; web icon declarations are in `web/manifest.json:11-33`.
- Replace template/blank launch screens, especially the documented placeholder iOS launch asset at `ios/Runner/Assets.xcassets/LaunchImage.imageset/README.md:1-5`.
- Configure iOS distribution signing. Release currently uses `Apple Development` in `ios/Runner.xcodeproj/project.pbxproj:591-617`.
- Decide the supported platform matrix. README states iOS, Android, and web (`README.md:9`), while a macOS project also exists but has no distribution signing/notarization setup.
- Replace Flutter-template web metadata. `web/index.html:19-32` and `web/manifest.json:2-9` still use generic descriptions and Flutter-blue theme data.
- Create privacy, support, and store-submission material. The app opens DOOM links externally (`lib/design/doom.dart:4-9`), but no privacy policy or support/contact documentation is present.
- Add CI to run analysis, tests, and release builds. No checked-in CI/release workflow was found.
- ~~Add widget or integration coverage for both completed game flows~~ ✅ Partially done. Grammar now has a widget test for full-round completion. Spot and error states still lack widget/integration coverage.
- Correct Spot's summary wording, which says time expired even after manual completion: `lib/games/spot/widgets/spot_summary.dart:121-145`.
- Make the countdown deadline-based and lifecycle-safe. It currently decrements from `Timer.periodic` without lifecycle handling: `lib/games/spot/spot_screen.dart:43-55`.
- Handle failed `url_launcher` calls and show user feedback instead of silently ignoring them.

## P2: Recommended Quality Work

- Add semantic labels and keyboard/focus support to tap-only controls. Examples use `GestureDetector` in `lib/home/home_screen.dart:338-340` and `lib/games/spot/widgets/text_token.dart:35-42`.
- Test and adjust layouts at enlarged system text sizes; large fixed text and overlay labels can overlap in Spot.
- Enforce the documented design-token conventions. Hardcoded layout, timing, and style values appear in several game widgets.
- Align the roadmap with the actual state: it still lists unit tests as incomplete even though 30 tests exist (`ROADMAP.md:12-14`).
- Decide whether the home screen's four prominent "In curand" games are appropriate for v1 or should be less prominent until available.

## Verification Results

| Check | Result | Notes |
| --- | --- | --- |
| `flutter analyze` | Passed | No issues found. |
| `flutter test` | Passed | 30 tests passed. |
| `flutter build web --release` | Passed | Production web bundle built successfully. |
| `flutter build appbundle --release` | Not run | This environment has no Android SDK. Signing must be fixed first. |
| iOS/macOS distribution archive | Not verified | Distribution identities and notarization/release automation are not configured in the repository. |

## Release Gate

Proceed to an internal device beta only after P0 is resolved. Proceed to public web/store release only after P0 and P1 are resolved, branded assets and privacy/support materials are prepared, Android/iOS release artifacts are signed correctly, and a final smoke test passes on every supported platform.
