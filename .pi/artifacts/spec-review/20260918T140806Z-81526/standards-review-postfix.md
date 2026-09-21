## Review — documented standards + smell baseline

Scope: packet diff `0c25802` vs `staging` (15 files). No files modified.

**Correct**
- No AGENTS.md violations introduced. No new hardcoded design values: new screen code uses tokens; the `circular(2)`, `fontSize: 11`, `letterSpacing: 1.2` literals in `spot_screen.dart` are unchanged context lines. Import grouping complies (`dart:async` first, blank line, packages, project-relative) in all four screens and both new tests. New tests mirror `lib/` (`test/progress/` ↔ `lib/progress/`) per AGENTS.md §Testing; comments/code English, new user-facing strings Romanian. Test import style (relative + `avoid_relative_lib_imports` ignore) matches the dominant repo convention, not a deviation.
- Spec-endorsed, so not baseline smells: the `ProgressStorage` seam, `load({storage})`, and `flush()` are exactly the seams issue #46 mandates; `SharedPreferencesProgressStorage` is an adapter, not a Middle Man. Moving `notionResults` onto `SpotGameState` (spot_game.dart:47-59) and the `answer`/`next` guards fix real Feature Envy and Duplicated Code in the old `_saveSessionProgress`.

**Finding: P2 (Duplicated Code / Repeated Switches)** — the lifecycle-flush shape is copy-pasted four times: `grammar_screen.dart:56-61`, `idioms_screen.dart:65-70`, `vocabulary_screen.dart:69-74`, `spot_screen.dart:54-58`, plus the same `dispose` line at 48 / 57 / 61 / 43. Fix: one mixin (e.g. `lib/progress/progress_flush_observer.dart`) owning observer registration, `dispose` flush, and the tri-state check; screens adopt it with `with`, keeping spot's `resumed` branch local.

**Finding: P2 (Divergent Change)** — `lib/progress/user_progress.dart` now changes for four reasons: domain model, repository (:121), storage seam (:100-118), and `RoundSelector`. Smallest fix: move `ProgressStorage` + `SharedPreferencesProgressStorage` to `lib/progress/progress_storage.dart`; that directory already uses one concern per file.

**Finding: P2 (inconsistent seam)** — `progressRepository` injection exists only in `idioms_screen.dart:21-24` and `vocabulary_screen.dart:24-28`; `grammar_screen.dart:66` and `spot_screen.dart:78` still call `ProgressRepository.load()` directly, so the lifecycle behavior is testable for two games only.

**Finding: P2 (test-fake duplication)** — `_LifecycleProgressStorage` (`lifecycle_persistence_test.dart:88-100`) repeats the read/write shape of `_MemoryProgressStorage` (`progress_repository_test.dart:159-176`); share one helper.

No P0/P1. Tooling-enforced items (analyze/test/content validation) skipped.

**Merge verdict: OK with notes.**

Report path: `/Users/m/dev/lexio/.pi/artifacts/spec-review/20260918T140806Z-81526/standards-review-postfix.md`