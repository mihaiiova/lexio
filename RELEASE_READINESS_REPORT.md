# Slove Release Readiness Report

**Assessment date:** 2026-08-06
**Recommendation:** Approaching release-ready. Remaining items are manual verification and human editorial review.

Slove has four playable Romanian-language games, a polished design system, local persistence, deadline-based timing, comprehensive tests, and checked-in CI/CD workflows. The app is approaching v1 readiness, but the workflows and release artifacts still need external verification.

## Release Distance

The app is approximately **85% of the way to a safe public v1 release**.

The remaining work is a final smoke test across real devices, qualified editorial review of Romanian content, configured hosting, and verified signed release artifacts.

## What Is Ready

- **4 complete games**: Grammar (423 exercises), Vocabulary (100), Idioms (60), Spot (60 texts)
- **Design system**: Centralized tokens (colors, typography, spacing, radius, shadows, animations)
- **Local persistence**: Spaced repetition via SharedPreferences
- **Error handling**: Romanian error screens with retry for all games
- **Deadline-based timer**: Spot uses wall-clock time, respects app lifecycle
- **Content validation**: Automated structural validation script (`scripts/validate_content.py`)
- **CI/CD configuration**: Analyze + Test + Web build + Android AAB on every push; release and TestFlight workflows are checked in but await a successful hosted run with secrets
- **Flutter SDK pinned**: `.tool-versions` at 3.44.5, all workflows use exact version
- **Store listings**: Draft App Store and Google Play text content (Romanian)
- **Web PWA**: Updated manifest, OG tags, robots.txt, and branded web assets ready for deployment
- **Brand assets**: Generated icon set and updated launch-screen sources require final platform visual verification
- **Privacy/support**: Static pages are ready for deployment at `https://lexio.app/confidentialitate` and `https://lexio.app/asistenta`
- **Tests**: 36+ tests covering game logic, content validation, integration flows

## What Was Fixed Since Last Report

| Issue | Status |
|---|---|
| Grammar round summary unreachable | ✅ Fixed |
| Spot timer not spanning all texts | ✅ Fixed |
| Content-loading failures unhandled | ✅ Fixed |
| w116 explanation contradiction (foarfece/foarfeci) | ✅ Fixed |
| Spot timer deadline-based + lifecycle-safe | In local verification (#18) |
| Default Flutter icons replaced | In local verification (#17) |
| Web metadata (manifest colors, OG, robots.txt) | Ready for deployment (#15) |
| Flutter SDK pinned, CI builds web + Android | Awaiting hosted CI verification (#19) |
| Spot full-flow integration coverage | In local verification (#20) |
| Store listing content created | Drafted; requires store-console work (#14) |
| Content validation script + editorial checklist | Implemented; human review pending (#16) |
| Documentation refreshed (README, ROADMAP, this report) | In local verification (#21) |

## Remaining for v1

### P1: Manual Verification

- [ ] Run smoke test on real iPhone and iPad (all 4 games, offline, background/resume)
- [ ] Run smoke test on real Android phone and tablet
- [ ] Verify web build on desktop Chrome/Safari and mobile browsers
- [ ] Test PWA installation on Android and iOS
- [ ] Verify signed AAB matches tested version

### P2: Content Quality

- [ ] Complete editorial review by a qualified Romanian speaker
- [ ] Resolve `common_error_pairs.json` p121 foarfece/foarfeci — verify against DOOM3
- [ ] Fill spot text_023 numbering gap (or renumber)

### P3: Polish

- [ ] Add semantic labels and keyboard/focus support for accessibility
- [ ] Test at enlarged system text sizes
- [ ] Handle failed `url_launcher` calls with user feedback

## Verification Results

| Check | Result | Notes |
|---|---|---|
| `flutter analyze` | Passed | One pre-existing unused import fixed. |
| `flutter test` | Passed | 119 tests (grammar, Spot, vocabulary, progress, semantics, content). |
| `flutter build web --release` | Passed | Production web bundle built locally on 2026-08-06. |
| `flutter build appbundle --release` | Not run | Android SDK is unavailable locally; checked-in CI builds an unsigned AAB on push. |
| iOS distribution archive | Not verified | Release workflow needs repository secrets and a successful hosted run. |
| Content structural validation | Passed | 849 items across 6 files — all valid. |

## Release Gate

Proceed to public web/store release after:
1. Final cross-platform smoke test passes (#22)
2. Qualified editorial review confirms content quality (#16 human review)
3. Store assets (screenshots, feature graphic) are prepared
4. Signed release artifacts are verified on target devices
