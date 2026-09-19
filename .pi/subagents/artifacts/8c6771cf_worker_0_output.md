I have the full diff and all new files. Here is the Spec-axis review.

## Spec review findings

**(a) Missing / partial**

- **#39 — token cleanup is partial (medium).** Acceptance says "UI values covered by the token policy use design tokens." Several flagged UI files still hardcode sizes/spacing/radii/durations after this diff:
  - `lib/games/grammar/grammar_screen.dart`: progress-bar `height: isCurrent ? 4 : 3`, checkmark `size: 80`, `Offset(0, 12 * (1 - value))`, border `width: LexioSpacing.xxs`.
  - `lib/games/grammar/widgets/result_overlay.dart`: `Offset(0, 20 * (1 - value))`, `height: 1.5`, `decorationThickness: 2` (unchanged).
  - `lib/design/components/lexio_button.dart`: spinner `height: 16`, `strokeWidth: 2`, icon `textStyle.fontSize! + 2`.
  - `lib/design/components/lexio_feedback.dart`: `Icon(size: 20)`.
  The issue background names "sizes, spacing, radii, and animation durations" as the drift; the diff tokenizes the Spot path, button, card, and grammar page duration, but leaves these untouched, so the acceptance criterion is only partially met.

**(b) Scope creep / out-of-scope hunks**

- `AGENTS.md` (`/skill:review` → `/skill:review-session`) and the `.pi/skills/review/*` deletions are unrelated to #36–#39 (pre-existing workspace state).
- `pubspec.yaml`/`pubspec.lock` adds `integration_test` (dev) plus transitive `flutter_driver`/`webdriver`/`sync_http`/`process`. This supports the pre-existing screenshot suite rather than #39's cleanup, but it is additive dependency surface not required by any of the four issues.

**(c) Looks wrong**

- None blocking. #36 write chaining is correctly ordered and error-swallowed (`_writeSnapshot` catches, so the `.then` chain never breaks); #37 guards are consistent (empty → unchanged/empty-screen before `currentExercise`/`currentText`); #38 keeps the existing event names/params and enforces exactly-once via `_active`/`_ended`/timer-dedup. No requirement appears implemented incorrectly.