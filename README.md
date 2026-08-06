# Slove

Beautiful Romanian word games. Calm, minimalist, typography-first.

## Overview

Slove is a collection of premium word games for the Romanian language — the "NYT Games for Romanian". The first game is a grammar challenge; more games (vocabulary, spelling, idioms, logic) are planned.

**Platforms**: iOS, Android, Web

## Quick Start

```bash
flutter pub get
flutter run
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
    components/                # Reusable UI components
  games/                       # All games
    game_interface.dart        # Contract for each game
    grammar/                   # Grammar game
  home/                        # Home screen
  content/                     # Local exercise data (JSON)
```

## Design Principles

- **Typography-first**: Large, readable text with generous spacing
- **Minimalist**: Only essential UI chrome
- **Calm**: Gentle colors, subtle animations
- **Premium**: Clean cards, consistent spacing, refined details
- **Fast**: Minimal dependencies, local data, no network calls

## Architecture Decisions

- Each game is an isolated module behind a common interface (`LexioGame`)
- Design tokens are centralized — changing fonts/colors needs edits in one place
- Content is stored as local JSON for easy addition of thousands of exercises
- No backend, no auth, no persistence — pure local experience

## Adding a New Game

1. Create a directory under `lib/games/yourgame/`
2. Implement the `LexioGame` interface from `lib/games/game_interface.dart`
3. Add content JSON to `lib/content/`
4. Register on the home screen

See `lib/games/grammar/` for the reference implementation.

## Dependencies

- **google_fonts**: Premium typography (Playfair Display + DM Sans)
- **cupertino_icons**: iOS-style icons
