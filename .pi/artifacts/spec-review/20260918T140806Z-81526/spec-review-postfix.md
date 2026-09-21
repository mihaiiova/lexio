## Review — branch vs issue #46 (post-fix)

**Acceptance-criteria matrix**

| # | Requirement (issue #46) | Status | Evidence |
|---|---|---|---|
| R1 | "commit approved baseline changes separately or revert them"; "Do not treat `analysis_options.yaml` native-directory exclusions or `MACOSX_DEPLOYMENT_TARGET` 12.0 as accepted" | met | `analysis_options.yaml:13` excludes only `build/**`; `macos/Runner.xcodeproj/project.pbxproj:474` still `10.15`; branch diff = 15 files, none native/config |
| R2 | "Re-run `flutter analyze`, `flutter test`, `python3 scripts/validate_content.py` … record … test count" | met (documented) | packet Verification: all three PASS, 134 tests; 134 = 132 prior + 2 new spot tests, so the count reconciles |
| R3 | "Preserve and verify the correct-answer progress … regressions" | met | `grammar_game.dart:24`, `idioms_game.dart:35`, `vocabulary_game.dart:35`; tests `grammar_game_test.dart:110`, `idioms_game_test.dart:59`, `vocabulary_game_test.dart:61` |
| R4 | "…`SpotGameState.isTextCompleted` regressions" | met | `spot_game.dart:57`; `spot_game_test.dart:141,163` |
| R5 | "durable across the critical answer → background/close path, including a deterministic flush/lifecycle seam" | partial | `user_progress.dart:180-193`; dispose/paused flush in all 4 screens; only `IdiomsScreen` lifecycle-tested |
| R6 | "regression tests for rapid answer sequences, failed writes/retries, flush ordering, and lifecycle-triggered persistence" | partial | `progress_repository_test.dart:30,56,80,131`; lifecycle only idioms |
| R7 | "Unit-test `ProgressRepository`…`recordAnswer`, `recordAnswers`, `flush`" with controlled/failing fakes | met | `progress_repository_test.dart:159-200` |
| R8 | "set spec `baseBranch` to `staging` and retain `releaseBranch` as `master`" | met | `.pi/settings.json:22-23`; `docs/releasing.md:42-43` |
| R9 | Out of scope: store/signing/analytics/privacy | met | diff confined to `lib/progress` + 4 game modules + tests |

**Findings**
- **P2** — "define the lifecycle flush behavior through an injectable/testable seam where practical": `GrammarScreen` (`grammar_screen.dart:66`) and `SpotScreen` (`spot_screen.dart:78`) still hardcode `ProgressRepository.load()`, so their "answer → background/close" flush is untested. Smallest fix: add `progressRepository` params (mirroring `idioms_screen.dart:21`) plus one lifecycle test each.
- **P2** — a11y labels now report correct answers while the bar encodes answered positions: `grammar_screen.dart:250`, `idioms_screen.dart:225`, `vocabulary_screen.dart:229`. Screen-reader output no longer matches the visual bar.
- **P2** — spot persistence wiring untested: `spot_screen.dart:180-187` (`_saveSessionProgress`, `_hasSavedSession`) has no test; only `SpotGameState.notionResults` is covered. Likewise `progress_repository_test.dart:56` proves recovery only because a later write follows — a single failed **final** write still loses the answer ("I do not lose an answer when the app is backgrounded").

Prior P1 (spot notion correctness) is **fixed** — `notionResults` uses per-mistake `foundIndices.contains(mistakeIndex)` (`spot_game.dart:60-72`). No material scope creep.

**Merge verdict: OK with notes.** Supervisor must run `flutter analyze`, `flutter test` (record total), `python3 scripts/validate_content.py`, `git status --porcelain`.

Report path: `/Users/m/dev/lexio/.pi/artifacts/spec-review/20260918T140806Z-81526/spec-review-postfix.md`