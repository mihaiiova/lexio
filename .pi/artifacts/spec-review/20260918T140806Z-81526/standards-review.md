## Review

**Artifact:** `/Users/m/dev/lexio/.pi/artifacts/spec-review/20260918T140806Z-81526/standards-review.md`

### Documented-standard violations (AGENTS.md)
**None found.** Checked against the diff: import grouping (`lib/games/grammar/grammar_screen.dart:1` dart → package → relative), no `package:lexio/` imports, snake_case files, `PascalCase`/`camelCase`/`_` private naming, `final` over `var` (all `var` locals are reassigned, e.g. `user_progress.dart:132,167`), no comments, Romanian user-facing strings, no added hardcoded design values. Import order, const-ness, and unused imports are analyzer-enforced — skipped.

Pre-existing, context-only: `lib/games/spot/spot_screen.dart:353` `borderRadius: BorderRadius.circular(2)` sits in a hunk the diff edits but the line itself is unchanged (hardcoded radius per AGENTS.md). Report-only.

### Baseline smells (judgement calls)
1. **Duplicated Code** — identical lifecycle plumbing in four screens: `grammar_screen.dart:41-61`, `idioms_screen.dart:42-69`, `vocabulary_screen.dart:46-73`, `spot_screen.dart:36-58`, e.g. `unawaited(_progress?.flush()); WidgetsBinding.instance.removeObserver(this);` and the same `paused || inactive || detached` cascade. AGENTS.md's "keep state local to the screen" doesn't override this — a mixin still keeps state local.
2. **Shotgun Surgery / Divergent Change** — the `progress` getter changed to `correctCount / exercises.length` in four state files plus four test files, yet `grep '\.progress\b'` shows **no production consumer**: it is asserted only in tests. Eight files changed for a test-only accessor.
3. **Speculative Generality (asymmetry)** — the test seam exists only on two screens (`idioms_screen.dart:21`, `vocabulary_screen.dart:24`), so flush/close behaviour is tested only for idioms; `grammar_screen.dart:48,55` and `spot_screen.dart:43,57` flush paths are unverified. Spec sanctioned an injectable seam, so this is report-only.
4. **Duplicated Code (tests)** — `_LifecycleProgressStorage` (`test/progress/lifecycle_persistence_test.dart:88-99`) duplicates `_MemoryProgressStorage` (`test/progress/progress_repository_test.dart:159-176`), minus failure injection; `_LifecycleProgressStorage.writes` (line 90) is written but never read (dead field).
5. **Primitive Obsession** — `user_progress.dart:107-110`: `Future<String?> read(); Future<void> write(String value);` passes raw JSON where the domain type is `UserProgress`.

### P2 findings
- `test/progress/lifecycle_persistence_test.dart:90` dead `writes` field (quote above).
- `lib/games/spot/spot_game.dart:56` `allMistakesFoundInCurrentText => isTextCompleted(currentTextIndex)` bypasses the `texts.isEmpty` guard added in the same hunk (lines 52-57); unguarded `isTextCompleted` (line 59) throws `RangeError` for empty texts where the old expression returned `true`. Unreachable via the screen (spot_screen.dart:build → currentText throws first), so report-only; smallest fix is `texts.isEmpty ||` inside `isTextCompleted`.
- Semantics labels now report correctness while the same bar displays answered state: `grammar_screen.dart:250`, `idioms_screen.dart:225`, `vocabulary_screen.dart:229`.

**Merge verdict: OK with notes.** No documented-standard violations; smells are consolidation opportunities, not blockers. Supervisor should run `flutter analyze`/`flutter test` (tooling evidence in packet: analyze PASS, 132 tests).