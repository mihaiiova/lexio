## Standards review

### HARD (documented-standard breaches)

- **`AGENTS.md` still documents the deleted `LexioGame` interface.** The diff removes `lib/games/game_interface.dart` and updates README/ARCHITECTURE/ROADMAP, but `AGENTS.md` → "Game Architecture → Game interface" still states "Every game must implement" the `LexioGame` abstract class and cites `lib/games/game_interface.dart`. `AGENTS.md` is the repo's declared "single source of truth", so it now mandates an interface that no longer exists — a self-inconsistency.

### JUDGEMENT calls

- **Residual hardcoded sizes/offsets (token-policy spirit + issue scope).** `lib/games/grammar/grammar_screen.dart` `height: isCurrent ? 4 : 3` (L295), `size: 80` (L358), `Offset(0, 12 * (1 - value))` (L387); `lib/games/spot/spot_screen.dart` `height: isCurrent ? 4 : 3` (L393); `lib/games/grammar/widgets/result_overlay.dart` `Offset(0, 20*…)`, `height: 1.5` (×4). The pass tokenized font/padding/radius/duration but not sizes/offsets/line-heights. AGENTS.md's "NEVER hardcode" enumerates colors/font-sizes/padding/radius/durations — so these are not hard breaches, but #39's goal listed "sizes".
- **Duplicated Code — `_buildEmptyScreen`.** Nearly identical to the pre-existing `_buildErrorScreen` (Scaffold+SafeArea+Center+Padding+`LexioFeedback`) in both `grammar_screen.dart` and `spot_screen.dart`, and duplicated across the two screens. A shared empty-state component would remove it.
- **Import-policy tension.** New tests use relative `../../lib/` imports with `// ignore: avoid_relative_lib_imports`; existing sibling tests (`grammar_game_test`, `spot_game_test`, `grammar_screen_test`) use `package:lexio/…`. AGENTS.md mandates relative and bans `package:lexio/`, but the lint rule contradicts it — worth resolving.
- **Divergent Change (mild).** Spot-specific tokens (`tokenVertical`, `tokenCorrectionOffset`, `feedbackOffset`, `spotText`, `spotCorrection`, `overline`) leak game concepts into the global `LexioSpacing`/`LexioTextStyles`.
- **Silent `catch (_) {}`** in `_writeSnapshot` (`lib/progress/user_progress.dart`) — swallows failures with no `debugPrint`, unlike `AnalyticsService`.
- **Redundant `setState` during `initState`** in spot `_init`'s `suppliedTexts` branch (legal, but inconsistent with grammar's direct field assignment).