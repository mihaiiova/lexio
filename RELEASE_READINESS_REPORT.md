# Lexio Release Readiness Report

**Assessment date:** 2026-07-29  
**Recommendation:** Do not submit to public app stores yet.

Lexio has a coherent v1 product foundation: two playable Romanian-language games, local content, a polished visual system, and a successful web production build. It is not release-ready because core gameplay completion behavior is broken, parts of the educational corpus are incorrect, and mobile distribution setup remains template/incomplete.

## Release Distance

The app is approximately **60% of the way to a safe public v1 release**.

For a small, focused team, the remaining work is roughly **2-4 weeks**: one week for product and content blockers, one week for store assets/signing/policy work, then 3-5 days for device validation and release-candidate fixes. This estimate assumes Apple/Google developer accounts are already available and a branded icon/splash design can be supplied promptly.

A limited web preview is closer, but it should still wait for the gameplay and content blockers below. Store submission should wait for every P0 and P1 item.

## What Is Ready

- The home screen routes to Grammar and Spot-the-error games.
- Content is bundled locally and the application works without a backend, accounts, or analytics.
- State-level tests and Spot corpus-integrity validation are in place.
- `flutter analyze` completed with no issues.
- `flutter test` passed all 29 tests.
- `flutter build web --release` completed successfully.
- App versioning is centrally derived from `pubspec.yaml` (`1.0.0+1`).

## P0: Must Fix Before Any Public Release

### 1. Grammar completion never reaches its summary

When the final grammar answer is submitted, `_advance()` creates a finished state and immediately replaces it with a new round. The implemented score summary is therefore unreachable.

- Affected code: `lib/games/grammar/grammar_screen.dart:70-82`
- Unreachable summary branch: `lib/games/grammar/grammar_screen.dart:109-118`

**Release impact:** users cannot complete the primary game loop or view their result.

### 2. Spot timer does not match the product promise

The home card advertises five texts in 60 seconds, but the timer resets after each text. A complete session can take almost five minutes.

- Product promise: `lib/home/home_screen.dart:388-406`
- Timer reset: `lib/games/spot/spot_game.dart:168-191`

**Release impact:** the timed game behaves materially differently from its advertised rule.

### 3. Educational content contains incorrect or contradictory corrections

Several exercises mark valid sentences as invalid, retain an invalid correction, or contradict their own explanation. Examples include grammar records at `lib/content/grammar_exercises.json:348-362`, `655-675`, and `689-709`, plus a Spot correction/explanation conflict at `lib/content/spot_texts.json:829-839`.

**Release impact:** incorrect language guidance undermines the product's core value and will cause trust/review problems.

### 4. Content-loading failures are unhandled

Grammar and Spot await JSON assets without an error state, retry path, or `mounted` guard before calling `setState`.

- Grammar: `lib/games/grammar/grammar_screen.dart:37-44`
- Spot: `lib/games/spot/spot_screen.dart:33-41`

**Release impact:** an asset issue or a user leaving during loading can leave a broken screen or cause a framework error.

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
- Add widget or integration coverage for both completed game flows, loading failure, timeout, replay, and external-link failure. Current test coverage does not exercise these journeys.
- Correct Spot's summary wording, which says time expired even after manual completion: `lib/games/spot/widgets/spot_summary.dart:121-145`.
- Make the countdown deadline-based and lifecycle-safe. It currently decrements from `Timer.periodic` without lifecycle handling: `lib/games/spot/spot_screen.dart:43-55`.
- Handle failed `url_launcher` calls and show user feedback instead of silently ignoring them.

## P2: Recommended Quality Work

- Add semantic labels and keyboard/focus support to tap-only controls. Examples use `GestureDetector` in `lib/home/home_screen.dart:338-340` and `lib/games/spot/widgets/text_token.dart:35-42`.
- Test and adjust layouts at enlarged system text sizes; large fixed text and overlay labels can overlap in Spot.
- Enforce the documented design-token conventions. Hardcoded layout, timing, and style values appear in several game widgets.
- Align the roadmap with the actual state: it still lists unit tests as incomplete even though 29 tests exist (`ROADMAP.md:12-14`).
- Decide whether the home screen's four prominent "In curand" games are appropriate for v1 or should be less prominent until available.

## Verification Results

| Check | Result | Notes |
| --- | --- | --- |
| `flutter analyze` | Passed | No issues found. |
| `flutter test` | Passed | 29 tests passed. |
| `flutter build web --release` | Passed | Production web bundle built successfully. |
| `flutter build appbundle --release` | Not run | This environment has no Android SDK. Even with an SDK, signing must be fixed first. |
| iOS/macOS distribution archive | Not verified | Distribution identities and notarization/release automation are not configured in the repository. |

## Release Gate

Proceed to an internal device beta only after P0 is resolved and the main user flows are covered by widget/integration tests. Proceed to public web/store release only after P0 and P1 are resolved, branded assets and privacy/support materials are prepared, Android/iOS release artifacts are signed correctly, and a final smoke test passes on every supported platform.
