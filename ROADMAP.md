# ROADMAP.md — Slove Development Roadmap

## v1.0 — Foundation ✅ Complete

- [x] Project structure and conventions
- [x] Design system (typography, colors, spacing, components)
- [x] Isolated game modules with immutable local state
- [x] Home screen with four playable games
- [x] Grammar game: "Corect sau greșit?" (511 generated exercises)
- [x] Vocabulary game: "Ce înseamnă?" (100 exercises)
- [x] Idioms game: "Vorba vine" (60 exercises)
- [x] Spot game: "Găsește greșeala" (59 texts, 60s timed)
- [x] Local JSON content layer
- [x] Spaced repetition progress tracking (SharedPreferences)
- [x] Subtle animations (page transitions, answer feedback, progress)
- [x] Unit tests for game logic and content parsing
- [x] Widget tests for screens and components
- [x] Deadline-based Spot timer (wall-clock vs callback counting)
- [x] Lifecycle-safe timer (WidgetsBindingObserver)
- [x] Error handling with Romanian error screens and retry
- [x] In-app privacy policy
- [x] App Store and Google Play store listing content
- [x] Branded icons and launch screens
- [x] CI/CD: analysis, tests, web and Android builds
- [x] Romanian locale and language metadata

## v1.1 — Launch Polish (Current)

- [x] Editorial review infrastructure (validation script, checklist)
- [x] Replace default Flutter launcher icons with branded "S"
- [x] Pin Flutter SDK version and verify release builds
- [x] Spot full-flow integration test coverage
- [x] Refresh project documentation (README, ROADMAP, release report)
- [ ] Check Firebase Analytics events — [#33](https://github.com/mihaiiova/lexio/issues/33)
- [ ] Review "Confidențialitate" footer wording — [#32](https://github.com/mihaiiova/lexio/issues/32)
- [ ] Smoke-test on real devices — [#25](https://github.com/mihaiiova/lexio/issues/25)
- [ ] Test signed TestFlight and Play Store builds — [#29](https://github.com/mihaiiova/lexio/issues/29)
- [ ] Editorial review of all Romanian content — [#26](https://github.com/mihaiiova/lexio/issues/26)
- [ ] Prepare store screenshots and feature graphics — [#30](https://github.com/mihaiiova/lexio/issues/30)
- [ ] Publish privacy-policy URL — [#31](https://github.com/mihaiiova/lexio/issues/31)
- [ ] Verify CI produces signed, version-matched artifacts — [#29](https://github.com/mihaiiova/lexio/issues/29)
- [ ] Submit to TestFlight and Google Play — [#35](https://github.com/mihaiiova/lexio/issues/35)

## v2.0 — Content Expansion

- [ ] Expand vocabulary to 200+ exercises
- [ ] Expand idioms to 100+ expressions
- [ ] Add Spot texts with new error categories
- [ ] Grammar difficulty calibration based on user data

## v3.0 — Social & Persistence

- [ ] Daily streak tracking
- [ ] Share results as images
- [ ] Cross-device progress sync (evaluate carefully)

## Future Ideas

- Audio pronunciation challenges
- Regional dialect mini-games
- Seasonal/holiday content packs
- Crossword puzzles
- Word chains / anagram challenges

## Non-Goals

These are explicitly out of scope:

- Accounts / authentication
- Cloud sync / backend (beyond simple progress export)
- Monetization / payments
- Advertising and cross-app tracking
- Social features (beyond simple sharing)
- AI-generated content
- Localization (the app IS Romanian)
- Web release (the web build remains a CI/dev convenience only)
