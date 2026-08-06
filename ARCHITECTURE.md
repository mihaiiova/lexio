# ARCHITECTURE.md — Slove Architecture

## Layers

```
┌──────────────────────────────┐
│  Screens (Home, Game)        │  UI layer
├──────────────────────────────┤
│  Game State + Logic           │  Business logic layer
├──────────────────────────────┤
│  Content Loader (JSON)        │  Data layer
└──────────────────────────────┘
```

### UI Layer
- **Home Screen** (`lib/home/home_screen.dart`): Game catalog, navigation
- **Game Screens** (`lib/games/<name>/<name>_screen.dart`): Each game's UI

### Logic Layer
- **Game State** (`lib/games/<name>/<name>_game.dart`): Immutable state classes
- **Game Interface** (`lib/games/game_interface.dart`): Contract for all games

### Data Layer
- **Content Loader** (`lib/games/<name>/<name>_content.dart`): Loads and caches JSON
- **Content Files** (`lib/content/*.json`): Raw exercise data

## Game Architecture

Each game follows this pattern:

```
games/<name>/
  <name>_screen.dart       # StatefulWidget, owns state, renders UI
  <name>_game.dart          # Pure Dart, immutable state, action methods
  <name>_content.dart       # Loader class (load, shuffle, getDaily)
  widgets/                  # Game-specific reusable widgets
```

### State Pattern

```dart
class GameState {
  final List<Exercise> exercises;
  final int currentIndex;
  final bool? lastAnswerCorrect;
  final bool isFinished;

  const GameState({...});    // All final, const constructor

  GameState answer(...) {...}  // Returns new state
  GameState next() {...}       // Returns new state
}
```

- State is immutable
- Each action creates a new state
- Screen calls `setState(() => _state = _state.answer(...))`

## Design System

All design values flow from a single set of token files:

```
design/
  theme.dart                # ThemeData builder (uses all tokens)
  colors.dart               # LexioColors
  typography.dart           # LexioTextStyles
  spacing.dart              # LexioSpacing
  radius.dart               # LexioRadius
  shadows.dart              # LexioShadows
  animations.dart           # LexioDurations, LexioCurves
  components/               # LexioCard, LexioButton, LexioFeedback
```

### Theme Generation

`LexioTheme.light` in `lib/design/theme.dart` takes all tokens and produces a complete `ThemeData`. Changing any token file immediately affects the entire app.

## Content Strategy

- All exercises stored as JSON in `lib/content/`
- Each game has its own content file: `<name>_exercises.json`
- Content loaded via `rootBundle.loadString()` (bundled at build time)
- Loader classes cache parsed data in memory
- Makes it easy to add thousands of exercises later (just add JSON entries)

### JSON Schema for Exercises

```json
[
  {
    "id": "unique-id",
    "sentence": "...",
    "isCorrect": true,
    "explanation": "..."
  }
]
```

Fields vary by game type but follow the same array-of-objects pattern.

## Adding a Game

1. Create `lib/games/<name>/` with screen, game, content, widgets
2. Implement the `LexioGame` interface
3. Create content JSON in `lib/content/`
4. Add a card to `HomeScreen`'s `_buildTodaySection` or `_buildComingSoon`

## Technical Constraints

- **No dependencies** beyond Flutter SDK, cupertino_icons, google_fonts
- **No package:lexio imports** — always use relative paths
- **No state management library** — simple StatefulWidget + setState
- **No code generation** — manual fromJson/toJson
- **No network** — all content is local JSON
