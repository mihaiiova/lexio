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
| Grammar | Corect sau greșit? | True/false grammar challenge | 423 |
| Vocabulary | Ce înseamnă? | Multiple-choice definitions | 100 |
| Idioms | Vorba vine | Expression meaning | 60 |
| Spot | Găsește greșeala | Timed error-finding (60s) | 60 texts |

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
    game_interface.dart        # Contract for each game
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

- Each game is an isolated module behind a common interface (`LexioGame`)
- Design tokens are centralized — changing fonts/colors needs edits in one place
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
flutter test      # Unit + widget + integration tests
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

- **CI** (`.github/workflows/ci.yml`): Analyze → Test → Build Web → Build Android (AAB)
- **Release** (`.github/workflows/release.yml`): Tag-triggered builds for all platforms
- **TestFlight** (`.github/workflows/deploy.yml`): Manual iOS deploy to TestFlight

## Privacy

- The Romanian privacy policy is available from the home-screen footer.
- The canonical policy text is stored in `store_listings/privacy_policy.md`.
- Android and iOS Firebase configuration is checked in. Web and macOS analytics
  are not configured.

## License

All rights reserved. © 2026 Slove.
