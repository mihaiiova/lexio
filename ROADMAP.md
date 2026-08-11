# ROADMAP.md — Slove Development Roadmap

## v1.0 — Foundation ✅ Complete

- [x] Project structure and conventions
- [x] Design system (typography, colors, spacing, components)
- [x] Game architecture with `LexioGame` interface
- [x] Home screen with four playable games
- [x] Grammar game: "Corect sau greșit?" (423 exercises)
- [x] Vocabulary game: "Ce înseamnă?" (100 exercises)
- [x] Idioms game: "Vorba vine" (60 exercises)
- [x] Spot game: "Găsește greșeala" (60 texts, 60s timed)
- [x] Local JSON content layer
- [x] Spaced repetition progress tracking (SharedPreferences)
- [x] Subtle animations (page transitions, answer feedback, progress)
- [x] Unit tests for game logic and content parsing
- [x] Widget tests for screens and components
- [x] Deadline-based Spot timer (wall-clock vs callback counting)
- [x] Lifecycle-safe timer (WidgetsBindingObserver)
- [x] Error handling with Romanian error screens and retry
- [x] Privacy and support pages (lexio.app)
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
- [x] Web PWA metadata (manifest, OG tags, robots.txt)
- [ ] Check Firebase Analytics events in Google Analytics after a fresh iOS and Android install
- [ ] Review and correct the "Confidențialitate" footer and privacy-screen wording
- [ ] Complete the release smoke-test checklist on iPhone, iPad, Android phone, Android tablet, and web
- [ ] Test the signed iOS TestFlight build and Android internal-testing build on target devices
- [ ] Complete qualified editorial review of all Romanian content (human review needed)
- [ ] Prepare and upload App Store and Google Play screenshots, feature graphics, and store metadata
- [ ] Publish the privacy-policy URL and add it to both store listings
- [ ] Verify the release CI workflows produce signed, version-matched artifacts
- [ ] Submit builds to TestFlight and the Google Play internal-testing track, then resolve review feedback

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
