# Slove

Beautiful Romanian word games. Calm, minimalist, typography-first.

## Overview

Slove is a collection of premium word games for the Romanian language — the "NYT Games for Romanian". Four interactive games: grammar correction, vocabulary definitions, Romanian idioms, and find-the-mistake texts.

**Platforms**: iOS, Android

## Quick Start

```bash
flutter pub get
flutter run
```

## Games

| Game | Romanian Title | Type | Exercises |
|---|---|---|---|
| Grammar | Corect sau greșit? | True/false grammar challenge | 511 generated exercises |
| Vocabulary | Ce înseamnă? | Multiple-choice definitions | 100 |
| Idioms | Vorba vine | Expression meaning | 60 |
| Spot | Găsește greșeala | Timed error-finding (60s) | 59 texts |

## Public content

The full Romanian content (words, idioms, grammar pairs, and spot texts) is
published in [`content_public/`](content_public/README.md) for editorial review.
Regenerate after content changes:

```bash
python3 scripts/generate_public_pages.py
```

## Project Structure

```
lib/
  main.dart                    # Entry point
  app/                         # App shell, routing
  design/                      # Design system
    theme.dart                 # Centralized theme
    colors.dart                # Color tokens
    typography.dart            # Type scale
    spacing.dart               # Spacing scale
    radius.dart                # Border radius tokens
    shadows.dart               # Shadow tokens
    animations.dart            # Animation durations & curves
    components/                # Reusable UI components (LexioButton, LexioCard, LexioFeedback)
  games/                       # All games
    grammar/                   # Grammar game — Corect sau greșit?
    vocabulary/                # Vocabulary game — Ce înseamnă?
    idioms/                    # Idioms game — Vorba vine
    spot/                      # Spot game — Găsește greșeala
  home/                        # Home screen
  content/                     # Local exercise data (JSON)
  progress/                    # Local progress persistence (SharedPreferences, spaced repetition)
```

## Design Principles

- **Typography-first**: Large, readable text with generous spacing
- **Minimalist**: Only essential UI chrome
- **Calm**: Gentle colors, subtle animations
- **Premium**: Clean cards, consistent spacing, refined details
- **Fast**: Local content and progress with lightweight usage analytics

## Architecture Decisions

- Each game is an isolated module; the home catalogue owns its navigation metadata
- Design tokens are centralized — changing fonts, colors, spacing, radii, or animation timing needs edits in one place
- Content is stored as local JSON for easy addition of thousands of exercises
- **Local persistence**: Progress tracked via `SharedPreferences` with spaced repetition
- **No backend or auth** — learning content and progress remain local
- **Privacy-conscious analytics**: Firebase records only game-open events; ad storage, ad personalization, and ad user data are disabled
- **Deadline-based timer**: Spot game uses wall-clock deadlines, not callback counting
- **Lifecycle-safe**: App respects background/foreground transitions (WidgetsBindingObserver)
- **Brand**: Primary blue `#4588E0`, NoticiaText font family, white surfaces

## Testing

```bash
flutter analyze   # Static analysis — zero warnings
flutter test      # Unit and widget tests under test/
flutter drive --driver test_driver/integration_test.dart --target integration_test/screenshot_test.dart  # Device screenshot workflow
```

Test structure:
```
test/
  design/          # Design component tests
  games/
    grammar/       # Grammar game tests
    spot/          # Spot game tests (logic + integration + content)
    vocabulary/    # Vocabulary game tests
  progress/        # Spaced repetition logic
  accessibility/   # Semantics tests
integration_test/
  screenshot_test.dart  # Device-only screenshot capture workflow
```

Content validation:
```bash
python3 scripts/validate_content.py
```

## Dependencies

- **flutter**: UI framework
- **shared_preferences**: Local progress storage
- **url_launcher**: External DOOM dictionary links
- **flutter_localizations**: Romanian locale support
- **firebase_core / firebase_analytics**: Anonymous game usage statistics

## CI/CD

- **CI** (`.github/workflows/ci.yml`): Analyze → unit/widget tests → Build Web → Build Android (AAB) — runs on PRs and feature-branch pushes
- **Screenshot integration test**: run manually on a connected device or emulator; it captures store-review assets and is not a CI release gate
- **Staging** (`.github/workflows/deploy-staging.yml`): push to `staging` → TestFlight + Play internal testing
- **Production** (`.github/workflows/deploy-prod.yml`): push to `master` → App Store Connect + Play production

See [`docs/releasing.md`](docs/releasing.md) for how to version, test, and ship updates.

## Privacy

- The Romanian privacy policy is available from the home-screen footer.
- The canonical policy text is stored in `store_listings/privacy_policy.md`.
- Android and iOS Firebase configuration is checked in. Web and macOS analytics
  are not configured.

## License

All rights reserved. © 2026 Slove.
