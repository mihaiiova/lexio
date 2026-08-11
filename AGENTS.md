# AGENTS.md — Slove Agent Development Guide

This file is the single source of truth for any coding agent working on this project. Follow these rules precisely.

## Conventions

### Language
- All code, comments, and docs in English
- All user-facing strings in Romanian
- All exercise content in Romanian

### File naming
- `snake_case` for files and directories
- `lib/games/<game_name>/` for each game module

### Code style
- `PascalCase` for classes, enums, typedefs
- `camelCase` for methods, variables, constants
- Prefix private members with `_`
- Use `const` constructors whenever possible
- Prefer `final` over `var` by default

### Imports
- Always use relative imports within the project (`import '../design/colors.dart'`)
- Group imports: dart SDK first, then packages, then project files
- Never use `package:lexio/` imports for internal files

### Widget structure
- Extract reusable UI into `lib/design/components/`
- Keep screens composable — break into private widget methods or separate files
- Use `LexioTextStyles`, `LexioColors`, `LexioSpacing` instead of hardcoded values

### State management
- Keep state local to the screen that owns it
- Use `StatefulWidget` for screen-level state
- No external state management libraries unless there's a clear need

## Design System

### Values MUST come from design tokens

| Token file | Class | Examples |
|---|---|---|
| `lib/design/colors.dart` | `LexioColors` | `LexioColors.primary`, `LexioColors.background` |
| `lib/design/typography.dart` | `LexioTextStyles` | `LexioTextStyles.headingMedium` |
| `lib/design/spacing.dart` | `LexioSpacing` | `LexioSpacing.xl`, `LexioSpacing.cardPadding` |
| `lib/design/radius.dart` | `LexioRadius` | `LexioRadius.xl` |
| `lib/design/shadows.dart` | `LexioShadows` | `LexioShadows.cardCombined` |
| `lib/design/animations.dart` | `LexioDurations`, `LexioCurves` | `LexioDurations.normal` |

### NEVER hardcode
- Colors
- Font sizes
- Padding/margin values
- Border radius
- Animation durations

### Components in `lib/design/components/`
- `LexioCard` — surface container with shadow
- `LexioButton` — primary/secondary/ghost/danger with sizes
- `LexioFeedback` — success/error/warning/info message

## Game Architecture

### Game interface (`lib/games/game_interface.dart`)
Every game must implement:
```dart
abstract class LexioGame {
  String get id;
  String get title;
  String get description;
  String get emoji;
  Color? get accentColor;
  Widget buildScreen(BuildContext context);
}
```

### Game module structure
```
games/<name>/
  <name>_screen.dart       # Main game screen
  <name>_game.dart          # Game state/logic (immutable)
  <name>_content.dart       # Content loading from JSON
  widgets/                  # Game-specific UI components
```

### Content format
- Store exercises in `lib/content/<name>_exercises.json`
- Each content file should have its own loader class in the game module
- Content files are loaded via `rootBundle.loadString()`

### State model
- Use immutable state classes (all fields `final`, `const` constructor)
- Each action returns a new state: `state.answer(...)`, `state.next()`
- Screen rebuilds from new state via `setState`

## Adding a game — checklist
1. Create directory `lib/games/<name>/`
2. Create content JSON in `lib/content/`
3. Implement content loader
4. Implement game state class
5. Implement game screen
6. Create any custom widgets in `widgets/`
7. Add to home screen in `lib/home/home_screen.dart`
8. Run `flutter analyze` — must pass with zero errors
9. Run app and test manually

## Testing
- Test files live in `test/`
- Mirror the `lib/` structure
- Test: game state logic, content parsing
- Widget tests: game screens, design components

## Project Organization

Task tracking and release planning live in **GitHub Issues**, not in markdown docs. When working on a feature or bugfix, reference the issue number in commits and PRs.

- **Release tracking:** `RELEASE_READINESS_REPORT.md` — summary + links to issues
- **Roadmap:** `ROADMAP.md` — long-term vision with links to active issues
- **Store checklists:** `store_listings/` — reference docs for smoke tests and editorial review; actual progress is in issues

Do NOT update status/progress directly in markdown docs — close the GitHub Issue instead.

After each feature or development round, run `/skill:review` to score the conversation and implement improvements to how we work.

## Commands
```bash
flutter pub get          # Install dependencies
flutter run              # Run the app
flutter analyze          # Static analysis
flutter test             # Run tests
```

## Do NOT
- Add new dependencies without strong justification
- Use `package:lexio/` imports for internal files
- Hardcode any design values
- Add comments that explain "what" — only "why" if non-obvious
- Introduce state management libraries
- Add backend calls, auth, databases, or APIs
