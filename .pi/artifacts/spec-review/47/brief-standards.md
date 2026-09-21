# Standards Review Brief

Read-only review. Do not modify any files. This standard applies to every file in the diff.

## Review mode

Branch diff. Base = `staging` (merge-base `e1dda781df763ad63c4a9c5afa3236f379c107e5`), HEAD = `a4cb99b`. Exact diff command: `git diff staging...HEAD`.

## Your inputs (read these files)

- Patch (full diff, 1244 lines): `/Users/m/dev/lexio/.pi/artifacts/spec-review/47/packet/diff.patch`
- Commit list: `/Users/m/dev/lexio/.pi/artifacts/spec-review/47/packet/commits.txt`
- Diff stat: `/Users/m/dev/lexio/.pi/artifacts/spec-review/47/packet/diffstat.txt`

## Changed files

- lib/analytics/game_session_analytics.dart
- lib/design/components/lexio_incorrect_answer_card.dart
- lib/games/grammar/grammar_screen.dart
- lib/games/idioms/idioms_screen.dart
- lib/games/spot/spot_screen.dart
- lib/games/vocabulary/vocabulary_screen.dart
- lib/home/home_screen.dart
- test/accessibility/responsive_test.dart (new)
- test/accessibility/semantics_test.dart
- test/analytics/game_session_analytics_test.dart (new)
- test/games/grammar/grammar_screen_injection_test.dart (new)
- test/games/spot/spot_screen_injection_test.dart (new)
- test/home/home_screen_test.dart (new)

## Standards sources (read each)

- `/Users/m/dev/lexio/AGENTS.md` — primary coding standards
- `/Users/m/dev/lexio/DESIGN.md` — design tokens
- `/Users/m/dev/lexio/ARCHITECTURE.md` — architecture / state pattern
- `/Users/m/dev/lexio/README.md` — commands

## Smell baseline (read)

`/Users/m/dev/pi-config/skills/code-review/references/smell-baseline.md`

## Validation evidence (already run — do not re-run)

- `flutter analyze` → No issues found
- `flutter test` → 170 tests passed
- `python3 scripts/validate_content.py` → ALL CONTENT PASSES STRUCTURAL VALIDATION

## Brief

Report, per file/hunk where relevant:

(a) every place the diff violates a documented standard — cite the standard (file + the rule);
(b) any baseline smell you spot — name it and quote the hunk.

Distinguish hard violations from judgement calls: documented-standard breaches can be hard; baseline smells are always judgement calls; a documented repo standard overrides the baseline. Skip anything tooling already enforces. Keep under 400 words.
