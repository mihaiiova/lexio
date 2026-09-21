## Review

**Acceptance-criteria matrix** (issue #46)

| # | Requirement (issue line) | Status | Evidence |
|---|---|---|---|
| R1 | "commit approved baseline changes separately or revert them" / "Do not treat `analysis_options.yaml` native-directory exclusions or `MACOSX_DEPLOYMENT_TARGET` 12.0 as accepted" | met | `analysis_options.yaml:13` only `build/**`; `macos/Runner.xcodeproj/project.pbxproj:474` still `10.15`; branch diff touches only the 15 #46 files. Working-tree cleanliness not shown — run `git status --porcelain` |
| R2 | "Re-run `flutter analyze`, `flutter test`, `python3 scripts/validate_content.py` … record … test count" | partial | Verification reports PASS/132; my enumeration of test declarations totals 132, but the issue says the tree "reports … 169 tests" — unexplained 50-test gap; mandated runner failed (`declare -A`) with no substitute evidence |
| R3 | "Preserve and verify the correct-answer progress … regressions" | met (game states) / partial (spot) | `grammar_game.dart:24`, `idioms_game.dart:63`, `vocabulary_game.dart:63`; tests `grammar_game_test.dart:103`, `idioms_game_test.dart:59`, `vocabulary_game_test.dart:61` |
| R4 | "…and `SpotGameState.isTextCompleted` regressions" | met | `spot_game.dart:59`; `spot_game_test.dart:141-151` |
| R5 | "durable across the critical answer → background/close path, including a deterministic flush/lifecycle seam" | partial | `user_progress.dart:184-196`, `grammar_screen.dart:48/55-59`, `idioms_screen.dart:57/64`, `vocabulary_screen.dart:61/68`, `spot_screen.dart:43/51-57`; typed `ProgressStorage` seam + `lifecycle_persistence_test.dart:16,47` — but only `IdiomsScreen` is lifecycle-tested |
| R6 | "regression tests for rapid answer sequences, failed writes/retries, flush ordering, and lifecycle-triggered persistence" | partial | `progress_repository_test.dart:80,131,30`; no retry of a failed snapshot (`:56-77` asserts only the later write) |
| R7 | "Unit-test `ProgressRepository`… with the existing controlled/failing storage fakes" | met | `progress_repository_test.dart:161-200` |
| R8 | "set spec `baseBranch` to `staging` and retain `releaseBranch` as `master`" | met | `.pi/settings.json:22-23`; `docs/releasing.md:42-43` |

**Findings**
- **P1** — spot notion correctness silently redefined, untested. Issue: *"Preserve and verify the correct-answer progress…"* `spot_screen.dart:180-199` now records `isCorrect = state.isTextCompleted(textIndex)` for **every** mistake in a text (previous code used `foundIndices.contains(i)`), so a mistake the learner actually found is persisted as *incorrect* when the text is incomplete, and duplicate notionIds are ANDed. No test touches `_saveSessionProgress`. Smallest fix: restore per-mistake correctness, or add a focused test pinning the intended semantics.
- **P2** — grammar `answer()` has no repeat guard (`grammar_game.dart:31-49`) unlike `idioms_game.dart:38` / `vocabulary_game.dart:38`, and no "ignores a second answer" test; with `progress = correctCount/length` this can exceed 1.0 and the a11y label (`grammar_screen.dart:250`) can exceed `exercises.length`. Screen guard `_hasAnswered` makes it unreachable in-app today.
- **P2** — a11y labels switched to `correctCount` (`grammar_screen.dart:250`, `idioms_screen.dart:225`, `vocabulary_screen.dart:229`) while the bar renders answered progress; untested and inconsistent.
- **P2** — R6 retry coverage and R5 non-idioms lifecycle wiring gaps (above).

**Merge verdict: OK with notes** (fix P1 test/semantics before release). Supervisor must run: `flutter analyze`, `flutter test` (record total), `python3 scripts/validate_content.py`, `git status --porcelain`.

Report path: `.pi/artifacts/spec-review/20260918T140806Z-81526/spec-review.md`